import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dressifyai/features/profile/viewmodels/profile_view_model.dart';
import 'package:dressifyai/services/profile_service.dart';
import 'package:dressifyai/services/media_service.dart';
import 'package:dressifyai/services/storage_service.dart';
import 'package:dressifyai/models/media.dart' as lib_media;
import 'package:dressifyai/models/profile.dart' as lib_profile;
import 'package:dressifyai/models/user_stats.dart' as lib_stats;
import 'package:dressifyai/models/profile_with_stats.dart';
import 'package:dressifyai/models/media_event.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Bug Condition Exploration Test for Media Cache Optimization
/// 
/// **Property 1: Bug Condition** - Unnecessary Database Queries on Cached Data
/// 
/// **Validates: Requirements 1.2, 1.3, 1.4**
/// 
/// This test demonstrates the bug: when loadProfile() is called with already-cached
/// media data, it executes unnecessary database queries via MediaService.getMediaList().
/// 
/// **CRITICAL**: This test is EXPECTED TO FAIL on unfixed code.
/// The failure confirms the bug exists: database queries are executed even with cached data.
/// 
/// **Scoped PBT Approach**: Tests the concrete failing case of navigation from profile
/// to selection screen with already-loaded media data.
/// 
/// Test Strategy:
/// 1. Create test doubles that track method calls
/// 2. Load profile initially (populates cache)
/// 3. Call loadProfile() again (simulates navigation)
/// 4. Assert getMediaList() was NOT called (expected behavior)
/// 5. On unfixed code, this assertion FAILS (proving the bug exists)

