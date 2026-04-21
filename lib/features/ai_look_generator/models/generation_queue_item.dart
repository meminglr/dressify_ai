import 'generation_request.dart';
import 'generation_status.dart';

/// GenerationQueueItem represents a single entry in the AI look generation queue.
///
/// Tracks the full lifecycle of a generation request from queued through to
/// completed or failed, and carries thumbnail URLs for UI display without
/// requiring a round-trip to the request object.
class GenerationQueueItem {
  /// Unique identifier for this queue item (UUID)
  final String id;

  /// The original generation request payload
  final GenerationRequest request;

  /// Current lifecycle status of this item
  final GenerationStatus status;

  /// When this item was added to the queue
  final DateTime timestamp;

  /// Thumbnail URL of the selected model photo, used for UI display
  final String modelThumbnail;

  /// Thumbnail URLs of the selected wardrobe items, used for UI display
  final List<String> wardrobeThumbnails;

  /// Public URL of the generated AI look image; null until generation completes
  final String? resultImageUrl;

  /// Supabase media ID of the saved result; null until generation completes
  final String? resultMediaId;

  /// Human-readable error message; null unless status is [GenerationStatus.failed]
  final String? errorMessage;

  const GenerationQueueItem({
    required this.id,
    required this.request,
    required this.status,
    required this.timestamp,
    required this.modelThumbnail,
    required this.wardrobeThumbnails,
    this.resultImageUrl,
    this.resultMediaId,
    this.errorMessage,
  });

  /// Returns a copy of this item with the specified fields replaced.
  ///
  /// Useful for immutable state updates in the queue ViewModel.
  GenerationQueueItem copyWith({
    String? id,
    GenerationRequest? request,
    GenerationStatus? status,
    DateTime? timestamp,
    String? modelThumbnail,
    List<String>? wardrobeThumbnails,
    String? resultImageUrl,
    String? resultMediaId,
    String? errorMessage,
  }) {
    return GenerationQueueItem(
      id: id ?? this.id,
      request: request ?? this.request,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      modelThumbnail: modelThumbnail ?? this.modelThumbnail,
      wardrobeThumbnails: wardrobeThumbnails ?? this.wardrobeThumbnails,
      resultImageUrl: resultImageUrl ?? this.resultImageUrl,
      resultMediaId: resultMediaId ?? this.resultMediaId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
