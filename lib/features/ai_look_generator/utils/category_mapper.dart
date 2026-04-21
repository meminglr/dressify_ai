/// CategoryMapper maps raw style tags and media type values to Turkish category labels.
///
/// This is a pure Dart utility with no Flutter or media-model dependencies,
/// making it safe to use in service and ViewModel layers without widget context.
class CategoryMapper {
  CategoryMapper._();

  /// Internal mapping from lowercase English style tags to Turkish category names.
  static const Map<String, String> _categoryMap = {
    'tshirt': 'Tişört',
    'blouse': 'Bluz',
    'shirt': 'Gömlek',
    'pants': 'Pantolon',
    'jeans': 'Jeans',
    'shorts': 'Şort',
    'skirt': 'Etek',
    'dress': 'Elbise',
    'jumpsuit': 'Tulum',
    'jacket': 'Ceket',
    'coat': 'Mont',
    'cardigan': 'Hırka',
    'shoes': 'Ayakkabı',
    'boots': 'Bot',
    'sneakers': 'Sneaker',
    'accessories': 'Aksesuar',
    'belt': 'Kemer',
    'bag': 'Çanta',
    'hat': 'Şapka',
  };

  /// Maps a [styleTag] and [mediaTypeValue] to a Turkish category label.
  ///
  /// Matching is case-insensitive. When [styleTag] is not recognised, the
  /// fallback is determined by [mediaTypeValue]:
  /// - `'TRENDYOL_PRODUCT'` → `'Kıyafet'`
  /// - anything else → `'Giysi'`
  ///
  /// Example:
  /// ```dart
  /// CategoryMapper.mapCategory('Tshirt', 'UPLOAD');   // → 'Tişört'
  /// CategoryMapper.mapCategory(null, 'TRENDYOL_PRODUCT'); // → 'Kıyafet'
  /// CategoryMapper.mapCategory('unknown', 'MODEL');   // → 'Giysi'
  /// ```
  static String mapCategory(String? styleTag, String mediaTypeValue) {
    if (styleTag != null) {
      final mapped = _categoryMap[styleTag.toLowerCase()];
      if (mapped != null) return mapped;
    }

    return mediaTypeValue == 'TRENDYOL_PRODUCT' ? 'Kıyafet' : 'Giysi';
  }
}
