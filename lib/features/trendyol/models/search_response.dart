import 'product.dart';

/// Trendyol arama API yanıt modeli
/// API'den dönen arama sonuçlarını temsil eder
class SearchResponse {
  final String query;
  final int totalCount;
  final int pagesFetched;
  final int count;
  final List<Product> products;

  const SearchResponse({
    required this.query,
    required this.totalCount,
    required this.pagesFetched,
    required this.count,
    required this.products,
  });

  /// JSON'dan SearchResponse nesnesi oluşturur
  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      query: json['query']?.toString() ?? '',
      totalCount: json['total_count'] as int? ?? 0,
      pagesFetched: json['pages_fetched'] as int? ?? 0,
      count: json['count'] as int? ?? 0,
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// SearchResponse nesnesini JSON'a dönüştürür
  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'total_count': totalCount,
      'pages_fetched': pagesFetched,
      'count': count,
      'products': products.map((p) => p.toJson()).toList(),
    };
  }
}
