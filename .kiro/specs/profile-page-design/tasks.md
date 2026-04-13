# Implementation Plan: Profile Page Design

## Overview

Bu implementation plan, Dressify AI Flutter uygulaması için profil sayfası UI tasarımının adım adım kodlanmasını içerir. MVVM mimarisi kullanılarak, Figma tasarımından alınan görsel öğeler Flutter/Dart ile implement edilecektir. Her task, önceki task'lerin üzerine inşa edilir ve tüm kod entegre bir şekilde çalışır durumda olacaktır.

## Tasks

- [x] 1. Proje yapısını ve temel model sınıflarını oluştur
  - `lib/features/profile/models/` klasörü oluştur
  - `profile.dart` model dosyasını oluştur (Profile sınıfı: id, fullName, username, bio, avatarUrl, coverImageUrl, createdAt, updatedAt)
  - `user_stats.dart` model dosyasını oluştur (UserStats sınıfı: aiLooksCount, uploadsCount, modelsCount)
  - `media.dart` model dosyasını oluştur (Media sınıfı ve MediaType enum: aiLook, upload, model)
  - Her model için `fromJson`, `toJson`, `copyWith` metodlarını implement et
  - Media sınıfına `aspectRatio` getter'ı ekle (masonry layout için)
  - _Requirements: 1, 7_

- [ ]* 1.1 Model sınıfları için unit testler yaz
  - `test/features/profile/models/` klasörü oluştur
  - Profile model için serialization/deserialization testleri yaz
  - UserStats model için serialization/deserialization testleri yaz
  - Media model için serialization/deserialization ve aspectRatio testleri yaz
  - _Requirements: 1, 7_

- [x] 2. Test data provider'ı oluştur
  - `lib/features/profile/data/` klasörü oluştur
  - `mock_profile_data.dart` dosyasını oluştur
  - `getMockProfile()` metodu implement et (gerçekçi profil verisi döndür)
  - `getMockStats()` metodu implement et (aiLooksCount: 24, uploadsCount: 12, modelsCount: 8)
  - `getMockMediaList()` metodu implement et (en az 8 farklı medya öğesi, farklı aspect ratio'lar)
  - _Requirements: 9_

- [x] 3. ProfileViewModel sınıfını oluştur
  - `lib/features/profile/viewmodels/` klasörü oluştur
  - `profile_view_model.dart` dosyasını oluştur
  - ChangeNotifier extend eden ProfileViewModel sınıfını oluştur
  - State properties ekle: `_profile`, `_stats`, `_mediaList`, `_isLoading`, `_isError`, `_errorMessage`, `_selectedTabIndex`
  - Getter'ları implement et: `profile`, `stats`, `mediaList`, `isLoading`, `isError`, `errorMessage`, `selectedTabIndex`
  - `_filteredMediaList` computed getter'ı implement et (tab index'e göre filtreleme)
  - `loadProfile(String? userId)` metodunu implement et (MockProfileData kullanarak)
  - `refreshProfile()` metodunu implement et
  - `selectTab(int index)` metodunu implement et
  - `_handleError(dynamic error)` ve `clearError()` metodlarını implement et
  - _Requirements: 7, 9, 11, 12_

- [ ]* 3.1 ProfileViewModel için unit testler yaz
  - `test/features/profile/viewmodels/` klasörü oluştur
  - Initial state testleri yaz (isLoading: false, isError: false)
  - `loadProfile()` metodunun loading state'i doğru set ettiğini test et
  - `selectTab()` metodunun filtrelemeyi doğru yaptığını test et
  - Error handling testlerini yaz
  - _Requirements: 7, 11, 12_

- [x] 4. Checkpoint - Model ve ViewModel katmanlarını doğrula
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Temel UI component'lerini oluştur
  - [x] 5.1 StatsOverlay widget'ını oluştur
    - `lib/features/profile/widgets/` klasörü oluştur
    - `stats_overlay.dart` dosyasını oluştur
    - Blur effect için BackdropFilter kullan (12px blur)
    - Shadow effect ekle (0px 25px 50px -12px rgba(0,0,0,0.25))
    - Üç istatistik göster (AI Looks, Uploads, Models)
    - Figma'dan alınan renk ve tipografi stillerini uygula
    - _Requirements: 3, 10_

  - [x] 5.2 ProfileInfoSection widget'ını oluştur
    - `profile_info_section.dart` dosyasını oluştur
    - Avatar widget'ı ekle (CircleAvatar, 80px çap)
    - İsim ve bio göster (Figma tipografi stillerine uygun)
    - StatsOverlay widget'ını entegre et
    - _Requirements: 3, 10_

  - [x] 5.3 GridItem widget'ını oluştur
    - `grid_item.dart` dosyasını oluştur
    - NetworkImage ile medya görseli göster
    - Tag overlay ekle (varsa)
    - Ripple effect için InkWell kullan
    - Hero animation tag ekle
    - RepaintBoundary ile sarma (performans için)
    - _Requirements: 5, 8, 15_

  - [x] 5.4 PrimaryActionButton widget'ını oluştur
    - `primary_action_button.dart` dosyasını oluştur
    - "Yeni Üret" butonu oluştur
    - Icon + Text layout
    - Figma shadow ve blur efektlerini uygula
    - _Requirements: 10_

