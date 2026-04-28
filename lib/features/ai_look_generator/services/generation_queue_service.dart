import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/generation_queue_item.dart';
import '../models/generation_status.dart';
import '../models/generation_request.dart';

/// Service for managing AI look generation queue in Supabase.
///
/// Handles CRUD operations for generation queue items, including:
/// - Creating new queue items
/// - Updating status and results
/// - Fetching queue and history
/// - Real-time subscriptions
class GenerationQueueService {
  final SupabaseClient _supabase;

  GenerationQueueService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Fetches active queue items (queued or processing) for the current user.
  ///
  /// Returns items ordered by creation time (oldest first - FIFO).
  Future<List<GenerationQueueItem>> fetchActiveQueue() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('generation_queue')
        .select()
        .eq('user_id', userId)
        .inFilter('status', ['queued', 'processing'])
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => _mapFromJson(json))
        .toList();
  }

  /// Fetches completed and failed items (history) for the current user.
  ///
  /// Returns items ordered by completion time (newest first).
  /// [limit] defaults to 50 items.
  Future<List<GenerationQueueItem>> fetchHistory({int limit = 50}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('generation_queue')
        .select()
        .eq('user_id', userId)
        .inFilter('status', ['completed', 'failed'])
        .order('completed_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => _mapFromJson(json))
        .toList();
  }

  /// Creates a new queue item in Supabase.
  ///
  /// Returns the created item with server-generated ID and timestamp.
  Future<GenerationQueueItem> createQueueItem({
    required String modelMediaId,
    required String modelThumbnail,
    required List<String> wardrobeMediaIds,
    required List<String> wardrobeThumbnails,
    required GenerationRequest request,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final data = {
      'user_id': userId,
      'model_media_id': modelMediaId,
      'model_thumbnail': modelThumbnail,
      'wardrobe_media_ids': wardrobeMediaIds,
      'wardrobe_thumbnails': wardrobeThumbnails,
      'status': 'queued',
    };

    final response = await _supabase
        .from('generation_queue')
        .insert(data)
        .select()
        .single();

    return _mapFromJson(response, request: request);
  }

  /// Updates queue item status to 'processing'.
  Future<void> markAsProcessing(String itemId) async {
    await _supabase
        .from('generation_queue')
        .update({
          'status': 'processing',
          'started_at': DateTime.now().toIso8601String(),
        })
        .eq('id', itemId);
  }

  /// Updates queue item with successful result.
  Future<void> markAsCompleted({
    required String itemId,
    required String resultImageUrl,
    required String resultMediaId,
    required DateTime startedAt,
  }) async {
    final completedAt = DateTime.now();
    final duration = completedAt.difference(startedAt).inSeconds;

    await _supabase
        .from('generation_queue')
        .update({
          'status': 'completed',
          'result_image_url': resultImageUrl,
          'result_media_id': resultMediaId,
          'completed_at': completedAt.toIso8601String(),
          'processing_duration_seconds': duration,
        })
        .eq('id', itemId);
  }

  /// Updates queue item with failure information.
  Future<void> markAsFailed({
    required String itemId,
    required String errorMessage,
    DateTime? startedAt,
  }) async {
    final completedAt = DateTime.now();
    final data = <String, dynamic>{
      'status': 'failed',
      'error_message': errorMessage,
      'completed_at': completedAt.toIso8601String(),
    };

    if (startedAt != null) {
      data['processing_duration_seconds'] = 
          completedAt.difference(startedAt).inSeconds;
    }

    await _supabase
        .from('generation_queue')
        .update(data)
        .eq('id', itemId);
  }

  /// Deletes a queue item from history.
  Future<void> deleteQueueItem(String itemId) async {
    await _supabase
        .from('generation_queue')
        .delete()
        .eq('id', itemId);
  }

  /// Deletes all completed and failed items for the current user.
  Future<void> clearHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('generation_queue')
        .delete()
        .eq('user_id', userId)
        .inFilter('status', ['completed', 'failed']);
  }

  /// Subscribes to real-time changes in the generation queue.
  ///
  /// Calls [onInsert], [onUpdate], or [onDelete] when changes occur.
  RealtimeChannel subscribeToQueue({
    required void Function(GenerationQueueItem) onInsert,
    required void Function(GenerationQueueItem) onUpdate,
    required void Function(String itemId) onDelete,
  }) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final channel = _supabase
        .channel('generation_queue_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'generation_queue',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final item = _mapFromJson(payload.newRecord);
            onInsert(item);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'generation_queue',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final item = _mapFromJson(payload.newRecord);
            onUpdate(item);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'generation_queue',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final itemId = payload.oldRecord['id'] as String;
            onDelete(itemId);
          },
        )
        .subscribe();

    return channel;
  }

  /// Unsubscribes from real-time changes.
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }

  // ---------------------------------------------------------------------------
  // Mapping helpers
  // ---------------------------------------------------------------------------

  GenerationQueueItem _mapFromJson(
    Map<String, dynamic> json, {
    GenerationRequest? request,
  }) {
    final status = _parseStatus(json['status'] as String);
    
    // If request is not provided, create a minimal one from stored data
    final generationRequest = request ?? GenerationRequest(
      userId: json['user_id'] as String,
      personImageUrl: json['model_thumbnail'] as String,
      garments: [], // We don't store full garment details, only thumbnails
    );

    return GenerationQueueItem(
      id: json['id'] as String,
      request: generationRequest,
      status: status,
      timestamp: DateTime.parse(json['created_at'] as String),
      modelThumbnail: json['model_thumbnail'] as String,
      wardrobeThumbnails: (json['wardrobe_thumbnails'] as List)
          .map((e) => e as String)
          .toList(),
      resultImageUrl: json['result_image_url'] as String?,
      resultMediaId: json['result_media_id'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }

  GenerationStatus _parseStatus(String status) {
    return switch (status) {
      'queued' => GenerationStatus.queued,
      'processing' => GenerationStatus.processing,
      'completed' => GenerationStatus.completed,
      'failed' => GenerationStatus.failed,
      _ => GenerationStatus.queued,
    };
  }
}
