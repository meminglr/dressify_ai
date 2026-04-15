/// MediaType enum representing different types of media content.
///
/// Validates Requirements 1, 7
enum MediaType {
  /// AI-generated content/looks
  aiLook,

  /// User uploaded content
  upload,

  /// User model photos
  model,

  /// Trendyol products saved to wardrobe
  trendyolProduct,
}

/// Media model representing user media content for the profile page.
///
/// This model contains media information including dimensions for masonry layout.
/// Validates Requirements 1, 7
class Media {
  /// Unique media ID
  final String id;

  /// Type of media content
  final MediaType type;

  /// Public URL to the media file
  final String imageUrl;

  /// Optional style tag for categorization
  final String? tag;

  /// When this media was created
  final DateTime createdAt;

  /// Image width in pixels (optional, for aspect ratio calculation)
  final int? width;

  /// Image height in pixels (optional, for aspect ratio calculation)
  final int? height;

  Media({
    required this.id,
    required this.type,
    required this.imageUrl,
    this.tag,
    required this.createdAt,
    this.width,
    this.height,
  });

  /// Calculates aspect ratio for masonry layout
  ///
  /// Returns width/height ratio if both dimensions are available and valid.
  /// Returns 1.0 (square) as default if dimensions are not available.
  double get aspectRatio {
    if (width != null && height != null && width! > 0 && height! > 0) {
      return width! / height!;
    }
    return 1.0; // Default square aspect ratio
  }

  /// Creates a Media instance from JSON data
  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'] as String,
      type: MediaType.values.firstWhere(
        (e) => e.toString() == 'MediaType.${json['type']}',
      ),
      imageUrl: json['imageUrl'] as String,
      tag: json['tag'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }

  /// Converts Media instance to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'imageUrl': imageUrl,
      'tag': tag,
      'createdAt': createdAt.toIso8601String(),
      'width': width,
      'height': height,
    };
  }

  /// Creates a copy of this Media with the given fields replaced
  Media copyWith({
    String? id,
    MediaType? type,
    String? imageUrl,
    String? tag,
    DateTime? createdAt,
    int? width,
    int? height,
  }) {
    return Media(
      id: id ?? this.id,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      tag: tag ?? this.tag,
      createdAt: createdAt ?? this.createdAt,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}