- [ ]* 5.5 UI component'leri için widget testleri yaz
  - StatsOverlay widget testi yaz
  - ProfileInfoSection widget testi yaz
  - GridItem widget testi yaz
  - PrimaryActionButton widget testi yaz
  - _Requirements: 3, 5, 10_

- [x] 6. ProfileTabBar widget'ını oluştur
  - `profile_tab_bar.dart` dosyasını oluştur
  - TabBar widget'ı oluştur (3 sekme: "All", "AI Looks", "Uploads")
  - Tab indicator stilini Figma tasarımına göre ayarla
  - `onTabSelected` callback implement et
  - Figma tipografi stillerini uygula
  - _Requirements: 4, 10_

- [ ]* 6.1 ProfileTabBar için widget testi yaz
  - Tab selection testini yaz
  - Tab indicator testini yaz
  - _Requirements: 4_

- [x] 7. MasonryGridView widget'ını oluştur
  - `masonry_grid_view.dart` dosyasını oluştur
  - SliverGrid.builder kullan
  - Responsive column count hesapla (MediaQuery ile: <600px: 3, 600-900px: 4, >900px: 5)
  - GridItem widget'larını render et
  - 12px grid gap uygula
  - Lazy loading için SliverChildBuilderDelegate kullan
  - `onItemTap` callback implement et
  - _Requirements: 5, 8, 14_

- [ ]* 7.1 MasonryGridView için widget testleri yaz
  - Grid rendering testini yaz
  - Responsive column count testlerini yaz (3 farklı ekran boyutu)
  - Item tap testini yaz
  - _Requirements: 5, 14_

- [x] 8. Checkpoint - UI component'lerini doğrula
  - Ensure all tests pass, ask the user if questions arise.

- [x] 9. CarouselView widget'ını oluştur
  - `carousel_view.dart` dosyasını oluştur
  - PageView.builder ile dikey scroll carousel oluştur
  - Hero animation implement et
  - Swipe to dismiss gesture ekle (DismissiblePage veya GestureDetector)
  - Full screen modal olarak aç
  - Close butonu ekle
  - _Requirements: 6, 15_

- [ ]* 9.1 CarouselView için widget testleri yaz
  - Carousel rendering testini yaz
  - Swipe gesture testini yaz
  - Close button testini yaz
  - _Requirements: 6_

- [x] 10. FlexibleSpaceBarWidget oluştur
  - `flexible_space_bar_widget.dart` dosyasını oluştur
  - FlexibleSpaceBar widget'ı oluştur
  - Gradient overlay ekle
  - Scroll animasyonlarını implement et (expand/collapse)
  - ProfileInfoSection widget'ını entegre et
  - Figma'dan alınan renk ve shadow stillerini uygula
  - _Requirements: 2, 10, 15_

- [ ]* 10.1 FlexibleSpaceBarWidget için widget testi yaz
  - Scroll animation testini yaz
  - Expand/collapse behavior testini yaz
  - _Requirements: 2, 15_

