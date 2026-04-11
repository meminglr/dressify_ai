# Design Document: Profile Page Backend

## Overview

Bu doküman, Dressify AI Flutter uygulaması için Supabase tabanlı profil sayfası backend sisteminin teknik tasarımını tanımlar. Sistem, kullanıcı profil yönetimi, medya galerisi, storage yönetimi ve realtime güncellemeler sağlar.

### Sistem Bileşenleri

- **Database Layer**: PostgreSQL tabloları (profiles, media), view'lar (user_stats), trigger'lar
- **Storage Layer**: Supabase Storage bucket'ları (avatars, gallery)
- **Service Layer**: Dart servisleri (ProfileService, MediaService, StorageService)
- **Security Layer**: Row Level Security (RLS) politikaları
- **Realtime Layer**: Supabase Realtime abonelikleri
- **Edge Functions**: AI üretim endpoint'i (generate-outfit)

### Teknoloji Stack'i

- **Backend**: Supabase (PostgreSQL, Storage, Realtime, Edge Functions)
- **Client**: Flutter/Dart
- **Authentication**: Supabase Auth (JWT)
- **Storage**: Supabase Storage (S3-compatible)

## Architecture

### Katmanlı Mimari

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter UI Layer                      │
│              (Screens, Widgets, ViewModels)              │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                  Service Layer (Dart)                    │
│  ┌──────────────┐ ┌──────────────┐ ┌─────────────────┐ │
│  │ProfileService│ │ MediaService │ │ StorageService  │ │
│  └──────────────┘ └──────────────┘ └─────────────────┘ │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│              Supabase Client (supabase_flutter)          │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                    Supabase Backend                      │
│  ┌──────────┐ ┌─────────┐ ┌─────────┐ ┌──────────────┐│
│  │PostgreSQL│ │ Storage │ │Realtime │ │Edge Functions││
│  │   +RLS   │ │ +RLS    │ │Channels │ │              ││
│  └──────────┘ └─────────┘ └─────────┘ └──────────────┘│
└─────────────────────────────────────────────────────────┘
```

### Veri Akışı

**Profil Okuma:**
```
UI → ProfileService.getProfile() → Supabase Client → PostgreSQL (profiles + user_stats) → RLS Check → Response
```

**Profil Güncelleme:**
```
UI → ProfileService.updateProfile() → Supabase Client → PostgreSQL (profiles) → RLS Check → Trigger (updated_at) → Realtime Event → UI Update
```

**Medya Yükleme:**
```
UI → MediaService.addMedia() → StorageService.uploadToGallery() → Supabase Storage (RLS Check) → MediaService.insertRecord() → PostgreSQL (media) → Realtime Event → UI Update
```

**AI Üretim:**
```
UI → Edge Function (generate-outfit) → JWT Validation → AI Processing → Storage Upload → PostgreSQL Insert → Response
```

## Components and Interfaces

### 1. Database Schema

#### profiles Table

```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  bio TEXT,
  avatar_url TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_profiles_updated_at ON profiles(updated_at);
```

**Trigger: auto_create_profile**
```sql
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

**Trigger: auto_update_timestamp**
```sql
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_profile_updated
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();
```

#### media Table

```sql
CREATE TABLE media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('AI_CREATION', 'MODEL', 'UPLOAD')),
  style_tag TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_media_user_created ON media(user_id, created_at DESC);
```

#### user_stats View

```sql
CREATE OR REPLACE VIEW user_stats AS
SELECT 
  user_id,
  COUNT(*) FILTER (WHERE type = 'AI_CREATION') AS ai_looks_count,
  COUNT(*) FILTER (WHERE type = 'UPLOAD') AS uploads_count,
  COUNT(*) FILTER (WHERE type = 'MODEL') AS models_count
FROM media
GROUP BY user_id;
```

### 2. Storage Buckets

#### avatars Bucket

```dart
// Configuration
{
  "name": "avatars",
  "public": false,
  "fileSizeLimit": 5242880, // 5MB
  "allowedMimeTypes": ["image/jpeg", "image/png", "image/webp"]
}

// File Path Structure
// {user_id}/{uuid}.{extension}
// Example: 123e4567-e89b-12d3-a456-426614174000/a1b2c3d4.jpg
```

