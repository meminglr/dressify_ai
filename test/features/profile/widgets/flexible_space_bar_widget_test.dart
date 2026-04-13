import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dressifyai/features/profile/models/profile.dart';
import 'package:dressifyai/features/profile/models/user_stats.dart';
import 'package:dressifyai/features/profile/widgets/flexible_space_bar_widget.dart';
import 'package:dressifyai/features/profile/widgets/profile_info_section.dart';

void main() {
  group('FlexibleSpaceBarWidget Tests', () {
    late Profile testProfile;
    late UserStats testStats;

    setUp(() {
      testProfile = Profile(
        id: 'test_001',
        fullName: 'Alex Rivera',
        username: '@alexrivera',
        bio: 'Digital Fashion Curator',
        avatarUrl: null,
        coverImageUrl: null, // Use null to avoid network image loading in tests
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testStats = UserStats(
        aiLooksCount: 24,
        uploadsCount: 12,
        modelsCount: 8,
      );
    });

    testWidgets('should create FlexibleSpaceBar widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: FlexibleSpaceBarWidget.expandedHeight,
                  flexibleSpace: FlexibleSpaceBarWidget(
                    profile: testProfile,
                    stats: testStats,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(FlexibleSpaceBar), findsOneWidget);
    });

    testWidgets('should integrate ProfileInfoSection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: FlexibleSpaceBarWidget.expandedHeight,
                  flexibleSpace: FlexibleSpaceBarWidget(
                    profile: testProfile,
                    stats: testStats,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ProfileInfoSection), findsOneWidget);
    });

    testWidgets('should pass correct profile to ProfileInfoSection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: FlexibleSpaceBarWidget.expandedHeight,
                  flexibleSpace: FlexibleSpaceBarWidget(
                    profile: testProfile,
                    stats: testStats,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final profileInfoSection = tester.widget<ProfileInfoSection>(
        find.byType(ProfileInfoSection),
      );
      expect(profileInfoSection.profile.fullName, 'Alex Rivera');
      expect(profileInfoSection.stats.aiLooksCount, 24);
    });

    testWidgets('should display default gradient background when no cover image', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: FlexibleSpaceBarWidget.expandedHeight,
                  flexibleSpace: FlexibleSpaceBarWidget(
                    profile: testProfile,
                    stats: testStats,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the widget renders without errors
      expect(find.byType(FlexibleSpaceBarWidget), findsOneWidget);
    });

    testWidgets('should have correct expanded height constant', (tester) async {
      expect(FlexibleSpaceBarWidget.expandedHeight, 480.0);
    });

    testWidgets('should have correct collapsed height constant', (tester) async {
      expect(FlexibleSpaceBarWidget.collapsedHeight, 56.0);
    });

    testWidgets('should use parallax collapse mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: FlexibleSpaceBarWidget.expandedHeight,
                  flexibleSpace: FlexibleSpaceBarWidget(
                    profile: testProfile,
                    stats: testStats,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final flexibleSpaceBar = tester.widget<FlexibleSpaceBar>(
        find.byType(FlexibleSpaceBar),
      );
      expect(flexibleSpaceBar.collapseMode, CollapseMode.parallax);
    });

    testWidgets('should have ClipRRect with border radius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: FlexibleSpaceBarWidget.expandedHeight,
                  flexibleSpace: FlexibleSpaceBarWidget(
                    profile: testProfile,
                    stats: testStats,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Find ClipRRect widgets
      final clipRRectFinder = find.descendant(
        of: find.byType(FlexibleSpaceBarWidget),
        matching: find.byType(ClipRRect),
      );

      expect(clipRRectFinder, findsWidgets);
    });

    testWidgets('should render with cover image URL', (tester) async {
      final profileWithCover = testProfile.copyWith(
        coverImageUrl: 'https://example.com/cover.jpg',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: FlexibleSpaceBarWidget.expandedHeight,
                  flexibleSpace: FlexibleSpaceBarWidget(
                    profile: profileWithCover,
                    stats: testStats,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Widget should render without errors even with network image
      expect(find.byType(FlexibleSpaceBarWidget), findsOneWidget);
    });
  });
}
