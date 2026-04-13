import 'package:flutter_test/flutter_test.dart';
import 'package:dressifyai/features/profile/models/profile.dart';
import 'package:dressifyai/features/profile/models/user_stats.dart';
import 'package:dressifyai/features/profile/models/media.dart';
import 'package:dressifyai/features/profile/data/mock_profile_data.dart';
import 'package:dressifyai/features/profile/viewmodels/profile_view_model.dart';

/// Checkpoint 4 validation tests for Model and ViewModel layers
void main() {
  group('Checkpoint 4: Model ve ViewModel Doğrulama', () {
    group('Profile Model', () {
      test('fromJson ve toJson çalışıyor', () {
        final profile = MockProfileData.getMockProfile();
        final json = profile.toJson();
        final fromJson = Profile.fromJson(json);

        expect(fromJson.id, profile.id);
        expect(fromJson.fullName, profile.fullName);
        expect(fromJson.username, profile.username);
        expect(fromJson.bio, profile.bio);
        expect(fromJson.avatarUrl, profile.avatarUrl);
      });

      test('copyWith çalışıyor', () {
        final profile = MockProfileData.getMockProfile();
        final copy = profile.copyWith(fullName: 'Test User');

        expect(copy.fullName, 'Test User');
        expect(copy.id, profile.id);
        expect(copy.username, profile.username);
      });
    });

    group('UserStats Model', () {
      test('fromJson ve toJson çalışıyor', () {
        final stats = MockProfileData.getMockStats();
        final json = stats.toJson();
        final fromJson = UserStats.fromJson(json);

        expect(fromJson.aiLooksCount, 24);
        expect(fromJson.uploadsCount, 12);
        expect(fromJson.modelsCount, 8);
      });

      test('copyWith çalışıyor', () {
        final stats = MockProfileData.getMockStats();
        final copy = stats.copyWith(aiLooksCount: 30);

        expect(copy.aiLooksCount, 30);
        expect(copy.uploadsCount, 12);
        expect(copy.modelsCount, 8);
      });
    });

    group('Media Model', () {
      test('fromJson ve toJson çalışıyor', () {
        final mediaList = MockProfileData.getMockMediaList();
        final media = mediaList.first;
        final json = media.toJson();
        final fromJson = Media.fromJson(json);

        expect(fromJson.id, media.id);
        expect(fromJson.type, media.type);
        expect(fromJson.imageUrl, media.imageUrl);
      });

      test('copyWith çalışıyor', () {
        final media = MockProfileData.getMockMediaList().first;
        final copy = media.copyWith(tag: 'NEW-TAG');

        expect(copy.tag, 'NEW-TAG');
        expect(copy.id, media.id);
        expect(copy.type, media.type);
      });

      test('aspectRatio doğru hesaplanıyor', () {
        final media = Media(
          id: 'test',
          type: MediaType.aiLook,
          imageUrl: 'test.jpg',
          createdAt: DateTime.now(),
          width: 400,
          height: 600,
        );

        expect(media.aspectRatio, closeTo(0.667, 0.01));
      });

      test('aspectRatio default değer döndürüyor', () {
        final media = Media(
          id: 'test',
          type: MediaType.aiLook,
          imageUrl: 'test.jpg',
          createdAt: DateTime.now(),
        );

        expect(media.aspectRatio, 1.0);
      });
    });

    group('MockProfileData', () {
      test('getMockProfile geçerli veri döndürüyor', () {
        final profile = MockProfileData.getMockProfile();

        expect(profile.id, isNotEmpty);
        expect(profile.fullName, isNotEmpty);
        expect(profile.username, startsWith('@'));
      });

      test('getMockStats doğru değerleri döndürüyor', () {
        final stats = MockProfileData.getMockStats();

        expect(stats.aiLooksCount, 24);
        expect(stats.uploadsCount, 12);
        expect(stats.modelsCount, 8);
      });

      test('getMockMediaList en az 8 öğe döndürüyor', () {
        final mediaList = MockProfileData.getMockMediaList();

        expect(mediaList.length, greaterThanOrEqualTo(8));
      });

      test('getMockMediaList farklı aspect ratio\'lar içeriyor', () {
        final mediaList = MockProfileData.getMockMediaList();
        final aspectRatios = mediaList.map((m) => m.aspectRatio).toSet();

        expect(aspectRatios.length, greaterThan(1));
      });
    });

    group('ProfileViewModel', () {
      test('initial state doğru', () {
        final viewModel = ProfileViewModel();

        expect(viewModel.isLoading, false);
        expect(viewModel.isError, false);
        expect(viewModel.profile, null);
        expect(viewModel.stats, null);
        expect(viewModel.selectedTabIndex, 0);
      });

      test('loadProfile() veri yüklüyor', () async {
        final viewModel = ProfileViewModel();

        await viewModel.loadProfile(null);

        expect(viewModel.isLoading, false);
        expect(viewModel.profile, isNotNull);
        expect(viewModel.stats, isNotNull);
        expect(viewModel.mediaList, isNotEmpty);
      });

      test('selectTab() filtreleme yapıyor', () async {
        final viewModel = ProfileViewModel();
        await viewModel.loadProfile(null);

        final allCount = viewModel.mediaList.length;

        viewModel.selectTab(1); // AI Looks
        final aiLooksCount = viewModel.mediaList.length;
        expect(aiLooksCount, lessThan(allCount));

        viewModel.selectTab(2); // Uploads
        final uploadsCount = viewModel.mediaList.length;
        expect(uploadsCount, lessThan(allCount));

        viewModel.selectTab(0); // All
        expect(viewModel.mediaList.length, allCount);
      });

      test('refreshProfile() veriyi yeniliyor', () async {
        final viewModel = ProfileViewModel();
        await viewModel.loadProfile(null);

        final oldProfile = viewModel.profile;
        await viewModel.refreshProfile();

        expect(viewModel.profile, isNotNull);
        expect(viewModel.isLoading, false);
      });

      test('clearError() hata durumunu temizliyor', () {
        final viewModel = ProfileViewModel();
        viewModel.clearError();

        expect(viewModel.isError, false);
        expect(viewModel.errorMessage, null);
      });
    });
  });
}