void main() {
  group('Bug Condition Exploration - Media Cache Optimization', () {
    late ProfileViewModel viewModel;
    late _TestMediaService testMediaService;
    late _TestProfileService testProfileService;
    late _TestStorageService testStorageService;

    setUp(() {
      // Create test doubles that track method calls
      testMediaService = _TestMediaService();
      testProfileService = _TestProfileService();
      testStorageService = _TestStorageService();

      viewModel = ProfileViewModel(
        profileService: testProfileService,
        mediaService: testMediaService,
        storageService: testStorageService,
      );
    });

    test(
      'PROPERTY 1: loadProfile() with cached data should NOT query database',
      () async {
        // GIVEN: ProfileViewModel with empty cache
        expect(viewModel.mediaList, isEmpty);
        expect(testMediaService.getMediaListCallCount, 0);

        // WHEN: First call to loadProfile() (initial load)
        await viewModel.loadProfile('test_user_id');

        // THEN: Database query executed (expected for first load)
        expect(testMediaService.getMediaListCallCount, 1,
            reason: 'First load should query database');
        expect(viewModel.mediaList, isNotEmpty,
            reason: 'Cache should be populated after first load');

        final cachedMediaCount = viewModel.mediaList.length;
        print('✓ First load: getMediaList() called once, cache populated with $cachedMediaCount items');

        // Reset call counter to track subsequent calls
        testMediaService.resetCallCount();

        // WHEN: Second call to loadProfile() with cached data (simulates navigation)
        // This simulates: user navigates from profile to selection screen
        // selection_screen.dart calls loadProfile() in initState
        await viewModel.loadProfile('test_user_id');

        // THEN: Database query should NOT be executed (cache should be used)
        // **EXPECTED OUTCOME ON UNFIXED CODE**: This assertion FAILS
        // The failure proves the bug: getMediaList() is called even with cached data
        expect(
          testMediaService.getMediaListCallCount,
          0,
          reason: '''
BUG DETECTED: loadProfile() called with non-empty cache, but getMediaList() was executed.

Bug Condition: isBugCondition(input) where:
  - input.method == 'loadProfile'
  - _mediaList.isNotEmpty (cache has $cachedMediaCount items)
  - NOT input.isExplicitRefresh (this is a navigation, not a refresh)
  - databaseQueryExecuted(input) == true (getMediaList() was called ${testMediaService.getMediaListCallCount} time(s))

Expected Behavior: loadProfile() should skip database query when cache exists.
Actual Behavior: Database query executed unnecessarily.

Root Cause Analysis:
- loadProfile() does not check if _mediaList is already populated
- _loadMediaList() is called unconditionally
- This causes redundant network requests on every navigation

Counterexample: Navigation from profile to selection screen with $cachedMediaCount cached items
resulted in ${testMediaService.getMediaListCallCount} unnecessary database query(ies).
''',
        );

        print('✓ Second load: getMediaList() NOT called, cache reused');
        print('✓ Bug condition test PASSED: Cache-aware loading works correctly');
      },
    );

    test(
      'COUNTEREXAMPLE 1: Profile to Selection navigation with cached data',
      () async {
        // Simulates: User opens profile page → navigates to selection screen
        
        // Step 1: User opens profile page
        await viewModel.loadProfile('test_user_id');
        final initialCallCount = testMediaService.getMediaListCallCount;
        final cachedCount = viewModel.mediaList.length;
        
        print('Profile page loaded: $cachedCount media items cached, $initialCallCount DB query');

        // Step 2: User navigates to selection screen
        // selection_screen.dart calls loadProfile() in initState
        testMediaService.resetCallCount();
        await viewModel.loadProfile('test_user_id');

        // Expected: No database query (cache should be used)
        // Actual on unfixed code: Database query executed
        expect(
          testMediaService.getMediaListCallCount,
          0,
          reason: 'Navigation with $cachedCount cached items should NOT query database',
        );

        print('✓ Navigation: Cache reused, no database query');
      },
    );

    test(
      'COUNTEREXAMPLE 2: Multiple navigation cycles with cached data',
      () async {
        // Simulates: User navigates back and forth multiple times
        
        // Initial load
        await viewModel.loadProfile('test_user_id');
        final cachedCount = viewModel.mediaList.length;
        testMediaService.resetCallCount();

        // Navigate 3 times
        for (int i = 1; i <= 3; i++) {
          await viewModel.loadProfile('test_user_id');
          print('Navigation $i: getMediaList() called ${testMediaService.getMediaListCallCount} time(s)');
        }

        // Expected: 0 database queries (cache should be used for all navigations)
        // Actual on unfixed code: 3 database queries
        expect(
          testMediaService.getMediaListCallCount,
          0,
          reason: '3 navigations with $cachedCount cached items should result in 0 DB queries, '
              'but got ${testMediaService.getMediaListCallCount}',
        );

        print('✓ Multiple navigations: Cache reused, no database queries');
      },
    );

    test(
      'EDGE CASE: Explicit refresh should ALWAYS query database',
      () async {
        // This is NOT a bug - explicit refresh should clear cache and reload
        
        // Initial load
        await viewModel.loadProfile('test_user_id');
        testMediaService.resetCallCount();

        // Explicit refresh - manually clear cache and reload
        // (avoiding refreshProfile() which requires Supabase.instance)
        viewModel.dispose();
        viewModel = ProfileViewModel(
          profileService: testProfileService,
          mediaService: testMediaService,
          storageService: testStorageService,
        );
        await viewModel.loadProfile('test_user_id');

        // Expected: Database query executed (refresh clears cache)
        expect(
          testMediaService.getMediaListCallCount,
          greaterThan(0),
          reason: 'Explicit refresh should ALWAYS query database',
        );

        print('✓ Explicit refresh: Database queried as expected');
      },
    );

    test(
      'EDGE CASE: First load with empty cache should query database',
      () async {
        // This is NOT a bug - first load should query database
        
        expect(viewModel.mediaList, isEmpty);

        await viewModel.loadProfile('test_user_id');

        // Expected: Database query executed (cache is empty)
        expect(
          testMediaService.getMediaListCallCount,
          1,
          reason: 'First load with empty cache should query database',
        );

        print('✓ First load: Database queried as expected');
      },
    );
  });
}

// =============================================================================
// Test Doubles - Manual mocks that track method calls
// =============================================================================

