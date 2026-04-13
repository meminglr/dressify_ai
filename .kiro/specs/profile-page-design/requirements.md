# Requirements Document

## Introduction

Bu doküman, Dressify AI Flutter uygulaması için profil sayfası UI tasarımının gereksinimlerini tanımlar. Sistem, MVVM mimarisi kullanarak performanslı, modern ve kullanıcı dostu bir profil deneyimi sağlar. Tasarım Stitch platformundan alınacak ve Flutter/Dart ile implement edilecektir.

## Glossary

- **Profile_Screen**: Kullanıcı profil sayfasını gösteren ana widget
- **Profile_ViewModel**: Profil sayfası iş mantığını yöneten ViewModel sınıfı
- **Sliver**: Flutter'ın scroll edilebilir alan widget'ları (CustomScrollView içinde kullanılır)
- **FlexibleSpaceBar**: AppBar içinde genişleyip daralan esnek alan widget'ı
- **TabView**: Sekmeli görünüm widget'ı (TabBar + TabBarView)
- **Grid_Item**: Grid içinde gösterilen medya öğesi widget'ı
- **Carousel_View**: Dikey scroll carousel görünümü widget'ı
- **ChangeNotifier**: Flutter'ın state yönetimi için kullanılan sınıf
- **Consumer**: ViewModel değişikliklerini dinleyen widget
- **Stitch_MCP**: Stitch tasarım platformu MCP entegrasyonu
- **Test_Data**: Geliştirme aşamasında kullanılan sahte veri
- **Rebuild**: Widget'ın yeniden oluşturulması işlemi

## Requirements

### Requirement 1: Profil Sayfası Temel Yapısı

**User Story:** Bir kullanıcı olarak, profil sayfamı açtığımda üst kısımda profil bilgilerimi ve alt kısımda içeriklerimi görmek istiyorum, böylece profilime genel bir bakış atabilirim.

#### Acceptance Criteria

1. THE Profile_Screen SHALL CustomScrollView kullanarak scroll edilebilir bir sayfa oluşturmalı
2. THE Profile_Screen SHALL SliverAppBar ile FlexibleSpaceBar içeren bir üst bar sağlamalı
3. THE Profile_Screen SHALL profil bilgileri bölümünü (avatar, isim, bio, istatistikler) göstermeli
4. THE Profile_Screen SHALL sekmeli içerik bölümünü (TabView) göstermeli

### Requirement 2: FlexibleSpaceBar ile Genişleyen Header

**User Story:** Bir kullanıcı olarak, sayfayı yukarı kaydırdığımda header'ın küçülmesini ve aşağı kaydırdığımda genişlemesini istiyorum, böylece modern bir kullanıcı deneyimi yaşayabilirim.

#### Acceptance Criteria

1. THE SliverAppBar SHALL FlexibleSpaceBar içermeli
2. WHEN kullanıcı sayfayı yukarı kaydırdığında, THE FlexibleSpaceBar SHALL daralan animasyon göstermeli
3. WHEN kullanıcı sayfayı aşağı kaydırdığında, THE FlexibleSpaceBar SHALL genişleyen animasyon göstermeli
4. THE FlexibleSpaceBar SHALL profil avatar'ını ve kullanıcı adını göstermeli

### Requirement 3: Profil Bilgileri Bölümü

**User Story:** Bir kullanıcı olarak, profil sayfamda avatar, isim, bio ve istatistiklerimi görmek istiyorum, böylece profil bilgilerime hızlıca erişebilirim.

#### Acceptance Criteria

1. THE Profile_Screen SHALL kullanıcı avatar'ını dairesel bir widget içinde göstermeli
2. THE Profile_Screen SHALL kullanıcı tam adını göstermeli
3. THE Profile_Screen SHALL kullanıcı bio'sunu göstermeli (varsa)
4. THE Profile_Screen SHALL üç istatistik göstermeli (AI Looks sayısı, Uploads sayısı, Models sayısı)

### Requirement 4: Sekmeli İçerik Görünümü

**User Story:** Bir kullanıcı olarak, içeriklerimi kategorilere göre filtrelemek için sekmeler kullanmak istiyorum, böylece aradığım içeriği kolayca bulabilirim.

#### Acceptance Criteria

1. THE Profile_Screen SHALL TabBar widget'ı ile üç sekme sağlamalı (All, AI Looks, Uploads)
2. THE Profile_Screen SHALL TabBarView widget'ı ile sekme içeriklerini göstermeli
3. WHEN kullanıcı bir sekmeye tıkladığında, THE TabBarView SHALL ilgili içeriği göstermeli
4. THE TabBar SHALL SliverPersistentHeader içinde pinned olarak kalmalı (scroll ederken sabit)

### Requirement 5: Grid Görünümü

**User Story:** Bir kullanıcı olarak, içeriklerimi grid formatında görmek istiyorum, böylece aynı anda birden fazla içeriği görebilirim.

