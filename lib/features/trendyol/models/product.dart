import 'package:equatable/equatable.dart';

/// Trendyol ürün modeli
/// API'den gelen ürün verilerini temsil eder
class Product extends Equatable {
  final String id;
  final String name;
  final String brand;
  final int brandId;
  final String category;
  final int categoryId;
  final double price;
  final double originalPrice;
  final int discountPct;
  final String currency;
  final double rating;
  final int reviewCount;
  final bool inStock;
  final String url;
  final List<String> images;
  final String description;
  final String seller;
  final String sellerId;
  final List<String> badges;
  final bool freeShipping;
  final bool hasGift;
  final int? cargoDays;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.brandId,
    required this.category,
    required this.categoryId,
    required this.price,
    required this.originalPrice,
    required this.discountPct,
    required this.currency,
    required this.rating,
    required this.reviewCount,
    required this.inStock,
    required this.url,
    required this.images,
    required this.description,
    required this.seller,
    required this.sellerId,
    required this.badges,
    required this.freeShipping,
    required this.hasGift,
    this.cargoDays,
  });

  /// JSON'dan Product nesnesi oluşturur
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      brandId: json['brand_id'] as int? ?? 0,
      category: json['category']?.toString() ?? '',
      categoryId: json['category_id'] as int? ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['original_price'] as num?)?.toDouble() ?? 0.0,
      discountPct: (json['discount_pct'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'TL',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      inStock: json['in_stock'] as bool? ?? false,
      url: json['url']?.toString() ?? '',
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      description: json['description']?.toString() ?? '',
      seller: json['seller']?.toString() ?? '',
      sellerId: json['seller_id']?.toString() ?? '',
      badges: (json['badges'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      freeShipping: json['free_shipping'] as bool? ?? false,
      hasGift: json['has_gift'] as bool? ?? false,
      cargoDays: (json['cargo_days'] as num?)?.toInt(),
    );
  }

  /// Product nesnesini JSON'a dönüştürür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'brand_id': brandId,
      'category': category,
      'category_id': categoryId,
      'price': price,
      'original_price': originalPrice,
      'discount_pct': discountPct,
      'currency': currency,
      'rating': rating,
      'review_count': reviewCount,
      'in_stock': inStock,
      'url': url,
      'images': images,
      'description': description,
      'seller': seller,
      'seller_id': sellerId,
      'badges': badges,
      'free_shipping': freeShipping,
      'has_gift': hasGift,
      'cargo_days': cargoDays,
    };
  }

  /// Belirli alanları güncelleyerek yeni Product nesnesi oluşturur
  Product copyWith({
    String? id,
    String? name,
    String? brand,
    int? brandId,
    String? category,
    int? categoryId,
    double? price,
    double? originalPrice,
    int? discountPct,
    String? currency,
    double? rating,
    int? reviewCount,
    bool? inStock,
    String? url,
    List<String>? images,
    String? description,
    String? seller,
    String? sellerId,
    List<String>? badges,
    bool? freeShipping,
    bool? hasGift,
    int? cargoDays,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      brandId: brandId ?? this.brandId,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      discountPct: discountPct ?? this.discountPct,
      currency: currency ?? this.currency,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      inStock: inStock ?? this.inStock,
      url: url ?? this.url,
      images: images ?? this.images,
      description: description ?? this.description,
      seller: seller ?? this.seller,
      sellerId: sellerId ?? this.sellerId,
      badges: badges ?? this.badges,
      freeShipping: freeShipping ?? this.freeShipping,
      hasGift: hasGift ?? this.hasGift,
      cargoDays: cargoDays ?? this.cargoDays,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        brand,
        brandId,
        category,
        categoryId,
        price,
        originalPrice,
        discountPct,
        currency,
        rating,
        reviewCount,
        inStock,
        url,
        images,
        description,
        seller,
        sellerId,
        badges,
        freeShipping,
        hasGift,
        cargoDays,
      ];

  @override
  bool get stringify => true;
}
