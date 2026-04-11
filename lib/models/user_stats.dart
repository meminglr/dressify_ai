/// UserStats model representing user statistics from Supabase user_stats view.
///
/// This model maps to the user_stats view structure and provides JSON deserialization.
/// Validates Requirements 3.1, 8.4
class UserStats {
  /// User ID matching auth.users.id
  final String userId;

  /// Count of AI-generated looks/creations
  final int aiLooksCount;

  /// Count of user uploads
  final int uploadsCount;

  /// Count of user models
  final int modelsCount;

  UserStats({
    required this.userId,
    required this.aiLooksCount,
    required this.uploadsCount,
    required this.modelsCount,
  });

  /// Creates a UserStats instance from JSON data
  ///
  /// Expects JSON with keys: user_id, ai_looks_count, uploads_count, models_count
  /// Defaults counts to 0 if null (handles cases where user has no media)
  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      userId: json['user_id'] as String,
      aiLooksCount: json['ai_looks_count'] as int? ?? 0,
      uploadsCount: json['uploads_count'] as int? ?? 0,
      modelsCount: json['models_count'] as int? ?? 0,
    );
  }
}