# Implementation Plan: Profile Page Backend

## Overview

Bu implementation planı, Supabase tabanlı profil sayfası backend sistemini adım adım oluşturur. Önce database migration'ları ve RLS politikaları kurulacak, ardından Dart service katmanı implement edilecek, son olarak realtime özellikler eklenecektir.

## Tasks

- [x] 1. Database migration dosyalarını oluştur
  - [x] 1.1 profiles tablosu migration'ını oluştur
    - `supabase/migrations/` klasöründe yeni migration dosyası oluştur
    - profiles tablosunu tanımla (id, full_name, bio, avatar_url, updated_at)
    - Foreign key constraint ekle (auth.users.id)
    - Index oluştur (updated_at)
    - _Requirements: 1.1, 1.2, 1.4_
  
  - [x] 1.2 media tablosu migration'ını oluştur
    - media tablosunu tanımla (id, user_id, image_url, type, style_tag, created_at)
    - Foreign key constraint ekle (auth.users.id)
    - CHECK constraint ekle (type IN ('AI_CREATION', 'MODEL', 'UPLOAD'))
    - Index oluştur (user_id, created_at DESC)
    - _Requirements: 2.1, 2.2, 2.3, 2.4_
  
  - [x] 1.3 Database trigger'larını oluştur
    - auto_create_profile trigger'ı ekle (auth.users INSERT sonrası)
    - auto_update_timestamp trigger'ı ekle (profiles UPDATE öncesi)
    - _Requirements: 1.3, 1.4_
  
  - [x] 1.4 user_stats view'ını oluştur
    - user_stats view tanımla (user_id, ai_looks_count, uploads_count, models_count)
    - media tablosundan type'a göre COUNT aggregate kullan
    - _Requirements: 3.1, 3.2_

- [x] 2. RLS politikalarını oluştur
  - [x] 2.1 profiles tablosu RLS politikalarını ekle
    - RLS'yi etkinleştir (ALTER TABLE profiles ENABLE ROW LEVEL SECURITY)
    - SELECT politikası: herkese izin ver
    - INSERT politikası: auth.uid() = id
    - UPDATE politikası: auth.uid() = id
    - _Requirements: 5.1, 5.2, 5.3, 5.4_
  
  - [x] 2.2 media tablosu RLS politikalarını ekle
    - RLS'yi etkinleştir (ALTER TABLE media ENABLE ROW LEVEL SECURITY)
    - SELECT politikası: auth.uid() = user_id
    - INSERT politikası: auth.uid() = user_id
    - DELETE politikası: auth.uid() = user_id
    - _Requirements: 6.1, 6.2, 6.3, 6.4_
  
  - [x] 2.3 Storage bucket RLS politikalarını ekle
    - avatars bucket için SELECT, INSERT, DELETE politikaları
    - gallery bucket için SELECT, INSERT, DELETE politikaları
    - storage.foldername(name)[1] = auth.uid()::text kontrolü
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [x] 3. Checkpoint - Migration'ları test et
  - Supabase local environment'ta migration'ları çalıştır
  - Tablo yapılarını doğrula
  - RLS politikalarının çalıştığını test et
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Data model sınıflarını oluştur
  - [x] 4.1 Profile model sınıfını oluştur
    - `lib/models/profile.dart` dosyası oluştur
    - Profile sınıfı tanımla (id, fullName, bio, avatarUrl, updatedAt)
    - fromJson ve toJson metodlarını implement et
    - _Requirements: 8.2, 9.4_
  
  - [x] 4.2 UserStats model sınıfını oluştur
    - `lib/models/user_stats.dart` dosyası oluştur
    - UserStats sınıfı tanımla (userId, aiLooksCount, uploadsCount, modelsCount)
    - fromJson metodunu implement et
    - _Requirements: 3.1, 8.4_
  
  - [x] 4.3 ProfileWithStats model sınıfını oluştur
    - `lib/models/profile_with_stats.dart` dosyası oluştur
    - ProfileWithStats sınıfı tanımla (profile, stats)
    - _Requirements: 8.4_
  
  - [x] 4.4 Media model sınıfını oluştur
    - `lib/models/media.dart` dosyası oluştur
    - MediaType enum tanımla (aiCreation, model, upload)
    - Media sınıfı tanımla (id, userId, imageUrl, type, styleTag, createdAt)
    - fromJson ve toJson metodlarını implement et
    - _Requirements: 11.2, 12.4_
  
  - [x] 4.5 MediaEvent model sınıfını oluştur
    - `lib/models/media_event.dart` dosyası oluştur
    - MediaEventType enum tanımla (insert, delete)
    - MediaEvent sınıfı tanımla (type, media)
    - _Requirements: 15.3_

