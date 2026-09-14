require "httparty"
require "json"

class GeminiCategorizer
  DEFAULT_MODEL = "gemini-3.5-flash-lite".freeze

  def initialize(transactions)
    @transactions = Array(transactions)
    @categories = Category.all.to_a
  end

  def call
    return { success: false, error: "İşlem listesi boş." } if @transactions.empty?
    return { success: false, error: "Tanımlı kategori bulunamadı." } if @categories.empty?

    api_key = fetch_api_key
    if api_key.blank?
      fallback_results = fallback_categorize(@transactions)
      return {
        success: true,
        results: fallback_results[:results],
        details: fallback_results[:details],
        fallback: true,
        message: "Gemini API anahtarı ayarlanmadığı için kural tabanlı derin eşleme kullanıldı."
      }
    end

    result = call_gemini(api_key)
    if result[:success]
      {
        success: true,
        results: result[:results],
        details: result[:details],
        fallback: false
      }
    else
      fallback_results = fallback_categorize(@transactions)
      {
        success: true,
        results: fallback_results[:results],
        details: fallback_results[:details],
        fallback: true,
        error: result[:error]
      }
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
      {
        id: tx.id,
        date: tx.date&.strftime("%d.%m.%Y"),
        description: tx.description,
        amount: tx.amount.to_f
      }
    end

    prompt = <<~PROMPT
      Sen kıdemli bir finans, bankacılık ve işlem analizi yapay zekası uzmanısın.
      Aşağıda bir banka ekstresindeki işlemlerin ID'si, tarihi, açıklaması ve tutarı verilmiştir.

      Banka ekstrelerinde işlem açıklamaları genellikle POS terminal kodları (örn: POS 12345), ödeme ağ geçitleri (İyzico, PayTR, Param, Sipay, Moka, BKM Express, GarantiPay), kurumsal unvan ekleri (A.Ş., Ltd. Şti., Tic., Paz., Dağ.), FAST/EFT transfer kodları veya kısaltmalar içerir.

      GÖREVİN:
      Her bir işlemi derinlemesine analiz etmek, arkasındaki gerçek kurum ve harcama amacını anlamak ve doğru kategoriye atamaktır.

      HER İŞLEM İÇİN ŞUNLARI ÇIKAR:
      1. "merchant": Gürültüden ve POS/unvan eklerinden arındırılmış temiz işletme, marka, platform, kurum veya kişi adı.
         Örnekler:
         - "POS 48201 IYZICO / TRENDYOL ISTANBUL" -> "Trendyol"
         - "CK BOGAZICI ELEKTRIK PERAKENDE SATIS" -> "CK Boğaziçi Elektrik"
         - "TAB GIDA BURGER KING KADIKOY" -> "Burger King"
         - "OPET AKARYAKIT ISTASYONU LEVENT" -> "Opet"
         - "FAST TR3200... AHMET YILMAZ KIRA ODEMESI" -> "Ahmet Yılmaz"
         - "APPLE SERVICES COM/BILL" -> "Apple"
      2. "analysis": Bu harcamanın veya gelirin tam olarak ne olduğunu ve amacını açıklayan net, profesyonel Türkçe 1 cümle.
         Örnekler:
         - "Online e-ticaret platformu giyim ve ürün alışverişi."
         - "Mesken elektrik aboneliği faturası ödemesi."
         - "Restoran ve fast-food yeme-içme harcaması."
         - "Akaryakıt istasyonundan benzin/motorin alımı."
         - "Aylık konut kira bedeli ödemesi."
         - "Aylık personel maaş hakedişi transferi."
      3. "category": YALNIZCA aşağıdaki geçerli kategorilerden en uygun olanını seç:
         #{category_names.join(", ")}
         - Asla kolayca "Diğer" seçeneğine kaçma!
         - Bir işlem giyim, e-ticaret, elektronik veya mağaza alışverişi ise 'Alışveriş' varsa onu, yoksa içeriğe en yakın kategoriyi seç.
         - Bir işlem restoran, kafe, hazır yemek ise 'Yeme & İçme' varsa onu, yoksa 'Eğlence' seç.
         - Sadece gerçekten hiçbir anlam çıkarılamayan rastgele anlamsız karakterler için "Diğer" kullan.
         - Pozitif tutarlar genellikle "Maaş / Gelir" veya benzeri gelir kategorilerine aittir.
      4. "confidence": 0.0 ile 1.0 arasında güven puanı (örn: 0.95).

      SADECE aşağıdaki JSON formatında geçerli bir JSON dizisi döndür:
      [
        {
          "id": 123,
          "merchant": "Trendyol",
          "analysis": "Online e-ticaret giyim ve kişisel alışveriş harcaması.",
          "category": "Alışveriş",
          "confidence": 0.98
        }
      ]

      İŞLEMLER:
      #{items_to_categorize.to_json}
    PROMPT

    url = "https://generativelanguage.googleapis.com/v1beta/models/#{model_name}:generateContent?key=#{api_key}"
    response = HTTParty.post(
      url,
      headers: { "Content-Type" => "application/json" },
      body: {
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { responseMimeType: "application/json" }
      }.to_json,
      timeout: 25
    )

    unless response.success?
      Rails.logger.error("Gemini API Hatası: #{response.code} - #{response.body}")
      return { success: false, error: "Gemini API hatası: #{response.code}" }
    end

    raw_text = response.dig("candidates", 0, "content", "parts", 0, "text")
    return { success: false, error: "Boş yanıt alındı." } if raw_text.blank?

    cleaned_json = raw_text.gsub(/```json|```/, "").strip
    parsed = JSON.parse(cleaned_json)

    results = {}
    details = {}

    parsed.each do |item|
      tx_id = item["id"].to_i
      next unless tx_id > 0

      cat_name = item["category"].to_s.strip
      merchant = item["merchant"].to_s.strip.presence
      analysis = item["analysis"].to_s.strip.presence
      confidence = item["confidence"].to_f

      results[tx_id] = cat_name if cat_name.present?
      details[tx_id] = {
        category: cat_name,
        merchant: merchant,
        analysis: analysis,
        confidence: confidence > 0 ? confidence : 0.9
      }
    end

    { success: true, results: results, details: details }
  rescue JSON::ParserError => e
    Rails.logger.error("Gemini JSON Ayrıştırma Hatası: #{e.message}")
    { success: false, error: "JSON ayrıştırma hatası: #{e.message}" }
  rescue StandardError => e
    Rails.logger.error("Gemini Çağrı Hatası: #{e.message}")
    { success: false, error: e.message }
  end

  # Local rule-based fallback when Gemini API key is missing or offline
  def fallback_categorize(transactions)
    results = {}
    details = {}
    available_cats = @categories.map(&:name)

    transactions.each do |tx|
      desc = tx.description.to_s
      clean_desc = desc.gsub(/\b(POS|DEKONT|REF|FIS NO|ISLEM NO|TR\d+|TL|TRY)\b/i, "")
                       .gsub(/\b\d{5,}\b/, "")
                       .gsub(/\s+/, " ")
                       .strip

      norm = normalize_tr(desc)
      amount = tx.amount.to_f

      merchant = nil
      analysis = nil
      cat = nil

      if amount > 0
        cat = "Maaş / Gelir"
        merchant = clean_desc.gsub(/MAAS|ODEME|TRANSFER|GELIR/i, "").strip.presence || "İşveren / Gelir Kaynağı"
        analysis = "Aylık personel maaş ödemesi veya hesaba aktarılan pozitif gelir transferi."
      elsif norm =~ /migros|macrocenter/
        cat = "Market"
        merchant = "Migros"
        analysis = "Süpermarket gıda, taze reyon ve günlük ev tüketim alışverişi."
      elsif norm =~ /\bbim\b|bim birlesik/
        cat = "Market"
        merchant = "BİM"
        analysis = "Perakende zincir marketten temel gıda ve ihtiyaç maddeleri alımı."
      elsif norm =~ /a101/
        cat = "Market"
        merchant = "A101"
        analysis = "Zincir market gıda ve tüketim malzemesi alışverişi."
      elsif norm =~ /sok|carrefour/
        cat = "Market"
        merchant = norm.include?("sok") ? "Şok Market" : "CarrefourSA"
        analysis = "Market ve süpermarket temel ihtiyaç harcaması."
      elsif norm =~ /turkcell|vodafone|turk telekom/
        cat = "Fatura"
        merchant = norm.include?("turkcell") ? "Turkcell" : (norm.include?("vodafone") ? "Vodafone" : "Türk Telekom")
        analysis = "GSM mobil hat ve internet iletişim hizmeti fatura ödemesi."
      elsif norm =~ /enerjisa|ck bogazici|elektrik/
        cat = "Fatura"
        merchant = "Elektrik Dağıtım Şirketi"
        analysis = "Aylık mesken elektrik tüketim faturası tahsilatı."
      elsif norm =~ /igdas|dogalgaz/
        cat = "Fatura"
        merchant = "İGDAŞ"
        analysis = "Konut doğalgaz ısınma ve kullanım faturası ödemesi."
      elsif norm =~ /iski|su faturasi/
        cat = "Fatura"
        merchant = "İSKİ"
        analysis = "Şebeke suyu ve atıksu hizmeti fatura ödemesi."
      elsif norm =~ /kira|ev sahibi/
        cat = "Kira & Konut"
        merchant = "Ev Sahibi / Mülk Sahibi"
        analysis = "Aylık konut/işyeri kira bedeli transferi."
      elsif norm =~ /aidat|apartman|site yonetim/
        cat = "Kira & Konut"
        merchant = "Site / Apartman Yönetimi"
        analysis = "Aylık apartman veya site ortak gider aidatı ödemesi."
      elsif norm =~ /trendyol|hepsiburada|amazon|zara|lcw|mango|boyner|decathlon|ikea|vatan|mediamarkt|teknosa/
        cat = available_cats.include?("Alışveriş") ? "Alışveriş" : "Diğer"
        merchant = norm =~ /trendyol/ ? "Trendyol" : (norm =~ /hepsiburada/ ? "Hepsiburada" : (norm =~ /amazon/ ? "Amazon" : "Alışveriş Mağazası"))
        analysis = "Giyim, teknoloji veya ev yaşam ihtiyaçları için online/mağaza alışverişi."
      elsif norm =~ /yemeksepeti|getir yemek|burger king|mcdonalds|starbucks|kahve|cafe|restaurant|restoran|doner|kebap|pizza/
        cat = available_cats.include?("Yeme & İçme") ? "Yeme & İçme" : "Eğlence"
        merchant = norm =~ /starbucks/ ? "Starbucks" : (norm =~ /yemeksepeti/ ? "Yemeksepeti" : (norm =~ /burger king/ ? "Burger King" : "Restoran / Kafe"))
        analysis = "Restoran, kafe veya online yemek siparişi harcaması."
      elsif norm =~ /netflix|spotify|youtube|apple|google|steam|playstation|sinema|biletix/
        cat = "Eğlence"
        merchant = norm =~ /netflix/ ? "Netflix" : (norm =~ /spotify/ ? "Spotify" : (norm =~ /apple/ ? "Apple" : "Dijital Eğlence"))
        analysis = "Dijital medya platformu abonelik veya eğlence harcaması."
      elsif norm =~ /shell|opet|bp|petrol ofisi|benzin|akaryakit/
        cat = "Ulaşım"
        merchant = norm =~ /shell/ ? "Shell" : (norm =~ /opet/ ? "Opet" : (norm =~ /bp/ ? "BP" : "Akaryakıt İstasyonu"))
        analysis = "Araç için akaryakıt veya benzin istasyonu harcaması."
      elsif norm =~ /istanbulkart|iett|metro|marmaray|uber|taksi|bitaksi|marti|binbin|otopark|ispark|hgs|ogs/
        cat = "Ulaşım"
        merchant = norm =~ /istanbulkart/ ? "İstanbulkart" : (norm =~ /ispark/ ? "İSPARK" : (norm =~ /uber/ ? "Uber" : "Toplu Taşıma / Ulaşım"))
        analysis = "Toplu taşıma dolumu, taksi veya şehir içi seyahat ücreti."
      elsif norm =~ /eczane|hastane|doktor|klinik|medikal|saglik/
        cat = "Sağlık"
        merchant = "Eczane / Sağlık Kuruluşu"
        analysis = "Reçeteli ilaç veya sağlık ve medikal hizmet ödemesi."
      else
        cat = "Diğer"
        merchant = clean_desc.truncate(30)
        analysis = "Banka ekstresinde yer alan muhtelif hesap hareketi."
      end

      results[tx.id] = cat
      details[tx.id] = {
        category: cat,
        merchant: merchant,
        analysis: analysis,
        confidence: 0.85
      }
    end

    { results: results, details: details }
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