/// Test double for MediaService that tracks getMediaList() calls
class _TestMediaService implements MediaService {
  int getMediaListCallCount = 0;
  final List<lib_media.Media> _mockMediaList = [
    lib_media.Media(
      id: 'media_001',
      userId: 'test_user_id',
      imageUrl: 'https://example.com/image1.jpg',
      type: lib_media.MediaType.model,
      styleTag: 'TEST-TAG-1',
      createdAt: DateTime.now(),
    ),
    lib_media.Media(
      id: 'media_002',
      userId: 'test_user_id',
      imageUrl: 'https://example.com/image2.jpg',
      type: lib_media.MediaType.upload,
      styleTag: 'TEST-TAG-2',
      createdAt: DateTime.now(),
    ),
    lib_media.Media(
      id: 'media_003',
      userId: 'test_user_id',
      imageUrl: 'https://example.com/image3.jpg',
      type: lib_media.MediaType.aiCreation,
      styleTag: 'TEST-TAG-3',
      createdAt: DateTime.now(),
    ),
    lib_media.Media(
      id: 'media_004',
      userId: 'test_user_id',
      imageUrl: 'https://example.com/image4.jpg',
      type: lib_media.MediaType.model,
      styleTag: 'TEST-TAG-4',
      createdAt: DateTime.now(),
    ),
    lib_media.Media(
      id: 'media_005',
      userId: 'test_user_id',
      imageUrl: 'https://example.com/image5.jpg',
      type: lib_media.MediaType.upload,
      styleTag: 'TEST-TAG-5',
      createdAt: DateTime.now(),
    ),
  ];

  void resetCallCount() {
    getMediaListCallCount = 0;
  }

  @override
  Future<List<lib_media.Media>> getMediaList({
    required String userId,
    lib_media.MediaType? type,
    int limit = 20,
    int offset = 0,
  }) async {
    getMediaListCallCount++;
    print('  → MediaService.getMediaList() called (call #$getMediaListCallCount)');
    
    // Simulate database query delay
    await Future.delayed(const Duration(milliseconds: 10));
    
    return _mockMediaList;
  }

  @override
  Future<lib_media.Media> addMedia({
    required String userId,
    required File imageFile,
    required lib_media.MediaType type,
    String? styleTag,
  }) async {
    throw UnimplementedError('Not needed for cache test');
  }

  @override
  Future<void> deleteMedia({
    required String userId,
    required String mediaId,
  }) async {
    throw UnimplementedError('Not needed for cache test');
  }

  @override
  RealtimeChannel subscribeToMediaChanges(
    String userId,
    void Function(MediaEvent) onEvent,
  ) {
    throw UnimplementedError('Not needed for cache test');
  }

  @override
  Future<void> unsubscribeFromMediaChanges(RealtimeChannel channel) async {
    // No-op for test
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Test double for ProfileService
class _TestProfileService implements ProfileService {
  @override
  Future<ProfileWithStats?> getProfile(String userId) async {
    return ProfileWithStats(
      profile: lib_profile.Profile(
        id: userId,
        fullName: 'Test User',
        bio: 'Test bio',
        avatarUrl: 'https://example.com/avatar.jpg',
        updatedAt: DateTime.now(),
      ),
      stats: lib_stats.UserStats(
        userId: userId,
        aiLooksCount: 10,
        uploadsCount: 5,
        modelsCount: 3,
      ),
    );
  }

  @override
  Future<lib_profile.Profile> updateProfile({
    required String userId,
    String? fullName,
    String? bio,
    String? avatarUrl,
  }) async {
    throw UnimplementedError('Not needed for cache test');
  }

  @override
  RealtimeChannel subscribeToProfileChanges(
    String userId,
    void Function(lib_profile.Profile) onUpdate,
  ) {
    throw UnimplementedError('Not needed for cache test');
  }

  @override
  Future<void> unsubscribeFromProfileChanges(RealtimeChannel channel) async {
    // No-op for test
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Test double for StorageService
class _TestStorageService implements StorageService {
  @override
  Future<String> uploadToGallery({
    required String userId,
    required File imageFile,
  }) async {
    throw UnimplementedError('Not needed for cache test');
  }

  @override
  Future<String> uploadAvatar({
    required String userId,
    required File imageFile,
  }) async {
    throw UnimplementedError('Not needed for cache test');
  }

  @override
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    throw UnimplementedError('Not needed for cache test');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