- [x] 5. Custom exception sınıflarını oluştur
  - [x] 5.1 ProfileException sınıfını oluştur
    - `lib/exceptions/profile_exception.dart` dosyası oluştur
    - ProfileException sınıfı tanımla (message, code, originalError)
    - _Requirements: 17.1_
  
  - [x] 5.2 MediaException sınıfını oluştur
    - `lib/exceptions/media_exception.dart` dosyası oluştur
    - MediaException sınıfı tanımla (message, code, originalError)
    - _Requirements: 17.2_
  
  - [x] 5.3 StorageException sınıfını oluştur
    - `lib/exceptions/storage_exception.dart` dosyası oluştur
    - StorageException sınıfı tanımla (message, code, originalError)
    - _Requirements: 17.3_

- [x] 6. StorageService'i implement et
  - [x] 6.1 StorageService sınıfını oluştur
    - `lib/services/storage_service.dart` dosyası oluştur
    - StorageService sınıfı tanımla (SupabaseClient dependency)
    - _Requirements: 4.1, 4.2_
  
  - [x] 6.2 uploadAvatar metodunu implement et
    - Dosya yükleme için unique path oluştur ({userId}/{uuid}.{extension})
    - Eski avatar varsa sil
    - Yeni dosyayı avatars bucket'ına yükle
    - Public URL döndür
    - Hata yönetimi ekle (try-catch, StorageException)
    - _Requirements: 10.1, 10.2, 10.3, 10.4_
  
  - [x] 6.3 uploadToGallery metodunu implement et
    - Dosya yükleme için unique path oluştur
    - Dosyayı gallery bucket'ına yükle
    - Public URL döndür
    - Hata yönetimi ekle
    - _Requirements: 12.2_
  
  - [x] 6.4 deleteFile metodunu implement et
    - Belirtilen bucket ve path'ten dosyayı sil
    - Hata yönetimi ekle
    - _Requirements: 13.3_
  
  - [ ]* 6.5 StorageService unit testlerini yaz
    - uploadAvatar başarılı senaryo testi
    - uploadAvatar eski avatar silme testi
    - uploadToGallery başarılı senaryo testi
    - deleteFile başarılı senaryo testi

- [x] 7. ProfileService'i implement et
  - [x] 7.1 ProfileService sınıfını oluştur
    - `lib/services/profile_service.dart` dosyası oluştur
    - ProfileService sınıfı tanımla (SupabaseClient dependency)
    - _Requirements: 8.1, 9.1_
  
  - [x] 7.2 getProfile metodunu implement et
    - profiles tablosundan kullanıcı bilgilerini çek
    - user_stats view'ından istatistikleri çek
    - ProfileWithStats nesnesi oluştur ve döndür
    - Profil bulunamazsa null döndür
    - Hata yönetimi ekle (try-catch, ProfileException)
    - _Requirements: 8.1, 8.2, 8.3, 8.4_
  
  - [x] 7.3 updateProfile metodunu implement et
    - profiles tablosunda güncelleme yap
    - Güncellenmiş profil bilgisini döndür
    - Hata yönetimi ekle
    - _Requirements: 9.1, 9.2, 9.3, 9.4_
  
  - [ ]* 7.4 ProfileService unit testlerini yaz
    - getProfile başarılı senaryo testi
    - getProfile profil bulunamadığında null döner testi
    - updateProfile başarılı güncelleme testi
    - updateProfile RLS ihlali hatası testi

