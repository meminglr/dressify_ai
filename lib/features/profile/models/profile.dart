/// Profile model for the profile page feature.
///
/// This model represents user profile data with all fields needed for the profile page UI.
/// Validates Requirements 1, 7
class Profile {
  /// Unique identifier for the user
  final String id;

  /// User's full name
  final String fullName;

  /// User's username (e.g., @username)
  final String username;

  /// User's biography/description
  final String? bio;

  /// URL to user's avatar image
  final String? avatarUrl;

  /// URL to user's cover/header image
  final String? coverImageUrl;

  /// When the profile was created
  final DateTime createdAt;

  /// When the profile was last updated
  final DateTime updatedAt;

  Profile({
    required this.id,
    required this.fullName,
    required this.username,
    this.bio,
    this.avatarUrl,
    this.coverImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a Profile instance from JSON data
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      username: json['username'] as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Converts Profile instance to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'username': username,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'coverImageUrl': coverImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy of this Profile with the given fields replaced
  Profile copyWith({
    String? id,
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? coverImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