#### Acceptance Criteria

1. THE Profile_Screen SHALL SliverGrid kullanarak içerikleri grid formatında göstermeli
2. THE SliverGrid SHALL 3 sütunlu bir düzen kullanmalı
3. THE Grid_Item SHALL medya görselini aspect ratio 1:1 ile göstermeli
4. THE Grid_Item SHALL tıklanabilir olmalı

### Requirement 6: Carousel View Açılması

**User Story:** Bir kullanıcı olarak, grid'deki bir öğeye tıkladığımda dikey scroll carousel görünümü açılmasını istiyorum, böylece içerikleri tam ekran görüntüleyebilirim.

#### Acceptance Criteria

1. WHEN kullanıcı bir Grid_Item'a tıkladığında, THE Profile_Screen SHALL Carousel_View açmalı
2. THE Carousel_View SHALL dikey scroll desteklemeli
3. THE Carousel_View SHALL tıklanan öğeden başlamalı
4. THE Carousel_View SHALL tam ekran modal olarak açılmalı

### Requirement 7: MVVM Mimarisi Uygulaması

**User Story:** Bir geliştirici olarak, profil sayfasının MVVM mimarisi ile geliştirilmesini istiyorum, böylece kod temiz ve test edilebilir olsun.

#### Acceptance Criteria

1. THE Profile_ViewModel SHALL ChangeNotifier extend etmeli
2. THE Profile_ViewModel SHALL profil verilerini yönetmeli (profile, stats, mediaList)
3. THE Profile_Screen SHALL Consumer widget'ı ile Profile_ViewModel'i dinlemeli
4. THE Profile_ViewModel SHALL iş mantığını UI'dan ayırmalı

### Requirement 8: Gereksiz Rebuild'lerin Önlenmesi

**User Story:** Bir geliştirici olarak, gereksiz widget rebuild'lerinin önlenmesini istiyorum, böylece uygulama performanslı çalışsın.

#### Acceptance Criteria

