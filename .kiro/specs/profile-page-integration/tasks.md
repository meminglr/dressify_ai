# Implementation Plan: Profile Page Integration

## Overview

Bu plan, mevcut ProfileViewModel'deki mock data'yı kaldırarak Supabase backend servisleri ile gerçek entegrasyonu sağlar. InstaAssetsPicker paketi eklenir, fotoğraf yükleme özellikleri implemente edilir ve Realtime abonelikler kurulur.

## Tasks

- [x] 1. InstaAssetsPicker paketini ekle ve bağımlılıkları güncelle
  - `pubspec.yaml` dosyasına `insta_assets_picker` paketini dependency olarak ekle
  - `flutter pub get` çalıştır
  - _Requirements: 7.1_

- [x] 2. ProfileViewModel'i Supabase servisleri ile yeniden yaz
  - [x] 2.1 ProfileViewModel constructor'ını dependency injection ile güncelle
    - `ProfileService`, `MediaService`, `StorageService` parametrelerini constructor'a ekle
    - `MockProfileData` import'unu ve kullanımını kaldır
    - `isUploading` state property'sini ekle
    - `_profileChannel` ve `_mediaChannel` RealtimeChannel field'larını ekle
    - _Requirements: 15.1, 15.3, 17.1, 17.4_

  - [x] 2.2 `loadProfile()` metodunu gerçek servis çağrıları ile güncelle
    - `ProfileService.getProfile()` çağrısını implemente et
    - Başarılı yanıtta `_profile` ve `_stats` state'ini güncelle
    - Hata durumunda `_handleError()` çağır
    - Yükleme tamamlandığında `_subscribeToProfileChanges()` ve `_subscribeToMediaChanges()` çağır
    - _Requirements: 1.1, 1.2, 1.4, 17.2_

  - [x] 2.3 `loadMediaList()` metodunu gerçek servis çağrıları ile implemente et
    - `MediaService.getMediaList()` çağrısını implemente et
    - Başarılı yanıtta `_mediaList` state'ini güncelle
    - Hata durumunda `_handleError()` çağır
    - _Requirements: 3.1, 3.2, 17.3_

  - [x] 2.4 `refreshProfile()` metodunu gerçek servis çağrıları ile güncelle
    - Hem profil hem medya listesini yeniden yükle
    - _Requirements: 12.3, 17.3_

  - [x] 2.5 Tab filtreleme computed getter'ını düzelt
    - `_filteredMediaList` getter'ını 3 tab'a göre güncelle: 0=aiLook, 1=upload, 2=model
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

  - [ ]* 2.6 Property test: Tab-Based Media Filtering (Property 4)
    - **Property 4: Tab-Based Media Filtering**
    - Karışık MediaType içeren rastgele medya listeleri üret
    - Her tab index için filteredMediaList'in sadece ilgili tipi döndürdüğünü doğrula
    - **Validates: Requirements 4.1, 4.2, 4.3**

- [x] 3. Realtime aboneliklerini implemente et
  - [x] 3.1 `_subscribeToProfileChanges()` metodunu implemente et
    - `ProfileService.subscribeToProfileChanges()` çağır
    - Callback'te `_profile` state'ini güncelle ve `notifyListeners()` çağır
    - `_profileChannel` field'ına kanalı kaydet
    - _Requirements: 5.1, 5.2_

  - [x] 3.2 `_subscribeToMediaChanges()` metodunu implemente et
    - `MediaService.subscribeToMediaChanges()` çağır
    - INSERT event'inde `_mediaList`'e yeni medyayı ekle
    - DELETE event'inde `_mediaList`'ten ilgili medyayı kaldır
    - Her iki durumda `notifyListeners()` çağır
    - _Requirements: 6.1, 6.2_

  - [x] 3.3 `_unsubscribeAll()` metodunu implemente et ve `dispose()` içinde çağır
    - `ProfileService.unsubscribeFromProfileChanges()` çağır
    - `MediaService.unsubscribeFromMediaChanges()` çağır
    - _Requirements: 5.3, 5.4, 6.3, 6.4_

  - [ ]* 3.4 Property test: Realtime Profile Update Propagation (Property 5)
    - **Property 5: Realtime Profile Update Propagation**
    - Rastgele profil güncelleme event'leri üret
    - Callback tetiklendiğinde ViewModel'in state'i güncellediğini ve `notifyListeners()` çağırdığını doğrula
    - **Validates: Requirements 5.2**

  - [ ]* 3.5 Property test: Realtime Media Event Handling (Property 6)
    - **Property 6: Realtime Media Event Handling**
    - Rastgele INSERT ve DELETE media event'leri üret
    - INSERT'te listenin büyüdüğünü, DELETE'te küçüldüğünü doğrula
    - **Validates: Requirements 6.2**

