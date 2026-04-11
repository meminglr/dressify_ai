# Requirements Document

## Introduction

Bu doküman, Dressify AI Flutter uygulaması için Supabase tabanlı profil sayfası backend sisteminin gereksinimlerini tanımlar. Sistem, kullanıcıların profil bilgilerini yönetmelerini, AI üretimleri ve yüklemeleri ile galeri oluşturmalarını sağlar.

## Glossary

- **Profile_Service**: Kullanıcı profil bilgilerini yöneten Supabase servis katmanı
- **Media_Service**: Kullanıcı medya içeriklerini (AI üretimleri, yüklemeler, modeller) yöneten servis
- **Storage_Service**: Supabase Storage bucket'larını yöneten servis (avatars, gallery)
- **Database**: Supabase PostgreSQL veritabanı
- **profiles**: Kullanıcı profil bilgilerini saklayan tablo
- **media**: Kullanıcı medya içeriklerini saklayan tablo
- **user_stats**: Kullanıcı istatistiklerini döndüren view/fonksiyon
- **RLS**: Row Level Security - Satır düzeyinde güvenlik politikaları
- **Edge_Function**: Supabase Edge Function - generate-outfit AI üretim fonksiyonu
- **Auth_User**: Supabase auth.users tablosundaki kimliği doğrulanmış kullanıcı
- **Media_Type**: Medya içerik tipi (AI_CREATION, MODEL, UPLOAD)
- **Realtime_Channel**: Supabase Realtime abonelik kanalı

## Requirements

### Requirement 1: Profil Tablosu Oluşturma

**User Story:** Bir geliştirici olarak, kullanıcı profil bilgilerinin saklanması için bir veritabanı tablosu oluşturmak istiyorum, böylece kullanıcılar profil bilgilerini yönetebilsin.

#### Acceptance Criteria

1. THE Database SHALL profiles tablosunu oluşturmalı (id UUID PRIMARY KEY, full_name TEXT, bio TEXT, avatar_url TEXT, updated_at TIMESTAMPTZ)
2. THE profiles.id SHALL auth.users.id ile foreign key ilişkisi kurmalı (ON DELETE CASCADE)
3. WHEN bir Auth_User oluşturulduğunda, THE Database SHALL otomatik olarak profiles tablosuna karşılık gelen satırı eklemeli (trigger ile)
4. THE profiles.updated_at SHALL her güncelleme işleminde otomatik olarak güncellenmelidir (trigger ile)

### Requirement 2: Medya Tablosu Oluşturma

**User Story:** Bir geliştirici olarak, kullanıcı medya içeriklerinin saklanması için bir veritabanı tablosu oluşturmak istiyorum, böylece AI üretimleri ve yüklemeler organize edilebilsin.

#### Acceptance Criteria

1. THE Database SHALL media tablosunu oluşturmalı (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID NOT NULL, image_url TEXT NOT NULL, type TEXT NOT NULL, style_tag TEXT, created_at TIMESTAMPTZ DEFAULT NOW())
2. THE media.user_id SHALL auth.users.id ile foreign key ilişkisi kurmalı (ON DELETE CASCADE)
3. THE media.type SHALL CHECK constraint ile sadece 'AI_CREATION', 'MODEL', 'UPLOAD' değerlerini kabul etmelidir
4. THE Database SHALL media.user_id ve media.created_at üzerinde index oluşturmalı (performans için)

### Requirement 3: Kullanıcı İstatistikleri View/Fonksiyonu

**User Story:** Bir kullanıcı olarak, profilimde AI üretim sayımı, yükleme sayımı ve model sayımı görmek istiyorum, böylece aktivitemi takip edebiliyim.

#### Acceptance Criteria

1. THE Database SHALL user_stats view veya fonksiyonu oluşturmalı (user_id, ai_looks_count, uploads_count, models_count döndürmeli)
2. WHEN user_stats sorgulandığında, THE Database SHALL media tablosundan type'a göre gruplandırılmış sayıları hesaplamalı
3. THE user_stats SHALL sadece çağıran kullanıcının kendi istatistiklerini döndürmeli (RLS ile)

