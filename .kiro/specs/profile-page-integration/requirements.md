# Requirements Document

## Introduction

Bu doküman, Dressify AI Flutter uygulamasının profil sayfası backend entegrasyonu için gereksinimleri tanımlar. Sistem, mevcut UI bileşenlerini Supabase backend servisleri ile entegre ederek kullanıcıların profil bilgilerini görüntülemesini, medya içeriklerini yönetmesini ve fotoğraf yüklemesini sağlar.

## Glossary

- **ProfileViewModel**: Profil sayfası business logic katmanı (MVVM pattern)
- **ProfileScreen**: Profil sayfası UI katmanı
- **ProfileService**: Supabase profil servisi (mevcut)
- **MediaService**: Supabase medya servisi (mevcut)
- **StorageService**: Supabase storage servisi (mevcut)
- **Supabase**: Backend veritabanı ve storage platformu
- **Realtime_Subscription**: Supabase Realtime abonelik kanalı
- **InstaAssetsPicker**: Fotoğraf seçme paketi (https://pub.dev/packages/insta_assets_picker)
- **Media_Type**: Medya içerik tipi (aiLook, upload, model)
- **Auth_User**: Kimliği doğrulanmış kullanıcı
- **Loading_State**: Yükleme durumu göstergesi
- **Error_State**: Hata durumu göstergesi

## Requirements

### Requirement 1: Profil Bilgilerini Supabase'den Çekme

**User Story:** Bir kullanıcı olarak, profil sayfasını açtığımda kendi profil bilgilerimi Supabase'den görmek istiyorum, böylece güncel bilgilerime erişebilirim.

#### Acceptance Criteria

1. WHEN ProfileScreen açıldığında, THE ProfileViewModel SHALL ProfileService.getProfile() metodunu çağırmalı
2. WHEN getProfile başarılı olduğunda, THE ProfileViewModel SHALL profil ve istatistik bilgilerini state'e kaydetmeli
3. WHILE profil yüklenirken, THE ProfileScreen SHALL skeleton loading göstermeli
4. IF getProfile başarısız olursa, THEN THE ProfileViewModel SHALL hata mesajını state'e kaydetmeli ve ProfileScreen hata durumunu göstermeli

### Requirement 2: Kullanıcı İstatistiklerini Görüntüleme

**User Story:** Bir kullanıcı olarak, profilimde AI looks sayımı, uploads sayımı ve models sayımı görmek istiyorum, böylece aktivitemi takip edebilirim.

#### Acceptance Criteria

1. WHEN profil bilgileri yüklendiğinde, THE ProfileViewModel SHALL UserStats bilgisini FlexibleSpaceBarWidget'a iletmeli
2. THE FlexibleSpaceBarWidget SHALL aiLooksCount, uploadsCount ve modelsCount değerlerini görüntülemeli
3. WHEN istatistikler sıfır olduğunda, THE FlexibleSpaceBarWidget SHALL "0" değerini göstermeli
4. THE istatistikler SHALL sayısal format ile gösterilmeli (örn: 1,234)

### Requirement 3: Medya Listesini Supabase'den Çekme

**User Story:** Bir kullanıcı olarak, galerimde AI görünümlerimi, yüklemelerimi ve modellerimi Supabase'den görmek istiyorum, böylece içeriklerimi yönetebilirim.

#### Acceptance Criteria

1. WHEN ProfileScreen açıldığında, THE ProfileViewModel SHALL MediaService.getMediaList() metodunu çağırmalı
2. WHEN getMediaList başarılı olduğunda, THE ProfileViewModel SHALL medya listesini state'e kaydetmeli
3. WHILE medya listesi yüklenirken, THE ProfileScreen SHALL MasonryShimmer göstermeli
4. THE ProfileViewModel SHALL medya listesini Media_Type'a göre filtrelemeli (tab seçimine göre)

### Requirement 4: Tab Bazlı Medya Filtreleme

**User Story:** Bir kullanıcı olarak, farklı tab'lara tıkladığımda ilgili medya tipini görmek istiyorum, böylece içeriklerimi kategorize edebilirim.

#### Acceptance Criteria

1. WHEN "AI Görünümler" tab'ı seçildiğinde, THE ProfileViewModel SHALL sadece MediaType.aiLook içeriklerini döndürmeli
2. WHEN "Gardırop" tab'ı seçildiğinde, THE ProfileViewModel SHALL sadece MediaType.upload içeriklerini döndürmeli
3. WHEN "Modellerim" tab'ı seçildiğinde, THE ProfileViewModel SHALL sadece MediaType.model içeriklerini döndürmeli
4. THE filtreleme işlemi SHALL computed getter ile yapılmalı (gereksiz rebuild önlenmeli)

### Requirement 5: Realtime Profil Güncellemeleri

**User Story:** Bir kullanıcı olarak, profil bilgilerim güncellendiğinde sayfanın otomatik yenilenmesini istiyorum, böylece her zaman güncel bilgileri görürüm.

#### Acceptance Criteria

1. WHEN ProfileScreen mount olduğunda, THE ProfileViewModel SHALL ProfileService.subscribeToProfileChanges() çağırmalı
2. WHEN profil güncellendiğinde, THE ProfileViewModel SHALL callback ile yeni profil bilgisini almalı ve state'i güncellemeli
3. WHEN ProfileScreen dispose olduğunda, THE ProfileViewModel SHALL ProfileService.unsubscribeFromProfileChanges() çağırmalı
4. THE Realtime_Subscription SHALL memory leak oluşturmamalı

### Requirement 6: Realtime Medya Güncellemeleri

**User Story:** Bir kullanıcı olarak, galeriye yeni içerik eklendiğinde veya silindiğinde sayfanın otomatik yenilenmesini istiyorum, böylece her zaman güncel galeriyi görürüm.

#### Acceptance Criteria

1. WHEN ProfileScreen mount olduğunda, THE ProfileViewModel SHALL MediaService.subscribeToMediaChanges() çağırmalı
2. WHEN medya eklendiğinde veya silindiğinde, THE ProfileViewModel SHALL callback ile event almalı ve medya listesini güncellemeli
3. WHEN ProfileScreen dispose olduğunda, THE ProfileViewModel SHALL MediaService.unsubscribeFromMediaChanges() çağırmalı
4. THE Realtime_Subscription SHALL memory leak oluşturmamalı

### Requirement 7: InstaAssetsPicker Paketi Entegrasyonu

**User Story:** Bir geliştirici olarak, fotoğraf seçme özelliği için InstaAssetsPicker paketini entegre etmek istiyorum, böylece kullanıcılar kolayca fotoğraf seçebilsin.

#### Acceptance Criteria

1. THE pubspec.yaml SHALL insta_assets_picker paketini dependency olarak içermeli
2. THE ProfileViewModel SHALL InstaAssetsPicker.pickAssets() metodunu çağıran bir metod sağlamalı
3. WHEN fotoğraf seçimi iptal edildiğinde, THE ProfileViewModel SHALL hiçbir işlem yapmamalı
4. WHEN fotoğraf seçildiğinde, THE ProfileViewModel SHALL seçilen fotoğrafı File nesnesine dönüştürmeli

### Requirement 8: Gardırop Fotoğraf Yükleme

**User Story:** Bir kullanıcı olarak, Gardırop tab'ında "Kıyafet Ekle" butonuna tıklayarak kıyafet fotoğrafı yüklemek istiyorum, böylece gardırobumu oluşturabilirim.

#### Acceptance Criteria

1. WHEN "Kıyafet Ekle" butonuna tıklandığında, THE ProfileViewModel SHALL InstaAssetsPicker ile fotoğraf seçme ekranını açmalı
2. WHEN fotoğraf seçildiğinde, THE ProfileViewModel SHALL MediaService.addMedia() metodunu MediaType.upload ile çağırmalı
3. WHILE yükleme devam ederken, THE ProfileScreen SHALL loading indicator göstermeli
4. WHEN yükleme başarılı olduğunda, THE ProfileScreen SHALL başarı mesajı göstermeli ve galeriyi otomatik güncellemeli

### Requirement 9: Modellerim Fotoğraf Yükleme

**User Story:** Bir kullanıcı olarak, Modellerim tab'ında "Model Ekle" butonuna tıklayarak vücut fotoğrafı yüklemek istiyorum, böylece modelimi oluşturabilirim.

#### Acceptance Criteria

1. WHEN "Model Ekle" butonuna tıklandığında, THE ProfileViewModel SHALL InstaAssetsPicker ile fotoğraf seçme ekranını açmalı
2. WHEN fotoğraf seçildiğinde, THE ProfileViewModel SHALL MediaService.addMedia() metodunu MediaType.model ile çağırmalı
3. WHILE yükleme devam ederken, THE ProfileScreen SHALL loading indicator göstermeli
4. WHEN yükleme başarılı olduğunda, THE ProfileScreen SHALL başarı mesajı göstermeli ve galeriyi otomatik güncellemeli

### Requirement 10: Yükleme Durumu Yönetimi

**User Story:** Bir kullanıcı olarak, fotoğraf yüklenirken ilerleme görmek istiyorum, böylece işlemin devam ettiğini bilebilirim.

#### Acceptance Criteria

1. WHEN fotoğraf yükleme başladığında, THE ProfileViewModel SHALL isUploading state'ini true yapmalı
2. WHILE isUploading true iken, THE ProfileScreen SHALL CircularProgressIndicator veya LinearProgressIndicator göstermeli
3. WHEN yükleme tamamlandığında veya hata oluştuğunda, THE ProfileViewModel SHALL isUploading state'ini false yapmalı
4. THE loading indicator SHALL kullanıcı etkileşimini engellemeli (modal overlay)

### Requirement 11: Hata Durumu Yönetimi

**User Story:** Bir kullanıcı olarak, fotoğraf yükleme veya veri çekme sırasında hata oluştuğunda anlaşılır bir mesaj görmek istiyorum, böylece ne olduğunu anlayabilirim.

#### Acceptance Criteria

1. WHEN ProfileService veya MediaService hata döndürdüğünde, THE ProfileViewModel SHALL hata mesajını yakalayıp Türkçe mesaja çevirmeli
2. WHEN hata oluştuğunda, THE ProfileScreen SHALL SnackBar ile hata mesajını göstermeli
3. THE hata mesajları SHALL kullanıcı dostu ve Türkçe olmalı
4. WHEN kritik hata oluştuğunda (profil yüklenemedi), THE ProfileScreen SHALL "Tekrar Dene" butonu göstermeli

### Requirement 12: Pull-to-Refresh Desteği

**User Story:** Bir kullanıcı olarak, profil sayfasını aşağı çekerek yenilemek istiyorum, böylece en güncel verileri görebilirim.

#### Acceptance Criteria

1. THE ProfileScreen SHALL RefreshIndicator widget'ı kullanmalı
2. WHEN kullanıcı sayfayı aşağı çektiğinde, THE ProfileViewModel SHALL refreshProfile() metodunu çağırmalı
3. THE refreshProfile() SHALL hem profil hem de medya listesini yeniden yüklemeli
4. WHILE yenileme devam ederken, THE RefreshIndicator SHALL loading animasyonu göstermeli

### Requirement 13: Empty State Yönetimi

**User Story:** Bir kullanıcı olarak, henüz içerik yüklemedim ise boş durum mesajı ve yükleme butonu görmek istiyorum, böylece ne yapacağımı bilebilirim.

#### Acceptance Criteria

1. WHEN Gardırop tab'ı boş olduğunda, THE ProfileScreen SHALL "Gardırop Boş" mesajı ve "Kıyafet Ekle" butonu göstermeli
2. WHEN Modellerim tab'ı boş olduğunda, THE ProfileScreen SHALL "Model Eklenmemiş" mesajı ve "Model Ekle" butonu göstermeli
3. WHEN AI Görünümler tab'ı boş olduğunda, THE ProfileScreen SHALL "Henüz içerik yok" mesajı göstermeli
4. THE empty state butonları SHALL fotoğraf yükleme işlemini tetiklemeli

### Requirement 14: Accessibility Desteği

**User Story:** Bir görme engelli kullanıcı olarak, profil sayfasındaki tüm öğelerin ekran okuyucu ile erişilebilir olmasını istiyorum, böylece uygulamayı kullanabilirim.

#### Acceptance Criteria

1. THE ProfileScreen SHALL tüm butonlar için Semantics widget'ı kullanmalı
2. THE Semantics widget'ları SHALL label, hint ve button özelliklerini içermeli
3. THE loading state'ler SHALL "Yükleniyor" semantik etiketi içermeli
4. THE hata mesajları SHALL ekran okuyucu tarafından okunabilir olmalı

### Requirement 15: MVVM Mimarisi Uyumu

**User Story:** Bir geliştirici olarak, kodun MVVM mimarisine uygun olmasını istiyorum, böylece bakım ve test edilebilirlik kolaylaşsın.

#### Acceptance Criteria

1. THE ProfileViewModel SHALL tüm business logic'i içermeli (API çağrıları, state yönetimi)
2. THE ProfileScreen SHALL sadece UI rendering ve user interaction handling içermeli
3. THE ProfileViewModel SHALL ChangeNotifier extend etmeli ve notifyListeners() kullanmalı
4. THE ProfileScreen SHALL Consumer<ProfileViewModel> veya context.watch<ProfileViewModel>() kullanmalı

### Requirement 16: Performans Optimizasyonu

**User Story:** Bir kullanıcı olarak, profil sayfasının hızlı ve akıcı çalışmasını istiyorum, böylece iyi bir deneyim yaşayabilirim.

#### Acceptance Criteria

1. THE ProfileViewModel SHALL gereksiz notifyListeners() çağrılarından kaçınmalı
2. THE ProfileViewModel SHALL computed getter'lar kullanarak filtreleme yapmalı
3. THE ProfileScreen SHALL const constructor'lar kullanmalı (mümkün olduğunda)
4. THE medya listesi SHALL lazy loading desteklemeli (pagination)

### Requirement 17: Mock Data Kaldırma

**User Story:** Bir geliştirici olarak, ProfileViewModel'deki mock data kullanımının kaldırılmasını istiyorum, böylece gerçek Supabase verileri kullanılsın.

#### Acceptance Criteria

1. THE ProfileViewModel SHALL MockProfileData import'unu kaldırmalı
2. THE ProfileViewModel SHALL loadProfile() metodunda gerçek ProfileService çağrıları yapmalı
3. THE ProfileViewModel SHALL refreshProfile() metodunda gerçek servis çağrıları yapmalı
4. THE ProfileViewModel SHALL constructor'da ProfileService, MediaService dependency injection almalı

### Requirement 18: Fotoğraf Seçme Konfigürasyonu

**User Story:** Bir kullanıcı olarak, fotoğraf seçerken sadece uygun formatlarda ve boyutlarda fotoğraf seçebilmek istiyorum, böylece yükleme hataları oluşmasın.

#### Acceptance Criteria

1. THE InstaAssetsPicker konfigürasyonu SHALL maxAssets: 1 olmalı (tek fotoğraf seçimi)
2. THE InstaAssetsPicker konfigürasyonu SHALL requestType: RequestType.image olmalı (sadece resim)
3. THE ProfileViewModel SHALL seçilen fotoğrafın boyutunu kontrol etmeli (max 10MB)
4. IF fotoğraf boyutu limit aşarsa, THEN THE ProfileViewModel SHALL "Fotoğraf çok büyük" hatası göstermeli

### Requirement 19: Profil Fotoğrafı Düzenleme

**User Story:** Bir kullanıcı olarak, profil fotoğrafımı değiştirmek istiyorum, böylece profilimi kişiselleştirebilirim.

#### Acceptance Criteria

1. THE ProfileScreen AppBar SHALL profil fotoğrafı düzenleme ikonu içermeli (örn: Iconsax.camera veya Iconsax.edit)
2. WHEN düzenleme ikonuna tıklandığında, THE ProfileViewModel SHALL InstaAssetsPicker ile fotoğraf seçme ekranını açmalı
3. WHEN fotoğraf seçildiğinde, THE ProfileViewModel SHALL StorageService.uploadAvatar() metodunu çağırmalı
4. WHEN avatar yükleme başarılı olduğunda, THE ProfileViewModel SHALL ProfileService.updateProfile() ile avatarUrl'i güncellemeli
5. WHILE avatar yüklenirken, THE ProfileScreen SHALL loading indicator göstermeli
6. WHEN güncelleme başarılı olduğunda, THE ProfileScreen SHALL başarı mesajı göstermeli ve profil fotoğrafı otomatik güncellenmelidir
7. THE düzenleme ikonu SHALL collapsed ve expanded AppBar durumlarında görünür olmalı

### Requirement 20: Avatar Yükleme Hata Yönetimi

**User Story:** Bir kullanıcı olarak, profil fotoğrafı yüklerken hata oluşursa anlaşılır bir mesaj görmek istiyorum, böylece sorunu anlayabilirim.

#### Acceptance Criteria

1. WHEN StorageService.uploadAvatar() hata döndürdüğünde, THE ProfileViewModel SHALL hata mesajını yakalayıp Türkçe mesaja çevirmeli
2. WHEN ProfileService.updateProfile() hata döndürdüğünde, THE ProfileViewModel SHALL hata mesajını yakalayıp Türkçe mesaja çevirmeli
3. IF avatar yükleme başarısız olursa, THEN THE ProfileScreen SHALL SnackBar ile "Profil fotoğrafı yüklenemedi" mesajı göstermeli
4. THE hata durumunda SHALL eski profil fotoğrafı korunmalı (değişmemeli)

### Requirement 21: Supabase Power Entegrasyonu

**User Story:** Bir geliştirici olarak, Supabase veritabanı ve storage işlemlerinde Kiro AI Supabase Power'ını kullanmak istiyorum, böylece veritabanı sorgularını ve storage yapılandırmasını kolayca yönetebilirim.

#### Acceptance Criteria

1. THE geliştirici SHALL Supabase Power'ı kullanarak veritabanı tablolarını (profiles, media) doğrulamalı
2. THE geliştirici SHALL Supabase Power'ı kullanarak RLS politikalarını kontrol etmeli
3. THE geliştirici SHALL Supabase Power'ı kullanarak storage bucket'larını (avatars, gallery) doğrulamalı
4. WHEN veritabanı hatası oluştuğunda, THE geliştirici SHALL Supabase Power'ın search_docs aracını kullanarak hata kodlarını araştırmalı
5. THE geliştirici SHALL Supabase Power'ın get_advisors aracını kullanarak güvenlik açıklarını ve performans iyileştirmelerini kontrol etmeli