- [x] 8. MediaService'i implement et
  - [x] 8.1 MediaService sınıfını oluştur
    - `lib/services/media_service.dart` dosyası oluştur
    - MediaService sınıfı tanımla (SupabaseClient, StorageService dependencies)
    - _Requirements: 11.1, 12.1, 13.1_
  
  - [x] 8.2 getMediaList metodunu implement et
    - media tablosundan filtrelenmiş sorgu yap
    - Sayfalandırma parametrelerini uygula (limit, offset)
    - created_at DESC sıralama ekle
    - Media listesi döndür
    - Hata yönetimi ekle
    - _Requirements: 11.1, 11.2, 11.3, 11.4_
  
  - [x] 8.3 addMedia metodunu implement et
    - StorageService.uploadToGallery ile dosyayı yükle
    - media tablosuna yeni kayıt ekle
    - Eklenen Media nesnesini döndür
    - Hata yönetimi ekle
    - _Requirements: 12.1, 12.2, 12.3, 12.4_
  
  - [x] 8.4 deleteMedia metodunu implement et
    - media tablosundan image_url'i al
    - StorageService.deleteFile ile dosyayı sil
    - media tablosundan kaydı sil
    - Hata yönetimi ekle
    - _Requirements: 13.1, 13.2, 13.3, 13.4_
  
  - [ ]* 8.5 MediaService unit testlerini yaz
    - getMediaList filtreleme ve sayfalandırma testi
    - addMedia başarılı ekleme testi
    - deleteMedia başarılı silme testi
    - deleteMedia yetkisiz erişim hatası testi

- [x] 9. Checkpoint - Service katmanını test et
  - Tüm service metodlarını manuel olarak test et
  - Hata senaryolarını doğrula
  - Ensure all tests pass, ask the user if questions arise.

- [x] 10. Realtime özelliklerini implement et
  - [x] 10.1 ProfileService realtime metodlarını ekle
    - subscribeToProfileChanges metodunu implement et
    - profiles tablosu için RealtimeChannel oluştur
    - UPDATE event'lerini dinle ve callback çağır
    - unsubscribeFromProfileChanges metodunu implement et
    - _Requirements: 14.1, 14.2, 14.3, 14.4_
  
  - [x] 10.2 MediaService realtime metodlarını ekle
    - subscribeToMediaChanges metodunu implement et
    - media tablosu için RealtimeChannel oluştur
    - INSERT ve DELETE event'lerini dinle ve callback çağır
    - unsubscribeFromMediaChanges metodunu implement et
    - _Requirements: 15.1, 15.2, 15.3, 15.4_
  
  - [ ]* 10.3 Realtime integration testlerini yaz
    - Profil değişikliklerinde realtime event tetikleme testi
    - Medya değişikliklerinde realtime event tetikleme testi
    - Subscription cleanup testi

- [x] 11. Storage bucket'larını Supabase'de yapılandır
  - [x] 11.1 avatars bucket'ını oluştur
    - Supabase Dashboard'da avatars bucket'ı oluştur
    - public: false, fileSizeLimit: 5MB ayarla
    - allowedMimeTypes: image/jpeg, image/png, image/webp ayarla
    - _Requirements: 4.1_
  
  - [x] 11.2 gallery bucket'ını oluştur
    - Supabase Dashboard'da gallery bucket'ı oluştur
    - public: false, fileSizeLimit: 10MB ayarla
    - allowedMimeTypes: image/jpeg, image/png, image/webp ayarla
    - _Requirements: 4.2_

- [x] 12. Edge Function oluştur (opsiyonel - AI üretim için)
  - [x] 12.1 generate-outfit Edge Function'ını oluştur
    - `supabase/functions/generate-outfit/index.ts` dosyası oluştur
    - JWT token doğrulaması ekle
    - AI üretim mantığını implement et
    - Üretilen görseli gallery bucket'ına kaydet
    - media tablosuna kayıt ekle
    - _Requirements: 16.1, 16.2, 16.3, 16.4_

- [x] 13. Final checkpoint - End-to-end test
  - Kullanıcı kaydı → profil otomatik oluşturma → profil görüntüleme akışını test et
  - Profil güncelleme → realtime event → UI güncelleme akışını test et
  - Medya yükleme → storage upload → DB insert → realtime event akışını test et
  - Medya silme → DB delete → storage delete akışını test et
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Migration dosyaları Supabase CLI ile oluşturulmalı: `supabase migration new <name>`
- Storage bucket'ları Supabase Dashboard veya CLI ile yapılandırılmalı
- Edge Function deployment için: `supabase functions deploy generate-outfit`
