import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/trendyol_service.dart';
import '../services/saved_product_service.dart';

/// Ürün detay sayfası ViewModel'i
/// MVVM pattern - Business logic ve state management
class ProductDetailViewModel extends ChangeNotifier {
  final TrendyolService _trendyolService;
  final SavedProductService _savedProductService;
  
  // State properties
  Product? _product;
  List<Review> _reviews = [];
  bool _isLoading = false;
  bool _isLoadingReviews = false;
  bool _isSaving = false;
  bool _isProductSaved = false;
  String? _errorMessage;
  String? _successMessage;

  bool _wasRemovedFromWardrobe = false;
  bool get wasRemovedFromWardrobe => _wasRemovedFromWardrobe;

  ProductDetailViewModel({
    required TrendyolService trendyolService,
    required SavedProductService savedProductService,
  })  : _trendyolService = trendyolService,
        _savedProductService = savedProductService;

  // Getters
  Product? get product => _product;
  List<Review> get reviews => List.unmodifiable(_reviews);
  bool get isLoading => _isLoading;
  bool get isLoadingReviews => _isLoadingReviews;
  bool get isSaving => _isSaving;
  bool get isProductSaved => _isProductSaved;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasProduct => _product != null;
  bool get hasReviews => _reviews.isNotEmpty;

  /// Ürünü direkt set et (API isteği yapmadan)
  /// Arama sonuçlarından gelen ürün bilgilerini kullanmak için
  Future<void> setProduct(Product product) async {
    _product = product;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // DB'den kayıt durumunu kontrol et, sonra UI'ı güncelle
    await _checkIfProductSaved();

    _isLoading = false;
    notifyListeners();
  }

  /// Kaydedilen üründen ürünü yükle (API isteği yapmadan)
  /// Gardırop ekranından açılırken kullanılır
  Future<void> loadFromSavedProduct(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _errorMessage = 'Kullanıcı oturumu bulunamadı';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final saved = await _savedProductService.getSavedProductByProductId(
          userId, productId);

      if (saved != null) {
        _product = saved.toProduct();
        _isProductSaved = true;
        _errorMessage = null;
      } else {
        // saved_products'ta yoksa API'ye düş
        await loadProductDetail(productId);
        return;
      }
    } on SavedProductException catch (e) {
      _errorMessage = e.message;
      _product = null;
    } catch (e) {
      _errorMessage = 'Ürün bilgisi yüklenemedi';
      _product = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ürün detayını yükle
  /// 
  /// [productId] - Ürün ID'si veya tam URL
  Future<void> loadProductDetail(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      _product = await _trendyolService.getProductDetail(productId);
      
      // Ürünün kaydedilip kaydedilmediğini kontrol et
      await _checkIfProductSaved();
      
      _errorMessage = null;
    } on TrendyolException catch (e) {
      _errorMessage = e.message;
      _product = null;
    } catch (e) {
      _errorMessage = 'Ürün detayı yüklenemedi';
      _product = null;
      if (kDebugMode) {
        print('Load product detail error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ürün yorumlarını yükle
  /// 
  /// [productId] - Ürün ID'si veya tam URL
  /// [maxPages] - Maksimum sayfa sayısı (varsayılan: 2)
  Future<void> loadReviews(String productId, {int maxPages = 2}) async {
    _isLoadingReviews = true;
    notifyListeners();

    try {
      _reviews = await _trendyolService.getProductReviews(
        productId,
        maxPages: maxPages,
      );
    } on TrendyolException catch (e) {
      if (kDebugMode) {
        print('Load reviews error: ${e.message}');
      }
      // Yorumlar yüklenemezse sessizce başarısız ol
      _reviews = [];
    } catch (e) {
      if (kDebugMode) {
        print('Load reviews error: $e');
      }
      _reviews = [];
    } finally {
      _isLoadingReviews = false;
      notifyListeners();
    }
  }

  /// Ürünü gardıroba kaydet
  Future<void> saveToWardrobe() async {
    if (_product == null) {
      _errorMessage = 'Ürün bilgisi bulunamadı';
      notifyListeners();
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _errorMessage = 'Lütfen önce giriş yapın';
      notifyListeners();
      return;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _savedProductService.saveProduct(
        userId: userId,
        product: _product!,
      );

      _isProductSaved = true;
      _successMessage = 'Ürün gardıroba eklendi';
      _errorMessage = null;
    } on SavedProductException catch (e) {
      _errorMessage = e.message;
      _successMessage = null;
    } catch (e) {
      _errorMessage = 'Ürün kaydedilemedi';
      _successMessage = null;
      if (kDebugMode) {
        print('Save to wardrobe error: $e');
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Ürünü gardıroptan çıkar
  Future<void> removeFromWardrobe() async {
    if (_product == null) {
      _errorMessage = 'Ürün bilgisi bulunamadı';
      notifyListeners();
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _errorMessage = 'Lütfen önce giriş yapın';
      notifyListeners();
      return;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _savedProductService.deleteSavedProductByProductId(
        userId,
        _product!.id,
      );

      _isProductSaved = false;
      _wasRemovedFromWardrobe = true;
      _successMessage = 'Ürün gardıroptan çıkarıldı';
      _errorMessage = null;
    } on SavedProductException catch (e) {
      _errorMessage = e.message;
      _successMessage = null;
    } catch (e) {
      _errorMessage = 'Ürün çıkarılamadı';
      _successMessage = null;
      if (kDebugMode) {
        print('Remove from wardrobe error: $e');
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Ürünün kaydedilip kaydedilmediğini kontrol et
  Future<void> _checkIfProductSaved() async {
    if (_product == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _isProductSaved = false;
      return;
    }

    try {
      _isProductSaved = await _savedProductService.isProductSaved(
        userId,
        _product!.id,
      );
    } catch (e) {
      _isProductSaved = false;
      if (kDebugMode) {
        print('Check if product saved error: $e');
      }
    }
  }

  /// Ürün ve yorumları birlikte yükle
  /// 
  /// [productId] - Ürün ID'si veya tam URL
  /// [loadReviewsFlag] - Yorumları yükle (varsayılan: true)
  /// [reviewPages] - Yorum sayfa sayısı (varsayılan: 2)
  Future<void> loadProductWithReviews(
    String productId, {
    bool loadReviewsFlag = true,
    int reviewPages = 2,
  }) async {
    // Önce ürün detayını yükle
    await loadProductDetail(productId);

    // Ürün başarıyla yüklendiyse yorumları yükle
    if (_product != null && loadReviewsFlag) {
      await loadReviews(productId, maxPages: reviewPages);
    }
  }

  /// Mevcut ürünün linkini paylaş
  Future<void> shareProduct() async {
    if (_product == null) return;

    final url = _product!.url.isNotEmpty
        ? _product!.url
        : 'https://www.trendyol.com/sr?q=${Uri.encodeComponent(_product!.name)}';

    await SharePlus.instance.share(
      ShareParams(
        text: '${_product!.name}\n$url',
        subject: _product!.name,
      ),
    );
  }

  /// Hata mesajını temizle
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Başarı mesajını temizle
  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  /// Tüm mesajları temizle
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// State'i sıfırla (yeni ürün için)
  void reset() {
    _product = null;
    _reviews = [];
    _isLoading = false;
    _isLoadingReviews = false;
    _isSaving = false;
    _isProductSaved = false;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
