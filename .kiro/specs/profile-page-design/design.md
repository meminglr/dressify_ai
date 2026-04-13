# Design Document: Profile Page Design

## Overview

Bu doküman, Dressify AI Flutter uygulaması için profil sayfası UI tasarımının teknik tasarımını tanımlar. Sistem, MVVM (Model-View-ViewModel) mimarisi kullanarak performanslı, modern ve kullanıcı dostu bir profil deneyimi sağlar.

### Temel Özellikler

- **Genişleyen Header**: FlexibleSpaceBar ile scroll'a duyarlı, animasyonlu header
- **Profil Bilgileri**: Avatar, isim, bio ve istatistikler (AI Looks, Uploads, Models)
- **Sekmeli İçerik**: TabBar ile filtrelenebilir içerik görünümü (All, AI Looks, Uploads)
- **Masonry Grid Layout**: Farklı yüksekliklerde medya öğeleri ile estetik grid düzeni
- **Carousel View**: Tam ekran dikey scroll medya görüntüleyici
- **MVVM Mimarisi**: Temiz kod ve test edilebilirlik için katmanlı mimari
- **Performans Optimizasyonları**: Gereksiz rebuild'lerin önlenmesi

### Figma Tasarım Referansı

Tasarım Figma'dan alınmıştır:
- **File Key**: hBpOrjOf5YWhR9TXrERITn
- **Node ID**: 1-2
- **Tasarım Adı**: User Profile - Clean Masonry & Action Button

#### Tasarım Özellikleri

**Renkler:**
- Primary: `#742fe5` (Mor - Ana butonlar ve vurgular)
- Primary Light: `#ceb5ff` (Açık mor - İstatistik sayıları)
- Background: `#f8f9fa` (Açık gri - Sayfa arka planı)
- Surface: `#ffffff` (Beyaz - Kart arka planları)
- Text Primary: `#000000` (Siyah - Ana metinler)
- Text Secondary: `#5a6062` (Koyu gri - İkincil metinler)
- Text On Dark: `#ffffff` (Beyaz - Koyu arka plan üzerindeki metinler)
- Text On Dark Secondary: `rgba(255,255,255,0.8)` (Yarı saydam beyaz)
- Overlay: `rgba(0,0,0,0.3)` (Yarı saydam siyah - Blur overlay)
- Border: `rgba(255,255,255,0.1)` (Yarı saydam beyaz - Kenarlıklar)

**Tipografi:**
- Heading 1 (İsim): Manrope Regular, 36px, -0.9px letter spacing
- Heading 2 (Buton): Manrope Regular, 14px
- Body (Bio): Be Vietnam Pro Medium, 14px
- Caption (İstatistik): Be Vietnam Pro Bold, 9px, 0.9px letter spacing, uppercase
- Tab Label: Be Vietnam Pro Bold, 12px
- Tag Label: Be Vietnam Pro Bold, 8px, 0.8px letter spacing, uppercase

**Spacing:**
- Section Gap: 32px
- Card Padding: 16px
- Button Padding: 24px horizontal, 10px vertical
- Stats Padding: 41px horizontal, 21px vertical
- Grid Gap: 12px (masonry layout için)

**Border Radius:**
- Hero Header: 40px
- Cards: 16px
- Buttons: 9999px (pill shape)
- Stats Overlay: 16px

**Shadows:**
- Hero Header: `0px 25px 50px -12px rgba(0,0,0,0.25)`
- Button: `0px 4px 6px -1px rgba(116,47,229,0.3), 0px 2px 4px -2px rgba(116,47,229,0.3)`
- Cards: `0px 1px 2px 0px rgba(0,0,0,0.05)`
- Stats Overlay: `0px 25px 50px -12px rgba(0,0,0,0.25)`

**Blur Effects:**
- Stats Overlay: 12px backdrop blur
- Button (Header): 6px backdrop blur
- Image Overlay: 10px backdrop blur

