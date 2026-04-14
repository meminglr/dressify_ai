# Design Document: Profile Page Integration

## Overview

Bu tasarım dokümanı, Dressify AI Flutter uygulamasının profil sayfası backend entegrasyonunu detaylandırır. Mevcut UI bileşenleri (ProfileScreen, FlexibleSpaceBarWidget, MasonryGridView) Supabase backend servisleri (ProfileService, MediaService, StorageService) ile entegre edilecek ve MVVM mimarisi kullanılarak ProfileViewModel üzerinden yönetilecektir.

### Temel Özellikler

- **Profil Bilgileri Yönetimi**: Kullanıcı profil bilgilerini ve istatistiklerini Supabase'den çekme ve görüntüleme
- **Medya Galerisi**: AI görünümleri, gardırop ve model fotoğraflarını tab bazlı filtreleme ile görüntüleme
- **Realtime Güncellemeler**: Profil ve medya değişikliklerini Supabase Realtime ile anlık güncelleme
- **Fotoğraf Yükleme**: InstaAssetsPicker ile gardırop ve model fotoğrafları yükleme
- **Profil Fotoğrafı Düzenleme**: Avatar yükleme ve güncelleme
- **Hata Yönetimi**: Türkçe hata mesajları ve kullanıcı dostu error handling
- **Performans Optimizasyonu**: Computed getters, gereksiz rebuild önleme, lazy loading

### Teknoloji Stack

- **Flutter**: UI framework
- **Provider**: State management (MVVM pattern)
- **Supabase**: Backend (PostgreSQL + Realtime + Storage)
- **InstaAssetsPicker**: Fotoğraf seçme paketi
- **Mevcut Servisler**: ProfileService, MediaService, StorageService

## Architecture

### MVVM Pattern

Uygulama MVVM (Model-View-ViewModel) mimarisini kullanır:

```
┌─────────────────┐
│  ProfileScreen  │  (View)
│   - UI Rendering│
│   - User Input  │
└────────┬────────┘
         │ Consumer/Watch
         ▼
┌─────────────────┐
│ProfileViewModel │  (ViewModel)
│ - Business Logic│
│ - State Mgmt    │
│ - Data Transform│
└────────┬────────┘
         │ Service Calls
         ▼
┌─────────────────┐
│   Services      │  (Model)
│ - ProfileService│
│ - MediaService  │
│ - StorageService│
└────────┬────────┘
         │ API Calls
         ▼
┌─────────────────┐
│    Supabase     │
│ - PostgreSQL    │
│ - Realtime      │
│ - Storage       │
└─────────────────┘
```

### Katman Sorumlulukları

**View (ProfileScreen)**:
- UI rendering ve widget composition
- User interaction handling (button clicks, gestures)
- ViewModel state'ini dinleme (Consumer/watch)
- Loading, error, empty state gösterimi
- Accessibility support (Semantics widgets)

**ViewModel (ProfileViewModel)**:
- Business logic ve data transformation
- State management (ChangeNotifier)
- Service orchestration
- Error handling ve Türkçe mesaj dönüşümü
- Computed getters ile filtreleme
- Realtime subscription yönetimi

**Model (Services)**:
- Supabase API çağrıları
- Data serialization/deserialization
- Realtime channel yönetimi
- Storage operations

### Data Flow

**Profil Yükleme Flow**:
```
User Opens Screen
    ↓
ProfileScreen.initState()
    ↓
ProfileViewModel.loadProfile()
    ↓
ProfileService.getProfile()
    ↓
Supabase Query
    ↓
ProfileViewModel updates state
    ↓
ProfileScreen rebuilds with data
```

**Fotoğraf Yükleme Flow**:
```
User Clicks Upload Button
    ↓
ProfileViewModel.uploadPhoto()
    ↓
InstaAssetsPicker.pickAssets()
    ↓
File validation (size, type)
    ↓
StorageService.uploadToGallery()
    ↓
MediaService.addMedia()
    ↓
Realtime event triggers
    ↓
ProfileViewModel updates media list
    ↓
ProfileScreen rebuilds with new media
```

