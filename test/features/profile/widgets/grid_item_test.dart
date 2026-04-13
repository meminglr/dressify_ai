import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dressifyai/features/profile/models/media.dart';
import 'package:dressifyai/features/profile/widgets/grid_item.dart';

void main() {
  group('GridItem Widget Tests', () {
    late Media testMedia;
    late Media testMediaWithTag;
    bool wasTapped = false;

    setUp(() {
      wasTapped = false;
      
      testMedia = Media(
        id: 'media_001',
        type: MediaType.aiLook,
        imageUrl: 'https://via.placeholder.com/400x600',
        tag: null,
        createdAt: DateTime.now(),
        width: 400,
        height: 600,
      );

      testMediaWithTag = Media(
        id: 'media_002',
        type: MediaType.aiLook,
        imageUrl: 'https://via.placeholder.com/400x500',
        tag: 'NEO-STREETWEAR',
        createdAt: DateTime.now(),
        width: 400,
        height: 500,
      );
    });

    testWidgets('should display media image', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: GridItem(
                media: testMedia,
                onTap: () {},
                heroTag: 'test_hero_1',
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should display tag overlay when tag exists', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: GridItem(
                media: testMediaWithTag,
                onTap: () {},
                heroTag: 'test_hero_2',
              ),
            ),
          ),
        ),
      );

      expect(find.text('NEO-STREETWEAR'), findsOneWidget);
    });

    testWidgets('should not display tag overlay when tag is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: GridItem(
                media: testMedia,
                onTap: () {},
                heroTag: 'test_hero_3',
              ),
            ),
          ),
        ),
      );

      // Should not find any tag text (tag is null)
      expect(find.text('NEO-STREETWEAR'), findsNothing);
    });

    testWidgets('should call onTap when tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: GridItem(
                media: testMedia,
                onTap: () {
                  wasTapped = true;
                },
                heroTag: 'test_hero_4',
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(wasTapped, true);
    });

    testWidgets('should have Hero widget with correct tag', (tester) async {
      const heroTag = 'unique_hero_tag';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: GridItem(
                media: testMedia,
                onTap: () {},
                heroTag: heroTag,
              ),
            ),
          ),
        ),
      );

      final heroFinder = find.byType(Hero);
      expect(heroFinder, findsOneWidget);
      
      final hero = tester.widget<Hero>(heroFinder);
      expect(hero.tag, heroTag);
    });

    testWidgets('should have RepaintBoundary for performance', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: GridItem(
                media: testMedia,
                onTap: () {},
                heroTag: 'test_hero_5',
              ),
            ),
          ),
        ),
      );

      // RepaintBoundary should be at the root of GridItem
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('should have InkWell for ripple effect', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: GridItem(
                media: testMedia,
                onTap: () {},
                heroTag: 'test_hero_6',
              ),
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('should have rounded corners (16px border radius)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: GridItem(
                media: testMedia,
                onTap: () {},
                heroTag: 'test_hero_7',
              ),
            ),
          ),
        ),
      );

      // Find Material widgets and check if any has the correct border radius
      final materialWidgets = tester.widgetList<Material>(find.byType(Material));
      final hasCorrectBorderRadius = materialWidgets.any(
        (material) => material.borderRadius == BorderRadius.circular(16),
      );
      
      expect(hasCorrectBorderRadius, true);
    });
  });
}
