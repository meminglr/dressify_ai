# Implementation Plan: Trendyol Ürün Arama ve Kaydetme

## Overview

Bu implementasyon planı, Dressify AI Flutter uygulamasına Trendyol ürün arama ve kaydetme özelliğini ekler. Özellik, MVVM mimarisi kullanarak Trendyol scraping API entegrasyonu, ürün arama/filtreleme, detay görüntüleme ve gardıroba kaydetme işlevlerini içerir.

## Tasks

- [x] 1. Proje yapısını ve temel modelleri oluştur
  - `lib/features/trendyol/` klasör yapısını oluştur (models, services, viewmodels, screens, widgets)
  - Product, SavedProduct, Review modellerini oluştur (fromJson, toJson, copyWith metodları ile)
  - SortOption enum'unu tanımla
  - _Requirements: 23, 24_

- [ ]* 1.1 Model unit testlerini yaz
  - Product, SavedProduct, Review modellerinin JSON dönüşüm testleri
  - copyWith ve equality testleri
  - _Requirements: 23, 24_

- [x] 2. TrendyolService servisini implement et
  - [x] 2.1 TrendyolService class'ını oluştur
    - Dio instance'ı yapılandır (base URL, timeout, retry interceptor)
    - Environment variable'lardan API konfigürasyonunu oku
    - _Requirements: 3, 22_
  
  - [x] 2.2 searchProducts metodunu implement et
    - Query, sort, price filters, free shipping parametrelerini destekle
    - API yanıtını Product listesine dönüştür
    - Pagination desteği ekle
    - _Requirements: 3, 14_
  
  - [x] 2.3 getProductDetail metodunu implement et
    - Product ID ile detay endpoint'ini çağır
    - Ürün görselleri, açıklama, fiyat bilgilerini parse et
    - _Requirements: 10_
  
  - [x] 2.4 getProductReviews metodunu implement et
    - Ürün yorumlarını çek ve Review listesine dönüştür
    - _Requirements: 29_
  
  - [x] 2.5 extractProductIdFromUrl metodunu implement et
    - Trendyol URL'inden ürün ID'sini regex ile çıkar
    - URL validation ekle
    - _Requirements: 13_
  
  - [x] 2.6 Error handling ve retry mekanizması ekle
    - DioException'ları yakala ve Türkçe mesajlara çevir
    - Timeout, network, server error durumlarını handle et
    - _Requirements: 16_

- [ ]* 2.7 TrendyolService unit testlerini yaz
  - searchProducts, getProductDetail, getProductReviews metodlarının testleri
  - extractProductIdFromUrl test cases
  - Error handling testleri
  - _Requirements: 3, 10, 13, 16_

- [x] 3. Checkpoint - Servis katmanını doğrula
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. SavedProductService servisini implement et
  - [x] 4.1 SavedProductService class'ını oluştur
    - Supabase client instance'ı al
    - _Requirements: 11_
  
  - [x] 4.2 saveProduct metodunu implement et
    - Ürün bilgilerini saved_products tablosuna kaydet
    - Duplicate check ekle (UNIQUE constraint)
    - _Requirements: 11_
  
  - [x] 4.3 getSavedProducts metodunu implement et
    - Kullanıcının kaydedilen ürünlerini çek
    - RLS policy ile sadece kendi ürünlerini getir
    - _Requirements: 12_
  
  - [x] 4.4 deleteSavedProduct metodunu implement et
    - Kaydedilen ürünü sil
    - _Requirements: 12_
  
  - [x] 4.5 isProductSaved metodunu implement et
    - Ürünün daha önce kaydedilip kaydedilmediğini kontrol et
    - _Requirements: 11_

- [ ]* 4.6 SavedProductService unit testlerini yaz
  - CRUD operasyonlarının testleri
  - RLS policy testleri
  - _Requirements: 11, 12_

- [x] 5. Supabase veritabanı şemasını oluştur
  - [x] 5.1 saved_products tablosunu oluştur
    - SQL migration script'i yaz
    - Tablo sütunlarını tanımla (id, user_id, product_id, product_name, product_image, product_price, product_url, saved_at)
    - UNIQUE constraint ekle (user_id, product_id)
    - Index'leri oluştur
    - _Requirements: 25_
  
  - [x] 5.2 RLS politikalarını ekle
    - SELECT, INSERT, DELETE politikalarını tanımla
    - auth.uid() = user_id kontrolü ekle
    - _Requirements: 25_
  
  - [x] 5.3 media tablosunu genişlet
    - TRENDYOL_PRODUCT enum değerini ekle
    - trendyol_product_id sütununu ekle
    - Index oluştur
    - _Requirements: 26_