**Realtime Update Flow**:
```
Database Change (INSERT/UPDATE/DELETE)
    ↓
Supabase Realtime Event
    ↓
Service callback
    ↓
ProfileViewModel updates state
    ↓
ProfileScreen rebuilds automatically
```

## Components and Interfaces

### ProfileViewModel

ProfileViewModel, profil sayfasının tüm business logic'ini yönetir.

**State Properties**:
```dart
class ProfileViewModel extends ChangeNotifier {
  // Data state
  Profile? _profile;
  UserStats? _stats;
  List<Media> _mediaList = [];
  
  // UI state
  bool _isProfileLoading = false;
  bool _isMediaLoading = false;
  bool _isUploading = false;
  bool _isError = false;
  String? _errorMessage;
  int _selectedTabIndex = 0;
  
  // Realtime subscriptions
  RealtimeChannel? _profileChannel;
  RealtimeChannel? _mediaChannel;
}
```

**Public Methods**:

```dart
// Profil yükleme
Future<void> loadProfile(String? userId);

// Profil yenileme (pull-to-refresh)
Future<void> refreshProfile();

// Tab seçimi ve filtreleme
void selectTab(int index);
List<Media> get filteredMediaList; // Computed getter

// Fotoğraf yükleme
Future<void> uploadGardıropPhoto();
Future<void> uploadModelPhoto();
Future<void> uploadAvatarPhoto();

// Realtime subscription yönetimi
void _subscribeToProfileChanges();
void _subscribeToMediaChanges();
void _unsubscribeAll();

// Hata yönetimi
void _handleError(dynamic error);
void clearError();
```

**Dependency Injection**:
```dart
ProfileViewModel({
  required ProfileService profileService,
  required MediaService mediaService,
  required StorageService storageService,
}) : _profileService = profileService,
     _mediaService = mediaService,
     _storageService = storageService;
```

### ProfileScreen

ProfileScreen, profil sayfasının UI katmanıdır.

**Widget Hierarchy**:
```
Scaffold
└── RefreshIndicator
    └── NestedScrollView
        ├── SliverAppBar (with FlexibleSpaceBar)
        │   ├── FlexibleSpaceBarWidget
        │   └── Actions (Settings, Edit Avatar)
        ├── SliverPersistentHeader (TabBar)
        └── TabBarView
            ├── AI Görünümler Tab
            ├── Gardırop Tab (with upload button)
            └── Modellerim Tab (with upload button)
```

**State Management**:
```dart
class _ProfileScreenState extends State<ProfileScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _nestedScrollController = ScrollController();
  bool _isCollapsed = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _nestedScrollController.addListener(_onScroll);
    
    // Load profile on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().loadProfile(widget.userId);
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _nestedScrollController.dispose();
    super.dispose();
  }
}
```

**Consumer Pattern**:
```dart
Consumer<ProfileViewModel>(
  builder: (context, viewModel, child) {
    if (viewModel.isError && viewModel.profile == null) {
      return _buildErrorState(viewModel);
    }
    return _buildMainContent(viewModel);
  },
)
```

### Service Interfaces

**ProfileService**:
```dart
class ProfileService {
  Future<ProfileWithStats?> getProfile(String userId);
  Future<Profile> updateProfile({
    required String userId,
    String? fullName,
    String? bio,
    String? avatarUrl,
  });
  RealtimeChannel subscribeToProfileChanges(
    String userId,
    void Function(Profile) onUpdate,
  );
  Future<void> unsubscribeFromProfileChanges(RealtimeChannel channel);
}
```

**MediaService**:
```dart
class MediaService {
  Future<List<Media>> getMediaList({
    required String userId,
    MediaType? type,
    int limit = 20,
    int offset = 0,
  });
  Future<Media> addMedia({
    required String userId,
    required File imageFile,
    required MediaType type,
    String? styleTag,
  });
  Future<void> deleteMedia({
    required String userId,
    required String mediaId,
  });
  RealtimeChannel subscribeToMediaChanges(
    String userId,
    void Function(MediaEvent) onEvent,
  );
  Future<void> unsubscribeFromMediaChanges(RealtimeChannel channel);
}
```