- [x] 11. ProfileScreen ana widget'ını oluştur
  - [x] 11.1 ProfileScreen temel yapısını oluştur
    - `lib/features/profile/screens/` klasörü oluştur
    - `profile_screen.dart` dosyasını oluştur
    - StatefulWidget olarak ProfileScreen oluştur
    - CustomScrollView yapısını kur
    - ChangeNotifierProvider ile ProfileViewModel'i provide et
    - _Requirements: 1, 7_

  - [x] 11.2 SliverAppBar ve FlexibleSpaceBar'ı entegre et
    - SliverAppBar ekle (pinned: false, floating: false, expandedHeight: 480)
    - FlexibleSpaceBarWidget'ı entegre et
    - Settings butonu ekle (AppBar actions)
    - _Requirements: 1, 2_

  - [x] 11.3 TabBar'ı SliverPersistentHeader olarak ekle
    - SliverPersistentHeader oluştur (pinned: true)
    - ProfileTabBar widget'ını entegre et
    - Tab selection'ı ViewModel'e bağla
    - _Requirements: 4_

  - [x] 11.4 PrimaryActionButton'ı ekle
    - SliverToBoxAdapter içinde PrimaryActionButton ekle
    - "Yeni Üret" butonunu göster
    - onPressed callback implement et (navigation)
    - _Requirements: 17_

  - [x] 11.5 MasonryGridView'ı entegre et
    - MasonryGridView widget'ını ekle
    - Consumer ile mediaList'i dinle
    - onItemTap callback'te CarouselView aç
    - _Requirements: 5, 6_

  - [x] 11.6 Loading, error ve empty state'leri ekle
    - Consumer ile isLoading state'i dinle
    - Loading state için CircularProgressIndicator göster
    - Error state için hata mesajı ve "Tekrar Dene" butonu göster
    - Empty state için boş durum widget'ı göster
    - _Requirements: 11, 12, 18_

  - [x] 11.7 Pull-to-refresh desteği ekle
    - RefreshIndicator ekle
    - onRefresh callback'te ViewModel.refreshProfile() çağır
    - _Requirements: 13_

  - [x] 11.8 Accessibility desteği ekle
    - Tüm interaktif widget'lara Semantics ekle
    - GridItem'lara anlamlı semantik etiketler ekle
    - İstatistik widget'larına ekran okuyucu açıklamaları ekle
    - TabBar'a anlamlı etiketler ekle
    - _Requirements: 16_

- [ ]* 11.9 ProfileScreen için widget testleri yaz
  - Loading indicator testini yaz
  - Profile info display testini yaz
  - Tab switching testini yaz
  - Grid item tap testini yaz (carousel açılması)
  - Pull-to-refresh testini yaz
  - Error state testini yaz
  - Empty state testini yaz
  - _Requirements: 1, 4, 5, 6, 11, 12, 13, 18_

- [x] 12. Tema ve stil dosyalarını oluştur
  - `lib/core/theme/` klasörü oluştur
  - `profile_theme.dart` dosyasını oluştur
  - Figma'dan alınan renk paletini tanımla (primary: #742fe5, primaryLight: #ceb5ff, vb.)
  - Figma'dan alınan tipografi stillerini tanımla (Manrope, Be Vietnam Pro)
  - Figma'dan alınan spacing değerlerini tanımla
  - Figma'dan alınan shadow stillerini tanımla
  - _Requirements: 10_

- [x] 13. Routing ve navigation'ı entegre et
  - ProfileScreen'i ana routing yapısına ekle
  - "Profili Düzenle" butonu için navigation ekle
  - "Yeni Üret" butonu için navigation ekle
  - CarouselView modal navigation'ını implement et
  - _Requirements: 6, 17_

- [x] 14. Checkpoint - Tüm entegrasyonu doğrula
  - Ensure all tests pass, ask the user if questions arise.

- [ ]* 15. Golden testler (snapshot tests) yaz
  - `test/goldens/` klasörü oluştur
  - ProfileInfoSection golden test yaz
  - StatsOverlay golden test yaz
  - GridItem golden test yaz
  - PrimaryActionButton golden test yaz
  - _Requirements: 3, 5_

- [ ]* 16. Integration testler yaz
  - `integration_test/` klasörü oluştur
  - Complete user flow testini yaz (profile açma, tab değiştirme, carousel açma)
  - Pull-to-refresh flow testini yaz
  - _Requirements: 1, 4, 6, 13_

- [ ]* 17. Performance testleri yaz
  - Rebuild performance testini yaz (tab değişiminde minimal rebuild)
  - Scroll performance testini yaz
  - _Requirements: 8_

- [x] 18. Final checkpoint - Tüm testleri çalıştır ve doğrula
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- `*` ile işaretli task'lar opsiyoneldir ve daha hızlı MVP için atlanabilir
- Her task, ilgili requirements'ları referans alır (traceability için)
- Checkpoint'ler, incremental validation sağlar
- Test task'ları, implementation task'larının hemen altında yer alır (erken hata yakalama)
- Tüm kod Flutter/Dart ile yazılacak ve MVVM mimarisine uygun olacak
- Figma tasarımı (File Key: hBpOrjOf5YWhR9TXrERITn, Node ID: 1-2) referans alınacak