- [x] 6. ProductSearchViewModel'i implement et
  - [x] 6.1 ProductSearchViewModel class'ını oluştur
    - ChangeNotifier extend et
    - State properties tanımla (products, searchQuery, filters, loading states)
    - TrendyolService dependency injection
    - _Requirements: 2, 19_
  
  - [x] 6.2 searchProducts metodunu implement et
    - TrendyolService.searchProducts() çağır
    - Loading state yönetimi
    - Error handling
    - notifyListeners() çağır
    - _Requirements: 2, 17_
  
  - [x] 6.3 Filtre ve sıralama metodlarını implement et
    - updateFilters metodu (minPrice, maxPrice, freeShipping)
    - updateSortOption metodu
    - clearFilters metodu
    - _Requirements: 5, 6, 7_
  
  - [x] 6.4 Pagination metodlarını implement et
    - loadMoreProducts metodu
    - hasMorePages kontrolü
    - _Requirements: 14_
  
  - [x] 6.5 Arama geçmişi metodlarını implement et
    - saveSearchQuery metodu (local storage)
    - getSearchHistory metodu
    - clearSearchHistory metodu
    - _Requirements: 15_
  
  - [x] 6.6 Debounce mekanizması ekle
    - updateSearchQuery metodu ile 500ms debounce
    - Timer kullanarak gereksiz API çağrılarını önle
    - _Requirements: 20_
  
  - [x] 6.7 Link ile ürün açma metodunu implement et
    - parseProductLink metodu
    - Clipboard'dan link oku
    - extractProductIdFromUrl kullanarak ID çıkar
    - _Requirements: 13_

- [ ]* 6.8 ProductSearchViewModel unit testlerini yaz
  - searchProducts success/failure testleri
  - Filter ve sort testleri
  - Pagination testleri
  - Debounce testleri
  - _Requirements: 2, 5, 6, 7, 14, 15, 20_

- [x] 7. ProductDetailViewModel'i implement et
  - [x] 7.1 ProductDetailViewModel class'ını oluştur
    - ChangeNotifier extend et
    - State properties tanımla (product, reviews, loading states)
    - TrendyolService ve SavedProductService dependency injection
    - _Requirements: 8, 19_
  
  - [x] 7.2 loadProductDetail metodunu implement et
    - TrendyolService.getProductDetail() çağır
    - Loading state yönetimi
    - Error handling
    - _Requirements: 10_
  
  - [x] 7.3 loadReviews metodunu implement et
    - TrendyolService.getProductReviews() çağır
    - Reviews listesini state'e kaydet
    - _Requirements: 29_
  
  - [x] 7.4 saveToWardrobe metodunu implement et
    - SavedProductService.saveProduct() çağır
    - Success/error message yönetimi
    - isProductSaved state'ini güncelle
    - _Requirements: 11_

- [ ]* 7.5 ProductDetailViewModel unit testlerini yaz
  - loadProductDetail testleri
  - loadReviews testleri
  - saveToWardrobe testleri
  - _Requirements: 8, 10, 11, 29_

- [x] 8. Checkpoint - ViewModel katmanını doğrula
  - Ensure all tests pass, ask the user if questions arise.

- [x] 9. ProductSearchScreen UI'ını oluştur
  - [x] 9.1 ProductSearchScreen widget'ını oluştur
    - Scaffold ve CustomScrollView yapısını kur
    - ChangeNotifierProvider ile ProductSearchViewModel'i bağla
    - _Requirements: 1, 3, 19_
  
  - [x] 9.2 SliverAppBar ve arama çubuğunu implement et
    - Floating ve snap özelliklerini ekle
    - TextField ile arama input'u
    - Search icon butonu
    - _Requirements: 2, 4_
  
  - [x] 9.3 Filtre ve sıralama UI'ını implement et
    - SliverToBoxAdapter içinde FilterChips
    - Fiyat input alanları (min/max)
    - Ücretsiz kargo checkbox
    - Sıralama dropdown
    - _Requirements: 5, 6, 7_
  
  - [x] 9.4 Ürün grid'ini implement et
    - SliverGrid ile 2 sütunlu layout
    - ProductCard widget'ları
    - Pagination için scroll listener
    - _Requirements: 4, 14_
  
  - [x] 9.5 Loading, error ve empty state'leri ekle
    - Skeleton loading/shimmer effect
    - Error message display
    - Empty state mesajları ve görselleri
    - _Requirements: 17, 18_
  
  - [x] 9.6 "Link ile Ekle" butonunu ekle
    - Floating action button veya app bar action
    - Clipboard okuma ve link parsing
    - _Requirements: 13_
  
  - [x] 9.7 Arama geçmişi dropdown'unu ekle
    - TextField focus olduğunda geçmişi göster
    - Geçmiş aramaya tıklama ile arama yap
    - _Requirements: 15_

- [x] 10. ProductCard widget'ını oluştur
  - Hero widget ile ürün görseli
  - CachedNetworkImage ile image caching
  - Ürün adı, marka, fiyat, rating bilgileri
  - onTap ile ProductDetailScreen'e navigation
  - _Requirements: 4, 20, 27_

- [ ]* 10.1 ProductSearchScreen widget testlerini yaz
  - UI element varlık testleri
  - Loading state testleri
  - User interaction testleri
  - _Requirements: 1, 2, 4, 17, 18_

