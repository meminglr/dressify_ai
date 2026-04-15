import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/trendyol_service.dart';
import '../services/saved_product_service.dart';

/// Ürün arama sayfası ViewModel'i
/// MVVM pattern - Business logic ve state management
class ProductSearchViewModel extends ChangeNotifier {
  final TrendyolService _trendyolService;
  final SavedProductService _savedProductService;
  
  // State properties
  List<Product> _products = [];
  String _searchQuery = '';
  SortOption _sortOption = SortOption.bestSeller;
  double? _minPrice;
  double? _maxPrice;
  bool _freeShippingOnly = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMorePages = true;
  int _totalCount = 0;
  List<String> _searchHistory = [];
  
  // Debounce timer
  Timer? _debounceTimer;
  
  // Constants
  static const int _maxSearchHistoryItems = 10;
  static const String _searchHistoryKey = 'trendyol_search_history';
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  ProductSearchViewModel({
    required TrendyolService trendyolService,
    required SavedProductService savedProductService,
  })  : _trendyolService = trendyolService,
        _savedProductService = savedProductService {
    _loadSearchHistory();
  }

  // Getters
  List<Product> get products => List.unmodifiable(_products);
  String get searchQuery => _searchQuery;
  SortOption get sortOption => _sortOption;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  bool get freeShippingOnly => _freeShippingOnly;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMorePages => _hasMorePages;
  int get totalCount => _totalCount;
  List<String> get searchHistory => List.unmodifiable(_searchHistory);
  bool get hasProducts => _products.isNotEmpty;
  bool get hasSearched => _searchQuery.isNotEmpty;
  
  // Service getters for navigation
  TrendyolService get trendyolService => _trendyolService;
  SavedProductService get savedProductService => _savedProductService;

  /// Arama query'sini güncelle (debounced)
  void updateSearchQuery(String query) {
    _searchQuery = query;
    _errorMessage = null;
    notifyListeners();
    
    // Debounce: 500ms bekle, sonra ara
    _debounceTimer?.cancel();
    if (query.trim().isNotEmpty) {
      _debounceTimer = Timer(_debounceDuration, () {
        searchProducts();
      });
    }
  }

  /// Ürün arama
  Future<void> searchProducts({bool resetPage = true}) async {
    if (_searchQuery.trim().isEmpty) {
      _errorMessage = 'Lütfen arama terimi girin';
      notifyListeners();
      return;
    }

    if (resetPage) {
      _currentPage = 1;
      _products = [];
      _hasMorePages = true;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _trendyolService.searchProducts(
        query: _searchQuery,
        sort: _sortOption,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        freeShipping: _freeShippingOnly,
        page: _currentPage,
      );

      _products = response.products;
      _totalCount = response.totalCount;
      _hasMorePages = response.products.length >= 24; // Trendyol sayfa başına ~24 ürün
      
      // Arama geçmişine ekle
      await _saveSearchQuery(_searchQuery);
      
      _errorMessage = null;
    } on TrendyolException catch (e) {
      _errorMessage = e.message;
      _products = [];
    } catch (e) {
      _errorMessage = 'Bir hata oluştu, lütfen tekrar deneyin';
      _products = [];
      if (kDebugMode) {
        print('Search error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Daha fazla ürün yükle (pagination)
  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMorePages || _searchQuery.trim().isEmpty) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await _trendyolService.searchProducts(
        query: _searchQuery,
        sort: _sortOption,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        freeShipping: _freeShippingOnly,
        page: _currentPage + 1,
      );

      if (response.products.isEmpty) {
        _hasMorePages = false;
      } else {
        _products.addAll(response.products);
        _currentPage++;
        _hasMorePages = response.products.length >= 24;
      }
    } on TrendyolException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Daha fazla ürün yüklenemedi';
      if (kDebugMode) {
        print('Load more error: $e');
      }
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Filtreleri güncelle ve yeni arama yap
  void updateFilters({
    double? minPrice,
    double? maxPrice,
    bool? freeShipping,
  }) {
    bool hasChanged = false;

    if (minPrice != _minPrice) {
      _minPrice = minPrice;
      hasChanged = true;
    }
    if (maxPrice != _maxPrice) {
      _maxPrice = maxPrice;
      hasChanged = true;
    }
    if (freeShipping != null && freeShipping != _freeShippingOnly) {
      _freeShippingOnly = freeShipping;
      hasChanged = true;
    }

    if (hasChanged && _searchQuery.isNotEmpty) {
      searchProducts(resetPage: true);
    } else {
      notifyListeners();
    }
  }

  /// Sıralama seçeneğini güncelle ve yeni arama yap
  void updateSortOption(SortOption sortOption) {
    if (_sortOption != sortOption) {
      _sortOption = sortOption;
      if (_searchQuery.isNotEmpty) {
        searchProducts(resetPage: true);
      } else {
        notifyListeners();
      }
    }
  }

  /// Filtreleri temizle
  void clearFilters() {
    _minPrice = null;
    _maxPrice = null;
    _freeShippingOnly = false;
    
    if (_searchQuery.isNotEmpty) {
      searchProducts(resetPage: true);
    } else {
      notifyListeners();
    }
  }

  /// Clipboard'dan link oku ve ürün detayına git
  Future<String?> parseProductLinkFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text?.trim();
      
      if (text == null || text.isEmpty) {
        _errorMessage = 'Panoda link bulunamadı';
        notifyListeners();
        return null;
      }

      // Trendyol linki mi kontrol et
      if (!text.contains('trendyol.com')) {
        _errorMessage = 'Geçersiz Trendyol linki';
        notifyListeners();
        return null;
      }

      // Ürün ID'sini çıkar
      final productId = _trendyolService.extractProductIdFromUrl(text);
      if (productId == null) {
        _errorMessage = 'Geçersiz Trendyol linki';
        notifyListeners();
        return null;
      }

      _errorMessage = null;
      notifyListeners();
      return productId;
    } catch (e) {
      _errorMessage = 'Link okunamadı';
      notifyListeners();
      if (kDebugMode) {
        print('Clipboard error: $e');
      }
      return null;
    }
  }

  /// Arama geçmişinden arama yap
  void searchFromHistory(String query) {
    _searchQuery = query;
    searchProducts(resetPage: true);
  }

  /// Arama geçmişini temizle
  Future<void> clearSearchHistory() async {
    _searchHistory = [];
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);
    } catch (e) {
      if (kDebugMode) {
        print('Clear history error: $e');
      }
    }
  }

  /// Arama geçmişini yükle
  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_searchHistoryKey) ?? [];
      _searchHistory = history;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Load history error: $e');
      }
    }
  }

  /// Arama query'sini geçmişe kaydet
  Future<void> _saveSearchQuery(String query) async {
    if (query.trim().isEmpty) return;

    try {
      // Eğer zaten varsa çıkar (en üste eklemek için)
      _searchHistory.remove(query);
      
      // En başa ekle
      _searchHistory.insert(0, query);
      
      // Maksimum 10 öğe tut
      if (_searchHistory.length > _maxSearchHistoryItems) {
        _searchHistory = _searchHistory.sublist(0, _maxSearchHistoryItems);
      }

      // SharedPreferences'a kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_searchHistoryKey, _searchHistory);
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Save history error: $e');
      }
    }
  }

  /// Hata mesajını temizle
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
