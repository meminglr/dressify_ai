import 'package:equatable/equatable.dart';

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

  const SavedProduct({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.productPrice,
    required this.productUrl,
    required this.savedAt,
  });

  /// JSON'dan SavedProduct nesnesi oluşturur
  factory SavedProduct.fromJson(Map<String, dynamic> json) {
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
    );
  }

  /// SavedProduct nesnesini JSON'a dönüştürür
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
    };
  }

  /// Belirli alanları güncelleyerek yeni SavedProduct nesnesi oluşturur
  SavedProduct copyWith({
    String? id,
    String? userId,
    String? productId,
    String? productName,
    String? productImage,
    double? productPrice,
    String? productUrl,
    DateTime? savedAt,
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
      ];

  @override
  bool get stringify => true;
}
