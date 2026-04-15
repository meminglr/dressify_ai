/// Trendyol ürün sıralama seçenekleri
/// API'nin desteklediği sıralama türlerini temsil eder
enum SortOption {
  /// Çok satanlar
  bestSeller('BEST_SELLER', 'Çok Satanlar'),

  /// Artan fiyat (ucuzdan pahalıya)
  priceByAsc('PRICE_BY_ASC', 'Artan Fiyat'),

  /// Azalan fiyat (pahalıdan ucuza)
  priceByDesc('PRICE_BY_DESC', 'Azalan Fiyat'),

  /// En çok değerlendirilen
  mostRated('MOST_RATED', 'En Çok Değerlendirilen'),

  /// Yeni gelenler
  newest('NEWEST', 'Yeni Gelenler');

  /// API'ye gönderilecek değer
  final String value;

  /// Kullanıcıya gösterilecek etiket
  final String label;

  const SortOption(this.value, this.label);

  /// String değerden SortOption'a dönüştürür
  static SortOption fromValue(String value) {
    return SortOption.values.firstWhere(
      (option) => option.value == value,
      orElse: () => SortOption.bestSeller,
    );
  }

  @override
  String toString() => label;
}