- [x] 4. Checkpoint - Temel veri akışını doğrula
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Hata yönetimini güçlendir
  - [x] 5.1 `_handleError()` metodunu Türkçe mesaj dönüşümü ile güncelle
    - `ProfileException`, `MediaException`, `StorageException` tiplerini yakala
    - `PostgrestException` için `_mapPostgrestError()` metodunu ekle
    - Tüm hata mesajlarını Türkçe'ye çevir
    - _Requirements: 11.1, 11.3, 20.1, 20.2_

  - [ ]* 5.2 Property test: Error Message Localization (Property 10)
    - **Property 10: Error Message Localization**
    - Rastgele servis hataları üret (ProfileException, MediaException, StorageException)
    - ViewModel'in her hata için Türkçe mesaj ürettiğini ve error state'ini set ettiğini doğrula
    - **Validates: Requirements 11.1, 20.1, 20.2**

- [x] 6. InstaAssetsPicker entegrasyonunu implemente et
  - [x] 6.1 `_pickPhoto()` yardımcı metodunu ProfileViewModel'e ekle
    - `InstaAssetsPicker.pickAssets()` çağrısını maxAssets:1, requestType:image ile konfigüre et
    - İptal durumunda null döndür
    - _Requirements: 7.2, 7.3, 18.1, 18.2_

  - [x] 6.2 `_assetToFile()` yardımcı metodunu implemente et
    - `AssetEntity`'yi `File`'a dönüştür
    - Dosya boyutunu kontrol et (max 10MB)
    - Boyut aşımında Türkçe hata fırlat
    - _Requirements: 7.4, 18.3, 18.4_

  - [ ]* 6.3 Property test: Asset to File Conversion (Property 7)
    - **Property 7: Asset to File Conversion**
    - Rastgele dosya boyutları üret (0 - 20MB arası)
    - 10MB altında dönüşümün başarılı, üstünde exception fırlattığını doğrula
    - **Validates: Requirements 7.4, 18.3**

  - [ ]* 6.4 Property test: File Size Validation (Property 11)
    - **Property 11: File Size Validation**
    - Rastgele byte değerleri üret
    - 10 * 1024 * 1024 sınırına göre validation sonucunu doğrula
    - **Validates: Requirements 18.3, 18.4**

- [x] 7. Gardırop ve Model fotoğraf yükleme metodlarını implemente et
  - [x] 7.1 `uploadGardıropPhoto()` metodunu implemente et
    - `_pickPhoto()` ile fotoğraf seç
    - `_assetToFile()` ile File'a dönüştür
    - `_isUploading = true` set et ve `notifyListeners()` çağır
    - `MediaService.addMedia()` metodunu `MediaType.upload` ile çağır
    - Başarıda `_isUploading = false` set et
    - Hata durumunda `_handleError()` çağır ve `_isUploading = false` set et
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 10.1, 10.3_

  - [x] 7.2 `uploadModelPhoto()` metodunu implemente et
    - `_pickPhoto()` ile fotoğraf seç
    - `_assetToFile()` ile File'a dönüştür
    - `_isUploading = true` set et ve `notifyListeners()` çağır
    - `MediaService.addMedia()` metodunu `MediaType.model` ile çağır
    - Başarıda `_isUploading = false` set et
    - Hata durumunda `_handleError()` çağır ve `_isUploading = false` set et
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 10.1, 10.3_

  - [ ]* 7.3 Property test: Media Upload with Correct Type (Property 8)
    - **Property 8: Media Upload with Correct Type**
    - Mock MediaService ile rastgele geçerli dosyalar üret
    - `uploadGardıropPhoto()` çağrısında `MediaType.upload`, `uploadModelPhoto()` çağrısında `MediaType.model` kullanıldığını doğrula
    - **Validates: Requirements 8.2, 9.2**

  - [ ]* 7.4 Property test: Upload State Management (Property 9)
    - **Property 9: Upload State Management**
    - Başarılı ve başarısız upload senaryoları üret
    - Her iki durumda da işlem sonunda `isUploading`'in false olduğunu doğrula
    - **Validates: Requirements 10.3**

- [x] 8. Profil fotoğrafı düzenleme özelliğini implemente et
  - [x] 8.1 `uploadAvatarPhoto()` metodunu implemente et
    - `_pickPhoto()` ile fotoğraf seç
    - `_assetToFile()` ile File'a dönüştür
    - `_isUploading = true` set et
    - `StorageService.uploadAvatar()` çağır
    - Başarıda `ProfileService.updateProfile()` ile avatarUrl'i güncelle
    - Hata durumunda mevcut `_profile.avatarUrl`'i koru (değiştirme)
    - `_isUploading = false` set et
    - _Requirements: 19.2, 19.3, 19.4, 19.5, 19.6, 20.4_

  - [ ]* 8.2 Property test: Avatar Update Preservation on Error (Property 12)
    - **Property 12: Avatar Update Preservation on Error**
    - Rastgele avatar upload hataları üret
    - Hata sonrasında `_profile.avatarUrl`'in upload öncesi değerini koruduğunu doğrula
    - **Validates: Requirements 20.4**

