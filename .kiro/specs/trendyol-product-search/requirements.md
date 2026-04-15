# Requirements Document

## Introduction

Bu doküman, Dressify AI Flutter uygulamasının Trendyol ürün arama ve kaydetme özelliği için gereksinimleri tanımlar. Sistem, kullanıcıların Trendyol'daki ürünleri aramasını, detaylarını görüntülemesini ve gardıroplarına kaydetmesini sağlar. Özellik, navigasyon barındaki ikinci sekmeye yerleştirilecek ve Trendyol scraping API'si ile entegre edilecektir.

## Glossary

- **ProductSearchScreen**: Ürün arama sayfası UI katmanı
- **ProductDetailScreen**: Ürün detay sayfası UI katmanı
- **ProductSearchViewModel**: Ürün arama business logic katmanı (MVVM pattern)
- **ProductDetailViewModel**: Ürün detay business logic katmanı (MVVM pattern)
- **TrendyolService**: Trendyol scraping API servisi
- **SavedProductService**: Kaydedilen ürünler Supabase servisi
- **Trendyol_API**: Trendyol scraping API (https://github.com/meminglr/trendyol_scrapping)
- **Hero_Animation**: Sayfa geçişlerinde kullanılan animasyon widget'ı
- **CarouselView**: Ürün görselleri için kaydırılabilir galeri widget'ı
- **Sliver_Architecture**: CustomScrollView ile scroll mekanizması
- **Search_Query**: Kullanıcının girdiği arama terimi
- **Product_Link**: Trendyol ürün URL'i
- **Saved_Product**: Gardıroba kaydedilen Trendyol ürünü
- **Media_Type**: Medya içerik tipi (upload, model, aiLook, trendyolProduct)
- **Sort_Option**: Sıralama seçeneği (BEST_SELLER, PRICE_BY_ASC, PRICE_BY_DESC, MOST_RATED, NEWEST)

## Requirements

### Requirement 1: Ürün Arama Sayfası UI

**User Story:** Bir kullanıcı olarak, Ürünler sekmesinde arama yapabileceğim bir sayfa görmek istiyorum, böylece Trendyol'daki ürünleri keşfedebilirim.

#### Acceptance Criteria

1. THE ProductSearchScreen SHALL navigasyon barındaki ikinci sekmeye yerleştirilmeli
2. THE ProductSearchScreen SHALL Figma tasarımına uygun olmalı (https://www.figma.com/design/hBpOrjOf5YWhR9TXrERITn/dressify?node-id=5-124)
3. THE ProductSearchScreen SHALL CustomScrollView ve Sliver yapıları kullanmalı
4. THE ProductSearchScreen SHALL arama çubuğu, filtre butonları ve ürün grid'i içermeli

### Requirement 2: Arama Çubuğu ve Arama İşlemi

**User Story:** Bir kullanıcı olarak, arama çubuğuna kelime girerek Trendyol'da ürün aramak istiyorum, böylece istediğim ürünleri bulabilirim.

#### Acceptance Criteria

1. WHEN kullanıcı arama çubuğuna metin girdiğinde, THE ProductSearchViewModel SHALL Search_Query'yi state'e kaydetmeli
2. WHEN kullanıcı arama butonuna bastığında, THE ProductSearchViewModel SHALL TrendyolService.searchProducts() metodunu çağırmalı
3. WHILE arama devam ederken, THE ProductSearchScreen SHALL loading indicator göstermeli
4. WHEN arama başarılı olduğunda, THE ProductSearchScreen SHALL ürün listesini grid formatında göstermeli

### Requirement 3: Trendyol API Entegrasyonu - Arama

**User Story:** Bir geliştirici olarak, Trendyol scraping API'sini kullanarak ürün araması yapmak istiyorum, böylece gerçek Trendyol verilerini çekebilirim.

#### Acceptance Criteria

1. THE TrendyolService SHALL Trendyol scraping API'sine HTTP istekleri yapmalı
2. WHEN searchProducts() çağrıldığında, THE TrendyolService SHALL arama endpoint'ini kullanmalı
3. THE TrendyolService SHALL API yanıtını Product model'ine dönüştürmeli
4. IF API hatası oluşursa, THEN THE TrendyolService SHALL TrendyolException fırlatmalı

### Requirement 4: Ürün Listesi Görüntüleme

**User Story:** Bir kullanıcı olarak, arama sonuçlarını grid formatında görmek istiyorum, böylece ürünleri kolayca tarayabilirim.

#### Acceptance Criteria

1. THE ProductSearchScreen SHALL ürünleri 2 sütunlu grid formatında göstermeli
2. THE her ürün kartı SHALL ürün görseli, başlığı, fiyatı ve marka bilgisi içermeli
3. WHEN ürün listesi boş olduğunda, THE ProductSearchScreen SHALL "Ürün bulunamadı" mesajı göstermeli
4. THE ürün kartları SHALL tıklanabilir olmalı ve ürün detay sayfasına yönlendirmeli

### Requirement 5: Sıralama Seçenekleri

**User Story:** Bir kullanıcı olarak, arama sonuçlarını farklı kriterlere göre sıralamak istiyorum, böylece istediğim ürünleri daha kolay bulabilirim.

#### Acceptance Criteria

1. THE ProductSearchScreen SHALL sıralama seçenekleri dropdown'u içermeli
2. THE sıralama seçenekleri SHALL BEST_SELLER, PRICE_BY_ASC, PRICE_BY_DESC, MOST_RATED, NEWEST olmalı
3. WHEN kullanıcı sıralama seçeneği değiştirdiğinde, THE ProductSearchViewModel SHALL yeni sıralama ile arama yapmalı
4. THE seçili sıralama seçeneği SHALL görsel olarak vurgulanmalı

### Requirement 6: Fiyat Filtresi

**User Story:** Bir kullanıcı olarak, minimum ve maksimum fiyat belirleyerek ürünleri filtrelemek istiyorum, böylece bütçeme uygun ürünleri görebilirim.

#### Acceptance Criteria

1. THE ProductSearchScreen SHALL minimum ve maksimum fiyat input alanları içermeli
2. WHEN kullanıcı fiyat filtresi uyguladığında, THE ProductSearchViewModel SHALL min_price ve max_price parametreleri ile arama yapmalı
3. THE fiyat input alanları SHALL sadece sayısal değer kabul etmeli
4. WHEN fiyat filtresi temizlendiğinde, THE ProductSearchViewModel SHALL filtresiz arama yapmalı

### Requirement 7: Ücretsiz Kargo Filtresi

**User Story:** Bir kullanıcı olarak, sadece ücretsiz kargolu ürünleri görmek istiyorum, böylece ekstra kargo ücreti ödemeden alışveriş yapabilirim.

#### Acceptance Criteria

1. THE ProductSearchScreen SHALL "Ücretsiz Kargo" checkbox'u içermeli
2. WHEN checkbox işaretlendiğinde, THE ProductSearchViewModel SHALL free_shipping=true parametresi ile arama yapmalı
3. WHEN checkbox kaldırıldığında, THE ProductSearchViewModel SHALL free_shipping filtresi olmadan arama yapmalı
4. THE checkbox durumu SHALL görsel olarak net bir şekilde gösterilmeli

### Requirement 8: Ürün Detay Sayfası UI

**User Story:** Bir kullanıcı olarak, ürüne tıkladığımda detaylı bilgileri görmek istiyorum, böylece ürün hakkında karar verebilirim.

#### Acceptance Criteria

1. THE ProductDetailScreen SHALL Figma tasarımına uygun olmalı (https://www.figma.com/design/hBpOrjOf5YWhR9TXrERITn/dressify?node-id=5-205)
2. THE ProductDetailScreen SHALL CustomScrollView ve Sliver yapıları kullanmalı
3. THE ProductDetailScreen SHALL ürün görselleri, başlık, fiyat, açıklama, yorumlar ve "Gardıroba Ekle" butonu içermeli
4. THE sayfa geçişi SHALL Hero animation kullanmalı

### Requirement 9: Ürün Görselleri Carousel

**User Story:** Bir kullanıcı olarak, ürün detay sayfasında birden fazla görseli kaydırarak görmek istiyorum, böylece ürünü her açıdan inceleyebilirim.

#### Acceptance Criteria

1. THE ProductDetailScreen SHALL ürün görselleri için CarouselView widget'ı kullanmalı
2. THE CarouselView SHALL yatay kaydırma ile görseller arasında geçiş yapmalı
3. THE CarouselView SHALL mevcut görsel indeksini göstermeli (örn: 1/5)
4. THE görseller SHALL tam ekran görüntüleme için tıklanabilir olmalı

### Requirement 10: Trendyol API Entegrasyonu - Ürün Detayı

**User Story:** Bir geliştirici olarak, Trendyol scraping API'sini kullanarak ürün detaylarını çekmek istiyorum, böylece kullanıcıya tam bilgi sunabilirim.

#### Acceptance Criteria

1. WHEN ProductDetailScreen açıldığında, THE ProductDetailViewModel SHALL TrendyolService.getProductDetail() metodunu çağırmalı
2. THE TrendyolService SHALL ürün detay endpoint'ini kullanmalı
3. THE TrendyolService SHALL ürün görselleri, açıklama, yorumlar ve fiyat bilgilerini çekmeli
4. WHILE detay yüklenirken, THE ProductDetailScreen SHALL skeleton loading göstermeli

### Requirement 11: Ürünü Gardıroba Kaydetme

**User Story:** Bir kullanıcı olarak, beğendiğim ürünü "Gardıroba Ekle" butonuna basarak kaydetmek istiyorum, böylece daha sonra erişebilirim.

#### Acceptance Criteria

1. WHEN "Gardıroba Ekle" butonuna basıldığında, THE ProductDetailViewModel SHALL SavedProductService.saveProduct() metodunu çağırmalı
2. THE SavedProductService SHALL ürün bilgilerini Supabase'e kaydetmeli
3. THE kaydedilen ürün SHALL MediaType.trendyolProduct tipi ile kaydedilmeli
4. WHEN kaydetme başarılı olduğunda, THE ProductDetailScreen SHALL "Ürün gardıroba eklendi" başarı mesajı göstermeli

### Requirement 12: Kaydedilen Ürünleri Profil Sayfasında Görüntüleme

**User Story:** Bir kullanıcı olarak, profil sayfamdaki gardırop sekmesinde hem kendi yüklediğim fotoğrafları hem de Trendyol'dan kaydettiğim ürünleri görmek istiyorum, böylece tüm kıyafetlerimi bir arada görebilirim.

#### Acceptance Criteria

1. THE ProfileViewModel SHALL MediaService.getMediaList() ile hem upload hem de trendyolProduct tipindeki medyaları çekmeli
2. WHEN Gardırop tab'ı açıldığında, THE ProfileScreen SHALL hem kullanıcı yüklemeleri hem de kaydedilen Trendyol ürünlerini göstermeli
3. THE Trendyol ürünleri SHALL görsel olarak farklılaştırılmalı (örn: Trendyol logosu badge'i)
4. WHEN Trendyol ürününe tıklandığında, THE ProfileScreen SHALL ProductDetailScreen'e yönlendirmeli

### Requirement 13: Trendyol Link ile Direkt Ürün Açma

**User Story:** Bir kullanıcı olarak, Trendyol ürün linkini kopyalayıp uygulamaya yapıştırarak direkt ürün detay sayfasına gitmek istiyorum, böylece hızlıca ürünü görebilirim.

#### Acceptance Criteria

1. THE ProductSearchScreen SHALL "Link ile Ekle" butonu içermeli
2. WHEN "Link ile Ekle" butonuna basıldığında, THE ProductSearchViewModel SHALL clipboard'dan link okumalı
3. WHEN geçerli Trendyol linki algılandığında, THE ProductSearchViewModel SHALL link'ten ürün ID'sini çıkarmalı
4. THE ProductSearchViewModel SHALL ürün ID'si ile ProductDetailScreen'e yönlendirmeli
5. IF geçersiz link ise, THEN THE ProductSearchScreen SHALL "Geçersiz Trendyol linki" hatası göstermeli

### Requirement 14: Pagination ve Lazy Loading

**User Story:** Bir kullanıcı olarak, arama sonuçlarını kaydırırken yeni ürünlerin otomatik yüklenmesini istiyorum, böylece tüm sonuçları görebilirim.

#### Acceptance Criteria

1. THE ProductSearchViewModel SHALL sayfa bazlı yükleme (pagination) desteklemeli
2. WHEN kullanıcı listenin sonuna geldiğinde, THE ProductSearchViewModel SHALL otomatik olarak bir sonraki sayfayı yüklemeli
3. WHILE yeni sayfa yüklenirken, THE ProductSearchScreen SHALL alt kısımda loading indicator göstermeli
4. WHEN tüm sonuçlar yüklendiğinde, THE ProductSearchViewModel SHALL daha fazla yükleme yapmamalı

### Requirement 15: Arama Geçmişi

**User Story:** Bir kullanıcı olarak, önceki aramalarımı görmek istiyorum, böylece tekrar aynı aramaları hızlıca yapabilirim.

#### Acceptance Criteria

1. THE ProductSearchViewModel SHALL son 10 arama terimini local storage'da saklamalı
2. WHEN arama çubuğuna tıklandığında, THE ProductSearchScreen SHALL arama geçmişini dropdown olarak göstermeli
3. WHEN geçmiş aramaya tıklandığında, THE ProductSearchViewModel SHALL o terim ile arama yapmalı
4. THE kullanıcı SHALL arama geçmişini temizleyebilmeli

### Requirement 16: Hata Durumu Yönetimi

**User Story:** Bir kullanıcı olarak, arama veya ürün detay yükleme sırasında hata oluştuğunda anlaşılır bir mesaj görmek istiyorum, böylece ne olduğunu anlayabilirim.

#### Acceptance Criteria

1. WHEN TrendyolService hata döndürdüğünde, THE ProductSearchViewModel SHALL hata mesajını yakalayıp Türkçe mesaja çevirmeli
2. WHEN API timeout oluştuğunda, THE ProductSearchScreen SHALL "Bağlantı zaman aşımına uğradı" mesajı göstermeli
3. WHEN ürün bulunamadığında, THE ProductSearchScreen SHALL "Ürün bulunamadı" mesajı ve yeni arama önerisi göstermeli
4. THE hata mesajları SHALL kullanıcı dostu ve Türkçe olmalı

### Requirement 17: Loading State Yönetimi

**User Story:** Bir kullanıcı olarak, ürünler yüklenirken ilerleme görmek istiyorum, böylece işlemin devam ettiğini bilebilirim.

#### Acceptance Criteria

1. WHEN arama başladığında, THE ProductSearchViewModel SHALL isLoading state'ini true yapmalı
2. WHILE isLoading true iken, THE ProductSearchScreen SHALL skeleton loading veya shimmer effect göstermeli
3. WHEN yükleme tamamlandığında, THE ProductSearchViewModel SHALL isLoading state'ini false yapmalı
4. THE loading indicator SHALL kullanıcı deneyimini olumsuz etkilememeli

### Requirement 18: Empty State Yönetimi

**User Story:** Bir kullanıcı olarak, henüz arama yapmadım ise başlangıç mesajı görmek istiyorum, böylece ne yapacağımı bilebilirim.

#### Acceptance Criteria

1. WHEN ProductSearchScreen ilk açıldığında, THE ProductSearchScreen SHALL "Ürün aramak için yukarıdaki arama çubuğunu kullanın" mesajı göstermeli
2. WHEN arama sonucu boş olduğunda, THE ProductSearchScreen SHALL "Ürün bulunamadı" mesajı ve farklı arama önerisi göstermeli
3. THE empty state görselleri SHALL Figma tasarımına uygun olmalı
4. THE empty state SHALL kullanıcıyı arama yapmaya teşvik etmeli

### Requirement 19: MVVM Mimarisi Uyumu

**User Story:** Bir geliştirici olarak, kodun MVVM mimarisine uygun olmasını istiyorum, böylece bakım ve test edilebilirlik kolaylaşsın.

#### Acceptance Criteria

1. THE ProductSearchViewModel ve ProductDetailViewModel SHALL tüm business logic'i içermeli
2. THE ProductSearchScreen ve ProductDetailScreen SHALL sadece UI rendering ve user interaction handling içermeli
3. THE ViewModel'ler SHALL ChangeNotifier extend etmeli ve notifyListeners() kullanmalı
4. THE Screen'ler SHALL Consumer<ViewModel> veya context.watch<ViewModel>() kullanmalı

### Requirement 20: Performans Optimizasyonu

**User Story:** Bir kullanıcı olarak, ürün arama sayfasının hızlı ve akıcı çalışmasını istiyorum, böylece iyi bir deneyim yaşayabilirim.

#### Acceptance Criteria

1. THE ProductSearchViewModel SHALL gereksiz notifyListeners() çağrılarından kaçınmalı
2. THE ProductSearchScreen SHALL const constructor'lar kullanmalı (mümkün olduğunda)
3. THE ürün görselleri SHALL cached_network_image paketi ile cache'lenmeli
4. THE arama işlemi SHALL debounce mekanizması kullanmalı (500ms)

### Requirement 21: Navigasyon Bar Entegrasyonu

**User Story:** Bir kullanıcı olarak, navigasyon barından Ürünler sekmesine kolayca geçiş yapmak istiyorum, böylece uygulamayı rahatça kullanabilirim.

#### Acceptance Criteria

1. THE Home widget SHALL ProductSearchScreen'i ikinci sekmeye eklemeli
2. THE navigasyon bar ikonu SHALL ürün arama özelliğini temsil etmeli (örn: Iconsax.bag veya Iconsax.shop)
3. WHEN Ürünler sekmesine geçildiğinde, THE ProductSearchScreen SHALL mount olmalı ve state'i korumalı
4. THE sekme geçişleri SHALL akıcı animasyonlar ile yapılmalı

### Requirement 22: Trendyol Scraping API Konfigürasyonu

**User Story:** Bir geliştirici olarak, Trendyol scraping API'sinin base URL'ini ve timeout ayarlarını yapılandırmak istiyorum, böylece API çağrıları doğru çalışsın.

#### Acceptance Criteria

1. THE TrendyolService SHALL base URL'i environment variable'dan okumalı
2. THE TrendyolService SHALL HTTP timeout süresini 30 saniye olarak ayarlamalı
3. THE TrendyolService SHALL retry mekanizması içermeli (3 deneme)
4. THE TrendyolService SHALL API yanıtlarını loglayabilmeli (debug mode)

### Requirement 23: Ürün Modeli ve Veri Dönüşümü

**User Story:** Bir geliştirici olarak, Trendyol API yanıtlarını uygulama içi Product modeline dönüştürmek istiyorum, böylece tip güvenliği sağlayabilirim.

#### Acceptance Criteria

1. THE Product model SHALL id, name, price, brand, imageUrl, description, rating alanlarını içermeli
2. THE TrendyolService SHALL API yanıtını Product.fromJson() ile dönüştürmeli
3. THE Product model SHALL copyWith() metodunu desteklemeli
4. THE Product model SHALL Equatable extend etmeli (karşılaştırma için)

### Requirement 24: Kaydedilen Ürün Modeli

**User Story:** Bir geliştirici olarak, Supabase'e kaydedilen ürünler için SavedProduct modeli oluşturmak istiyorum, böylece veritabanı işlemlerini yönetebilirim.

#### Acceptance Criteria

1. THE SavedProduct model SHALL id, userId, productId, productName, productImage, productPrice, productUrl, savedAt alanlarını içermeli
2. THE SavedProduct model SHALL fromJson() ve toJson() metodlarını içermeli
3. THE SavedProductService SHALL SavedProduct modelini kullanarak Supabase işlemleri yapmalı
4. THE SavedProduct SHALL Media modeli ile uyumlu olmalı (MediaType.trendyolProduct)

### Requirement 25: Supabase Veritabanı Şeması

**User Story:** Bir geliştirici olarak, kaydedilen Trendyol ürünleri için Supabase veritabanı tablosu oluşturmak istiyorum, böylece ürünleri saklayabilirim.

#### Acceptance Criteria

1. THE Supabase SHALL "saved_products" tablosu içermeli
2. THE "saved_products" tablosu SHALL id (uuid), user_id (uuid), product_id (text), product_name (text), product_image (text), product_price (numeric), product_url (text), saved_at (timestamp) sütunlarını içermeli
3. THE "saved_products" tablosu SHALL RLS (Row Level Security) politikalarına sahip olmalı
4. THE RLS politikaları SHALL kullanıcıların sadece kendi kayıtlarını görmesini ve düzenlemesini sağlamalı

### Requirement 26: Media Tablosu Genişletme

**User Story:** Bir geliştirici olarak, mevcut media tablosunu Trendyol ürünlerini destekleyecek şekilde genişletmek istiyorum, böylece gardırop entegrasyonu çalışsın.

#### Acceptance Criteria

1. THE media tablosu type enum'u SHALL "TRENDYOL_PRODUCT" değerini içermeli
2. THE media tablosu SHALL trendyol_product_id (text, nullable) sütunu içermeli
3. WHEN MediaType.trendyolProduct ile medya eklendiğinde, THE MediaService SHALL trendyol_product_id alanını doldurmalı
4. THE mevcut media sorguları SHALL yeni tip ile uyumlu çalışmalı

### Requirement 27: Hero Animation Implementasyonu

**User Story:** Bir kullanıcı olarak, ürün kartından detay sayfasına geçerken akıcı bir animasyon görmek istiyorum, böylece daha iyi bir deneyim yaşayabilirim.

#### Acceptance Criteria

1. THE ürün kartı görseli SHALL Hero widget ile sarılmalı
2. THE ProductDetailScreen görseli SHALL aynı Hero tag'i ile sarılmalı
3. THE Hero tag SHALL benzersiz olmalı (örn: "product_${productId}")
4. THE sayfa geçişi SHALL akıcı ve hatasız olmalı

### Requirement 28: Sliver Scroll Mekanizması

**User Story:** Bir geliştirici olarak, ProductSearchScreen ve ProductDetailScreen'de Sliver yapıları kullanmak istiyorum, böylece performanslı scroll deneyimi sağlayabilirim.

#### Acceptance Criteria

1. THE ProductSearchScreen SHALL CustomScrollView kullanmalı
2. THE ProductSearchScreen SHALL SliverAppBar, SliverGrid ve SliverToBoxAdapter içermeli
3. THE ProductDetailScreen SHALL CustomScrollView kullanmalı
4. THE ProductDetailScreen SHALL SliverAppBar, SliverToBoxAdapter ve SliverList içermeli

### Requirement 29: Ürün Yorumları Görüntüleme

**User Story:** Bir kullanıcı olarak, ürün detay sayfasında diğer kullanıcıların yorumlarını görmek istiyorum, böylece ürün hakkında fikir edinebilirim.

#### Acceptance Criteria

1. WHEN ProductDetailScreen açıldığında, THE ProductDetailViewModel SHALL TrendyolService.getProductReviews() metodunu çağırmalı
2. THE ProductDetailScreen SHALL yorumları liste formatında göstermeli
3. THE her yorum SHALL kullanıcı adı, yıldız puanı, yorum metni ve tarih içermeli
4. WHEN yorumlar yüklenirken, THE ProductDetailScreen SHALL skeleton loading göstermeli
