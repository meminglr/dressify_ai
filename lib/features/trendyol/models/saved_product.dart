import 'package:equatable/equatable.dart';
import 'product.dart';

/// Gardıroba kaydedilen Trendyol ürünü modeli
/// Supabase saved_products tablosundaki verileri temsil eder
class SavedProduct extends Equatable {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final String productImage;
  final double productPrice;
  final String productUrl;
  final DateTime savedAt;

  // Detay alanları (API'ye gitmeden detay sayfasını açmak için)
  final String? productBrand;
  final String? productDescription;
  final List<String> productImages;
  final double? productOriginalPrice;
  final int productDiscountPct;
  final double productRating;
  final int productReviewCount;
  final String? productSeller;
  final bool productFreeShipping;

  const SavedProduct({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.productPrice,
    required this.productUrl,
    required this.savedAt,
    this.productBrand,
    this.productDescription,
    this.productImages = const [],
    this.productOriginalPrice,
    this.productDiscountPct = 0,
    this.productRating = 0,
    this.productReviewCount = 0,
    this.productSeller,
    this.productFreeShipping = false,
  });

  factory SavedProduct.fromJson(Map<String, dynamic> json) {
    final images = (json['product_images'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return SavedProduct(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      productImage: json['product_image']?.toString() ?? '',
      productPrice: (json['product_price'] as num?)?.toDouble() ?? 0.0,
      productUrl: json['product_url']?.toString() ?? '',
      savedAt: json['saved_at'] != null
          ? DateTime.parse(json['saved_at'].toString())
          : DateTime.now(),
      productBrand: json['product_brand']?.toString(),
      productDescription: json['product_description']?.toString(),
      productImages: images,
      productOriginalPrice:
          (json['product_original_price'] as num?)?.toDouble(),
      productDiscountPct:
          (json['product_discount_pct'] as num?)?.toInt() ?? 0,
      productRating: (json['product_rating'] as num?)?.toDouble() ?? 0,
      productReviewCount:
          (json['product_review_count'] as num?)?.toInt() ?? 0,
      productSeller: json['product_seller']?.toString(),
      productFreeShipping:
          json['product_free_shipping'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'product_price': productPrice,
      'product_url': productUrl,
      'saved_at': savedAt.toIso8601String(),
      'product_brand': productBrand,
      'product_description': productDescription,
      'product_images': productImages,
      'product_original_price': productOriginalPrice,
      'product_discount_pct': productDiscountPct,
      'product_rating': productRating,
      'product_review_count': productReviewCount,
      'product_seller': productSeller,
      'product_free_shipping': productFreeShipping,
    };
  }

  /// SavedProduct'tan Product nesnesi oluşturur (API isteği olmadan detay sayfası için)
  Product toProduct() {
    final allImages = productImages.isNotEmpty
        ? productImages
        : (productImage.isNotEmpty ? [productImage] : <String>[]);

    return Product(
      id: productId,
      name: productName,
      brand: productBrand ?? '',
      brandId: 0,
      category: '',
      categoryId: 0,
      price: productPrice,
      originalPrice: productOriginalPrice ?? productPrice,
      discountPct: productDiscountPct,
      currency: 'TL',
      rating: productRating,
      reviewCount: productReviewCount,
      inStock: true,
      url: productUrl,
      images: allImages,
      description: productDescription ?? '',
      seller: productSeller ?? '',
      sellerId: '',
      badges: const [],
      freeShipping: productFreeShipping,
      hasGift: false,
    );
  }

  SavedProduct copyWith({
    String? id,
    String? userId,
    String? productId,
    String? productName,
    String? productImage,
    double? productPrice,
    String? productUrl,
    DateTime? savedAt,
    String? productBrand,
    String? productDescription,
    List<String>? productImages,
    double? productOriginalPrice,
    int? productDiscountPct,
    double? productRating,
    int? productReviewCount,
    String? productSeller,
    bool? productFreeShipping,
  }) {
    return SavedProduct(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      productPrice: productPrice ?? this.productPrice,
      productUrl: productUrl ?? this.productUrl,
      savedAt: savedAt ?? this.savedAt,
      productBrand: productBrand ?? this.productBrand,
      productDescription: productDescription ?? this.productDescription,
      productImages: productImages ?? this.productImages,
      productOriginalPrice: productOriginalPrice ?? this.productOriginalPrice,
      productDiscountPct: productDiscountPct ?? this.productDiscountPct,
      productRating: productRating ?? this.productRating,
      productReviewCount: productReviewCount ?? this.productReviewCount,
      productSeller: productSeller ?? this.productSeller,
      productFreeShipping: productFreeShipping ?? this.productFreeShipping,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        productId,
        productName,
        productImage,
        productPrice,
        productUrl,
        savedAt,
        productBrand,
        productDescription,
        productImages,
        productOriginalPrice,
        productDiscountPct,
        productRating,
        productReviewCount,
        productSeller,
        productFreeShipping,
      ];

  @override
  bool get stringify => true;
}
