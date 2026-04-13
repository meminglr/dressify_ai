import '../models/profile.dart';
import '../models/user_stats.dart';
import '../models/media.dart';

/// Mock data provider for profile page development and testing.
///
/// Provides realistic test data with Turkish names and varied media items.
/// Validates Requirement 9
class MockProfileData {
  /// Returns a mock Profile instance with realistic Turkish user data
  static Profile getMockProfile() {
    return Profile(
      id: 'user_001',
      fullName: 'Ayşe Yılmaz',
      username: '@ayseyilmaz',
      bio: 'Dijital Moda Küratörü | AI ile Stil Yaratıcısı',
      avatarUrl: 'https://i.pravatar.cc/300?img=47',
      coverImageUrl: 'https://images.unsplash.com/photo-1558769132-cb1aea3c8565?w=1200&h=400&fit=crop',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now(),
    );
  }

  /// Returns mock UserStats with specified counts
  ///
  /// aiLooksCount: 24, uploadsCount: 12, modelsCount: 8
  static UserStats getMockStats() {
    return UserStats(
      aiLooksCount: 24,
      uploadsCount: 12,
      modelsCount: 8,
    );
  }

  /// Returns a list of mock Media items with varied aspect ratios
  ///
  /// Contains at least 8 different media items with different types and dimensions
  /// for masonry layout testing.
  static List<Media> getMockMediaList() {
    return [
      // AI Look - Portrait (2:3 ratio)
      Media(
        id: 'media_001',
        type: MediaType.aiLook,
        imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400&h=600&fit=crop',
        tag: 'NEO-STREETWEAR',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        width: 400,
        height: 600,
      ),
      
      // AI Look - Square (1:1 ratio)
      Media(
        id: 'media_002',
        type: MediaType.aiLook,
        imageUrl: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=400&h=400&fit=crop',
        tag: 'MİNİMALİST',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        width: 400,
        height: 400,
      ),
      
      // Upload - Tall portrait (9:16 ratio)
      Media(
        id: 'media_003',
        type: MediaType.upload,
        imageUrl: 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=400&h=711&fit=crop',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        width: 400,
        height: 711,
      ),
      
      // Model - Medium portrait (3:4 ratio)
      Media(
        id: 'media_004',
        type: MediaType.model,
        imageUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400&h=533&fit=crop',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        width: 400,
        height: 533,
      ),
      
      // AI Look - Wide (4:3 ratio)
      Media(
        id: 'media_005',
        type: MediaType.aiLook,
        imageUrl: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=533&h=400&fit=crop',
        tag: 'VINTAGE',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        width: 533,
        height: 400,
      ),
      
      // Upload - Portrait (2:3 ratio)
      Media(
        id: 'media_006',
        type: MediaType.upload,
        imageUrl: 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=400&h=600&fit=crop',
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
        width: 400,
        height: 600,
      ),
      
      // AI Look - Tall (3:5 ratio)
      Media(
        id: 'media_007',
        type: MediaType.aiLook,
        imageUrl: 'https://images.unsplash.com/photo-1487222477894-8943e31ef7b2?w=400&h=667&fit=crop',
        tag: 'BOHEM',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        width: 400,
        height: 667,
      ),
      
      // Model - Square (1:1 ratio)
      Media(
        id: 'media_008',
        type: MediaType.model,
        imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=400&fit=crop',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        width: 400,
        height: 400,
      ),
      
      // AI Look - Portrait (2:3 ratio)
      Media(
        id: 'media_009',
        type: MediaType.aiLook,
        imageUrl: 'https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=400&h=600&fit=crop',
        tag: 'MODERN',
        createdAt: DateTime.now().subtract(const Duration(days: 9)),
        width: 400,
        height: 600,
      ),
      
      // Upload - Medium (3:4 ratio)
      Media(
        id: 'media_010',
        type: MediaType.upload,
        imageUrl: 'https://images.unsplash.com/photo-1502716119720-b23a93e5fe1b?w=400&h=533&fit=crop',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        width: 400,
        height: 533,
      ),
    ];
  }
}
