import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

/// Kaydedilen Trendyol ürünleri servisi
/// Supabase saved_products tablosu ile CRUD işlemlerini yönetir
class SavedProductService {
  final SupabaseClient _client;

  SavedProductService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Ürünü gardıroba kaydet
  /// 
  /// [userId] - Kullanıcı ID'si
  /// [product] - Kaydedilecek ürün
  /// 
  /// Returns: Kaydedilen SavedProduct nesnesi
  /// Throws: SavedProductException
  Future<SavedProduct> saveProduct({
    required String userId,
    required Product product,
  }) async {
    try {
      // Önce ürünün zaten kaydedilip kaydedilmediğini kontrol et
      final exists = await isProductSaved(userId, product.id);
      if (exists) {
        throw SavedProductException(
          message: 'Bu ürün zaten gardırobunuzda',
          type: SavedProductExceptionType.alreadyExists,
        );
      }

      // saved_products tablosuna kaydet (tüm detaylarla birlikte)
      final savedProductData = {
        'user_id': userId,
        'product_id': product.id,
        'product_name': product.name,
        'product_image': product.images.isNotEmpty ? product.images.first : '',
        'product_price': product.price,
        'product_url': product.url,
        // Detay alanları - API'ye gitmeden detay sayfasını açmak için
        'product_brand': product.brand,
        'product_description': product.description,
        'product_images': product.images,
        'product_original_price': product.originalPrice,
        'product_discount_pct': product.discountPct,
        'product_rating': product.rating,
        'product_review_count': product.reviewCount,
        'product_seller': product.seller,
        'product_free_shipping': product.freeShipping,
      };

      final savedProductResponse = await _client
          .from('saved_products')
          .insert(savedProductData)
          .select()
          .single();

      // media tablosuna da kaydet (profil sayfasında gösterilmesi için)
      final mediaData = {
        'user_id': userId,
        'image_url': product.images.isNotEmpty ? product.images.first : '',
        'type': 'TRENDYOL_PRODUCT',
        'style_tag': product.id, // Product ID'yi tag olarak sakla
        'trendyol_product_id': product.id,
      };

      await _client
          .from('media')
          .insert(mediaData);

      return SavedProduct.fromJson(savedProductResponse);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is SavedProductException) rethrow;
      throw SavedProductException(
        message: 'Ürün kaydedilemedi',
        type: SavedProductExceptionType.unknown,
        originalError: e,
      );
    }
  }

  /// Kullanıcının kaydedilen ürünlerini getir
  /// 
  /// [userId] - Kullanıcı ID'si
  /// 
  /// Returns: SavedProduct listesi
  /// Throws: SavedProductException
  Future<List<SavedProduct>> getSavedProducts(String userId) async {
    try {
      final response = await _client
          .from('saved_products')
          .select()
          .eq('user_id', userId)
          .order('saved_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => SavedProduct.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is SavedProductException) rethrow;
      throw SavedProductException(
        message: 'Kaydedilen ürünler getirilemedi',
        type: SavedProductExceptionType.unknown,
        originalError: e,
      );
    }
  }

  /// Kaydedilen ürünü sil
  /// 
  /// [savedProductId] - Kaydedilen ürün ID'si
  /// 
  /// Throws: SavedProductException
  Future<void> deleteSavedProduct(String savedProductId) async {
    try {
      await _client
          .from('saved_products')
          .delete()
          .eq('id', savedProductId);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is SavedProductException) rethrow;
      throw SavedProductException(
        message: 'Ürün silinemedi',
        type: SavedProductExceptionType.unknown,
        originalError: e,
      );
    }
  }

  /// Ürün ID'sine göre kaydedilen ürünü getir
  ///
  /// [userId] - Kullanıcı ID'si
  /// [productId] - Trendyol ürün ID'si
  ///
  /// Returns: SavedProduct veya null
  Future<SavedProduct?> getSavedProductByProductId(
      String userId, String productId) async {
    try {
      final response = await _client
          .from('saved_products')
          .select()
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      if (response == null) return null;
      return SavedProduct.fromJson(response);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is SavedProductException) rethrow;
      throw SavedProductException(
        message: 'Ürün bilgisi getirilemedi',
        type: SavedProductExceptionType.unknown,
        originalError: e,
      );
    }
  }

  /// Ürün ID'sine göre kaydedilen ürünü sil
  /// 
  /// [userId] - Kullanıcı ID'si
  /// [productId] - Trendyol ürün ID'si
  /// 
  /// Throws: SavedProductException
  Future<void> deleteSavedProductByProductId(String userId, String productId) async {
    try {
      // saved_products tablosundan sil
      await _client
          .from('saved_products')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId);

      // media tablosundan da sil
      await _client
          .from('media')
          .delete()
          .eq('user_id', userId)
          .eq('trendyol_product_id', productId);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is SavedProductException) rethrow;
      throw SavedProductException(
        message: 'Ürün silinemedi',
        type: SavedProductExceptionType.unknown,
        originalError: e,
      );
    }
  }

  /// Ürünün kaydedilip kaydedilmediğini kontrol et
  /// 
  /// [userId] - Kullanıcı ID'si
  /// [productId] - Trendyol ürün ID'si
  /// 
  /// Returns: true ise ürün kaydedilmiş, false ise kaydedilmemiş
  Future<bool> isProductSaved(String userId, String productId) async {
    try {
      final response = await _client
          .from('saved_products')
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      return response != null;
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is SavedProductException) rethrow;
      throw SavedProductException(
        message: 'Ürün durumu kontrol edilemedi',
        type: SavedProductExceptionType.unknown,
        originalError: e,
      );
    }
  }

  /// Kaydedilen ürün sayısını getir
  /// 
  /// [userId] - Kullanıcı ID'si
  /// 
  /// Returns: Kaydedilen ürün sayısı
  Future<int> getSavedProductCount(String userId) async {
    try {
      final response = await _client
          .from('saved_products')
          .select('id')
          .eq('user_id', userId);

      return (response as List).length;
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is SavedProductException) rethrow;
      throw SavedProductException(
        message: 'Ürün sayısı getirilemedi',
        type: SavedProductExceptionType.unknown,
        originalError: e,
      );
    }
  }

  /// PostgrestException'ı SavedProductException'a dönüştürür
  SavedProductException _handlePostgrestError(PostgrestException error) {
    // RLS policy violation
    if (error.code == '42501' || error.message.contains('permission denied')) {
      return SavedProductException(
        message: 'Bu işlem için yetkiniz yok',
        type: SavedProductExceptionType.permissionDenied,
        originalError: error,
      );
    }

    // Unique constraint violation
    if (error.code == '23505') {
      return SavedProductException(
        message: 'Bu ürün zaten gardırobunuzda',
        type: SavedProductExceptionType.alreadyExists,
        originalError: error,
      );
    }

    // Foreign key violation
    if (error.code == '23503') {
      return SavedProductException(
        message: 'Geçersiz kullanıcı veya ürün',
        type: SavedProductExceptionType.invalidData,
        originalError: error,
      );
    }

    // Not found
    if (error.code == 'PGRST116') {
      return SavedProductException(
        message: 'Ürün bulunamadı',
        type: SavedProductExceptionType.notFound,
        originalError: error,
      );
    }

    return SavedProductException(
      message: 'Veritabanı hatası: ${error.message}',
      type: SavedProductExceptionType.database,
      originalError: error,
    );
  }
}

/// SavedProduct servis exception'ı
class SavedProductException implements Exception {
  final String message;
  final SavedProductExceptionType type;
  final dynamic originalError;

  SavedProductException({
    required this.message,
    required this.type,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// SavedProduct exception tipleri
enum SavedProductExceptionType {
  alreadyExists,
  notFound,
  permissionDenied,
  invalidData,
  database,
  unknown,
}
