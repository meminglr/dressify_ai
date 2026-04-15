import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/models.dart';

/// Trendyol scraping API servisi
/// Trendyol ürün arama, detay ve yorum işlemlerini yönetir
class TrendyolService {
  late final Dio _dio;
  final String baseUrl;
  final int timeout;
  final int retryCount;

  TrendyolService({
    String? baseUrl,
    int? timeout,
    int? retryCount,
    Dio? dio,
  })  : baseUrl = baseUrl ?? dotenv.env['TRENDYOL_API_BASE_URL'] ?? 'http://localhost:8000',
        timeout = timeout ?? int.tryParse(dotenv.env['TRENDYOL_API_TIMEOUT'] ?? '30000') ?? 30000,
        retryCount = retryCount ?? int.tryParse(dotenv.env['TRENDYOL_API_RETRY_COUNT'] ?? '3') ?? 3 {
    _dio = dio ?? _createDio();
  }

  /// Dio instance'ı oluşturur ve yapılandırır
  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(milliseconds: timeout),
        receiveTimeout: Duration(milliseconds: timeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Retry interceptor ekle
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (_shouldRetry(error) && error.requestOptions.extra['retryCount'] == null) {
            error.requestOptions.extra['retryCount'] = 0;
          }

          final retryCount = error.requestOptions.extra['retryCount'] as int? ?? 0;
          if (retryCount < this.retryCount && _shouldRetry(error)) {
            error.requestOptions.extra['retryCount'] = retryCount + 1;
            
            // Exponential backoff
            await Future.delayed(Duration(seconds: retryCount + 1));
            
            try {
              final response = await dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
          
          return handler.next(error);
        },
      ),
    );

    // Debug mode'da logging ekle
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }

    return dio;
  }

  /// Hatanın retry edilip edilmeyeceğini kontrol eder
  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        (error.response?.statusCode != null && error.response!.statusCode! >= 500);
  }

  /// Ürün arama
  /// 
  /// [query] - Arama terimi
  /// [sort] - Sıralama seçeneği
  /// [minPrice] - Minimum fiyat
  /// [maxPrice] - Maksimum fiyat
  /// [freeShipping] - Sadece ücretsiz kargolu ürünler
  /// [page] - Sayfa numarası (pagination için)
  Future<SearchResponse> searchProducts({
    required String query,
    SortOption? sort,
    double? minPrice,
    double? maxPrice,
    bool? freeShipping,
    int page = 1,
  }) async {
    try {
      // API supports both GET and POST
      // Using POST for better parameter handling
      final requestData = <String, dynamic>{
        'query': query,
        'page': page, // Single page mode
      };

      if (sort != null) {
        requestData['sort'] = sort.value;
      }
      if (minPrice != null) {
        requestData['min_price'] = minPrice;
      }
      if (maxPrice != null) {
        requestData['max_price'] = maxPrice;
      }
      if (freeShipping != null && freeShipping) {
        requestData['free_shipping'] = freeShipping;
      }

      final response = await _dio.post(
        '/v1/search',
        data: requestData,
      );

      return SearchResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Ürün detayı getir
  /// 
  /// [productId] - Ürün ID'si veya tam URL
  Future<Product> getProductDetail(String productId) async {
    try {
      // Eğer URL ise direkt kullan, değilse ID'den URL oluştur
      final url = productId.startsWith('http') 
          ? productId 
          : 'https://www.trendyol.com/p-$productId';
      
      final response = await _dio.post(
        '/v1/product',
        data: {
          'url': url,
          'review_pages': 0, // Yorumları ayrı çekeceğiz
        },
      );

      final productData = response.data['product'] as Map<String, dynamic>;
      return Product.fromJson(productData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Ürün yorumlarını getir
  /// 
  /// [productId] - Ürün ID'si veya tam URL
  /// [maxPages] - Maksimum sayfa sayısı
  Future<List<Review>> getProductReviews(String productId, {int maxPages = 1}) async {
    try {
      // Eğer URL ise direkt kullan, değilse ID'den URL oluştur
      final url = productId.startsWith('http') 
          ? productId 
          : 'https://www.trendyol.com/p-$productId';
      
      final response = await _dio.post(
        '/v1/product',
        data: {
          'url': url,
          'review_pages': maxPages,
        },
      );

      final reviewsData = response.data['reviews'] as List<dynamic>?;
      if (reviewsData == null) return [];

      return reviewsData
          .map((json) => Review.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Trendyol URL'inden ürün ID'sini çıkarır
  /// 
  /// URL formatı: https://www.trendyol.com/marka/urun-adi-p-123456
  /// veya: https://www.trendyol.com/marka/urun-adi-p-123456?boutiqueId=...
  String? extractProductIdFromUrl(String url) {
    // Regex pattern: -p- ile başlayan ve sonrasında sayılar gelen kısım
    final regex = RegExp(r'-p-(\d+)');
    final match = regex.firstMatch(url);
    
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    
    return null;
  }

  /// URL'den ürün detayı getir
  /// 
  /// [url] - Trendyol ürün URL'i
  Future<Product> getProductFromUrl(String url) async {
    final productId = extractProductIdFromUrl(url);
    
    if (productId == null) {
      throw TrendyolException(
        message: 'Geçersiz Trendyol linki',
        type: TrendyolExceptionType.invalidUrl,
      );
    }
    
    return getProductDetail(productId);
  }

  /// DioException'ı TrendyolException'a dönüştürür
  TrendyolException _handleError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return TrendyolException(
        message: 'Bağlantı zaman aşımına uğradı',
        type: TrendyolExceptionType.timeout,
        originalError: error,
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return TrendyolException(
        message: 'İnternet bağlantınızı kontrol edin',
        type: TrendyolExceptionType.network,
        originalError: error,
      );
    }

    final statusCode = error.response?.statusCode;
    if (statusCode != null) {
      switch (statusCode) {
        case 404:
          return TrendyolException(
            message: 'Ürün bulunamadı',
            type: TrendyolExceptionType.notFound,
            originalError: error,
          );
        case 429:
          return TrendyolException(
            message: 'Çok fazla istek, lütfen bekleyin',
            type: TrendyolExceptionType.rateLimit,
            originalError: error,
          );
        case >= 500:
          return TrendyolException(
            message: 'Trendyol servisi şu an kullanılamıyor',
            type: TrendyolExceptionType.server,
            originalError: error,
          );
      }
    }

    return TrendyolException(
      message: 'Bir hata oluştu, lütfen tekrar deneyin',
      type: TrendyolExceptionType.unknown,
      originalError: error,
    );
  }
}

/// Trendyol servis exception'ı
class TrendyolException implements Exception {
  final String message;
  final TrendyolExceptionType type;
  final dynamic originalError;

  TrendyolException({
    required this.message,
    required this.type,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Trendyol exception tipleri
enum TrendyolExceptionType {
  timeout,
  network,
  notFound,
  rateLimit,
  server,
  invalidUrl,
  unknown,
}