**StorageService**:
```dart
class StorageService {
  Future<String> uploadAvatar({
    required String userId,
    required File imageFile,
  });
  Future<String> uploadToGallery({
    required String userId,
    required File imageFile,
  });
  Future<void> deleteFile({
    required String bucket,
    required String path,
  });
}
```

### InstaAssetsPicker Integration

**Picker Configuration**:
```dart
Future<List<AssetEntity>?> _pickPhoto() async {
  final List<AssetEntity>? result = await InstaAssetsPicker.pickAssets(
    context,
    pickerConfig: InstaAssetPickerConfig(
      maxAssets: 1,
      requestType: RequestType.image,
      textDelegate: const TurkishTextDelegate(),
      themeColor: const Color(0xFF742FE5),
    ),
  );
  return result;
}
```

**File Conversion**:
```dart
Future<File?> _assetToFile(AssetEntity asset) async {
  final file = await asset.file;
  if (file == null) return null;
  
  // Validate file size (max 10MB)
  final fileSize = await file.length();
  if (fileSize > 10 * 1024 * 1024) {
    throw Exception('Fotoğraf çok büyük (max 10MB)');
  }
  
  return file;
}
```

## Data Models

### Profile Model

```dart
class Profile {
  final String id;
  final String fullName;
  final String? bio;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Profile({
    required this.id,
    required this.fullName,
    this.bio,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
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
  aiLook('AI_CREATION'),
  upload('UPLOAD'),
  model('MODEL');
  
  final String value;
  const MediaType(this.value);
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
      type: MediaType.values.firstWhere(
        (e) => e.value == json['type'],
        orElse: () => MediaType.upload,
      ),
      styleTag: json['style_tag'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
```

### MediaEvent Model

