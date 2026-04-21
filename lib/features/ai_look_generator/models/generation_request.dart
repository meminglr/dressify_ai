import 'garment_data.dart';

/// GenerationRequest represents the payload sent to the n8n API for AI look generation.
///
/// Contains the authenticated user's ID, the model photo URL, and the list of
/// garments to virtually try on.
class GenerationRequest {
  /// The authenticated user's ID (references auth.users.id)
  final String userId;

  /// Public URL to the model/person photo used as the base image
  final String personImageUrl;

  /// List of garments to apply in the virtual try-on (1–5 items)
  final List<GarmentData> garments;

  const GenerationRequest({
    required this.userId,
    required this.personImageUrl,
    required this.garments,
  });

  /// Converts this request to a JSON map for the n8n API payload.
  ///
  /// Keys follow the n8n webhook contract: user_id, person_image_url, garments.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'person_image_url': personImageUrl,
      'garments': garments.map((g) => g.toJson()).toList(),
    };
  }
}
