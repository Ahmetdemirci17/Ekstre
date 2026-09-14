# Seed default categories with distinct matte banking colors
default_categories = [
  { name: "Market", color: "#2D936C" },       # Matte Sage
  { name: "Fatura", color: "#B91C1C" },       # Matte Crimson
  { name: "Ulaşım", color: "#D97706" },       # Matte Amber
  { name: "Yeme & İçme", color: "#EA580C" },  # Matte Warm Orange
  { name: "Alışveriş", color: "#9333EA" },    # Matte Violet
  { name: "Eğlence", color: "#4F46E5" },      # Matte Indigo
  { name: "Sağlık", color: "#BE185D" },       # Matte Rose
  { name: "Kira & Konut", color: "#2563EB" }, # Matte Blue
  { name: "Eğitim", color: "#0284C7" },       # Matte Sky Blue
  { name: "Maaş / Gelir", color: "#059669" }, # Matte Forest
  { name: "Diğer", color: "#64748B" }         # Matte Slate Gray
]

categories = {}
default_categories.each do |cat|
  category = Category.find_or_initialize_by(name: cat[:name])
  category.color = cat[:color]
  category.save!
  categories[cat[:name]] = category
end

puts "Seeded #{Category.count} categories."

# 6 Months of realistic Turkish banking statements & transactions
# Nisan 2026 - Eylül 2026 (Son 6 ay)
monthly_statements = [
  {
    bank: "Garanti BBVA",
    filename: "garanti_ekstre_nisan_2026.csv",
    date_prefix: "2026-04",
    imported_at: Time.zone.parse("2026-05-01 09:30:00"),
    items: [
      { day: 1, desc: "ABC TEKNOLOJI A.S. MAAS ODEMESI", amount: 78500.00, cat: "Maaş / Gelir" },
      { day: 2, desc: "EV SAHIBI AHMET YILMAZ KIRA BEDELI", amount: -22000.00, cat: "Kira & Konut" },
      { day: 4, desc: "ENERJISA ELEKTRIK FATURASI", amount: -1150.40, cat: "Fatura" },
      { day: 5, desc: "IGDAS DOGALGAZ DAGITIM A.S.", amount: -2480.00, cat: "Fatura" },
      { day: 6, desc: "ISKI SU FATURASI ODEMESI", amount: -320.50, cat: "Fatura" },
      { day: 7, desc: "TURKCELL ILETISIM FATURASI", amount: -720.00, cat: "Fatura" },
      { day: 9, desc: "MIGROS TICARET A.S. ATASEHIR", amount: -2150.80, cat: "Market" },
      { day: 12, desc: "OPET AKARYAKIT KADIKOY", amount: -1950.00, cat: "Ulaşım" },
      { day: 14, desc: "YEMEKSEPETI SIPARISI", amount: -640.00, cat: "Eğlence" },
      { day: 16, desc: "CARREFOURSA SUPERMARKET", amount: -1420.30, cat: "Market" },
      { day: 18, desc: "ACIBADEM SAGLIK GRUBU MUAYENE", amount: -2400.00, cat: "Sağlık" },
      { day: 19, desc: "NETFLIX ODEME HIZMETLERI", amount: -229.99, cat: "Eğlence" },
      { day: 20, desc: "SPOTIFY TURKIYE MUZIK ABONELIK", amount: -64.99, cat: "Eğlence" },
      { day: 22, desc: "ISTANBULKART ONLINE DOLUM", amount: -500.00, cat: "Ulaşım" },
      { day: 24, desc: "TRENDYOL ALISVERIS MERKEZI", amount: -1850.00, cat: "Diğer" },
      { day: 26, desc: "MACROCENTER KANYON AVM", amount: -2890.50, cat: "Market" },
      { day: 28, desc: "SHELL PETROL UMRANIYE", amount: -1800.00, cat: "Ulaşım" }
    ]
  },
  {
    bank: "İş Bankası",
    filename: "isbank_ekstre_mayis_2026.csv",
    date_prefix: "2026-05",
    imported_at: Time.zone.parse("2026-06-01 10:15:00"),
    items: [
      { day: 1, desc: "ABC TEKNOLOJI A.S. MAAS ODEMESI", amount: 78500.00, cat: "Maaş / Gelir" },
      { day: 2, desc: "EV SAHIBI AHMET YILMAZ KIRA BEDELI", amount: -22000.00, cat: "Kira & Konut" },
      { day: 3, desc: "PROJE BASARI PRIMI EK ODEME", amount: 12000.00, cat: "Maaş / Gelir" },
      { day: 5, desc: "ENERJISA ELEKTRIK FATURASI", amount: -980.00, cat: "Fatura" },
      { day: 6, desc: "IGDAS DOGALGAZ DAGITIM", amount: -1450.00, cat: "Fatura" },
      { day: 7, desc: "TURK TELEKOM FIBER INTERNET", amount: -550.00, cat: "Fatura" },
      { day: 9, desc: "MIGROS SANAL MARKET", amount: -2650.40, cat: "Market" },
      { day: 11, desc: "BP PETROL KOSUYOLU", amount: -2100.00, cat: "Ulaşım" },
      { day: 14, desc: "ZARA GIYIM BUYAKA AVM", amount: -3850.00, cat: "Diğer" },
      { day: 17, desc: "GETIR PERAKENDE LOJISTIK", amount: -890.50, cat: "Market" },
      { day: 19, desc: "BILETIX KONSER BILETI", amount: -1750.00, cat: "Eğlence" },
      { day: 21, desc: "ECZANE DERMAN ILAC ALIMI", amount: -480.00, cat: "Sağlık" },
      { day: 23, desc: "UBER TURKIYE YOLCULUK", amount: -420.00, cat: "Ulaşım" },
      { day: 25, desc: "HEPSIBURADA ELEKTRONIK", amount: -2100.00, cat: "Diğer" },
      { day: 27, desc: "BIM BIRLESIK MAGAZALAR", amount: -760.30, cat: "Market" },
      { day: 29, desc: "RESTORAN NUSRET STEAKHOUSE", amount: -3200.00, cat: "Eğlence" }
    ]
  },
  {
    bank: "Yapı Kredi",
    filename: "yapkredi_ekstre_haziran_2026.csv",
    date_prefix: "2026-06",
    imported_at: Time.zone.parse("2026-07-01 11:00:00"),
    items: [
      { day: 1, desc: "ABC TEKNOLOJI A.S. MAAS ODEMESI", amount: 82000.00, cat: "Maaş / Gelir" },
      { day: 2, desc: "EV SAHIBI AHMET YILMAZ KIRA BEDELI", amount: -24000.00, cat: "Kira & Konut" },
      { day: 4, desc: "ENERJISA ELEKTRIK FATURASI", amount: -1350.00, cat: "Fatura" },
      { day: 5, desc: "IGDAS DOGALGAZ DAGITIM", amount: -650.00, cat: "Fatura" },
      { day: 6, desc: "TURKCELL FATURA ODEMESI", amount: -750.00, cat: "Fatura" },
      { day: 8, desc: "MIGROS TICARET A.S.", amount: -2850.00, cat: "Market" },
      { day: 10, desc: "OPET AKARYAKIT ISTASYONU", amount: -2300.00, cat: "Ulaşım" },
      { day: 13, desc: "TATILBUDUR TURIZM REZERVASYON", amount: -14500.00, cat: "Eğlence" },
      { day: 15, desc: "CARREFOURSA GURME", amount: -1980.00, cat: "Market" },
      { day: 18, desc: "MEDICANA HASTANESI CHECK-UP", amount: -4200.00, cat: "Sağlık" },
      { day: 20, desc: "DECATHLON SPOR MALZEMELERI", amount: -2450.00, cat: "Diğer" },
      { day: 22, desc: "STARBUCKS COFFEE KADIKOY", amount: -380.00, cat: "Eğlence" },
      { day: 25, desc: "SHELL PETROL KARTAL", amount: -2150.00, cat: "Ulaşım" },
      { day: 28, desc: "AMAZON TURKIYE SIPARIS", amount: -1650.00, cat: "Diğer" }
    ]
  },
  {
    bank: "Akbank",
    filename: "akbank_ekstre_temmuz_2026.csv",
    date_prefix: "2026-07",
    imported_at: Time.zone.parse("2026-08-01 14:20:00"),
    items: [
      { day: 1, desc: "ABC TEKNOLOJI A.S. MAAS ODEMESI", amount: 82000.00, cat: "Maaş / Gelir" },
      { day: 2, desc: "EV SAHIBI AHMET YILMAZ KIRA BEDELI", amount: -24000.00, cat: "Kira & Konut" },
      { day: 4, desc: "ENERJISA ELEKTRIK FATURASI", amount: -2150.00, cat: "Fatura" },
      { day: 5, desc: "ISKI SU FATURASI", amount: -480.00, cat: "Fatura" },
      { day: 7, desc: "MIGROS JET CESME SUBESI", amount: -3400.00, cat: "Market" },
      { day: 9, desc: "PETROL OFISI BODRUM YOLU", amount: -2850.00, cat: "Ulaşım" },
      { day: 12, desc: "MARINA YACHT CLUB RESTORAN", amount: -4600.00, cat: "Eğlence" },
      { day: 15, desc: "SUALTI DALIS VE AKTIVITE", amount: -2500.00, cat: "Eğlence" },
      { day: 18, desc: "ECZANE GUNES KREMI & SAGLIK", amount: -850.00, cat: "Sağlık" },
      { day: 21, desc: "BOYNER BUYAKA MAGAZASI", amount: -3200.00, cat: "Diğer" },
      { day: 24, desc: "MACROCENTER ALACATI", amount: -3100.00, cat: "Market" },
      { day: 27, desc: "OPET BENZIN ALIMI", amount: -2400.00, cat: "Ulaşım" },
      { day: 30, desc: "HGS OTOYOL GECIS UCRETI", amount: -650.00, cat: "Ulaşım" }
    ]
  },
  {
    bank: "QNB Finansbank",
    filename: "qnb_ekstre_agustos_2026.csv",
    date_prefix: "2026-08",
    imported_at: Time.zone.parse("2026-09-01 09:10:00"),
    items: [
      { day: 1, desc: "ABC TEKNOLOJI A.S. MAAS ODEMESI", amount: 82000.00, cat: "Maaş / Gelir" },
      { day: 2, desc: "EV SAHIBI AHMET YILMAZ KIRA BEDELI", amount: -24000.00, cat: "Kira & Konut" },
      { day: 3, desc: "DANISMANLIK EK GELIRI", amount: 18000.00, cat: "Maaş / Gelir" },
      { day: 5, desc: "ENERJISA ELEKTRIK FATURASI", amount: -1850.00, cat: "Fatura" },
      { day: 6, desc: "TURKCELL FATURA ODEMESI", amount: -820.00, cat: "Fatura" },
      { day: 8, desc: "MIGROS TICARET A.S.", amount: -3120.00, cat: "Market" },
      { day: 11, desc: "SHELL AKARYAKIT ISTASYONU", amount: -2400.00, cat: "Ulaşım" },
      { day: 14, desc: "TEKNOSA BILGISAYAR MONITR", amount: -5600.00, cat: "Diğer" },
      { day: 17, desc: "GETIRYEMEK SIPARISI", amount: -780.00, cat: "Eğlence" },
      { day: 20, desc: "DIS KLINIGI DOLGU VE BAKIM", amount: -3500.00, cat: "Sağlık" },
      { day: 23, desc: "CARREFOURSA SUPERMARKET", amount: -2100.00, cat: "Market" },
      { day: 26, desc: "IKEA MOBILYA VE EV GERECLERI", amount: -4800.00, cat: "Diğer" },
      { day: 28, desc: "BP PETROL ATATURK CAD.", amount: -1950.00, cat: "Ulaşım" },
      { day: 30, desc: "NETFLIX & SPOTIFY ABONELIK", amount: -294.98, cat: "Eğlence" }
    ]
  },
  {
    bank: "Enpara",
    filename: "enpara_ekstre_eylul_2026.csv",
    date_prefix: "2026-09",
    imported_at: Time.zone.parse("2026-09-15 08:30:00"),
    items: [
      { day: 1, desc: "ABC TEKNOLOJI A.S. MAAS ODEMESI", amount: 85000.00, cat: "Maaş / Gelir" },
      { day: 2, desc: "EV SAHIBI AHMET YILMAZ KIRA BEDELI", amount: -25000.00, cat: "Kira & Konut" },
      { day: 3, desc: "YILLIK PERFORMANS PRIMI", amount: 25000.00, cat: "Maaş / Gelir" },
      { day: 4, desc: "ENERJISA ELEKTRIK ODEMESI", amount: -1250.00, cat: "Fatura" },
      { day: 5, desc: "TURK TELEKOM FIBER INTERNET", amount: -650.00, cat: "Fatura" },
      { day: 6, desc: "TURKCELL ILETISIM FATURASI", amount: -850.00, cat: "Fatura" },
      { day: 8, desc: "MIGROS SANAL MARKET ALISVERISI", amount: -2750.50, cat: "Market" },
      { day: 9, desc: "D&R KIRTASIYE VE KITAP", amount: -1450.00, cat: "Diğer" },
      { day: 10, desc: "OPET AKARYAKIT MALTEPE", amount: -2350.00, cat: "Ulaşım" },
      { day: 11, desc: "CARREFOURSA HIPERMARKET", amount: -2100.00, cat: "Market" },
      { day: 12, desc: "ECZANE DERMAN ILAC", amount: -620.00, cat: "Sağlık" },
      { day: 13, desc: "RESTORAN AKSAM YEMEGI MODA", amount: -1850.00, cat: "Eğlence" },
      { day: 14, desc: "ISTANBULKART DOLUM", amount: -600.00, cat: "Ulaşım" },
      { day: 15, desc: "TRENDYOL TEKNOLOJI VE GIYIM", amount: -3200.00, cat: "Diğer" }
    ]
  }
]