## Architecture

### MVVM Pattern

Sistem, MVVM (Model-View-ViewModel) mimarisi kullanır:

```
┌─────────────────────────────────────────────────────────────┐
│                         View Layer                          │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              ProfileScreen (Widget)                   │  │
│  │  - CustomScrollView                                   │  │
│  │  - SliverAppBar + FlexibleSpaceBar                   │  │
│  │  - Profile Info Section                               │  │
│  │  - TabBar + TabBarView                                │  │
│  │  - SliverGrid (Masonry Layout)                        │  │
│  │  - Consumer<ProfileViewModel>                         │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ notifyListeners()
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      ViewModel Layer                        │
│  ┌───────────────────────────────────────────────────────┐  │
│  │         ProfileViewModel (ChangeNotifier)             │  │
│  │  - State Management                                   │  │
│  │  - Business Logic                                     │  │
│  │  - Data Fetching                                      │  │
│  │  - Error Handling                                     │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ getData()
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                       Model Layer                           │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                  Data Models                          │  │
│  │  - Profile                                            │  │
│  │  - UserStats                                          │  │
│  │  - Media                                              │  │
│  │  - MediaType (enum)                                   │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Test Data Provider                       │  │
│  │  - MockProfileData                                    │  │
│  │  - MockMediaList                                      │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Scroll Architecture

Profil sayfası, Flutter'ın Sliver widget'larını kullanarak karmaşık scroll davranışları sağlar:

```
CustomScrollView
├── SliverAppBar (pinned: false, floating: false)
│   ├── FlexibleSpaceBar
│   │   ├── Background (Gradient + Image)
│   │   ├── Profile Info (Avatar, Name, Bio)
│   │   └── Stats Overlay (Blur + Shadow)
│   └── Actions (Settings Button)
├── SliverPersistentHeader (pinned: true)
│   └── TabBar (All, AI Looks, Uploads)
├── SliverToBoxAdapter
│   └── Primary Action Button (Yeni Üret)
└── SliverGrid (Masonry Layout)
    ├── GridItem (AI Creation 1)
    ├── GridItem (AI Creation 2)
    ├── GridItem (AI Creation 3)
    └── GridItem (AI Creation 4)
```

### Performance Optimization Strategy

1. **Selective Rebuilds**: Consumer widget'ları sadece değişen bölümlerde kullanılır
2. **Const Constructors**: Statik widget'lar const olarak işaretlenir
3. **RepaintBoundary**: Grid item'lar RepaintBoundary ile sarmalanır
4. **Image Caching**: NetworkImage ile otomatik cache
5. **Lazy Loading**: SliverGrid ile viewport dışındaki öğeler lazy load edilir

## Components and Interfaces

### 1. ProfileScreen (View)

Ana profil sayfası widget'ı. CustomScrollView kullanarak scroll edilebilir bir sayfa oluşturur.

**Sorumluluklar:**
- UI rendering
- User interactions
- ViewModel'i dinleme (Consumer)
- Navigation

**Key Properties:**
- `userId`: String? - Görüntülenecek kullanıcının ID'si (null ise kendi profili)

**Key Methods:**
- `build(BuildContext context)`: Widget tree'yi oluşturur
- `_buildSliverAppBar()`: Genişleyen header'ı oluşturur
- `_buildProfileInfo()`: Profil bilgileri bölümünü oluşturur
- `_buildTabBar()`: Sekme çubuğunu oluşturur
- `_buildMasonryGrid()`: Masonry grid layout'u oluşturur
- `_openCarousel(int index)`: Carousel view'ı açar

### 2. ProfileViewModel (ViewModel)

Profil sayfası iş mantığını yöneten ViewModel sınıfı.

**Sorumluluklar:**
- State management
- Data fetching
- Business logic
- Error handling

**State Properties:**
```dart
class ProfileViewModel extends ChangeNotifier {
  // Data
  Profile? _profile;
  UserStats? _stats;
  List<Media> _mediaList = [];
  
