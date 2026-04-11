/// Profile model representing user profile data from Supabase profiles table.
///
/// This model maps to the profiles table structure and provides JSON serialization.
/// Validates Requirements 8.2, 9.4
class Profile {
  /// Unique identifier matching auth.users.id
  final String id;

  /// User's full name
  final String? fullName;

  /// User's biography/description
  final String? bio;

  /// URL to user's avatar image in storage
  final String? avatarUrl;

  /// Timestamp of last profile update
  final DateTime updatedAt;

  Profile({
    required this.id,
    this.fullName,
    this.bio,
    this.avatarUrl,
    required this.updatedAt,
  });

  /// Creates a Profile instance from JSON data
  ///
  /// Expects JSON with keys: id, full_name, bio, avatar_url, updated_at
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Converts Profile instance to JSON format
  ///
  /// Returns JSON with keys: id, full_name, bio, avatar_url, updated_at
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
