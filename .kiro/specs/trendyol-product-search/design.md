# Design Document: Trendyol Ürün Arama ve Kaydetme

## Overview

Bu doküman, Dressify AI Flutter uygulamasının Trendyol ürün arama ve kaydetme özelliğinin teknik tasarımını tanımlar. Özellik, kullanıcıların Trendyol'daki ürünleri aramasını, detaylarını görüntülemesini ve gardıroplarına kaydetmesini sağlar.

### Temel Özellikler

- **Ürün Arama**: Trendyol scraping API ile ürün arama
- **Filtreleme ve Sıralama**: Fiyat, ücretsiz kargo, sıralama seçenekleri
- **Ürün Detayları**: Görseller, açıklama, yorumlar, fiyat bilgisi
- **Gardıroba Kaydetme**: Beğenilen ürünleri Supabase'e kaydetme
- **Link ile Ekleme**: Trendyol ürün linkini yapıştırarak direkt ürün açma
- **Profil Entegrasyonu**: Kaydedilen ürünleri profil sayfasında görüntüleme

### Teknoloji Stack

- **UI Framework**: Flutter (MVVM pattern)
- **State Management**: Provider (ChangeNotifier)
- **Backend**: Trendyol Scraping API + Supabase
- **Scroll Architecture**: CustomScrollView + Slivers
- **Animations**: Hero animations
- **Image Carousel**: CarouselView widget
- **Caching**: cached_network_image

## Architecture

### MVVM Pattern

Uygulama MVVM (Model-View-ViewModel) mimarisini kullanır:

```
┌─────────────────────────────────────────────────────────────┐
│                         View Layer                          │
│  ┌──────────────────────┐    ┌──────────────────────────┐  │
│  │ ProductSearchScreen  │    │ ProductDetailScreen      │  │
│  │ - UI Rendering       │    │ - UI Rendering           │  │
│  │ - User Interactions  │    │ - User Interactions      │  │
│  └──────────────────────┘    └──────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                          │                    │
                          ▼                    ▼
┌─────────────────────────────────────────────────────────────┐
│                      ViewModel Layer                        │
│  ┌──────────────────────┐    ┌──────────────────────────┐  │
│  │ProductSearchViewModel│    │ProductDetailViewModel    │  │
│  │ - Business Logic     │    │ - Business Logic         │  │
│  │ - State Management   │    │ - State Management       │  │
│  │ - notifyListeners()  │    │ - notifyListeners()      │  │
│  └──────────────────────┘    └──────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                          │                    │
                          ▼                    ▼
┌─────────────────────────────────────────────────────────────┐
│                       Service Layer                         │
│  ┌──────────────────────┐    ┌──────────────────────────┐  │
│  │  TrendyolService     │    │ SavedProductService      │  │
│  │  - API Calls         │    │ - Supabase Operations    │  │
│  │  - Data Mapping      │    │ - CRUD Operations        │  │
│  └──────────────────────┘    └──────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                          │                    │
                          ▼                    ▼
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                            │
│  ┌──────────────────────┐    ┌──────────────────────────┐  │
│  │ Trendyol Scraping API│    │ Supabase Database        │  │
│  │ - Product Search     │    │ - saved_products table   │  │
│  │ - Product Details    │    │ - media table            │  │
│  └──────────────────────┘    └──────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Navigation Flow

```
Home (TabBar)
    │
    ├─── Tab 0: HomeScreen
    │
    ├─── Tab 1: ProductSearchScreen ◄─── (Yeni Özellik)
    │         │
    │         ├─── Search Results (Grid)
    │         │
    │         └─── ProductDetailScreen
    │                   │
    │                   └─── Save to Wardrobe
    │
    ├─── Tab 2: Keşfet (Placeholder)
    │
    └─── Tab 3: ProfileScreen
              │
              └─── Gardırop Tab
                    │
                    ├─── User Uploads
                    └─── Saved Trendyol Products