  // UI State
  bool _isLoading = false;
  bool _isError = false;
  String? _errorMessage;
  int _selectedTabIndex = 0;
  
  // Getters
  Profile? get profile => _profile;
  UserStats? get stats => _stats;
  List<Media> get mediaList => _filteredMediaList;
  bool get isLoading => _isLoading;
  bool get isError => _isError;
  String? get errorMessage => _errorMessage;
  int get selectedTabIndex => _selectedTabIndex;
  
  // Computed
  List<Media> get _filteredMediaList {
    switch (_selectedTabIndex) {
      case 0: return _mediaList; // All
      case 1: return _mediaList.where((m) => m.type == MediaType.aiLook).toList();
      case 2: return _mediaList.where((m) => m.type == MediaType.upload).toList();
      default: return _mediaList;
    }
  }
}
```

**Key Methods:**
```dart
// Data Operations
Future<void> loadProfile(String? userId);
Future<void> refreshProfile();

// Tab Management
void selectTab(int index);

// Error Handling
void _handleError(dynamic error);
void clearError();
```

### 3. FlexibleSpaceBarWidget

SliverAppBar içinde kullanılan, scroll'a duyarlı genişleyen/daralan header widget'ı.

**Sorumluluklar:**
- Scroll animasyonları
- Gradient overlay
- Profile info display

**Key Properties:**
- `profile`: Profile - Profil bilgileri
- `stats`: UserStats - İstatistikler
- `expandedHeight`: double - Maksimum yükseklik (480px)
- `collapsedHeight`: double - Minimum yükseklik (56px)

### 4. ProfileInfoSection

Profil bilgilerini gösteren widget (avatar, isim, bio, istatistikler).

**Sorumluluklar:**
- Avatar display
- Name and bio display
- Stats display (blur overlay)

**Key Properties:**
- `profile`: Profile
- `stats`: UserStats

### 5. StatsOverlay

İstatistikleri blur ve shadow efekti ile gösteren widget.

**Sorumluluklar:**
- Stats display
- Blur effect
- Shadow effect

**Key Properties:**
- `aiLooksCount`: int
- `uploadsCount`: int
- `modelsCount`: int

### 6. ProfileTabBar

Sekmeli navigasyon widget'ı.

**Sorumluluklar:**
- Tab selection
- Tab indicator
- Smooth transitions

**Key Properties:**
- `selectedIndex`: int
- `onTabSelected`: Function(int)
- `tabs`: List<String> - ["AI Creations", "Models", "Uploads"]

### 7. MasonryGridView

Farklı yüksekliklerde medya öğeleri gösteren grid widget'ı.

**Sorumluluklar:**
- Masonry layout
- Lazy loading
- Item click handling

**Key Properties:**
- `mediaList`: List<Media>
- `onItemTap`: Function(int index)
- `crossAxisCount`: int - Responsive (3-5 sütun)

### 8. GridItem

Grid içinde gösterilen medya öğesi widget'ı.

**Sorumluluklar:**
- Image display
- Overlay with tag
- Ripple effect
- Hero animation tag

**Key Properties:**
- `media`: Media
- `onTap`: VoidCallback
- `heroTag`: String - Hero animasyonu için

### 9. CarouselView

Tam ekran dikey scroll medya görüntüleyici.

**Sorumluluklar:**
- Full screen display
- Vertical scroll
- Hero animation
- Swipe to dismiss

**Key Properties:**
- `mediaList`: List<Media>
- `initialIndex`: int
- `heroTag`: String

### 10. PrimaryActionButton

"Yeni Üret" butonu widget'ı.

**Sorumluluklar:**
- Action trigger
- Icon + Text display
- Shadow effect

**Key Properties:**
- `label`: String - "Yeni Üret"
- `icon`: IconData
- `onPressed`: VoidCallback

## Data Models

### Profile Model

Kullanıcı profil bilgilerini temsil eder.

```dart
class Profile {
  final String id;
  final String fullName;
  final String username;
  final String? bio;
  final String? avatarUrl;
  final String? coverImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Profile({
    required this.id,
    required this.fullName,
    required this.username,
    this.bio,
    this.avatarUrl,
    this.coverImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      username: json['username'] as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'username': username,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'coverImageUrl': coverImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  Profile copyWith({
    String? id,
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? coverImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

### UserStats Model

Kullanıcı istatistiklerini temsil eder.

```dart
class UserStats {
  final int aiLooksCount;
  final int uploadsCount;
  final int modelsCount;
  
  UserStats({
    required this.aiLooksCount,
    required this.uploadsCount,
    required this.modelsCount,
  });
  
  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      aiLooksCount: json['aiLooksCount'] as int,
      uploadsCount: json['uploadsCount'] as int,
      modelsCount: json['modelsCount'] as int,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'aiLooksCount': aiLooksCount,
      'uploadsCount': uploadsCount,
      'modelsCount': modelsCount,
    };
  }
  
  UserStats copyWith({
    int? aiLooksCount,
    int? uploadsCount,
    int? modelsCount,
  }) {
    return UserStats(
      aiLooksCount: aiLooksCount ?? this.aiLooksCount,
      uploadsCount: uploadsCount ?? this.uploadsCount,
      modelsCount: modelsCount ?? this.modelsCount,
    );
  }
}
```

### Media Model

Medya öğelerini (AI Looks, Uploads, Models) temsil eder.

```dart
enum MediaType {
  aiLook,
  upload,
  model,
}

class Media {
  final String id;
  final MediaType type;
  final String imageUrl;
  final String? tag;
  final DateTime createdAt;
  final int? width;
  final int? height;
  
  Media({
    required this.id,
    required this.type,
    required this.imageUrl,
    this.tag,
    required this.createdAt,
    this.width,
    this.height,
  });
  
  // Masonry layout için aspect ratio hesaplama
  double get aspectRatio {
    if (width != null && height != null && width! > 0 && height! > 0) {
      return width! / height!;
    }
    return 1.0; // Default square
  }
  
  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'] as String,
      type: MediaType.values.firstWhere(
        (e) => e.toString() == 'MediaType.${json['type']}',
      ),
      imageUrl: json['imageUrl'] as String,
      tag: json['tag'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'imageUrl': imageUrl,
      'tag': tag,
      'createdAt': createdAt.toIso8601String(),
      'width': width,
      'height': height,
    };
  }
  
  Media copyWith({
    String? id,
    MediaType? type,
    String? imageUrl,
    String? tag,
    DateTime? createdAt,
    int? width,
    int? height,
  }) {
    return Media(
      id: id ?? this.id,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      tag: tag ?? this.tag,
      createdAt: createdAt ?? this.createdAt,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}
```

### Test Data Provider

Geliştirme aşamasında kullanılacak test verileri.

```dart
class MockProfileData {
  static Profile getMockProfile() {
    return Profile(
      id: 'user_001',
      fullName: 'Alex Rivera',
      username: '@alexrivera',
      bio: 'Digital Fashion Curator',
      avatarUrl: 'https://example.com/avatar.jpg',
      coverImageUrl: 'https://example.com/cover.jpg',
      createdAt: DateTime.now().subtract(Duration(days: 365)),
      updatedAt: DateTime.now(),
    );
  }
  
  static UserStats getMockStats() {
    return UserStats(
      aiLooksCount: 24,
      uploadsCount: 12,
      modelsCount: 8,
    );
  }
  
  static List<Media> getMockMediaList() {
    return [
      Media(
        id: 'media_001',
        type: MediaType.aiLook,
        imageUrl: 'https://example.com/ai1.jpg',
        tag: 'NEO-STREETWEAR',
        createdAt: DateTime.now().subtract(Duration(days: 1)),
        width: 400,
        height: 600,
      ),
      Media(
        id: 'media_002',
        type: MediaType.aiLook,
        imageUrl: 'https://example.com/ai2.jpg',
        tag: 'MINIMALIST',
        createdAt: DateTime.now().subtract(Duration(days: 2)),
        width: 400,
        height: 500,
      ),
      Media(
        id: 'media_003',
        type: MediaType.upload,
        imageUrl: 'https://example.com/upload1.jpg',
        createdAt: DateTime.now().subtract(Duration(days: 3)),
        width: 400,
        height: 700,
      ),
      Media(
        id: 'media_004',
        type: MediaType.model,
        imageUrl: 'https://example.com/model1.jpg',
        createdAt: DateTime.now().subtract(Duration(days: 4)),
        width: 400,
        height: 550,
      ),
    ];
  }
}
```


## Error Handling

### Error States

Sistem, aşağıdaki hata durumlarını yönetir:

1. **Network Errors**: İnternet bağlantısı olmadığında
2. **Server Errors**: Backend servisi yanıt vermediğinde
3. **Data Parsing Errors**: Gelen veri formatı hatalı olduğunda
4. **Not Found Errors**: Kullanıcı profili bulunamadığında

### Error Handling Strategy

```dart
class ProfileViewModel extends ChangeNotifier {
  void _handleError(dynamic error) {
    _isLoading = false;
    _isError = true;
    
    if (error is NetworkException) {
      _errorMessage = 'İnternet bağlantınızı kontrol edin';
    } else if (error is ServerException) {
      _errorMessage = 'Sunucu hatası. Lütfen daha sonra tekrar deneyin';
    } else if (error is NotFoundException) {
      _errorMessage = 'Profil bulunamadı';
    } else {
      _errorMessage = 'Bir hata oluştu. Lütfen tekrar deneyin';
    }
    
    notifyListeners();
  }
  
  void clearError() {
    _isError = false;
    _errorMessage = null;
    notifyListeners();
  }
}
```

### Error UI Components

**ErrorWidget:**
```dart
class ProfileErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            child: Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}
```

### Loading States

**Loading Indicators:**
- **Initial Load**: Full screen CircularProgressIndicator
- **Refresh**: RefreshIndicator at top
- **Pagination**: Bottom loading indicator (future enhancement)

```dart
Widget _buildLoadingState() {
  return Center(
    child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF742FE5)),
    ),
  );
}
```

### Empty States

**Empty State Widget:**
```dart
class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          if (onAction != null && actionLabel != null) ...[
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }
}
```

## Testing Strategy

### Overview

Bu feature için **property-based testing uygun değildir** çünkü:
- UI rendering ve layout testi yapılıyor
- Görsel tasarım ve kullanıcı deneyimi odaklı
- Snapshot tests ve visual regression tests daha uygun

### Testing Approach

**1. Unit Tests**
- ViewModel business logic testleri
- Data model serialization/deserialization testleri
- Error handling testleri
- Tab filtering logic testleri

**2. Widget Tests**
- Individual component testleri
- User interaction testleri
- State management testleri
- Navigation testleri

**3. Golden Tests (Snapshot Tests)**
- UI component görsel testleri
- Farklı state'lerde görsel doğrulama
- Responsive layout testleri

**4. Integration Tests**
- End-to-end user flow testleri
- Navigation flow testleri
- Data loading ve refresh testleri

### Unit Test Examples

**ViewModel Tests:**
```dart
group('ProfileViewModel', () {
  late ProfileViewModel viewModel;
  
  setUp(() {
    viewModel = ProfileViewModel();
  });
  
  test('initial state should be loading false', () {
    expect(viewModel.isLoading, false);
    expect(viewModel.isError, false);
  });
  
  test('loadProfile should set loading state', () async {
    viewModel.loadProfile('user_001');
    expect(viewModel.isLoading, true);
  });
  
  test('selectTab should filter media list', () {
    viewModel.selectTab(1); // AI Looks
    expect(viewModel.selectedTabIndex, 1);
    // Verify filtered list contains only AI Looks
  });
  
  test('error handling should set error state', () {
    viewModel._handleError(NetworkException());
    expect(viewModel.isError, true);
    expect(viewModel.errorMessage, isNotNull);
  });
});
```

**Model Tests:**
```dart
group('Profile Model', () {
  test('fromJson should parse correctly', () {
    final json = {
      'id': 'user_001',
      'fullName': 'Alex Rivera',
      'username': '@alexrivera',
      'bio': 'Digital Fashion Curator',
      'createdAt': '2024-01-01T00:00:00.000Z',
      'updatedAt': '2024-01-15T00:00:00.000Z',
    };
    
    final profile = Profile.fromJson(json);
    
    expect(profile.id, 'user_001');
    expect(profile.fullName, 'Alex Rivera');
    expect(profile.username, '@alexrivera');
  });
  
  test('toJson should serialize correctly', () {
    final profile = Profile(
      id: 'user_001',
      fullName: 'Alex Rivera',
      username: '@alexrivera',
      createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      updatedAt: DateTime.parse('2024-01-15T00:00:00.000Z'),
    );
    
    final json = profile.toJson();
    
    expect(json['id'], 'user_001');
    expect(json['fullName'], 'Alex Rivera');
  });
});
```

### Widget Test Examples

**ProfileScreen Tests:**
```dart
group('ProfileScreen Widget', () {
  testWidgets('should display loading indicator initially', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => ProfileViewModel(),
          child: ProfileScreen(),
        ),
      ),
    );
    
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
  
  testWidgets('should display profile info when loaded', (tester) async {
    final viewModel = ProfileViewModel();
    // Mock data loading
    
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: viewModel,
          child: ProfileScreen(),
        ),
      ),
    );
    
    await tester.pumpAndSettle();
    
    expect(find.text('Alex Rivera'), findsOneWidget);
    expect(find.text('Digital Fashion Curator'), findsOneWidget);
  });
  
  testWidgets('should switch tabs on tap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => ProfileViewModel(),
          child: ProfileScreen(),
        ),
      ),
    );
    
    await tester.pumpAndSettle();
    
    // Tap on "Models" tab
    await tester.tap(find.text('Models'));
    await tester.pumpAndSettle();
    
    // Verify tab changed
    // Verify filtered content
  });
  
  testWidgets('should open carousel on grid item tap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => ProfileViewModel(),
          child: ProfileScreen(),
        ),
      ),
    );
    
    await tester.pumpAndSettle();
    
    // Tap on first grid item
    await tester.tap(find.byType(GridItem).first);
    await tester.pumpAndSettle();
    
    // Verify carousel opened
    expect(find.byType(CarouselView), findsOneWidget);
  });
});
```

### Golden Test Examples

**Component Golden Tests:**
```dart
group('Profile Component Golden Tests', () {
  testWidgets('ProfileInfoSection golden test', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileInfoSection(
            profile: MockProfileData.getMockProfile(),
            stats: MockProfileData.getMockStats(),
          ),
        ),
      ),
    );
    
    await expectLater(
      find.byType(ProfileInfoSection),
      matchesGoldenFile('goldens/profile_info_section.png'),
    );
  });
  
  testWidgets('StatsOverlay golden test', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatsOverlay(
            aiLooksCount: 24,
            uploadsCount: 12,
            modelsCount: 8,
          ),
        ),
      ),
    );
    
    await expectLater(
      find.byType(StatsOverlay),
      matchesGoldenFile('goldens/stats_overlay.png'),
    );
  });
  
  testWidgets('GridItem golden test', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GridItem(
            media: MockProfileData.getMockMediaList().first,
            onTap: () {},
            heroTag: 'test_hero',
          ),
        ),
      ),
    );
    
    await expectLater(
      find.byType(GridItem),
      matchesGoldenFile('goldens/grid_item.png'),
    );
  });
});
```

### Responsive Layout Tests

**Screen Size Tests:**
```dart
group('Responsive Layout Tests', () {
  testWidgets('should show 3 columns on small screen', (tester) async {
    tester.binding.window.physicalSizeTestValue = Size(360, 640);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => ProfileViewModel(),
          child: ProfileScreen(),
        ),
      ),
    );
    
    await tester.pumpAndSettle();
    
    // Verify 3 columns
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
  });
  
  testWidgets('should show 4 columns on medium screen', (tester) async {
    tester.binding.window.physicalSizeTestValue = Size(768, 1024);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => ProfileViewModel(),
          child: ProfileScreen(),
        ),
      ),
    );
    
    await tester.pumpAndSettle();
    
    // Verify 4 columns
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
  });
  
  testWidgets('should show 5 columns on large screen', (tester) async {
    tester.binding.window.physicalSizeTestValue = Size(1200, 800);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => ProfileViewModel(),
          child: ProfileScreen(),
        ),
      ),
    );
    
    await tester.pumpAndSettle();
    
    // Verify 5 columns
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
  });
});
```

### Integration Test Examples

**End-to-End Flow Tests:**
```dart
void main() {
  group('Profile Page E2E Tests', () {
    testWidgets('complete user flow', (tester) async {
      await tester.pumpWidget(MyApp());
      
      // Navigate to profile
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      
      // Verify profile loaded
      expect(find.text('Alex Rivera'), findsOneWidget);
      
      // Switch to AI Looks tab
      await tester.tap(find.text('AI Creations'));
      await tester.pumpAndSettle();
      
      // Tap on first item
      await tester.tap(find.byType(GridItem).first);
      await tester.pumpAndSettle();
      
      // Verify carousel opened
      expect(find.byType(CarouselView), findsOneWidget);
      
      // Swipe to next item
      await tester.drag(find.byType(CarouselView), Offset(0, -300));
      await tester.pumpAndSettle();
      
      // Close carousel
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      
      // Verify back to profile
      expect(find.byType(ProfileScreen), findsOneWidget);
    });
    
    testWidgets('pull to refresh flow', (tester) async {
      await tester.pumpWidget(MyApp());
      
      // Navigate to profile
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      
      // Pull to refresh
      await tester.drag(find.byType(RefreshIndicator), Offset(0, 300));
      await tester.pumpAndSettle();
      
      // Verify refresh indicator appeared and disappeared
      // Verify data reloaded
    });
  });
}
```

### Performance Tests

**Rebuild Performance:**
```dart
group('Performance Tests', () {
  testWidgets('should not rebuild entire tree on tab change', (tester) async {
    int buildCount = 0;
    
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => ProfileViewModel(),
          child: Builder(
            builder: (context) {
              buildCount++;
              return ProfileScreen();
            },
          ),
        ),
      ),
    );
    
    await tester.pumpAndSettle();
    final initialBuildCount = buildCount;
    
    // Change tab
    await tester.tap(find.text('Models'));
    await tester.pumpAndSettle();
    
    // Verify minimal rebuilds
    expect(buildCount, lessThan(initialBuildCount + 5));
  });
});
```

### Test Coverage Goals

- **Unit Tests**: 90%+ coverage for ViewModel and Models
- **Widget Tests**: 80%+ coverage for UI components
- **Golden Tests**: All major UI components
- **Integration Tests**: All critical user flows
- **Performance Tests**: Key interaction scenarios

### Continuous Integration

Tests should run on:
- Every pull request
- Before merge to main branch
- Nightly builds for golden tests (to catch visual regressions)

### Test Data Management

- Use `MockProfileData` for consistent test data
- Mock network calls with `mockito` or `http_mock_adapter`
- Use `fake_async` for time-dependent tests
- Golden files stored in `test/goldens/` directory