#### gallery Bucket

```dart
// Configuration
{
  "name": "gallery",
  "public": false,
  "fileSizeLimit": 10485760, // 10MB
  "allowedMimeTypes": ["image/jpeg", "image/png", "image/webp"]
}

// File Path Structure
// {user_id}/{uuid}.{extension}
// Example: 123e4567-e89b-12d3-a456-426614174000/x9y8z7w6.png
```

### 3. RLS Policies

#### profiles Table Policies

```sql
-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- SELECT: Everyone can view all profiles
CREATE POLICY "Profiles are viewable by everyone"
  ON profiles FOR SELECT
  USING (true);

-- INSERT: Users can only insert their own profile
CREATE POLICY "Users can insert their own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- UPDATE: Users can only update their own profile
CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);
```

#### media Table Policies

```sql
-- Enable RLS
ALTER TABLE media ENABLE ROW LEVEL SECURITY;

-- SELECT: Users can only view their own media
CREATE POLICY "Users can view their own media"
  ON media FOR SELECT
  USING (auth.uid() = user_id);

-- INSERT: Users can only insert their own media
CREATE POLICY "Users can insert their own media"
  ON media FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- DELETE: Users can only delete their own media
CREATE POLICY "Users can delete their own media"
  ON media FOR DELETE
  USING (auth.uid() = user_id);
```

#### Storage Policies

```sql
-- avatars bucket
CREATE POLICY "Users can view their own avatars"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can upload their own avatars"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own avatars"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- gallery bucket (same policies)
CREATE POLICY "Users can view their own gallery"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'gallery' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can upload to their own gallery"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'gallery' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete from their own gallery"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'gallery' AND auth.uid()::text = (storage.foldername(name))[1]);
```

### 4. Service Layer Interfaces

#### ProfileService

```dart
class ProfileService {
  final SupabaseClient _client;
  
  ProfileService(this._client);
  
  /// Fetches user profile with statistics
  /// Returns null if profile not found
  Future<ProfileWithStats?> getProfile(String userId);
  
  /// Updates user profile information
  /// Throws ProfileException on failure
  Future<Profile> updateProfile({
    required String userId,
    String? fullName,
    String? bio,
    String? avatarUrl,
  });
  
  /// Subscribes to profile changes via Realtime
  /// Returns RealtimeChannel for cleanup
  RealtimeChannel subscribeToProfileChanges(
    String userId,
    void Function(Profile) onUpdate,
  );
  
  /// Unsubscribes from profile changes
  Future<void> unsubscribeFromProfileChanges(RealtimeChannel channel);
}
```

#### MediaService

```dart
class MediaService {
  final SupabaseClient _client;
  final StorageService _storageService;
  
  MediaService(this._client, this._storageService);
  
  /// Fetches paginated media list with optional type filter
  Future<List<Media>> getMediaList({
    required String userId,
    MediaType? type,
    int limit = 20,
    int offset = 0,
  });
  
  /// Adds new media (uploads file and creates DB record)
  /// Throws MediaException on failure
  Future<Media> addMedia({
    required String userId,
    required File imageFile,
    required MediaType type,
    String? styleTag,
  });
  
  /// Deletes media (removes file and DB record)
  /// Throws MediaException on failure
  Future<void> deleteMedia({
    required String userId,
    required String mediaId,
  });
  
  /// Subscribes to media changes via Realtime
  /// Returns RealtimeChannel for cleanup
  RealtimeChannel subscribeToMediaChanges(
    String userId,
    void Function(MediaEvent) onEvent,
  );
  
  /// Unsubscribes from media changes
  Future<void> unsubscribeFromMediaChanges(RealtimeChannel channel);
}
```

#### StorageService