### Requirement 4: Storage Bucket'ları Oluşturma

**User Story:** Bir geliştirici olarak, kullanıcı fotoğraflarının güvenli şekilde saklanması için storage bucket'ları oluşturmak istiyorum, böylece profil ve galeri görselleri yönetilebilsin.

#### Acceptance Criteria

1. THE Storage_Service SHALL 'avatars' bucket'ını oluşturmalı (public: false, file size limit: 5MB, allowed MIME types: image/jpeg, image/png, image/webp)
2. THE Storage_Service SHALL 'gallery' bucket'ını oluşturmalı (public: false, file size limit: 10MB, allowed MIME types: image/jpeg, image/png, image/webp)
3. THE Storage_Service SHALL her bucket için otomatik dosya adı çakışması önleme mekanizması sağlamalı (UUID kullanarak)

### Requirement 5: Profil RLS Politikaları

**User Story:** Bir kullanıcı olarak, diğer kullanıcıların profillerini görüntüleyebilmek ama sadece kendi profilimi düzenleyebilmek istiyorum, böylece güvenli bir deneyim yaşayabilirim.

#### Acceptance Criteria

1. THE Database SHALL profiles tablosunda SELECT için herkese izin veren RLS politikası oluşturmalı
2. THE Database SHALL profiles tablosunda UPDATE için sadece auth.uid() = id koşulunu sağlayan RLS politikası oluşturmalı
3. THE Database SHALL profiles tablosunda INSERT için sadece auth.uid() = id koşulunu sağlayan RLS politikası oluşturmalı
4. THE Database SHALL profiles tablosunda RLS'yi etkinleştirmeli (ALTER TABLE profiles ENABLE ROW LEVEL SECURITY)

### Requirement 6: Medya RLS Politikaları

**User Story:** Bir kullanıcı olarak, sadece kendi medya içeriklerimi görüntüleyebilmek, ekleyebilmek ve silebilmek istiyorum, böylece gizliliğim korunsun.

#### Acceptance Criteria

1. THE Database SHALL media tablosunda SELECT için sadece auth.uid() = user_id koşulunu sağlayan RLS politikası oluşturmalı
2. THE Database SHALL media tablosunda INSERT için sadece auth.uid() = user_id koşulunu sağlayan RLS politikası oluşturmalı
3. THE Database SHALL media tablosunda DELETE için sadece auth.uid() = user_id koşulunu sağlayan RLS politikası oluşturmalı
4. THE Database SHALL media tablosunda RLS'yi etkinleştirmeli (ALTER TABLE media ENABLE ROW LEVEL SECURITY)

### Requirement 7: Storage RLS Politikaları

**User Story:** Bir kullanıcı olarak, sadece kendi dosyalarımı yükleyebilmek, görüntüleyebilmek ve silebilmek istiyorum, böylece dosyalarım güvende olsun.

#### Acceptance Criteria

1. THE Storage_Service SHALL avatars bucket'ında SELECT için sadece auth.uid() = (storage.foldername(name))[1] koşulunu sağlayan RLS politikası oluşturmalı
2. THE Storage_Service SHALL avatars bucket'ında INSERT için sadece auth.uid() = (storage.foldername(name))[1] koşulunu sağlayan RLS politikası oluşturmalı
3. THE Storage_Service SHALL avatars bucket'ında DELETE için sadece auth.uid() = (storage.foldername(name))[1] koşulunu sağlayan RLS politikası oluşturmalı
4. THE Storage_Service SHALL gallery bucket'ı için aynı RLS politikalarını oluşturmalı

### Requirement 8: Profil Bilgilerini Çekme Servisi

**User Story:** Bir kullanıcı olarak, profil sayfasında kendi bilgilerimi görmek istiyorum, böylece profilimi kontrol edebiliyim.

#### Acceptance Criteria

