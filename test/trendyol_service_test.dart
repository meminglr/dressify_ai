import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dressifyai/features/trendyol/services/trendyol_service.dart';
import 'package:dressifyai/features/trendyol/models/models.dart';

void main() {
  group('TrendyolService Integration Tests', () {
    late TrendyolService service;

    setUpAll(() async {
      // Load .env file
      await dotenv.load(fileName: '.env');
    });

    setUp(() {
      service = TrendyolService();
    });

    test('searchProducts should return results for "yeşil ceket"', () async {
      final response = await service.searchProducts(
        query: 'yeşil ceket',
        page: 1,
      );

      expect(response.query, 'yeşil ceket');
      expect(response.products, isNotEmpty);
      expect(response.totalCount, greaterThan(0));
      expect(response.count, greaterThan(0));
      
      // Check first product has required fields
      final firstProduct = response.products.first;
      expect(firstProduct.id, isNotEmpty);
      expect(firstProduct.name, isNotEmpty);
      expect(firstProduct.price, greaterThan(0));
      expect(firstProduct.images, isNotEmpty);
    });

    test('searchProducts with filters should work', () async {
      final response = await service.searchProducts(
        query: 'ceket',
        page: 1,
        minPrice: 100,
        maxPrice: 1000,
        freeShipping: true,
      );

      expect(response.products, isNotEmpty);
      
      // Verify products match filters
      for (final product in response.products) {
        expect(product.price, greaterThanOrEqualTo(100));
        expect(product.price, lessThanOrEqualTo(1000));
      }
    });

    test('extractProductIdFromUrl should extract ID correctly', () {
      final url = 'https://www.trendyol.com/ethiquet/lillesol-kadin-fitilli-gorunumlu-slim-fit-vucuda-oturan-havuz-yakali-pamuklu-basic-haki-bluz-atlet-p-990029954?boutiqueId=61&merchantId=829806';
      
      final productId = service.extractProductIdFromUrl(url);
      
      expect(productId, '990029954');
    });
  });
}