```dart
class StorageService {
  final SupabaseClient _client;
  
  StorageService(this._client);
  
  /// Uploads avatar image
  /// Deletes old avatar if exists
  /// Returns public URL
  Future<String> uploadAvatar({
    required String userId,
    required File imageFile,
  });
  
  /// Uploads image to gallery
  /// Returns public URL
  Future<String> uploadToGallery({
    required String userId,
    required File imageFile,
  });
  
  /// Deletes file from storage
  /// Throws StorageException on failure
  Future<void> deleteFile({
    required String bucket,
    required String path,
  });
  
  /// Generates unique file path
  String _generateFilePath(String userId, String extension);
}
```

## Data Models

### Profile Model

```dart
class Profile {
  final String id;
  final String? fullName;
  final String? bio;
  final String? avatarUrl;
  final DateTime updatedAt;
  
  Profile({
    required this.id,
    this.fullName,
    this.bio,
    this.avatarUrl,
    required this.updatedAt,
  });
  
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
```

### ProfileWithStats Model

```dart
class ProfileWithStats {
  final Profile profile;
  final UserStats stats;
  
  ProfileWithStats({
    required this.profile,
    required this.stats,
  });
}
```

### UserStats Model

```dart
class UserStats {
  final String userId;
  final int aiLooksCount;
  final int uploadsCount;
  final int modelsCount;
  
  UserStats({
    required this.userId,
    required this.aiLooksCount,
    required this.uploadsCount,
    required this.modelsCount,
  });
  
  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      userId: json['user_id'] as String,
      aiLooksCount: json['ai_looks_count'] as int? ?? 0,
      uploadsCount: json['uploads_count'] as int? ?? 0,
      modelsCount: json['models_count'] as int? ?? 0,
    );
  }
}
```

### Media Model

```dart
enum MediaType {
  aiCreation('AI_CREATION'),
  model('MODEL'),
  upload('UPLOAD');
  
  final String value;
  const MediaType(this.value);
  
  static MediaType fromString(String value) {
    return MediaType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Invalid MediaType: $value'),
    );
  }
}

class Media {
  final String id;
  final String userId;
  final String imageUrl;
  final MediaType type;
  final String? styleTag;
  final DateTime createdAt;
  
  Media({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.type,
    this.styleTag,
    required this.createdAt,
  });
  
  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      imageUrl: json['image_url'] as String,
      type: MediaType.fromString(json['type'] as String),
      styleTag: json['style_tag'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'image_url': imageUrl,
      'type': type.value,
      'style_tag': styleTag,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
```

### MediaEvent Model (Realtime)

```dart
enum MediaEventType { insert, delete }

class MediaEvent {
  final MediaEventType type;
  final Media? media;
  
  MediaEvent({
    required this.type,
    this.media,
  });
}
```

## Error Handling

### Custom Exception Classes

```dart
class ProfileException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  ProfileException(this.message, {this.code, this.originalError});
  
  @override
  String toString() => 'ProfileException: $message';
}

class MediaException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  MediaException(this.message, {this.code, this.originalError});
  
  @override
  String toString() => 'MediaException: $message';
}

class StorageException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  StorageException(this.message, {this.code, this.originalError});
  
  @override
  String toString() => 'StorageException: $message';
}
```

### Error Handling Strategy

**Service Layer Error Handling:**

```dart
// Example: ProfileService.getProfile()
Future<ProfileWithStats?> getProfile(String userId) async {
  try {
    // Fetch profile
    final profileResponse = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    
    if (profileResponse == null) {
      return null;
    }
    
    // Fetch stats
    final statsResponse = await _client
        .from('user_stats')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    
    final profile = Profile.fromJson(profileResponse);
    final stats = statsResponse != null 
        ? UserStats.fromJson(statsResponse)
        : UserStats(userId: userId, aiLooksCount: 0, uploadsCount: 0, modelsCount: 0);
    
    return ProfileWithStats(profile: profile, stats: stats);
    
  } on PostgrestException catch (e) {
    debugPrint('ProfileService.getProfile error: ${e.message}');
    throw ProfileException(
      _getErrorMessage(e.code),
      code: e.code,
      originalError: e,
    );
  } catch (e) {
    debugPrint('ProfileService.getProfile unexpected error: $e');
    throw ProfileException(
      'Profil bilgileri alınırken bir hata oluştu',
      originalError: e,
    );
  }
}
```

**User-Friendly Error Messages:**

