import 'profile.dart';
import 'user_stats.dart';

/// ProfileWithStats model combining Profile and UserStats for profile page display.
///
/// This model aggregates profile information with user statistics to provide
/// all necessary data for the profile page in a single object.
/// Validates Requirements 8.4
class ProfileWithStats {
  /// User profile information
  final Profile profile;

  /// User statistics (AI looks, uploads, models counts)
  final UserStats stats;

  ProfileWithStats({
    required this.profile,
    required this.stats,
  });
}