import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dressifyai/features/profile/models/media.dart';
import 'package:dressifyai/features/profile/widgets/masonry_grid_view.dart';
import 'package:dressifyai/features/profile/widgets/grid_item.dart';
import 'package:dressifyai/features/profile/data/mock_profile_data.dart';

void main() {
  group('MasonryGridView Widget Tests', () {
    late List<Media> testMediaList;
    int tappedIndex = -1;

    setUp(() {
      tappedIndex = -1;
      testMediaList = MockProfileData.getMockMediaList();
    });

    testWidgets('should render SliverGrid with correct number of items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                MasonryGridView(
                  mediaList: testMediaList,
                  onItemTap: (index) {
                    tappedIndex = index;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Should find GridItem widgets
      expect(find.byType(GridItem), findsWidgets);
    });

    testWidgets('should use 3 columns on small screen (<600px)', (tester) async {
      // Set small screen size (mobile)
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                MasonryGridView(
                  mediaList: testMediaList,
                  onItemTap: (index) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Find the SliverGrid
      final sliverGridFinder = find.byType(SliverGrid);
      expect(sliverGridFinder, findsOneWidget);

      // Get the SliverGrid widget
      final sliverGrid = tester.widget<SliverGrid>(sliverGridFinder);
      final gridDelegate = sliverGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      // Verify 3 columns
      expect(gridDelegate.crossAxisCount, 3);
    });

    testWidgets('should use 4 columns on medium screen (600-900px)', (tester) async {
      // Set medium screen size (tablet)
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                MasonryGridView(
                  mediaList: testMediaList,
                  onItemTap: (index) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Find the SliverGrid
      final sliverGridFinder = find.byType(SliverGrid);
      expect(sliverGridFinder, findsOneWidget);

      // Get the SliverGrid widget
      final sliverGrid = tester.widget<SliverGrid>(sliverGridFinder);
      final gridDelegate = sliverGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      // Verify 4 columns
      expect(gridDelegate.crossAxisCount, 4);
    });

    testWidgets('should use 5 columns on large screen (>900px)', (tester) async {
      // Set large screen size (desktop)
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                MasonryGridView(
                  mediaList: testMediaList,
                  onItemTap: (index) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Find the SliverGrid
      final sliverGridFinder = find.byType(SliverGrid);
      expect(sliverGridFinder, findsOneWidget);

      // Get the SliverGrid widget
      final sliverGrid = tester.widget<SliverGrid>(sliverGridFinder);
      final gridDelegate = sliverGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      // Verify 5 columns
      expect(gridDelegate.crossAxisCount, 5);
    });

    testWidgets('should apply 12px grid gap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                MasonryGridView(
                  mediaList: testMediaList,
                  onItemTap: (index) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Find the SliverGrid
      final sliverGridFinder = find.byType(SliverGrid);
      expect(sliverGridFinder, findsOneWidget);

      // Get the SliverGrid widget
      final sliverGrid = tester.widget<SliverGrid>(sliverGridFinder);
      final gridDelegate = sliverGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      // Verify 12px spacing
      expect(gridDelegate.crossAxisSpacing, 12);
      expect(gridDelegate.mainAxisSpacing, 12);
    });

    testWidgets('should call onItemTap with correct index when item is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                MasonryGridView(
                  mediaList: testMediaList,
                  onItemTap: (index) {
                    tappedIndex = index;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Tap on the first item
      await tester.tap(find.byType(GridItem).first);
      await tester.pumpAndSettle();

      // Verify callback was called with index 0
      expect(tappedIndex, 0);
    });

    testWidgets('should generate unique hero tags for each item', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                MasonryGridView(
                  mediaList: testMediaList.take(3).toList(),
                  onItemTap: (index) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Find all Hero widgets
      final heroWidgets = tester.widgetList<Hero>(find.byType(Hero));
      final heroTags = heroWidgets.map((hero) => hero.tag).toList();

      // Verify all tags are unique
      expect(heroTags.toSet().length, heroTags.length);

      // Verify tags follow the pattern 'media_{id}'
      expect(heroTags.first, 'media_${testMediaList[0].id}');
    });

    testWidgets('should use SliverChildBuilderDelegate for lazy loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                MasonryGridView(
                  mediaList: testMediaList,
                  onItemTap: (index) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Find the SliverGrid
      final sliverGridFinder = find.byType(SliverGrid);
      expect(sliverGridFinder, findsOneWidget);

      // Get the SliverGrid widget
      final sliverGrid = tester.widget<SliverGrid>(sliverGridFinder);

      // Verify it uses SliverChildBuilderDelegate
      expect(sliverGrid.delegate, isA<SliverChildBuilderDelegate>());
    });

    testWidgets('should handle empty media list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                MasonryGridView(
                  mediaList: [],
                  onItemTap: (index) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Should not find any GridItem widgets
      expect(find.byType(GridItem), findsNothing);
    });

    testWidgets('should render all media items in the list', (tester) async {
      final smallMediaList = testMediaList.take(3).toList();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                MasonryGridView(
                  mediaList: smallMediaList,
                  onItemTap: (index) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Should find exactly 3 GridItem widgets
      expect(find.byType(GridItem), findsNWidgets(3));
    });
  });
}