- [x] 9. ProfileScreen'i ProfileViewModel metodlarına bağla
  - [x] 9.1 ProfileScreen'deki TODO upload butonlarını gerçek metodlara bağla
    - `_buildInlineUploadButton()` içindeki `onTap`'i `viewModel.uploadGardıropPhoto()` veya `viewModel.uploadModelPhoto()` ile güncelle
    - `_buildEmptyStateWithUpload()` içindeki `onTap`'i aynı şekilde güncelle
    - _Requirements: 8.1, 9.1, 13.4_

  - [x] 9.2 Avatar düzenleme ikonunu SliverAppBar'a ekle
    - `_buildSliverAppBar()` actions listesine kamera/düzenleme ikonu ekle
    - `onPressed`'e `viewModel.uploadAvatarPhoto()` bağla
    - Collapsed ve expanded durumlarında görünür olacak şekilde renk ayarla
    - _Requirements: 19.1, 19.7_

  - [x] 9.3 `isUploading` durumunda modal loading overlay ekle
    - `Consumer<ProfileViewModel>` içinde `viewModel.isUploading` kontrolü ekle
    - `Stack` ile `CircularProgressIndicator` içeren modal overlay göster
    - Overlay kullanıcı etkileşimini engellemeli (`AbsorbPointer` veya `IgnorePointer`)
    - _Requirements: 10.2, 10.4_

  - [x] 9.4 Başarı ve hata SnackBar'larını ProfileScreen'e ekle
    - ViewModel'de `_successMessage` state'i ekle
    - Upload başarısında Türkçe başarı mesajı göster
    - Hata durumunda `viewModel.errorMessage` ile SnackBar göster
    - _Requirements: 8.4, 9.4, 11.2, 19.6, 20.3_

- [x] 10. ProfileScreen'de ChangeNotifierProvider kurulumunu güncelle
  - `ProfileScreen`'in sağlandığı yerde (home.dart veya router) `ChangeNotifierProvider`'ı gerçek servislerle güncelle
  - `ProfileViewModel` constructor'ına `ProfileService.instance()`, `MediaService` ve `StorageService` inject et
  - _Requirements: 15.4, 17.4_

- [x] 11. Checkpoint - Tüm entegrasyonu doğrula
  - Ensure all tests pass, ask the user if questions arise.

- [x] 12. Supabase veritabanı ve storage yapılandırmasını doğrula
  - Supabase Power kullanarak `profiles` ve `media` tablolarının şemasını doğrula
  - Supabase Power kullanarak RLS politikalarını kontrol et (profiles, media tabloları)
  - Supabase Power kullanarak `avatars` ve `gallery` storage bucket'larının varlığını doğrula
  - Supabase Power'ın `get_advisors` aracı ile güvenlik açıklarını kontrol et
  - _Requirements: 21.1, 21.2, 21.3, 21.5_

- [ ] 13. Property test: Profile State Update Consistency (Property 1)
  - [ ] 13.1 Property test: Profile State Update Consistency
    - **Property 1: Profile State Update Consistency**
    - Mock ProfileService ile rastgele Profile ve UserStats verileri üret (100 iterasyon)
    - `loadProfile()` sonrasında state'in doğru güncellendiğini ve `notifyListeners()`'ın tam 1 kez çağrıldığını doğrula
    - **Validates: Requirements 1.2**

  - [ ] 13.2 Property test: Media List State Update (Property 3)
    - **Property 3: Media List State Update**
    - Mock MediaService ile rastgele medya listeleri üret (100 iterasyon)
    - `loadProfile()` sonrasında `mediaList` state'inin güncellendiğini ve `notifyListeners()`'ın çağrıldığını doğrula
    - **Validates: Requirements 3.2**

- [x] 14. FlexibleSpaceBarWidget istatistik formatlamasını doğrula
  - [x] 14.1 İstatistik sayılarını formatla (bin ayracı)
    - `FlexibleSpaceBarWidget` içinde sayıları `NumberFormat` ile formatla (örn: 1,234)
    - Sıfır değerlerinin "0" olarak gösterildiğini doğrula
    - _Requirements: 2.2, 2.3, 2.4_

  - [ ]* 14.2 Property test: Stats Display Formatting (Property 2)
    - **Property 2: Stats Display Formatting**
    - Rastgele negatif olmayan integer değerler ile UserStats üret (100 iterasyon)
    - Widget'ın doğru formatlanmış sayıları gösterdiğini doğrula (>= 1000 için bin ayracı)
    - **Validates: Requirements 2.2, 2.4**

- [x] 15. Final checkpoint - Tüm testlerin geçtiğini doğrula
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- `*` ile işaretli görevler opsiyoneldir, MVP için atlanabilir
- Her görev ilgili gereksinimlere referans verir
- Property testleri `test` paketi ile yazılmalı, minimum 100 iterasyon kullanılmalı
- Test tag formatı: `@Tags(['pbt', 'profile-page-integration'])`
- Tüm hata mesajları Türkçe olmalı
- `MockProfileData` tamamen kaldırılmalı, gerçek servis çağrıları kullanılmalı