```dart
enum MediaEventType {
  insert,
  delete,
}

class MediaEvent {
  final MediaEventType type;
  final Media media;
  
  MediaEvent({
    required this.type,
    required this.media,
  });
  
  factory MediaEvent.fromRealtimeEvent({
    required String eventType,
    required Map<String, dynamic> record,
  }) {
    return MediaEvent(
      type: eventType == 'INSERT' 
          ? MediaEventType.insert 
          : MediaEventType.delete,
      media: Media.fromJson(record),
    );
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

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Profile State Update Consistency

*For any* valid profile data returned by ProfileService.getProfile(), when the ViewModel receives this data, the ViewModel's state SHALL be updated with the profile and stats, and notifyListeners() SHALL be called exactly once.

**Validates: Requirements 1.2**

### Property 2: Stats Display Formatting

*For any* UserStats object with non-negative integer values, when FlexibleSpaceBarWidget renders these stats, the displayed text SHALL contain the correct formatted numbers (with thousand separators for values >= 1000).

**Validates: Requirements 2.2, 2.4**

### Property 3: Media List State Update

*For any* valid media list returned by MediaService.getMediaList(), when the ViewModel receives this list, the ViewModel's mediaList state SHALL be updated and notifyListeners() SHALL be called.

**Validates: Requirements 3.2**

### Property 4: Tab-Based Media Filtering

*For any* media list containing mixed MediaType values, when a tab index is selected (0=aiLook, 1=upload, 2=model), the filteredMediaList computed getter SHALL return only media items matching that type.

**Validates: Requirements 3.4, 4.1, 4.2, 4.3**

### Property 5: Realtime Profile Update Propagation

*For any* profile update event received via Realtime subscription, when the callback is triggered with new profile data, the ViewModel SHALL update its profile state and call notifyListeners().

**Validates: Requirements 5.2**

### Property 6: Realtime Media Event Handling

*For any* media event (INSERT or DELETE) received via Realtime subscription, when the callback is triggered, the ViewModel SHALL update its mediaList state appropriately (add for INSERT, remove for DELETE) and call notifyListeners().

**Validates: Requirements 6.2**

### Property 7: Asset to File Conversion

*For any* AssetEntity selected from InstaAssetsPicker, when converted to File, if the file size is <= 10MB, the conversion SHALL succeed and return a valid File object; if > 10MB, it SHALL throw an exception.

**Validates: Requirements 7.4, 18.3**

### Property 8: Media Upload with Correct Type

*For any* valid image file, when uploadGardıropPhoto() is called, MediaService.addMedia() SHALL be invoked with MediaType.upload; when uploadModelPhoto() is called, it SHALL be invoked with MediaType.model.

**Validates: Requirements 8.2, 9.2**

### Property 9: Upload State Management

*For any* upload operation (success or failure), when the operation completes, the ViewModel's isUploading state SHALL be set to false.

**Validates: Requirements 10.3**

### Property 10: Error Message Localization

*For any* error thrown by ProfileService or MediaService, when the ViewModel catches this error, it SHALL produce a user-friendly Turkish error message and set the error state.

**Validates: Requirements 11.1, 20.1, 20.2**

### Property 11: File Size Validation

*For any* file with size in bytes, when validated, if size > 10MB (10 * 1024 * 1024 bytes), validation SHALL fail with "Fotoğraf çok büyük" error; otherwise it SHALL pass.

**Validates: Requirements 18.3, 18.4**

### Property 12: Avatar Update Preservation on Error

*For any* avatar upload error, when the error occurs, the ViewModel's current profile.avatarUrl SHALL remain unchanged from its value before the upload attempt.

**Validates: Requirements 20.4**

## Error Handling

### Error Categories

**1. Network Errors**:
- Connection timeout
- No internet connection
- Server unavailable

**Türkçe Mesajlar**:
- "İnternet bağlantınızı kontrol edin"
- "Sunucuya bağlanılamadı"

**2. Authentication Errors**:
- Unauthorized (401)
- Forbidden (403)
- RLS policy violation

**Türkçe Mesajlar**:
- "Bu işlem için yetkiniz yok"
- "Oturum süreniz dolmuş, lütfen tekrar giriş yapın"

**3. Validation Errors**:
- File size too large
- Invalid file type
- Missing required fields

**Türkçe Mesajlar**:
- "Fotoğraf çok büyük (max 10MB)"
- "Geçersiz dosya formatı"
- "Zorunlu alanları doldurun"

**4. Database Errors**:
- Record not found (PGRST116)
- Unique violation (23505)
- Foreign key violation (23503)

**Türkçe Mesajlar**:
- "Kayıt bulunamadı"
- "Bu kayıt zaten mevcut"
- "İlişkili kayıt bulunamadı"

**5. Storage Errors**:
- Upload failed
- Delete failed
- Bucket not found

**Türkçe Mesajlar**:
- "Fotoğraf yüklenemedi"
- "Dosya silinemedi"
- "Depolama alanına erişilemiyor"

### Error Handling Strategy

**ViewModel Error Handling**:
```dart
void _handleError(dynamic error) {
  _isProfileLoading = false;
  _isMediaLoading = false;
  _isUploading = false;
  _isError = true;
  
  // Convert error to Turkish message
  if (error is ProfileException) {
    _errorMessage = error.message;
  } else if (error is MediaException) {
    _errorMessage = error.message;
  } else if (error is StorageException) {
    _errorMessage = error.message;
  } else if (error is PostgrestException) {
    _errorMessage = _mapPostgrestError(error.code);
  } else {
    _errorMessage = 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }
  
  notifyListeners();
}

String _mapPostgrestError(String? code) {
  switch (code) {
    case 'PGRST116':
      return 'Kayıt bulunamadı';
    case '23505':
      return 'Bu kayıt zaten mevcut';
    case '23503':
      return 'İlişkili kayıt bulunamadı';
    case '42501':
    case 'PGRST301':
      return 'Bu işlem için yetkiniz yok';
    default:
      return 'Veritabanı hatası oluştu';
  }
}
```

**UI Error Display**:
```dart
// Critical error (profile couldn't load)
Widget _buildErrorState(ProfileViewModel viewModel) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Iconsax.warning_2, size: 64, color: Colors.red),
        SizedBox(height: 16),
        Text(viewModel.errorMessage ?? 'Bir hata oluştu'),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            viewModel.clearError();
            viewModel.loadProfile(widget.userId);
          },
          child: Text('Tekrar Dene'),
        ),
      ],
    ),
  );
}

