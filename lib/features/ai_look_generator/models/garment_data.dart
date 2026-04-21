/// GarmentData represents a single garment item in an AI look generation request.
///
/// Each garment has a public image URL, a Turkish category label, and an optional
/// product name (used for Trendyol products).
class GarmentData {
  /// Public URL to the garment image in storage
  final String imageUrl;

  /// Turkish category label (e.g. 'Tişört', 'Pantolon')
  final String category;

  /// Optional product name, typically populated for Trendyol products
  final String? productName;

  const GarmentData({
    required this.imageUrl,
    required this.category,
    this.productName,
  });

  /// Converts this garment to a JSON map for the n8n API payload.
  ///
  /// The [productName] key is omitted when null to keep the payload clean.
  Map<String, dynamic> toJson() {
    return {
      'image_url': imageUrl,
      'category': category,
      if (productName != null) 'product_name': productName,
    };
  }
}
