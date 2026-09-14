require "csv"

module StatementParsers
  class CsvParser
    DATE_HEADERS = [
      "tarih", "işlem tarihi", "islem tarihi", "valor tarihi", "valör tarihi",
      "dekont tarihi", "date", "trans date", "transaction date"
    ].freeze

    DESC_HEADERS = [
      "açıklama", "aciklama", "işlem açıklaması", "islem aciklamasi",
      "tanım", "tanim", "detay", "işlem detayı", "islem detayi",
      "description", "details", "narrative"
    ].freeze

    AMOUNT_HEADERS = [
      "tutar", "işlem tutarı", "islem tutari", "tutar (tl)", "tutar (try)",
      "amount", "hareket tutarı"
    ].freeze

    DEBIT_HEADERS = ["borç", "borc", "debit", "çekilen", "cekilen", "harcama"].freeze
    CREDIT_HEADERS = ["alacak", "credit", "yatırılan", "yatirilan", "gelir"].freeze

    def initialize(file_or_content, statement: nil)
      @content = extract_content(file_or_content)
      @statement = statement
    end

    def call
      return { success: false, error: "Dosya içeriği boş." } if @content.blank?

      normalized_text = normalize_encoding(@content)
      delimiter = detect_delimiter(normalized_text)
      rows = parse_rows(normalized_text, delimiter)

      return { success: false, error: "CSV satırları okunamadı." } if rows.empty?

      header_idx, mapping = detect_headers(rows)
      return { success: false, error: "Tarih, açıklama veya tutar sütunları tespit edilemedi." } unless mapping

      parsed_transactions = []
      rows[(header_idx + 1)..].each do |row|
        next if row.compact.empty?

        date_val = parse_date(row[mapping[:date]])
        desc_val = clean_description(row[mapping[:desc]])
        amount_val = extract_amount(row, mapping)

        next unless date_val && desc_val.present? && amount_val.present?

        raw_line = row.join(delimiter)

        parsed_transactions << {
          date: date_val,
          description: desc_val,
          amount: amount_val,
          raw_row: raw_line,
          categorized_by: :unassigned
        }
      end

      return { success: false, error: "Geçerli işlem satırı bulunamadı." } if parsed_transactions.empty?

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
    rescue CSV::MalformedCSVError => e
      { success: false, error: "CSV biçimi geçersiz: #{e.message}" }
    rescue StandardError => e
      { success: false, error: "Ayrıştırma hatası: #{e.message}" }
    end

    private

    def extract_content(file_or_content)
      if file_or_content.respond_to?(:read)
        file_or_content.rewind if file_or_content.respond_to?(:rewind)
        file_or_content.read
      else
        file_or_content.to_s
      end
    end

    def normalize_encoding(str)
      return "" if str.blank?

      if str.valid_encoding? && str.encoding == Encoding::UTF_8
        str.sub("\xEF\xBB\xBF", "") # remove UTF-8 BOM if present
      else
        # Try Windows-1254 (Turkish) then ISO-8859-9 then binary force
        begin
          str.encode("UTF-8", "Windows-1254", invalid: :replace, undef: :replace)
        rescue EncodingError
          str.encode("UTF-8", "ISO-8859-9", invalid: :replace, undef: :replace)
        end
      end
    end

    def detect_delimiter(text)
      first_lines = text.lines.first(10).join("\n")
      semicolons = first_lines.count(";")
      commas = first_lines.count(",")
      tabs = first_lines.count("\t")

      counts = { ";" => semicolons, "," => commas, "\t" => tabs }
      max_delimiter = counts.max_by { |_, count| count }
      max_delimiter && max_delimiter[1] > 0 ? max_delimiter[0] : ";"
    end

    def parse_rows(text, delimiter)
      CSV.parse(text, col_sep: delimiter, liberal_parsing: true)
    rescue CSV::MalformedCSVError
      # Fallback: parse line by line
      text.lines.map do |line|
        line.strip.split(delimiter).map(&:strip)
      end
    end

    def detect_headers(rows)
      rows.each_with_index do |row, idx|
        next if row.nil? || row.empty?

        sanitized_cells = row.map { |cell| cell.to_s.strip.downcase }

        date_col = sanitized_cells.find_index { |c| DATE_HEADERS.any? { |h| c.include?(h) } }
        desc_col = sanitized_cells.find_index { |c| DESC_HEADERS.any? { |h| c.include?(h) } }
        amount_col = sanitized_cells.find_index { |c| AMOUNT_HEADERS.any? { |h| c == h || c.include?(h) } }

        debit_col = sanitized_cells.find_index { |c| DEBIT_HEADERS.any? { |h| c == h || c.include?(h) } }
        credit_col = sanitized_cells.find_index { |c| CREDIT_HEADERS.any? { |h| c == h || c.include?(h) } }

        if date_col && desc_col && (amount_col || (debit_col && credit_col) || debit_col || credit_col)
          mapping = {
            date: date_col,
            desc: desc_col,
            amount: amount_col,
            debit: debit_col,
            credit: credit_col
          }
          return [idx, mapping]
        end
      end

      nil
    end

    def parse_date(date_str)
      return nil if date_str.blank?

      cleaned = date_str.to_s.strip
      # Formats: DD.MM.YYYY, DD/MM/YYYY, YYYY-MM-DD, DD-MM-YYYY
      if cleaned =~ %r{^(\d{1,2})[./-](\d{1,2})[./-](\d{4})}
        day = $1.to_i
        month = $2.to_i
        year = $3.to_i
        Date.new(year, month, day) rescue nil
      elsif cleaned =~ %r{^(\d{4})[./-](\d{1,2})[./-](\d{1,2})}
        year = $1.to_i
        month = $2.to_i
        day = $3.to_i
        Date.new(year, month, day) rescue nil
      else
        Date.parse(cleaned) rescue nil
      end
    end

    def clean_description(desc)
      return "" if desc.blank?
      desc.to_s.gsub(/\s+/, " ").strip
    end

    def extract_amount(row, mapping)
      if mapping[:amount] && row[mapping[:amount]].present?
        raw_val = row[mapping[:amount]]
        parse_number(raw_val)
      elsif mapping[:debit] && row[mapping[:debit]].present? && parse_number(row[mapping[:debit]]).to_f != 0
        debit_val = parse_number(row[mapping[:debit]]).abs
        -debit_val # Debit is an expense
      elsif mapping[:credit] && row[mapping[:credit]].present? && parse_number(row[mapping[:credit]]).to_f != 0
        parse_number(row[mapping[:credit]]).abs # Credit is an income
      else
        nil
      end
    end

    def parse_number(num_str)
      return nil if num_str.blank?

      str = num_str.to_s.strip
      # Remove currency symbols or text like TL, TRY, $, EUR
      str = str.gsub(/[^\d.,\-+()]/, "").strip

      # Check parenthesis notation: (120,50) -> -120,50
      if str =~ /^\((.*)\)$/
        str = "-#{$1}"
      end

      # Trailing minus: 120,50- -> -120,50
      if str.end_with?("-")
        str = "-#{str.chomp('-')}"
      end

      # Handle Turkish / European vs US formatting
      # If string has both dot and comma (e.g. 1.250,50):
      if str.include?(".") && str.include?(",")
        if str.rindex(",") > str.rindex(".")
          # 1.250,50 -> 1250.50
          str = str.gsub(".", "").tr(",", ".")
        else
          # 1,250.50 -> 1250.50
          str = str.tr(",", "")
        end
      elsif str.include?(",")
        # Only comma (e.g. 1250,50)
        str = str.tr(",", ".")
      end

      BigDecimal(str) rescue nil
    end
  end
end