monthly_statements.each do |stmt_data|
  statement = Statement.find_or_create_by!(source_filename: stmt_data[:filename]) do |s|
    s.bank_name = stmt_data[:bank]
    s.imported_at = stmt_data[:imported_at]
    s.status = :categorized
  end

  # Refresh transactions for idempotent seeds
  statement.transactions.destroy_all

  stmt_data[:items].each do |item|
    date = Date.parse("#{stmt_data[:date_prefix]}-#{sprintf('%02d', item[:day])}")
    category = categories[item[:cat]] || categories["Diğer"]

    temp_tx = Transaction.new(id: 1, description: item[:desc], amount: item[:amount])
    analysis_data = GeminiCategorizer.new([temp_tx]).send(:fallback_categorize, [temp_tx])[:details][1] || {}

    statement.transactions.create!(
      date: date,
      description: item[:desc],
      amount: item[:amount],
      category: category,
      merchant_name: analysis_data[:merchant],
      ai_analysis: analysis_data[:analysis],
      confidence_score: 0.95,
      categorized_by: :ai,
      raw_row: "#{date.strftime('%d.%m.%Y')};#{item[:desc]};#{item[:amount]}"
    )
  end
end

puts "Seeded 6 months of statements: #{Statement.count} statements and #{Transaction.count} transactions in total."