```

## Components and Interfaces

### 1. ProductSearchScreen (View)

**Sorumluluklar:**
- Arama çubuğu UI
- Filtre ve sıralama UI
- Ürün grid görünümü
- Loading, error, empty states
- Hero animation başlangıç noktası

**Widget Hiyerarşisi:**
```dart
Scaffold
└── CustomScrollView
    ├── SliverAppBar
    │   └── SearchBar + Filters
    ├── SliverToBoxAdapter
    │   └── Sort Options
    └── SliverGrid (2 columns)
        └── ProductCard (Hero wrapped)
```

**Key Properties:**
- `scrollController`: Scroll kontrolü için
- `viewModel`: ProductSearchViewModel instance

### 2. ProductSearchViewModel (ViewModel)

**Sorumluluklar:**
- Arama query yönetimi
- Filtre ve sıralama state'i
- TrendyolService çağrıları
- Pagination logic
- Arama geçmişi yönetimi
- Error handling

**State Properties:**
```dart
class ProductSearchViewModel extends ChangeNotifier {
  List<Product> _products = [];
  String _searchQuery = '';
  SortOption _sortOption = SortOption.BEST_SELLER;
  double? _minPrice;
  double? _maxPrice;
  bool _freeShippingOnly = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMorePages = true;
  List<String> _searchHistory = [];
  
  // Getters
  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  // ... other getters
  
  // Methods
  Future<void> searchProducts();
  Future<void> loadMoreProducts();
  void updateFilters({...});
  void clearFilters();
  void saveSearchQuery(String query);
  List<String> getSearchHistory();
}
```

### 3. ProductDetailScreen (View)

**Sorumluluklar:**
- Ürün görselleri carousel
- Ürün bilgileri görüntüleme
- Yorumlar listesi
- "Gardıroba Ekle" butonu
- Hero animation bitiş noktası

**Widget Hiyerarşisi:**
```dart
Scaffold
└── CustomScrollView
    ├── SliverAppBar
    │   └── Hero(
    │         child: CarouselView(images)
    │       )
    ├── SliverToBoxAdapter
    │   ├── Product Info
    │   ├── Description
    │   └── Save Button
    └── SliverList
        └── Reviews
```

### 4. ProductDetailViewModel (ViewModel)

**Sorumluluklar:**
- Ürün detay yükleme
- Yorumlar yükleme
- Gardıroba kaydetme işlemi
- Loading states

**State Properties:**
```dart
class ProductDetailViewModel extends ChangeNotifier {
  Product? _product;
  List<Review> _reviews = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  
  Future<void> loadProductDetail(String productId);
  Future<void> loadReviews(String productId);
  Future<void> saveToWardrobe(Product product);
}
```

### 5. TrendyolService (Service)

**Sorumluluklar:**
- Trendyol scraping API çağrıları
- HTTP request/response handling
- JSON parsing
- Retry mekanizması
- Error mapping

**API Endpoints:**
```dart
class TrendyolService {
  final String baseUrl;
  final Dio _dio;
  
  // Search products
  Future<SearchResponse> searchProducts({
    required String query,
    SortOption? sort,
    double? minPrice,
    double? maxPrice,
    bool? freeShipping,
    int page = 1,
  });
  
  // Get product detail
  Future<Product> getProductDetail(String productId);
  
  // Get product reviews
  Future<List<Review>> getProductReviews(String productId);
  
  // Extract product ID from URL
  String? extractProductIdFromUrl(String url);
}
```

**API Response Format:**
```json
{
  "query": "elbise",
  "total_count": 1250,
  "pages_fetched": 1,
  "count": 24,
  "products": [
    {
      "id": "123456",
      "name": "Kadın Siyah Elbise",
      "brand": "Mango",
      "category": "Kadın > Giyim > Elbise",
      "price": 299.99,
      "original_price": 499.99,
      "discount_pct": 40,
      "rating": 4.5,
      "review_count": 128,
      "in_stock": true,
      "url": "https://www.trendyol.com/...",
      "images": ["url1", "url2"],
      "description": "...",
      "free_shipping": true,
      "badges": ["Hızlı Teslimat", "İade Garantisi"]
    }
  ]
}
```

### 6. SavedProductService (Service)

**Sorumluluklar:**
- Supabase CRUD operations
- RLS policy enforcement
- Media table entegrasyonu

**Methods:**
```dart
class SavedProductService {
  final SupabaseClient _client;
  
