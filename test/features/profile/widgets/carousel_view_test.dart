import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dressifyai/features/profile/models/media.dart';
import 'package:dressifyai/features/profile/widgets/carousel_view.dart';

void main() {
  group('MediaCarouselView Widget Tests', () {
    late List<Media> testMediaList;

    setUp(() {
      testMediaList = [
        Media(
          id: 'media_001',
          type: MediaType.aiLook,
          imageUrl: 'https://via.placeholder.com/400x600',
          tag: 'NEO-STREETWEAR',
          createdAt: DateTime.now(),
          width: 400,
          height: 600,
        ),
        Media(
          id: 'media_002',
          type: MediaType.aiLook,
          imageUrl: 'https://via.placeholder.com/400x500',
          tag: 'MINIMALIST',
          createdAt: DateTime.now(),
          width: 400,
          height: 500,
        ),
        Media(
          id: 'media_003',
          type: MediaType.upload,
          imageUrl: 'https://via.placeholder.com/400x700',
          tag: null,
          createdAt: DateTime.now(),
          width: 400,
          height: 700,
        ),
      ];
    });

    testWidgets('should display carousel with initial page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaCarouselView(
            mediaList: testMediaList,
            initialIndex: 0,
            heroTag: 'test_hero',
          ),
        ),
      );

      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('should display close button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaCarouselView(
            mediaList: testMediaList,
            initialIndex: 0,
            heroTag: 'test_hero',
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should close carousel when close button is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MediaCarouselView(
                          mediaList: testMediaList,
                          initialIndex: 0,
                          heroTag: 'test_hero',
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Carousel'),
                );
              },
            ),
          ),
        ),
      );

      // Open carousel
      await tester.tap(find.text('Open Carousel'));
      await tester.pumpAndSettle();

      // Verify carousel is open
      expect(find.byType(MediaCarouselView), findsOneWidget);

      // Tap close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Verify carousel is closed
      expect(find.byType(MediaCarouselView), findsNothing);
    });

    testWidgets('should display page indicator when multiple items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaCarouselView(
            mediaList: testMediaList,
            initialIndex: 0,
            heroTag: 'test_hero',
          ),
        ),
      );

      // Should show "1 / 3" initially
      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('should not display page indicator when single item', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaCarouselView(
            mediaList: [testMediaList.first],
            initialIndex: 0,
            heroTag: 'test_hero',
          ),
        ),
      );

      // Should not show page indicator for single item
      expect(find.text('1 / 1'), findsNothing);
    });

    testWidgets('should have Hero widget with correct tag on initial page', (tester) async {
      const heroTag = 'unique_hero_tag';
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaCarouselView(
            mediaList: testMediaList,
            initialIndex: 0,
            heroTag: heroTag,
          ),
        ),
      );

      final heroFinder = find.byType(Hero);
      expect(heroFinder, findsOneWidget);
      
      final hero = tester.widget<Hero>(heroFinder);
      expect(hero.tag, heroTag);
    });

    testWidgets('should have black background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaCarouselView(
            mediaList: testMediaList,
            initialIndex: 0,
            heroTag: 'test_hero',
          ),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('should use vertical scroll direction', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaCarouselView(
            mediaList: testMediaList,
            initialIndex: 0,
            heroTag: 'test_hero',
          ),
        ),
      );

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.scrollDirection, Axis.vertical);
    });

    testWidgets('should start at initial index', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaCarouselView(
            mediaList: testMediaList,
            initialIndex: 1,
            heroTag: 'test_hero',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show "2 / 3" for index 1
      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('should update page indicator on swipe', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaCarouselView(
            mediaList: testMediaList,
            initialIndex: 0,
            heroTag: 'test_hero',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially should show "1 / 3"
      expect(find.text('1 / 3'), findsOneWidget);

      // Swipe up to go to next page
      await tester.drag(find.byType(PageView), const Offset(0, -400));
      await tester.pumpAndSettle();

      // Should now show "2 / 3"
      expect(find.text('2 / 3'), findsOneWidget);
    });
  });
}
