<div align="center">

# 💳 Ekstre — Akıllı Banka Ekstresi & AI Finansal Analiz Platformu

**Banka ekstrelerinizi (PDF & CSV) otomatik ayrıştıran, Google Gemini yapay zekası ile işlemleri derinlemesine anlamlandıran ve mat kurumsal bankacılık arayüzüyle finansal durumunuzu görselleştiren modern web uygulaması.**

[![Ruby on Rails](https://img.shields.io/badge/Rails-8.1-CC0000.svg?style=flat&logo=rubyonrails)](https://rubyonrails.org/)
[![Ruby](https://img.shields.io/badge/Ruby-4.0+-CC342D.svg?style=flat&logo=ruby)](https://www.ruby-lang.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16+-336791.svg?style=flat&logo=postgresql)](https://www.postgresql.org/)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-v4-06B6D4.svg?style=flat&logo=tailwindcss)](https://tailwindcss.com/)
[![Hotwire](https://img.shields.io/badge/Hotwire-Turbo_%26_Stimulus-FF7700.svg?style=flat)](https://hotwired.dev/)
[![Gemini AI](https://img.shields.io/badge/Google_Gemini-3.5_Flash_Lite-8E75B2.svg?style=flat&logo=google)](https://ai.google.dev/)
[![Tests](https://img.shields.io/badge/Tests-27%20Passing%20(100%25)-10B981.svg?style=flat)](#-test-ve-kalite-güvencesi)

</div>

---

## 📌 Genel Bakış

**Ekstre**, Türkiye'deki tüm bankaların (Garanti BBVA, İş Bankası, Yapı Kredi, Akbank, QNB Finansbank, Enpara, Ziraat Bankası, VakıfBank vb.) e-ekstre PDF ve CSV dosyalarını tek bir tıkla içe aktaran, karmaşık POS ve kurum kodlarını yapay zeka ile temizleyen ve harcamalarınızı anlamlı içgörülere dönüştüren yeni nesil bir bütçe takip sistemidir.

### 🌟 Neden Ekstre?
Geleneksel bankacılık ekstreleri genellikle `POS 48201 IYZICO / TRENDYOL ISTANBUL` veya `CK BOGAZICI ELEK` gibi karmaşık metinler içerir. **Ekstre**, Google Gemini 3.5 yapay zeka motorunu kullanarak bu gürültüyü temizler:
- Gerçek satıcıyı bulur (**Trendyol**),
- Harcamanın niteliğini Türkçe açıklar (*"Online e-ticaret giyim ve kişisel alışveriş harcaması"*),
- Doğru bütçe kategorisine otomatik atar ve güven skorunu hesaplar.

---

## ✨ Öne Çıkan Özellikler

### 📄 1. Hibrit Ekstre Ayrıştırma Motoru (PDF & CSV)
- **Poppler `pdftotext` Motoru**: Yüksek performanslı sistem ayrıştırıcısı ile tablo düzeni bozulmadan banka PDF e-ekstrelerinden satır satır veri çekimi.
- **Otomatik Banka Tespiti**: Ekstre başlık ve formatından bankayı anında tanır.
- **Borç (B) & Alacak (A) Algılama**: Pozitif gelir ve negatif gider tutarlarını, Türkçe ondalık/binlik ayracı (`1.250,50 ₺`) ve döviz kodlarını hatasız ayrıştırır.

### 🧠 2. Gemini 3.5 Derin Semantik Analiz
- **Model**: Google'ın yüksek hızlı ve güncel `gemini-3.5-flash-lite` modeli.
- **Yapılandırılmış Çıktı**: `responseMimeType: "application/json"` moduyla garantili ve hatasız JSON dönüşü.
- **Akıllı Çıkarımlar**:
  - `merchant_name`: Gürültüden arındırılmış temiz işletme/kurum adı.
  - `ai_analysis`: Harcamanın mahiyetini 1 cümleyle özetleyen Türkçe açıklama.
  - `confidence_score`: Yapay zekanın sınıflandırma güven oranı (%0 - %100).
- **Yerel Kural Motoru (Fallback)**: API anahtarı girilmediğinde veya kota aşıldığında sistem durmaz; yerleşik Türkçe finansal kural motoru sınıflandırmayı kesintisiz sürdürür.

### 📊 3. Etkileşimli Bankacılık Kontrol Paneli (Dashboard)
- **KPI Kartları**: Toplam harcama, toplam gelir, net nakit akışı / bakiye, en yüksek harcama kalemi ve aydan aya değişim (MoM).
- **Aylık Gelir & Gider Trend Grafiği (Chart.js)**:
  - Tıklanabilir interaktif filtre kutucukları.
  - Aktif seriler renkli dolgu (`✓`) ile belirtilirken, gizlenen serilerin kutucuğu boşalır ve üzeri çizilir.
- **Kategori Dağılımı Halka Grafiği (Doughnut)**:
  - Üzerine gelinen kategori dilimi dışa doğru 20 piksel fırlayarak büyür (`hoverOffset: 20`).
  - Halkanın ortasındaki HUD göstergesi yumuşak animasyonla (`scale-110`) o kategorinin adını, tutarını ve bütçe içindeki yüzdesini anlık olarak gösterir.

### ⚡ 4. Hotwire Turbo Frames ile Anlık Düzenleme
- Ekstre inceleme tablosunda işlem kategorileri açılır menüden değiştirildiğinde, sayfa yenilenmeden arka planda kaydedilir (`turbo_stream`).
- İşlem rozeti anında `⚡ AI Analizli` durumundan `👤 Manuel` durumuna güncellenir.

### 🎨 5. Profesyonel Mat Bankacılık Tasarımı
- Gözü yoran neon renkler ve aşırı parlak siyahlar yerine, kurumsal bankacılık standartlarında **mat derin grafit (`#111215`)**, **mat antrasit kartlar (`#18191E`)** ve **vişne kırmızısı (`#B91C1C`)** tonları.
- Rakam hizalamasını kusursuz kılan `tabular-nums` ve yüksek okunabilirlikli **`Inter`** tipografisi.

---

## 🛠️ Teknoloji Yığını

| Katman | Teknoloji | Açıklama |
| :--- | :--- | :--- |
| **Backend** | Ruby 4.0+ / Rails 8.1 | Modern Rails mimarisi, Propshaft, ActiveJob |
| **Veritabanı** | PostgreSQL | İlişkisel finansal veri modeli ve indeksler |
| **Frontend** | Hotwire (Turbo & Stimulus) | SPA hızında, JavaScript framework yükü olmadan reaktif UI |
| **Stil / Tasarım** | Tailwind CSS v4 | Özel mat bankacılık renk paleti ve duyarlı düzen |
| **Grafikler** | Chart.js | Trend çizgi ve dinamik halka grafikleri |
| **Yapay Zeka** | Google Gemini API | `gemini-3.5-flash-lite` ile işlem analizi |
| **PDF Ayrıştırıcı** | Poppler `pdftotext` | Layout-accurate metin çıkarma motoru |

---

## 📁 Veritabanı ve Proje Mimarisi

```text
Ekstre/
├── app/
│   ├── controllers/
│   │   ├── dashboard_controller.rb     # KPI'lar, trendler ve halka grafik verisi
│   │   ├── statements_controller.rb    # PDF/CSV yükleme ve otomatik yönlendirme
│   │   └── transactions_controller.rb  # Turbo stream satır içi kategori güncelleme
│   ├── javascript/
│   │   └── controllers/
│   │       └── chart_controller.js     # Chart.js etkileşimleri, hover HUD ve filtreler
│   ├── jobs/
│   │   └── categorize_transactions_job.rb # Asenkron AI sınıflandırma arka plan işi
│   ├── models/
│   │   ├── category.rb                 # Kategori tanımları ve mat renk kodları
│   │   ├── statement.rb                # Ekstre başlığı, banka adı, toplamlar
│   │   └── transaction.rb              # İşlem tutarı, temiz marka, AI analizi
│   ├── services/
│   │   ├── gemini_categorizer.rb       # Gemini 3.5 derin semantik analiz ve fallback
│   │   └── statement_parsers/
│   │       ├── csv_parser.rb           # Türkçe CSV ayrıştırma servisi
│   │       └── pdf_parser.rb           # Poppler tabanlı PDF e-ekstre ayrıştırma
│   └── views/
│       ├── dashboard/index.html.erb    # Finansal kontrol paneli
│       ├── statements/                 # Ekstre listeleme, yükleme ve inceleme
│       └── transactions/               # Hotwire Turbo frame satır içi hücreler
├── db/
│   ├── migrate/                        # PostgreSQL şema taşıma dosyaları
│   └── seeds.rb                        # 6 aylık gerçekçi banka işlem veri seti
└── test/                               # 27 birim ve entegrasyon testi (%100 yeşil)
```

---

## 🚀 Kurulum ve Çalıştırma

### 1. Sistem Gereksinimleri
- **Ruby**: 3.2+ (Önerilen: 4.0+)
- **PostgreSQL**: 14+
- **Poppler Utils** (PDF ayrıştırma için):
  ```bash
  # Ubuntu / Debian
  sudo apt install poppler-utils -y
  
  # macOS (Homebrew)
  brew install poppler
  ```

### 2. Depoyu Klonlayın
```bash
git clone git@github.com:Ahmetdemirci17/Ekstre.git
cd Ekstre
```

### 3. Bağımlılıkları Yükleyin
```bash
bundle install
```

### 4. Ortam Değişkenlerini Ayarlayın
Proje kök dizininde bir `.env` dosyası oluşturun:
```env
GEMINI_API_KEY=your_google_gemini_api_key_here
GEMINI_MODEL=gemini-3.5-flash-lite
```
*(Not: API anahtarı olmadan da yerel kural motoru sayesinde uygulama %100 çalışır).*

### 5. Veritabanını Hazırlayın ve 6 Aylık Veriyi Yükleyin
```bash
bin/rails db:create db:migrate
bin/rails db:seed
```
*Bu komutla son 6 aya ait (Nisan 2026 – Eylül 2026) 6 farklı Türk bankasına ait 100 gerçekçi işlem veritabanına aktarılır.*

### 6. Uygulamayı Başlatın
Tailwind derleyicisi ve Rails sunucusunu birlikte başlatmak için:
```bash
bin/dev
# veya
bin/rails server
```
Tarayıcınızdan **`http://localhost:3000`** adresine gidin.

---

## 🧪 Test ve Kalite Güvencesi

Proje kapsamlı birim, kontrolör, servis ve uçtan uca entegrasyon testlerine sahiptir:
- Model validasyonları ve bakiye hesaplamaları
- CSV ve PDF ayrıştırıcılarının Türkçe karakter ve sayı formatı testleri
- Gemini AI yanıt ve çevrimdışı kural motoru testleri
- Ekstre yükleme, ayrıştırma ve asenkron kategorilendirme entegrasyon akışı

Testleri çalıştırmak için:
```bash
bin/rails test
```

**Test Sonuçları:**
```text
Running 27 tests in a single process (parallelization threshold is 50)
...........................
Finished in 0.595346s, 45.3518 runs/s, 209.9620 assertions/s.
27 runs, 125 assertions, 0 failures, 0 errors, 0 skips
```

---

## 📄 Lisans

Bu proje [MIT Lisansı](LICENSE) altında lisanslanmıştır.
