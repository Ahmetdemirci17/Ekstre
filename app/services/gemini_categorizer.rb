require "httparty"
require "json"

class GeminiCategorizer
  DEFAULT_MODEL = "gemini-2.5-flash".freeze

  def initialize(transactions)
    @transactions = Array(transactions)
    @categories = Category.all.to_a
  end

  def call
    return { success: false, error: "İşlem listesi boş." } if @transactions.empty?
    return { success: false, error: "Tanımlı kategori bulunamadı." } if @categories.empty?

    api_key = fetch_api_key
    if api_key.blank?
      # Fallback when API key is not configured
      fallback_mapping = fallback_categorize(@transactions)
      return { success: true, results: fallback_mapping, fallback: true, message: "Gemini API anahtarı ayarlanmadığı için kural tabanlı eşleme kullanıldı." }
    end

    result = call_gemini(api_key)
    if result[:success]
      { success: true, results: result[:mapping], fallback: false }
    else
      # Graceful fallback to keyword rules if API call fails
      fallback_mapping = fallback_categorize(@transactions)
      { success: true, results: fallback_mapping, fallback: true, error: result[:error] }
    end
  end

  private

  def fetch_api_key
    Rails.application.credentials.dig(:gemini, :api_key) || ENV["GEMINI_API_KEY"]
  end

  def model_name
    ENV["GEMINI_MODEL"] || Rails.application.credentials.dig(:gemini, :model_name) || DEFAULT_MODEL
  end

  def call_gemini(api_key)
    category_names = @categories.map(&:name)
    items_to_categorize = @transactions.map do |tx|
      { id: tx.id, description: tx.description, amount: tx.amount.to_f }
    end

    prompt = <<~PROMPT
      Sen bir finans ve bütçe uzmanısın. Aşağıda bir banka ekstresindeki işlemlerin ID'si, açıklaması ve tutarı verilmiştir.
      Görevin her bir işlemi, YALNIZCA aşağıdaki geçerli kategorilerden en uygun olanına atamaktır.

      GEÇERLİ KATEGORİLER:
      #{category_names.join(", ")}

      KURALLAR:
      1. Sadece yukarıda verilen geçerli kategorilerden birini seç.
      2. Emin olamadığın veya genel işlemler için 'Diğer' kategorisini seç.
      3. Pozitif tutarlar genellikle 'Maaş / Gelir' veya benzeri gelir kategorilerine aittir.
      4. SADECE aşağıdaki JSON formatında geçerli bir JSON dizisi döndür, başka hiçbir metin veya açıklama ekleme:

      [
        { "id": 123, "category": "KategoriAdı" }
      ]

      İŞLEMLER:
      #{items_to_categorize.to_json}
    PROMPT

    url = "https://generativelanguage.googleapis.com/v1beta/models/#{model_name}:generateContent?key=#{api_key}"
    response = HTTParty.post(
      url,
      headers: { "Content-Type" => "application/json" },
      body: { contents: [{ parts: [{ text: prompt }] }] }.to_json,
      timeout: 15
    )

    unless response.success?
      Rails.logger.error("Gemini API Hatası: #{response.code} - #{response.body}")
      return { success: false, error: "Gemini API hatası: #{response.code}" }
    end

    raw_text = response.dig("candidates", 0, "content", "parts", 0, "text")
    return { success: false, error: "Boş yanıt alındı." } if raw_text.blank?

    cleaned_json = raw_text.gsub(/```json|```/, "").strip
    parsed = JSON.parse(cleaned_json)

    mapping = {}
    parsed.each do |item|
      tx_id = item["id"].to_i
      cat_name = item["category"].to_s.strip
      mapping[tx_id] = cat_name if tx_id > 0 && cat_name.present?
    end

    { success: true, mapping: mapping }
  rescue JSON::ParserError => e
    Rails.logger.error("Gemini JSON Ayrıştırma Hatası: #{e.message}")
    { success: false, error: "JSON ayrıştırma hatası: #{e.message}" }
  rescue StandardError => e
    Rails.logger.error("Gemini Çağrı Hatası: #{e.message}")
    { success: false, error: e.message }
  end

  # Local rule-based fallback when Gemini API key is missing or offline
  def fallback_categorize(transactions)
    mapping = {}
    transactions.each do |tx|
      desc = tx.description.to_s
               .tr("İIı", "iii")
               .tr("Şş", "ss")
               .tr("Ğğ", "gg")
               .tr("Çç", "cc")
               .tr("Öö", "oo")
               .tr("Üü", "uu")
               .downcase

      cat = if tx.amount.to_f > 0
              "Maaş / Gelir"
            elsif desc.match?(/migros|bim|a101|sok|carrefour|market|firin|kasap|manav|sarkuteri/i)
              "Market"
            elsif desc.match?(/fatura|turkcell|vodafone|turk telekom|enerjisa|iski|igdas|elektrik|su|dogalgaz|internet/i)
              "Fatura"
            elsif desc.match?(/kira|ev sahibi|aidat|apartman/i)
              "Kira & Konut"
            elsif desc.match?(/netflix|spotify|sinema|biletix|bilet|kafe|cafe|restaurant|restoran|steam|oyun|starbucks/i)
              "Eğlence"
            elsif desc.match?(/uber|taksi|metro|iett|marmaray|benzin|opet|shell|bp|otopark|hgs|ogs|ulasim|istanbulkart/i)
              "Ulaşım"
            elsif desc.match?(/eczane|hastane|doktor|klinik|medikal|saglik/i)
              "Sağlık"
            else
              "Diğer"
            end

      mapping[tx.id] = cat
    end
    mapping
  end
end
