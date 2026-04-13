/// UserStats model representing user statistics for the profile page.
///
/// This model contains counts of different types of user content.
/// Validates Requirements 1, 7
class UserStats {
  /// Count of AI-generated looks/creations
  final int aiLooksCount;

  /// Count of user uploads
  final int uploadsCount;

  /// Count of user models
  final int modelsCount;

  UserStats({
    required this.aiLooksCount,
    required this.uploadsCount,
    required this.modelsCount,
  });

  /// Creates a UserStats instance from JSON data
  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      aiLooksCount: json['aiLooksCount'] as int,
      uploadsCount: json['uploadsCount'] as int,
      modelsCount: json['modelsCount'] as int,
    );
  }

  /// Converts UserStats instance to JSON format
  Map<String, dynamic> toJson() {
    return {
      'aiLooksCount': aiLooksCount,
      'uploadsCount': uploadsCount,
      'modelsCount': modelsCount,
    };
  }

  /// Creates a copy of this UserStats with the given fields replaced
  UserStats copyWith({
    int? aiLooksCount,
    int? uploadsCount,
    int? modelsCount,
  }) {
    return UserStats(
      aiLooksCount: aiLooksCount ?? this.aiLooksCount,
      uploadsCount: uploadsCount ?? this.uploadsCount,
      modelsCount: modelsCount ?? this.modelsCount,
    );
  }
}
