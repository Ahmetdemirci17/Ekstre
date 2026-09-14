require "open3"
require "tempfile"
require "bigdecimal"

module StatementParsers
  class PdfParser
    BANK_SIGNATURES = {
      "Garanti BBVA" => /garanti/i,
      "İş Bankası" => /is\s*bankasi|isbank/i,
      "Yapı Kredi" => /yapi\s*(ve)?\s*kredi/i,
      "Akbank" => /akbank/i,
      "QNB Finansbank" => /qnb|finansbank/i,
      "Enpara" => /enpara/i,
      "Ziraat Bankası" => /ziraat/i,
      "VakıfBank" => /vakif\s*bank/i
    }.freeze

    DATE_REGEX = %r{\b(\d{1,2}[./-]\d{1,2}[./-]\d{4})\b}
    AMOUNT_PATTERN = %r{([+-]?\s*\(?[\d]+(?:[.,]\d{3})*(?:[.,]\d{2})\)?\s*(?:\([BA]\)|[BA]|\-|\+|TL|TRY)?)}i

    def initialize(file_or_path, statement: nil)
      @file_or_path = file_or_path
      @statement = statement
    end

    def call
      raw_text = extract_text_from_pdf
      return { success: false, error: "PDF metni okunamadı veya dosya boş." } if raw_text.blank?

      auto_detect_bank(raw_text)

      lines = raw_text.lines.map(&:strip).reject(&:empty?)
      parsed_transactions = []

      lines.each do |line|
        tx = parse_line(line)
        parsed_transactions << tx if tx.present?
      end

      return { success: false, error: "PDF içerisinde geçerli hesap hareketi bulunamadı." } if parsed_transactions.empty?

      if @statement
        created_records = []
        ActiveRecord::Base.transaction do
          parsed_transactions.each do |tx_attrs|
            created_records << @statement.transactions.create!(tx_attrs)
          end
          @statement.update!(status: :parsed)
        end
        { success: true, count: created_records.size, transactions: created_records }
      else
        { success: true, count: parsed_transactions.size, transactions: parsed_transactions }
      end
    rescue StandardError => e
      Rails.logger.error("PdfParser Hatası: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
      { success: false, error: "PDF ayrıştırma hatası: #{e.message}" }
    end

    private

    def extract_text_from_pdf
      if @file_or_path.is_a?(String) && File.exist?(@file_or_path)
        run_pdftotext(@file_or_path)
      elsif @file_or_path.respond_to?(:path) && @file_or_path.path.present? && File.exist?(@file_or_path.path)
        run_pdftotext(@file_or_path.path)
      else
        temp_file = Tempfile.new(["statement_upload", ".pdf"], binmode: true)
        begin
          if @file_or_path.respond_to?(:read)
            @file_or_path.rewind if @file_or_path.respond_to?(:rewind)
            temp_file.write(@file_or_path.read)
          else
            temp_file.write(@file_or_path.to_s)
          end
          temp_file.flush
          run_pdftotext(temp_file.path)
        ensure
          temp_file.close
          temp_file.unlink
        end
      end
    end

    def run_pdftotext(path)
      stdout, stderr, status = Open3.capture3("pdftotext", "-layout", "-enc", "UTF-8", path, "-")
      unless status.success?
        Rails.logger.warn("pdftotext uyarısı: #{stderr}")
      end
      stdout
    rescue Errno::ENOENT
      Rails.logger.error("pdftotext komutu sistemde bulunamadı.")
      nil
    end

    def auto_detect_bank(text)
      return if @statement.nil? || @statement.bank_name.present?

      first_chunk = text.lines.first(40).join(" ")
      normalized_chunk = normalize_tr(first_chunk)

      BANK_SIGNATURES.each do |bank_name, regex|
        if normalized_chunk =~ regex
          @statement.update_column(:bank_name, bank_name)
          break
        end
      end
    end

    def parse_line(line)
      # Skip metadata / headers / footers
      norm = normalize_tr(line)
      return nil if norm =~ /\b(sayfa|page|toplam|devreden|hesap no|iban|musteri no|donem:)\b/i
      return nil unless line =~ DATE_REGEX

      date_str = $1
      date_val = parse_date(date_str)
      return nil unless date_val

      # Everything after the date
      idx = line.index(date_str)
      after_date = line[(idx + date_str.length)..].strip

      # Find all numeric currency patterns in the rest of the line
      matches = after_date.scan(AMOUNT_PATTERN).flatten.map(&:strip)
      return nil if matches.empty?

      # Find valid parsed amounts
      valid_amounts = matches.map { |m| [m, parse_number_token(m)] }.reject { |_, val| val.nil? }
      return nil if valid_amounts.empty?

      # In bank statements with multiple numbers (e.g. Tutar and Bakiye),
      # the transaction amount is the first valid amount token after description
      amount_token, amount_val = valid_amounts.first

      # Description is between date and the amount token
      token_idx = after_date.rindex(amount_token) || after_date.index(amount_token)
      desc = token_idx ? after_date[0...token_idx].strip : after_date

      # Clean up description
      cleaned_desc = clean_description(desc)
      return nil if cleaned_desc.blank?

      {
        date: date_val,
        description: cleaned_desc,
        amount: amount_val,
        raw_row: line,
        categorized_by: :unassigned
      }
    end

    def parse_date(date_str)
      cleaned = date_str.to_s.strip
      if cleaned =~ %r{^(\d{1,2})[./-](\d{1,2})[./-](\d{4})}
        Date.new($3.to_i, $2.to_i, $1.to_i) rescue nil
      elsif cleaned =~ %r{^(\d{4})[./-](\d{1,2})[./-](\d{1,2})}
        Date.new($1.to_i, $2.to_i, $3.to_i) rescue nil
      else
        Date.parse(cleaned) rescue nil
      end
    end

    def parse_number_token(token)
      str = token.to_s.strip

      is_debit = false
      is_credit = false

      if str =~ /\(B\)/i || str.end_with?(" B", " b")
        is_debit = true
      elsif str =~ /\(A\)/i || str.end_with?(" A", " a")
        is_credit = true
      end

      # Strip indicators and currencies
      clean = str.gsub(/\([BA]\)/i, "")
                 .gsub(/\b[BA]\b/i, "")
                 .gsub(/TL|TRY|₺|\$/i, "")
                 .strip

      is_negative = clean.start_with?("-") || clean.end_with?("-") || (clean.start_with?("(") && clean.end_with?(")"))
      clean = clean.gsub(/[^\d.,]/, "").strip
      return nil if clean.blank?

      # Handle comma/dot formatting
      if clean.include?(".") && clean.include?(",")
        if clean.rindex(",") > clean.rindex(".")
          clean = clean.gsub(".", "").tr(",", ".")
        else
          clean = clean.tr(",", "")
        end
      elsif clean.include?(",")
        clean = clean.tr(",", ".")
      end

      val = BigDecimal(clean) rescue nil
      return nil unless val && val.abs > 0

      if is_debit || is_negative
        -val.abs
      elsif is_credit
        val.abs
      else
        # If no explicit sign or B/A indicator, default to expense unless marked positive
        token.include?("+") ? val.abs : -val.abs
      end
    end

    def clean_description(desc)
      return "" if desc.blank?

      desc.gsub(/\b(DEKONT|REF|ISLEM NO|FIS NO):\s*\w+/i, "")
          .gsub(/\s+/, " ")
          .strip
    end

    def normalize_tr(text)
      text.to_s
          .tr("İIı", "iii")
          .tr("Şş", "ss")
          .tr("Ğğ", "gg")
          .tr("Çç", "cc")
          .tr("Öö", "oo")
          .tr("Üü", "uu")
          .downcase
    end
  end
end