1. THE Profile_Screen SHALL const constructor'lar kullanmalı (mümkün olan yerlerde)
2. THE Profile_Screen SHALL Consumer widget'larını sadece değişen kısımlarda kullanmalı
3. THE Profile_ViewModel SHALL notifyListeners() metodunu sadece gerekli durumlarda çağırmalı
4. THE Grid_Item SHALL RepaintBoundary ile sarmalanmalı (gereksiz repaint'leri önlemek için)

### Requirement 9: Test Verileri Kullanımı

**User Story:** Bir geliştirici olarak, geliştirme aşamasında test verileri kullanmak istiyorum, böylece backend bağlantısı olmadan UI geliştirmesi yapabilirim.

#### Acceptance Criteria

1. THE Profile_ViewModel SHALL Test_Data kullanarak sahte profil bilgileri sağlamalı
2. THE Profile_ViewModel SHALL Test_Data kullanarak sahte medya listesi sağlamalı
3. THE Test_Data SHALL gerçekçi veri yapısına sahip olmalı (Profile, UserStats, Media modelleri ile uyumlu)
4. THE Profile_ViewModel SHALL gelecekte gerçek servislerle değiştirilebilir şekilde tasarlanmalı

### Requirement 10: Stitch Tasarım Entegrasyonu

**User Story:** Bir geliştirici olarak, Stitch platformundan tasarım bilgilerini almak istiyorum, böylece tasarımcının hazırladığı görsel tasarımı implement edebilirim.

#### Acceptance Criteria

1. THE geliştirici SHALL Stitch_MCP kullanarak Project ID: projects/4760427592547491373'ten tasarım bilgilerini almalı
2. THE geliştirici SHALL Stitch'ten alınan renk paletini Flutter tema renklerine dönüştürmeli
3. THE geliştirici SHALL Stitch'ten alınan spacing değerlerini Flutter padding/margin değerlerine dönüştürmeli
4. THE geliştirici SHALL Stitch'ten alınan tipografi bilgilerini Flutter TextStyle'lara dönüştürmeli

### Requirement 11: Profil Yükleme Durumu

**User Story:** Bir kullanıcı olarak, profil bilgileri yüklenirken bir loading göstergesi görmek istiyorum, böylece uygulamanın çalıştığını anlayabilirim.

#### Acceptance Criteria

1. THE Profile_ViewModel SHALL isLoading state'i yönetmeli
2. WHEN profil verileri yüklenirken, THE Profile_Screen SHALL CircularProgressIndicator göstermeli
3. WHEN profil verileri yüklendikten sonra, THE Profile_Screen SHALL içeriği göstermeli
4. THE Profile_ViewModel SHALL hata durumlarını yönetmeli (isError, errorMessage)

### Requirement 12: Hata Durumu Gösterimi

**User Story:** Bir kullanıcı olarak, profil yüklenirken bir hata oluştuğunda anlamlı bir hata mesajı görmek istiyorum, böylece ne olduğunu anlayabilirim.

#### Acceptance Criteria

1. WHEN profil yükleme hatası oluştuğunda, THE Profile_Screen SHALL hata mesajı göstermeli
2. THE Profile_Screen SHALL "Tekrar Dene" butonu sağlamalı
3. WHEN kullanıcı "Tekrar Dene" butonuna tıkladığında, THE Profile_ViewModel SHALL profil yükleme işlemini tekrar başlatmalı
4. THE hata mesajı SHALL kullanıcı dostu Türkçe metin olmalı

### Requirement 13: Pull-to-Refresh Desteği

**User Story:** Bir kullanıcı olarak, sayfayı aşağı çekerek profil bilgilerimi yenilemek istiyorum, böylece güncel verileri görebilirim.

#### Acceptance Criteria

1. THE Profile_Screen SHALL RefreshIndicator widget'ı kullanmalı
2. WHEN kullanıcı sayfayı aşağı çektiğinde, THE Profile_ViewModel SHALL profil verilerini yeniden yüklemeli
3. WHEN yenileme tamamlandığında, THE RefreshIndicator SHALL kaybolmalı
4. THE Profile_Screen SHALL yenileme sırasında mevcut içeriği göstermeye devam etmeli

### Requirement 14: Responsive Tasarım

**User Story:** Bir kullanıcı olarak, profil sayfasının farklı ekran boyutlarında düzgün görünmesini istiyorum, böylece her cihazda iyi bir deneyim yaşayabilirim.

#### Acceptance Criteria

1. THE Profile_Screen SHALL MediaQuery kullanarak ekran boyutunu algılamalı
2. WHEN ekran genişliği 600px'den küçükse, THE SliverGrid SHALL 3 sütun kullanmalı
3. WHEN ekran genişliği 600px ile 900px arasındaysa, THE SliverGrid SHALL 4 sütun kullanmalı
4. WHEN ekran genişliği 900px'den büyükse, THE SliverGrid SHALL 5 sütun kullanmalı

### Requirement 15: Animasyonlar ve Geçişler

**User Story:** Bir kullanıcı olarak, sayfa geçişlerinde ve etkileşimlerde yumuşak animasyonlar görmek istiyorum, böylece premium bir deneyim yaşayabilirim.

#### Acceptance Criteria

1. WHEN Carousel_View açıldığında, THE Profile_Screen SHALL Hero animasyonu kullanmalı
2. WHEN sekme değiştiğinde, THE TabBarView SHALL yumuşak geçiş animasyonu göstermeli
3. THE Grid_Item SHALL tıklandığında ripple efekti göstermeli
4. THE FlexibleSpaceBar SHALL yumuşak expand/collapse animasyonu göstermeli

### Requirement 16: Accessibility Desteği

**User Story:** Bir kullanıcı olarak, ekran okuyucu kullanırken profil sayfasını kullanabilmek istiyorum, böylece erişilebilir bir deneyim yaşayabilirim.

#### Acceptance Criteria

1. THE Profile_Screen SHALL tüm interaktif widget'lara Semantics eklemeli
2. THE Grid_Item SHALL anlamlı semantik etiketler içermeli (örn: "AI Look, 15 Ocak 2024")
3. THE istatistik widget'ları SHALL ekran okuyucu için anlamlı açıklamalar içermeli
4. THE TabBar SHALL her sekme için anlamlı etiketler sağlamalı

### Requirement 17: Profil Düzenleme Butonu

**User Story:** Bir kullanıcı olarak, kendi profilimde "Profili Düzenle" butonu görmek istiyorum, böylece profil bilgilerimi güncelleyebilirim.

#### Acceptance Criteria

1. THE Profile_Screen SHALL "Profili Düzenle" butonu göstermeli (sadece kendi profilinde)
2. WHEN kullanıcı "Profili Düzenle" butonuna tıkladığında, THE Profile_Screen SHALL profil düzenleme sayfasına navigate etmeli
3. THE buton SHALL FlexibleSpaceBar içinde veya profil bilgileri bölümünde konumlanmalı
4. THE buton SHALL Material Design 3 stilinde olmalı

### Requirement 18: Boş Durum Gösterimi

**User Story:** Bir kullanıcı olarak, henüz içerik yüklemediyse boş durum mesajı görmek istiyorum, böylece ne yapmam gerektiğini anlayabilirim.

#### Acceptance Criteria

1. WHEN kullanıcının medya listesi boşsa, THE Profile_Screen SHALL boş durum widget'ı göstermeli
2. THE boş durum widget'ı SHALL açıklayıcı bir ikon göstermeli
3. THE boş durum widget'ı SHALL "Henüz içerik yok" gibi bir mesaj göstermeli
4. THE boş durum widget'ı SHALL "İçerik Ekle" butonu sağlamalı (opsiyonel)