1. THE Profile_Service SHALL getProfile(userId) metodunu sağlamalı
2. WHEN getProfile çağrıldığında, THE Profile_Service SHALL profiles tablosundan ilgili kullanıcının bilgilerini döndürmeli
3. IF profil bulunamazsa, THEN THE Profile_Service SHALL null döndürmeli
4. THE Profile_Service SHALL user_stats'tan kullanıcı istatistiklerini de çekmeli ve profil bilgisiyle birleştirmeli

### Requirement 9: Profil Güncelleme Servisi

**User Story:** Bir kullanıcı olarak, profil bilgilerimi (isim, bio, avatar) güncelleyebilmek istiyorum, böylece profilimi özelleştirebiliyim.

#### Acceptance Criteria

1. THE Profile_Service SHALL updateProfile(userId, fullName, bio, avatarUrl) metodunu sağlamalı
2. WHEN updateProfile çağrıldığında, THE Profile_Service SHALL profiles tablosunda ilgili satırı güncellemeli
3. IF güncelleme başarısızsa, THEN THE Profile_Service SHALL hata mesajı döndürmeli
4. WHEN güncelleme başarılıysa, THE Profile_Service SHALL güncellenmiş profil bilgisini döndürmeli

### Requirement 10: Avatar Yükleme Servisi

**User Story:** Bir kullanıcı olarak, profil fotoğrafımı yükleyebilmek istiyorum, böylece profilimi kişiselleştirebiliyim.

#### Acceptance Criteria

1. THE Storage_Service SHALL uploadAvatar(userId, imageFile) metodunu sağlamalı
2. WHEN uploadAvatar çağrıldığında, THE Storage_Service SHALL dosyayı avatars bucket'ına {userId}/{uuid}.{extension} formatında yüklemeli
3. IF eski avatar varsa, THEN THE Storage_Service SHALL eski dosyayı silmeli
4. WHEN yükleme başarılıysa, THE Storage_Service SHALL public URL döndürmeli

### Requirement 11: Medya Listesi Çekme Servisi

**User Story:** Bir kullanıcı olarak, galerimde AI üretimlerimi, yüklemelerimi ve modellerimi filtreleyerek görmek istiyorum, böylece içeriklerimi organize edebiliyim.

#### Acceptance Criteria

1. THE Media_Service SHALL getMediaList(userId, mediaType, limit, offset) metodunu sağlamalı
2. WHEN getMediaList çağrıldığında, THE Media_Service SHALL media tablosundan filtrelenmiş ve sayfalandırılmış sonuçları döndürmeli
3. WHERE mediaType belirtilmişse, THE Media_Service SHALL sadece o tipteki medyaları döndürmeli
4. THE Media_Service SHALL sonuçları created_at'e göre azalan sırada döndürmeli

### Requirement 12: Medya Ekleme Servisi

**User Story:** Bir kullanıcı olarak, galeriye yeni fotoğraf yükleyebilmek istiyorum, böylece içerik koleksiyonumu genişletebiliyim.

#### Acceptance Criteria

1. THE Media_Service SHALL addMedia(userId, imageFile, mediaType, styleTag) metodunu sağlamalı
2. WHEN addMedia çağrıldığında, THE Storage_Service SHALL dosyayı gallery bucket'ına yüklemeli
3. WHEN yükleme başarılıysa, THE Media_Service SHALL media tablosuna yeni kayıt eklemeli
4. WHEN kayıt eklendiğinde, THE Media_Service SHALL eklenen medya bilgisini döndürmeli

### Requirement 13: Medya Silme Servisi

**User Story:** Bir kullanıcı olarak, galerimden istemediğim fotoğrafları silebilmek istiyorum, böylece içeriklerimi yönetebiliyim.

#### Acceptance Criteria

1. THE Media_Service SHALL deleteMedia(userId, mediaId) metodunu sağlamalı
2. WHEN deleteMedia çağrıldığında, THE Media_Service SHALL önce media tablosundan image_url'i almalı
3. WHEN image_url alındığında, THE Storage_Service SHALL gallery bucket'ından dosyayı silmeli
4. WHEN dosya silindikten sonra, THE Media_Service SHALL media tablosundan kaydı silmeli

