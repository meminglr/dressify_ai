import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dressifyai/features/profile/models/profile.dart';
import 'package:dressifyai/features/profile/models/user_stats.dart';
import 'package:dressifyai/features/profile/widgets/profile_info_section.dart';
import 'package:dressifyai/features/profile/widgets/stats_overlay.dart';

void main() {
  group('ProfileInfoSection Widget Tests', () {
    late Profile testProfile;
    late UserStats testStats;

    setUp(() {
      testProfile = Profile(
        id: 'test_001',
        fullName: 'Alex Rivera',
        username: '@alexrivera',
        bio: 'Digital Fashion Curator',
        avatarUrl: null, // Use null to avoid network image loading in tests
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testStats = UserStats(
        aiLooksCount: 24,
        uploadsCount: 12,
        modelsCount: 8,
      );
    });

    testWidgets('should display profile name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileInfoSection(
              profile: testProfile,
              stats: testStats,
            ),
          ),
        ),
      );

      expect(find.text('Alex Rivera'), findsOneWidget);
    });

    testWidgets('should display bio when available', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileInfoSection(
              profile: testProfile,
              stats: testStats,
            ),
          ),
        ),
      );

      expect(find.text('Digital Fashion Curator'), findsOneWidget);
    });

    testWidgets('should not display bio when null', (tester) async {
      final profileWithoutBio = Profile(
        id: 'test_001',
        fullName: 'Alex Rivera',
        username: '@alexrivera',
        bio: null, // Explicitly null
        avatarUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileInfoSection(
              profile: profileWithoutBio,
              stats: testStats,
            ),
          ),
        ),
      );

      expect(find.text('Digital Fashion Curator'), findsNothing);
    });

    testWidgets('should not display bio when empty', (tester) async {
      final profileWithEmptyBio = testProfile.copyWith(bio: '');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileInfoSection(
              profile: profileWithEmptyBio,
              stats: testStats,
            ),
          ),
        ),
      );

      // Should not find bio text (only name and stats labels)
      expect(find.text(''), findsNothing);
    });

    testWidgets('should display CircleAvatar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileInfoSection(
              profile: testProfile,
              stats: testStats,
            ),
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('should display placeholder icon when avatarUrl is null', (tester) async {
      final profileWithoutAvatar = testProfile.copyWith(avatarUrl: null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileInfoSection(
              profile: profileWithoutAvatar,
              stats: testStats,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('should integrate StatsOverlay widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileInfoSection(
              profile: testProfile,
              stats: testStats,
            ),
          ),
        ),
      );

      expect(find.byType(StatsOverlay), findsOneWidget);
    });

    testWidgets('should pass correct stats to StatsOverlay', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileInfoSection(
              profile: testProfile,
              stats: testStats,
            ),
          ),
        ),
      );

      final statsOverlay = tester.widget<StatsOverlay>(find.byType(StatsOverlay));
      expect(statsOverlay.aiLooksCount, 24);
      expect(statsOverlay.uploadsCount, 12);
      expect(statsOverlay.modelsCount, 8);
    });
  });
}