```dart
String _getErrorMessage(String? code) {
  switch (code) {
    case '23505': // unique_violation
      return 'Bu kayıt zaten mevcut';
    case '23503': // foreign_key_violation
      return 'İlişkili kayıt bulunamadı';
    case '42501': // insufficient_privilege
      return 'Bu işlem için yetkiniz yok';
    case 'PGRST116': // no rows returned
      return 'Kayıt bulunamadı';
    default:
      return 'Bir hata oluştu';
  }
}
```

## Testing Strategy

Bu sistem Infrastructure as Code (IaC), external service integration ve CRUD operasyonları içerdiğinden Property-Based Testing uygun değildir. Bunun yerine aşağıdaki test stratejileri kullanılacaktır:

### 1. Unit Tests (Example-Based)

**ProfileService Tests:**
- `getProfile()` başarılı senaryosu
- `getProfile()` profil bulunamadığında null döner
- `updateProfile()` başarılı güncelleme
- `updateProfile()` RLS ihlali hatası

**MediaService Tests:**
- `getMediaList()` filtreleme ve sayfalandırma
- `addMedia()` başarılı ekleme
- `deleteMedia()` başarılı silme
- `deleteMedia()` yetkisiz erişim hatası

**StorageService Tests:**
- `uploadAvatar()` başarılı yükleme
- `uploadAvatar()` eski avatar silme
- `uploadToGallery()` dosya boyutu limiti kontrolü
- `deleteFile()` başarılı silme

### 2. Integration Tests

**Database Integration:**
- Migration dosyalarının başarılı çalışması
- Trigger'ların doğru tetiklenmesi (auto_create_profile, auto_update_timestamp)
- RLS politikalarının doğru çalışması
- View'ların doğru sonuç döndürmesi (user_stats)

**Storage Integration:**
- Bucket'ların doğru yapılandırılması
- RLS politikalarının storage'da çalışması
- Dosya yükleme ve silme işlemleri

**Realtime Integration:**
- Profil değişikliklerinde realtime event'lerin tetiklenmesi
- Medya değişikliklerinde realtime event'lerin tetiklenmesi
- Subscription cleanup işlemlerinin doğru çalışması

### 3. Mock-Based Tests

**Service Layer Mocking:**
```dart
// Example: MediaService test with mocked StorageService
test('addMedia uploads file and creates record', () async {
  final mockStorage = MockStorageService();
  final mockClient = MockSupabaseClient();
  final mediaService = MediaService(mockClient, mockStorage);
  
  when(mockStorage.uploadToGallery(any, any))
      .thenAnswer((_) async => 'https://example.com/image.jpg');
  
  when(mockClient.from('media').insert(any))
      .thenAnswer((_) async => {'id': 'test-id', ...});
  
  final result = await mediaService.addMedia(
    userId: 'user-123',
    imageFile: File('test.jpg'),
    type: MediaType.upload,
  );
  
  expect(result.imageUrl, 'https://example.com/image.jpg');
  verify(mockStorage.uploadToGallery(any, any)).called(1);
  verify(mockClient.from('media').insert(any)).called(1);
});
```

### 4. Schema Validation Tests

**Database Schema:**
- Tablo yapılarının doğru oluşturulması
- Foreign key constraint'lerin doğru tanımlanması
- Index'lerin doğru oluşturulması
- Check constraint'lerin doğru çalışması (media.type)

### 5. End-to-End Tests

**User Flows:**
- Kullanıcı kaydı → profil otomatik oluşturma → profil görüntüleme
- Profil güncelleme → realtime event → UI güncelleme
- Medya yükleme → storage upload → DB insert → realtime event
- Medya silme → DB delete → storage delete

### Test Coverage Hedefleri

- Unit Tests: %80+ code coverage
- Integration Tests: Tüm kritik akışlar
- Mock-Based Tests: Tüm service metodları
- Schema Validation: Tüm migration dosyaları
- E2E Tests: Ana kullanıcı senaryoları

### Test Execution

```bash
# Unit tests
flutter test test/services/

# Integration tests (requires Supabase local setup)
flutter test integration_test/

# E2E tests
flutter drive --target=test_driver/app.dart
```