  Future<SavedProduct> saveProduct({
    required String userId,
    required Product product,
  });
  
  Future<List<SavedProduct>> getSavedProducts(String userId);
  
  Future<void> deleteSavedProduct(String savedProductId);
  
  Future<bool> isProductSaved(String userId, String productId);
}
```

## Data Models

### Product Model

```dart
class Product {
  final String id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final double? originalPrice;
  final int? discountPct;
  final double? rating;
  final int? reviewCount;
  final bool inStock;
  final String url;
  final List<String> images;
  final String? description;
  final bool freeShipping;
  final List<String> badges;
  
  Product({...});
  
  factory Product.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  Product copyWith({...});
}
```

### SavedProduct Model

```dart
class SavedProduct {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final String productImage;
  final double productPrice;
  final String productUrl;
  final DateTime savedAt;
  
  SavedProduct({...});
  
  factory SavedProduct.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

### Review Model

```dart
class Review {
  final String id;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;
  
  Review({...});
  
  factory Review.fromJson(Map<String, dynamic> json);
}
```

### SortOption Enum

```dart
enum SortOption {
  BEST_SELLER('BEST_SELLER', 'Çok Satanlar'),
  PRICE_BY_ASC('PRICE_BY_ASC', 'Artan Fiyat'),
  PRICE_BY_DESC('PRICE_BY_DESC', 'Azalan Fiyat'),
  MOST_RATED('MOST_RATED', 'En Çok Değerlendirilen'),
  NEWEST('NEWEST', 'Yeni Gelenler');
  
  final String value;
  final String label;
  const SortOption(this.value, this.label);
}
```

## Error Handling

### Error Types

1. **Network Errors**
   - Timeout: "Bağlantı zaman aşımına uğradı"
   - No Internet: "İnternet bağlantınızı kontrol edin"
   - Server Error: "Sunucu hatası, lütfen tekrar deneyin"

2. **API Errors**
   - 404: "Ürün bulunamadı"
   - 429: "Çok fazla istek, lütfen bekleyin"
   - 500: "Trendyol servisi şu an kullanılamıyor"

3. **Validation Errors**
   - Invalid URL: "Geçersiz Trendyol linki"
   - Empty Search: "Lütfen arama terimi girin"
   - Invalid Price Range: "Geçersiz fiyat aralığı"

4. **Database Errors**
   - Save Failed: "Ürün kaydedilemedi"
   - Already Saved: "Bu ürün zaten gardırobunuzda"
   - Permission Denied: "Bu işlem için yetkiniz yok"

### Error Handling Strategy

```dart
try {
  final products = await _trendyolService.searchProducts(query: query);
  _products = products;
  _errorMessage = null;
} on DioException catch (e) {
  if (e.type == DioExceptionType.connectionTimeout) {
    _errorMessage = 'Bağlantı zaman aşımına uğradı';
  } else if (e.type == DioExceptionType.receiveTimeout) {
    _errorMessage = 'Sunucu yanıt vermiyor';
  } else if (e.response?.statusCode == 404) {
    _errorMessage = 'Ürün bulunamadı';
  } else {
    _errorMessage = 'Bir hata oluştu, lütfen tekrar deneyin';
  }
} catch (e) {
  _errorMessage = 'Beklenmeyen bir hata oluştu';
} finally {
  _isLoading = false;
  notifyListeners();
}
```

## Testing Strategy

### Unit Tests

Bu özellik için property-based testing uygun değildir çünkü:
- External API entegrasyonu (Trendyol scraping API)
- UI rendering ve kullanıcı etkileşimleri
- Supabase veritabanı işlemleri
- Network çağrıları ve side effects

Bunun yerine **example-based unit tests** ve **integration tests** kullanılacaktır:

#### ViewModel Tests

```dart
// ProductSearchViewModel Tests
test('searchProducts updates products list on success', () async {
  final mockService = MockTrendyolService();
  final viewModel = ProductSearchViewModel(service: mockService);
  
  when(mockService.searchProducts(query: 'elbise'))
      .thenAnswer((_) async => [mockProduct1, mockProduct2]);
  
  await viewModel.searchProducts();
  
  expect(viewModel.products.length, 2);
  expect(viewModel.isLoading, false);
  expect(viewModel.errorMessage, null);
});

test('searchProducts sets error message on failure', () async {
  final mockService = MockTrendyolService();
  final viewModel = ProductSearchViewModel(service: mockService);
  
  when(mockService.searchProducts(query: 'elbise'))
      .thenThrow(DioException(requestOptions: RequestOptions()));
  
  await viewModel.searchProducts();
  
  expect(viewModel.products.length, 0);
  expect(viewModel.errorMessage, isNotNull);
});

test('updateFilters triggers new search', () async {
  final mockService = MockTrendyolService();
  final viewModel = ProductSearchViewModel(service: mockService);
  
  viewModel.updateFilters(minPrice: 100, maxPrice: 500);
  
  verify(mockService.searchProducts(
    query: any,
    minPrice: 100,
    maxPrice: 500,
  )).called(1);
});
```

#### Service Tests

```dart
// TrendyolService Tests
test('searchProducts returns products on success', () async {
  final dio = MockDio();
  final service = TrendyolService(dio: dio);
  
  when(dio.get(any, queryParameters: anyNamed('queryParameters')))
      .thenAnswer((_) async => Response(
        data: mockApiResponse,
        statusCode: 200,
        requestOptions: RequestOptions(),
      ));
  
  final result = await service.searchProducts(query: 'elbise');
  
  expect(result.length, greaterThan(0));
  expect(result.first.name, isNotEmpty);
});

test('extractProductIdFromUrl extracts ID correctly', () {
  final service = TrendyolService();
  
  final url = 'https://www.trendyol.com/mango/elbise-p-123456';
  final productId = service.extractProductIdFromUrl(url);
  
  expect(productId, '123456');
});
```

#### Widget Tests

```dart
// ProductSearchScreen Widget Tests
testWidgets('displays search bar and grid', (tester) async {
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => MockProductSearchViewModel(),
      child: MaterialApp(home: ProductSearchScreen()),
    ),
  );
  
  expect(find.byType(TextField), findsOneWidget);
  expect(find.byType(SliverGrid), findsOneWidget);
});

testWidgets('shows loading indicator when searching', (tester) async {
  final viewModel = MockProductSearchViewModel();
  when(viewModel.isLoading).thenReturn(true);
  
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: viewModel,
      child: MaterialApp(home: ProductSearchScreen()),
    ),
  );
  
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

### Integration Tests

```dart
// End-to-end flow test
testWidgets('complete search and save flow', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // Navigate to products tab
  await tester.tap(find.byIcon(Iconsax.shop));
  await tester.pumpAndSettle();
  
  // Enter search query
  await tester.enterText(find.byType(TextField), 'elbise');
  await tester.tap(find.byIcon(Icons.search));
  await tester.pumpAndSettle();
  
  // Verify products are displayed
  expect(find.byType(ProductCard), findsWidgets);
  
  // Tap on first product
  await tester.tap(find.byType(ProductCard).first);
  await tester.pumpAndSettle();
  
  // Verify detail screen
  expect(find.byType(ProductDetailScreen), findsOneWidget);
  
  // Save to wardrobe
  await tester.tap(find.text('Gardıroba Ekle'));
  await tester.pumpAndSettle();
  
  // Verify success message
  expect(find.text('Ürün gardıroba eklendi'), findsOneWidget);
});
```

### Performance Tests

```dart
test('debounce prevents excessive API calls', () async {
  final mockService = MockTrendyolService();
  final viewModel = ProductSearchViewModel(service: mockService);
  
  // Simulate rapid typing
  viewModel.updateSearchQuery('e');
  viewModel.updateSearchQuery('el');
  viewModel.updateSearchQuery('elb');
  viewModel.updateSearchQuery('elbi');
  viewModel.updateSearchQuery('elbis');
  viewModel.updateSearchQuery('elbise');
  
  await Future.delayed(Duration(milliseconds: 600));
  
  // Should only call API once after debounce period
  verify(mockService.searchProducts(query: 'elbise')).called(1);
});
```

## Database Schema

### saved_products Table

```sql
CREATE TABLE saved_products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL,
  product_name TEXT NOT NULL,
  product_image TEXT NOT NULL,
  product_price NUMERIC(10, 2) NOT NULL,
  product_url TEXT NOT NULL,
  saved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(user_id, product_id)
);