- [x] 11. ProductDetailScreen UI'ını oluştur
  - [x] 11.1 ProductDetailScreen widget'ını oluştur
    - Scaffold ve CustomScrollView yapısını kur
    - ChangeNotifierProvider ile ProductDetailViewModel'i bağla
    - Product ID parametresini al
    - _Requirements: 8, 19_
  
  - [x] 11.2 SliverAppBar ve ürün görselleri carousel'ini implement et
    - Hero widget ile animasyon
    - CarouselView ile görseller arası geçiş
    - Görsel indeks göstergesi (1/5)
    - _Requirements: 9, 27_
  
  - [x] 11.3 Ürün bilgileri section'ını implement et
    - SliverToBoxAdapter içinde ürün adı, marka, fiyat
    - Rating ve review count
    - Ürün açıklaması
    - Badge'ler (ücretsiz kargo, hızlı teslimat)
    - _Requirements: 8_
  
  - [x] 11.4 "Gardıroba Ekle" butonunu implement et
    - Floating action button veya bottom bar
    - saveToWardrobe çağrısı
    - Success/error snackbar
    - _Requirements: 11_
  
  - [x] 11.5 Yorumlar listesini implement et
    - SliverList ile yorumlar
    - Her yorum için kullanıcı adı, rating, metin, tarih
    - Skeleton loading
    - _Requirements: 29_
  
  - [x] 11.6 Loading ve error state'leri ekle
    - Skeleton loading
    - Error message display
    - _Requirements: 16, 17_

- [ ]* 11.7 ProductDetailScreen widget testlerini yaz
  - UI element varlık testleri
  - Hero animation testleri
  - Save button interaction testleri
  - _Requirements: 8, 11, 27, 29_

- [x] 12. Navigasyon bar entegrasyonu
  - Home widget'ında TabBarView'e ProductSearchScreen ekle
  - İkinci sekme olarak yerleştir
  - Tab icon'u ekle (Iconsax.shop veya Iconsax.bag)
  - Tab geçişlerinde state preservation
  - _Requirements: 1, 21_

- [x] 13. Checkpoint - UI katmanını doğrula
  - Ensure all tests pass, ask the user if questions arise.

- [x] 14. Profil sayfası entegrasyonu
  - ProfileViewModel'de MediaService.getMediaList() çağrısını güncelle
  - MediaType.trendyolProduct tipini filtrele
  - Gardırop tab'ında Trendyol ürünlerini göster
  - Trendyol ürünleri için badge ekle (Trendyol logosu)
  - Trendyol ürününe tıklamada ProductDetailScreen'e yönlendir
  - _Requirements: 12_

- [ ]* 14.1 Profil entegrasyonu testlerini yaz
  - MediaType.trendyolProduct filtreleme testleri
  - Navigation testleri
  - _Requirements: 12_

- [x] 15. Performans optimizasyonları
  - [x] 15.1 Image caching yapılandırması
    - CachedNetworkImage için cache key stratejisi
    - memCacheWidth ve memCacheHeight ayarları
    - _Requirements: 20_
  
  - [x] 15.2 Const constructor'lar ekle
    - Stateless widget'larda const kullan
    - Immutable widget'ları optimize et
    - _Requirements: 20_
  
  - [x] 15.3 Selective rebuild optimizasyonları
    - Consumer yerine Selector kullan (gerekli yerlerde)
    - notifyListeners() çağrılarını optimize et
    - _Requirements: 20_

- [ ] 16. Accessibility iyileştirmeleri
  - Semantics widget'ları ekle
  - Screen reader desteği için label'lar
  - Interactive elementler için hint'ler
  - _Requirements: Genel UX_

- [x] 17. Error handling ve kullanıcı mesajları
  - Tüm error case'leri için Türkçe mesajlar
  - SnackBar veya Dialog ile kullanıcı bildirimleri
  - Retry mekanizması UI'ı
  - _Requirements: 16_

- [x] 18. Environment configuration
  - .env dosyasına TRENDYOL_API_BASE_URL ekle
  - API timeout ve retry ayarlarını yapılandır
  - Debug mode logging ayarları
  - _Requirements: 22_

- [ ]* 19. Integration testlerini yaz
  - End-to-end arama ve kaydetme flow testi
  - Navigation flow testleri
  - Filter ve sort integration testleri
  - _Requirements: 1-29_

- [x] 20. Final checkpoint - Tüm özellikleri doğrula
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- `*` ile işaretli task'lar optional test task'larıdır ve daha hızlı MVP için atlanabilir
- Her task spesifik requirement'lara referans verir
- Checkpoint'ler incremental validation sağlar
- MVVM mimarisi boyunca tutarlı bir şekilde uygulanır
- Tüm UI implementasyonları Figma tasarımlarına uygun olmalıdır
- Trendyol scraping API entegrasyonu için API dokümantasyonuna başvurulmalıdır
