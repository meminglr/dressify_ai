/// MediaType enum representing different types of media content.
///
/// Maps to the database CHECK constraint: type IN ('AI_CREATION', 'MODEL', 'UPLOAD', 'TRENDYOL_PRODUCT')
/// Validates Requirements 11.2, 12.4
enum MediaType {
  /// AI-generated content/looks
  aiCreation('AI_CREATION'),
  
  /// User model photos
  model('MODEL'),
  
  /// User uploaded content
  upload('UPLOAD'),

  /// Trendyol product saved to wardrobe
  trendyolProduct('TRENDYOL_PRODUCT');

  /// Database value for this media type
  final String value;
  
  const MediaType(this.value);

  /// Creates MediaType from database string value
  ///
  /// Returns [upload] as fallback if value is not recognized
  static MediaType fromString(String value) {
    return MediaType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MediaType.upload,
    );
  }
}

/// Media model representing user media content from Supabase media table.
///
/// This model maps to the media table structure and provides JSON serialization.
/// Validates Requirements 11.2, 12.4
class Media {
  /// Unique media ID (UUID)
  final String id;

  /// User ID who owns this media (references auth.users.id)
  final String userId;

  /// Public URL to the media file in storage
  final String imageUrl;

  /// Type of media content
  final MediaType type;

  /// Optional style tag for categorization
  final String? styleTag;

  /// When this media was created
  final DateTime createdAt;

  Media({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.type,
    this.styleTag,
    required this.createdAt,
  });

  /// Creates a Media instance from JSON data
  ///
  /// Expects JSON with keys: id, user_id, image_url, type, style_tag, created_at
  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      imageUrl: json['image_url'] as String,
      type: MediaType.fromString(json['type'] as String),
      styleTag: json['style_tag'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Converts Media instance to JSON for database operations
  ///
  /// Returns JSON with keys: id, user_id, image_url, type, style_tag, created_at
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'image_url': imageUrl,
      'type': type.value,
      'style_tag': styleTag,
      'created_at': createdAt.toIso8601String(),
    };
  }
}