// Non-critical error (upload failed)
void _showErrorSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      action: SnackBarAction(
        label: 'Tamam',
        textColor: Colors.white,
        onPressed: () {},
      ),
    ),
  );
}
```

### Retry Strategy

**Automatic Retry**:
- Network errors: 3 attempts with exponential backoff
- Timeout errors: 2 attempts

**Manual Retry**:
- Critical errors: "Tekrar Dene" button
- Upload errors: User can retry upload

**No Retry**:
- Authentication errors: Redirect to login
- Validation errors: Show error message
- Permission errors: Show error message

## Testing Strategy

### Unit Tests

Unit tests focus on specific examples, edge cases, and error conditions for individual components.

**ProfileViewModel Tests**:
- `test_loadProfile_success`: Verify profile and stats are loaded correctly
- `test_loadProfile_error`: Verify error state is set on failure
- `test_selectTab_updatesIndex`: Verify tab selection updates state
- `test_filteredMediaList_aiLook`: Verify filtering returns only aiLook items
- `test_filteredMediaList_upload`: Verify filtering returns only upload items
- `test_filteredMediaList_model`: Verify filtering returns only model items
- `test_uploadPhoto_sizeValidation`: Verify files > 10MB are rejected
- `test_uploadPhoto_success`: Verify upload updates state correctly
- `test_uploadPhoto_error`: Verify error handling
- `test_refreshProfile_reloadsData`: Verify refresh calls services
- `test_errorMessageLocalization`: Verify Turkish error messages

**ProfileScreen Widget Tests**:
- `test_showsSkeletonWhileLoading`: Verify skeleton is shown during loading
- `test_showsProfileWhenLoaded`: Verify profile data is displayed
- `test_showsErrorStateOnCriticalError`: Verify error UI is shown
- `test_showsEmptyStateForEmptyTabs`: Verify empty state UI
- `test_pullToRefreshTriggersRefresh`: Verify pull-to-refresh works
- `test_tabSwitchingUpdatesContent`: Verify tab switching
- `test_uploadButtonOpensPickerGardirop`: Verify upload button for Gardırop
- `test_uploadButtonOpensPickerModel`: Verify upload button for Model
- `test_editAvatarButtonOpensPicker`: Verify avatar edit button

**Service Tests**:
- `test_ProfileService_getProfile`: Verify profile fetching
- `test_ProfileService_updateProfile`: Verify profile updating
- `test_MediaService_getMediaList`: Verify media list fetching
- `test_MediaService_addMedia`: Verify media upload
- `test_StorageService_uploadAvatar`: Verify avatar upload
- `test_StorageService_uploadToGallery`: Verify gallery upload

### Property-Based Tests

Property-based tests verify universal properties across many generated inputs using the `test` package with custom generators.

**Test Configuration**:
- Minimum 100 iterations per property test
- Use custom generators for Profile, UserStats, Media, MediaEvent
- Tag format: `@Tags(['pbt', 'profile-page-integration'])`

**Property Test Implementation**:

```dart
// Property 1: Profile State Update Consistency
@Tags(['pbt', 'profile-page-integration'])
void main() {
  test('Property 1: Profile state update consistency', () {
    // Feature: profile-page-integration, Property 1: Profile State Update Consistency
    
    for (int i = 0; i < 100; i++) {
      // Generate random profile data
      final profile = generateRandomProfile();
      final stats = generateRandomStats();
      
      // Create ViewModel with mocked services
      final viewModel = ProfileViewModel(
        profileService: MockProfileService(profile, stats),
        mediaService: MockMediaService(),
        storageService: MockStorageService(),
      );
      
      int notifyCount = 0;
      viewModel.addListener(() => notifyCount++);
      
      // Act
      await viewModel.loadProfile(profile.id);
      
      // Assert
      expect(viewModel.profile, equals(profile));
      expect(viewModel.stats, equals(stats));
      expect(notifyCount, equals(1)); // Called exactly once
    }
  });
}
```

**Property Tests to Implement**:

1. **Property 1: Profile State Update Consistency** (100 iterations)
   - Generate random Profile and UserStats
   - Verify state update and single notifyListeners() call
   - Tag: `Feature: profile-page-integration, Property 1`

2. **Property 2: Stats Display Formatting** (100 iterations)
   - Generate random UserStats with various number ranges
   - Verify correct formatting with thousand separators
   - Tag: `Feature: profile-page-integration, Property 2`

3. **Property 3: Media List State Update** (100 iterations)
   - Generate random media lists
   - Verify state update and notifyListeners() call
   - Tag: `Feature: profile-page-integration, Property 3`

4. **Property 4: Tab-Based Media Filtering** (100 iterations)
   - Generate random mixed media lists
   - Verify filtering for each tab index
   - Tag: `Feature: profile-page-integration, Property 4`

5. **Property 5: Realtime Profile Update Propagation** (100 iterations)
   - Generate random profile updates
   - Verify callback triggers state update
   - Tag: `Feature: profile-page-integration, Property 5`

6. **Property 6: Realtime Media Event Handling** (100 iterations)
   - Generate random media events (INSERT/DELETE)
   - Verify correct list updates
   - Tag: `Feature: profile-page-integration, Property 6`

7. **Property 7: Asset to File Conversion** (100 iterations)
   - Generate random file sizes
   - Verify conversion success/failure based on size
   - Tag: `Feature: profile-page-integration, Property 7`

8. **Property 8: Media Upload with Correct Type** (100 iterations)
   - Generate random image files
   - Verify correct MediaType is used
   - Tag: `Feature: profile-page-integration, Property 8`

9. **Property 9: Upload State Management** (100 iterations)
   - Generate random upload outcomes (success/error)
   - Verify isUploading is set to false
   - Tag: `Feature: profile-page-integration, Property 9`

10. **Property 10: Error Message Localization** (100 iterations)
    - Generate random service errors
    - Verify Turkish error messages
    - Tag: `Feature: profile-page-integration, Property 10`

11. **Property 11: File Size Validation** (100 iterations)
    - Generate random file sizes
    - Verify validation logic
    - Tag: `Feature: profile-page-integration, Property 11`

12. **Property 12: Avatar Update Preservation on Error** (100 iterations)
    - Generate random avatar upload errors
    - Verify original avatarUrl is preserved
    - Tag: `Feature: profile-page-integration, Property 12`

### Integration Tests

Integration tests verify end-to-end flows with real or mocked Supabase backend.

**Integration Test Scenarios**:
- `test_fullProfileLoadFlow`: Load profile → display → realtime update
- `test_fullUploadFlow`: Pick photo → validate → upload → display
- `test_fullAvatarUpdateFlow`: Pick photo → upload → update profile → display
- `test_realtimeSubscriptionCleanup`: Verify no memory leaks
- `test_pullToRefreshFlow`: Pull → reload → display
- `test_tabSwitchingWithRealData`: Switch tabs with real media data
- `test_errorRecoveryFlow`: Error → retry → success

### Accessibility Tests

**Semantic Tests**:
- Verify all buttons have Semantics labels
- Verify loading states have "Yükleniyor" label
- Verify error messages are readable by screen readers
- Verify empty states have descriptive labels

### Performance Tests

**Performance Metrics**:
- Profile load time: < 500ms
- Media list load time: < 1s
- Tab switch time: < 100ms
- Upload time: < 5s (for 5MB file)
- Rebuild count: Minimize unnecessary rebuilds

**Performance Tests**:
- `test_noUnnecessaryRebuilds`: Verify computed getters prevent rebuilds
- `test_lazyLoadingWorks`: Verify pagination reduces initial load
- `test_constConstructorsUsed`: Verify const widgets where possible

### Test Coverage Goals

- Unit test coverage: > 80%
- Property test coverage: All correctness properties
- Integration test coverage: All critical user flows
- Widget test coverage: All UI states (loading, error, empty, success)

---

**Design Document Completed**

Bu tasarım dokümanı, profil sayfası backend entegrasyonu için gerekli tüm mimari kararları, bileşen arayüzlerini, veri modellerini, correctness properties'leri ve test stratejisini içermektedir. Implementation sırasında bu doküman referans alınmalı ve tüm gereksinimler karşılanmalıdır.