### Requirement 14: Realtime Profil Güncellemeleri

**User Story:** Bir kullanıcı olarak, profil bilgilerim güncellendiğinde uygulamanın otomatik olarak yenilenmesini istiyorum, böylece her zaman güncel bilgileri görüyorum.

#### Acceptance Criteria

1. THE Profile_Service SHALL subscribeToProfileChanges(userId, callback) metodunu sağlamalı
2. WHEN subscribeToProfileChanges çağrıldığında, THE Profile_Service SHALL Realtime_Channel oluşturmalı ve profiles tablosunu dinlemeli
3. WHEN profil güncellendiğinde, THE Profile_Service SHALL callback fonksiyonunu güncellenmiş verilerle çağırmalı
4. THE Profile_Service SHALL unsubscribeFromProfileChanges() metodunu sağlamalı

### Requirement 15: Realtime Medya Güncellemeleri

**User Story:** Bir kullanıcı olarak, galeriye yeni içerik eklendiğinde veya silindiğinde uygulamanın otomatik olarak yenilenmesini istiyorum, böylece her zaman güncel galeriyi görüyorum.

#### Acceptance Criteria

1. THE Media_Service SHALL subscribeToMediaChanges(userId, callback) metodunu sağlamalı
2. WHEN subscribeToMediaChanges çağrıldığında, THE Media_Service SHALL Realtime_Channel oluşturmalı ve media tablosunu dinlemeli
3. WHEN medya eklendiğinde veya silindiğinde, THE Media_Service SHALL callback fonksiyonunu güncellenmiş verilerle çağırmalı
4. THE Media_Service SHALL unsubscribeFromMediaChanges() metodunu sağlamalı

### Requirement 16: AI Üretim Edge Function

**User Story:** Bir kullanıcı olarak, yeni AI kıyafet üretimi tetikleyebilmek istiyorum, böylece kişiselleştirilmiş stil önerileri alabilirim.

#### Acceptance Criteria

1. THE Edge_Function SHALL generate-outfit endpoint'ini sağlamalı
2. WHEN generate-outfit çağrıldığında, THE Edge_Function SHALL JWT token doğrulaması yapmalı
3. WHEN token geçerliyse, THE Edge_Function SHALL AI üretim işlemini başlatmalı ve sonucu döndürmeli
4. WHEN üretim başarılıysa, THE Edge_Function SHALL üretilen görseli gallery bucket'ına kaydetmeli ve media tablosuna eklemeli

### Requirement 17: Hata Yönetimi ve Logging

**User Story:** Bir geliştirici olarak, backend işlemlerinde oluşan hataların loglanmasını istiyorum, böylece sorunları hızlıca tespit edip çözebilirim.

#### Acceptance Criteria

1. THE Profile_Service SHALL tüm hataları yakalayıp kullanıcı dostu mesajlar döndürmeli
2. THE Media_Service SHALL tüm hataları yakalayıp kullanıcı dostu mesajlar döndürmeli
3. THE Storage_Service SHALL tüm hataları yakalayıp kullanıcı dostu mesajlar döndürmeli
4. WHEN bir hata oluştuğunda, THE servisler SHALL hata detaylarını console'a loglamalı

### Requirement 18: Migration Dosyaları

**User Story:** Bir geliştirici olarak, veritabanı değişikliklerinin migration dosyaları ile yönetilmesini istiyorum, böylece değişiklikler versiyon kontrolünde takip edilebilsin.

#### Acceptance Criteria

1. THE Database SHALL create_profiles_table migration dosyası oluşturmalı
2. THE Database SHALL create_media_table migration dosyası oluşturmalı
3. THE Database SHALL create_user_stats_view migration dosyası oluşturmalı
4. THE Database SHALL setup_rls_policies migration dosyası oluşturmalı