-- Index for faster queries
CREATE INDEX idx_saved_products_user_id ON saved_products(user_id);
CREATE INDEX idx_saved_products_saved_at ON saved_products(saved_at DESC);

-- RLS Policies
ALTER TABLE saved_products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own saved products"
  ON saved_products FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own saved products"
  ON saved_products FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own saved products"
  ON saved_products FOR DELETE
  USING (auth.uid() = user_id);
```

### media Table Extension

```sql
-- Add new enum value for media type
ALTER TYPE media_type ADD VALUE IF NOT EXISTS 'TRENDYOL_PRODUCT';

-- Add new column for Trendyol product ID
ALTER TABLE media ADD COLUMN IF NOT EXISTS trendyol_product_id TEXT;

-- Index for Trendyol products
CREATE INDEX IF NOT EXISTS idx_media_trendyol_product_id 
  ON media(trendyol_product_id) 
  WHERE trendyol_product_id IS NOT NULL;
```

## Performance Optimizations

### 1. Image Caching

```dart
CachedNetworkImage(
  imageUrl: product.images.first,
  cacheKey: 'product_${product.id}',
  memCacheWidth: 400,
  memCacheHeight: 400,
  placeholder: (context, url) => ShimmerPlaceholder(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

### 2. Debounced Search

```dart
Timer? _debounceTimer;

void updateSearchQuery(String query) {
  _searchQuery = query;
  
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(milliseconds: 500), () {
    searchProducts();
  });
}
```

### 3. Pagination

```dart
Future<void> loadMoreProducts() async {
  if (_isLoadingMore || !_hasMorePages) return;
  
  _isLoadingMore = true;
  notifyListeners();
  
  try {
    final newProducts = await _trendyolService.searchProducts(
      query: _searchQuery,
      page: _currentPage + 1,
    );
    
    if (newProducts.isEmpty) {
      _hasMorePages = false;
    } else {
      _products.addAll(newProducts);
      _currentPage++;
    }
  } finally {
    _isLoadingMore = false;
    notifyListeners();
  }
}
```

### 4. Const Constructors

```dart
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  
  const ProductCard({
    Key? key,
    required this.product,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return const Card(...); // Use const where possible
  }
}
```

### 5. Selective Rebuilds

```dart
// Only rebuild when specific properties change
Consumer<ProductSearchViewModel>(
  builder: (context, viewModel, child) {
    return ListView.builder(
      itemCount: viewModel.products.length,
      itemBuilder: (context, index) {
        return ProductCard(product: viewModel.products[index]);
      },
    );
  },
)

// Use Selector for granular updates
Selector<ProductSearchViewModel, bool>(
  selector: (context, viewModel) => viewModel.isLoading,
  builder: (context, isLoading, child) {
    return isLoading ? LoadingIndicator() : ProductGrid();
  },
)
```

## Implementation Notes

### Hero Animation Setup

```dart
// In ProductCard (Search Screen)
Hero(
  tag: 'product_${product.id}',
  child: CachedNetworkImage(
    imageUrl: product.images.first,
  ),
)

// In ProductDetailScreen
Hero(
  tag: 'product_${product.id}',
  child: CarouselView(
    images: product.images,
  ),
)
```

### Sliver Architecture

```dart
// ProductSearchScreen
CustomScrollView(
  slivers: [
    SliverAppBar(
      floating: true,
      snap: true,
      title: SearchBar(),
    ),
    SliverToBoxAdapter(
      child: FilterChips(),
    ),
    SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => ProductCard(product: products[index]),
        childCount: products.length,
      ),
    ),
  ],
)
```

### Navigation Bar Integration

```dart
// In Home widget
TabBarView(
  controller: tabController,
  children: [
    HomeScreen(),
    ChangeNotifierProvider(
      create: (_) => ProductSearchViewModel(
        trendyolService: TrendyolService(),
        savedProductService: SavedProductService(),
      ),
      child: ProductSearchScreen(),
    ),
    KeşfetScreen(),
    ProfileScreen(),
  ],
)
```

## Figma Design References

- **Ürün Arama Sayfası**: https://www.figma.com/design/hBpOrjOf5YWhR9TXrERITn/dressify?node-id=5-124
- **Ürün Detay Sayfası**: https://www.figma.com/design/hBpOrjOf5YWhR9TXrERITn/dressify?node-id=5-205

## API Configuration

### Environment Variables

```dart
// .env
TRENDYOL_API_BASE_URL=https://api.trendyol-scraping.com
TRENDYOL_API_TIMEOUT=30000
TRENDYOL_API_RETRY_COUNT=3
```

### Dio Configuration

```dart
final dio = Dio(
  BaseOptions(
    baseUrl: dotenv.env['TRENDYOL_API_BASE_URL']!,
    connectTimeout: Duration(milliseconds: 30000),
    receiveTimeout: Duration(milliseconds: 30000),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ),
);

// Add retry interceptor
dio.interceptors.add(
  RetryInterceptor(
    dio: dio,
    retries: 3,
    retryDelays: [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 3),
    ],
  ),
);

// Add logging interceptor (debug mode only)
if (kDebugMode) {
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
  ));
}
```

## Accessibility

### Semantic Labels

```dart
Semantics(
  label: 'Ürün arama çubuğu',
  hint: 'Aramak istediğiniz ürünü yazın',
  child: TextField(...),
)

Semantics(
  label: '${product.name}, ${product.price} TL',
  button: true,
  child: ProductCard(...),
)
```

### Screen Reader Support

- Tüm interaktif elementler semantic label içermeli
- Loading states sesli bildirim ile desteklenmeli
- Error messages ekran okuyucu ile okunabilir olmalı

## Security Considerations

1. **API Key Management**: Trendyol API key'i environment variable'da saklanmalı
2. **RLS Policies**: Supabase RLS politikaları ile kullanıcılar sadece kendi verilerine erişebilmeli
3. **Input Validation**: Tüm kullanıcı girdileri validate edilmeli
4. **URL Validation**: Trendyol link'leri regex ile validate edilmeli
5. **Rate Limiting**: API çağrıları debounce ve throttle ile sınırlandırılmalı

## Future Enhancements

1. **Favoriler**: Ürünleri favorilere ekleme
2. **Fiyat Takibi**: Ürün fiyat değişikliklerini takip etme
3. **Bildirimler**: Fiyat düştüğünde bildirim gönderme
4. **Paylaşım**: Ürünleri sosyal medyada paylaşma
5. **Karşılaştırma**: Birden fazla ürünü karşılaştırma
6. **AI Önerileri**: Kullanıcı tercihlerine göre ürün önerileri

---

**Validates Requirements**: 1-29
