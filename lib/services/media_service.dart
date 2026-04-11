import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/media.dart';
import '../models/media_event.dart';
import '../exceptions/media_exception.dart';
import 'storage_service.dart';

/// Service for managing user media content operations
/// 
/// This service handles media CRUD operations, file uploads/deletions,
/// and Realtime subscriptions for media changes. It integrates with
/// StorageService for file management and Supabase for database operations.
/// 
/// Validates Requirements 11.1, 12.1, 13.1
class MediaService {
  final SupabaseClient _client;
  final StorageService _storageService;
  
  /// Creates a new MediaService instance
  /// 
  /// [client] - The Supabase client instance for database operations
  /// [storageService] - The storage service for file operations
  MediaService(this._client, this._storageService);
  
  /// Fetches paginated media list with optional type filter
  /// 
  /// Returns media items ordered by creation date (newest first).
  /// Supports filtering by media type and pagination.
  /// 
  /// [userId] - The user ID to fetch media for
  /// [type] - Optional media type filter (AI_CREATION, MODEL, UPLOAD)
  /// [limit] - Maximum number of items to return (default: 20)
  /// [offset] - Number of items to skip for pagination (default: 0)
  /// 
  /// Returns list of Media objects
  /// Throws [MediaException] on failure
  /// 
  /// Validates Requirements 11.1
  Future<List<Media>> getMediaList({
    required String userId,
    MediaType? type,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      PostgrestFilterBuilder query = _client
          .from('media')
          .select()
          .eq('user_id', userId);
      
      // Apply type filter if specified
      if (type != null) {
        query = query.eq('type', type.value);
      }
      
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return (response as List<dynamic>)
          .map((json) => Media.fromJson(json as Map<String, dynamic>))
          .toList();
          
    } on PostgrestException catch (e) {
      debugPrint('MediaService.getMediaList error: ${e.message}');
      throw MediaException(
        _getErrorMessage(e.code),
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      debugPrint('MediaService.getMediaList unexpected error: $e');
      throw MediaException(
        'Medya listesi alınırken bir hata oluştu',
        originalError: e,
      );
    }
  }
  /// Adds new media (uploads file and creates DB record)
  /// 
  /// First uploads the image file to gallery storage, then creates
  /// a database record with the file URL and metadata.
  /// 
  /// [userId] - The user ID who owns this media
  /// [imageFile] - The image file to upload
  /// [type] - The type of media content
  /// [styleTag] - Optional style tag for categorization
  /// 
  /// Returns the created Media object
  /// Throws [MediaException] on failure
  /// 
  /// Validates Requirements 12.1
  Future<Media> addMedia({
    required String userId,
    required File imageFile,
    required MediaType type,
    String? styleTag,
  }) async {
    try {
      // Upload file to storage first
      final imageUrl = await _storageService.uploadToGallery(
        userId: userId,
        imageFile: imageFile,
      );
      
      // Create database record
      final mediaData = {
        'user_id': userId,
        'image_url': imageUrl,
        'type': type.value,
        'style_tag': styleTag,
      };
      
      final response = await _client
          .from('media')
          .insert(mediaData)
          .select()
          .single();
      
      return Media.fromJson(response);
      
    } on MediaException {
      // Re-throw MediaException from storage service
      rethrow;
    } on PostgrestException catch (e) {
      debugPrint('MediaService.addMedia error: ${e.message}');
      throw MediaException(
        _getErrorMessage(e.code),
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      debugPrint('MediaService.addMedia unexpected error: $e');
      throw MediaException(
        'Medya eklenirken bir hata oluştu',
        originalError: e,
      );
    }
  }
  
  /// Deletes media (removes file and DB record)
  /// 
  /// First fetches the media record to get the image URL,
  /// then deletes the file from storage and removes the database record.
  /// 
  /// [userId] - The user ID who owns this media
  /// [mediaId] - The ID of the media to delete
  /// 
  /// Throws [MediaException] on failure
  /// 
  /// Validates Requirements 13.1
  Future<void> deleteMedia({
    required String userId,
    required String mediaId,
  }) async {
    try {
      // First get the media record to extract file path from URL
      final mediaResponse = await _client
          .from('media')
          .select('image_url')
          .eq('id', mediaId)
          .eq('user_id', userId)
          .single();
      
      final imageUrl = mediaResponse['image_url'] as String;
      
      // Extract file path from URL for storage deletion
      final filePath = _extractFilePathFromUrl(imageUrl, userId);
      
      // Delete file from storage
      await _storageService.deleteFile(
        bucket: 'gallery',
        path: filePath,
      );
      
      // Delete database record
      await _client
          .from('media')
          .delete()
          .eq('id', mediaId)
          .eq('user_id', userId);
          
    } on PostgrestException catch (e) {
      debugPrint('MediaService.deleteMedia error: ${e.message}');
      throw MediaException(
        _getErrorMessage(e.code),
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      debugPrint('MediaService.deleteMedia unexpected error: $e');
      throw MediaException(
        'Medya silinirken bir hata oluştu',
        originalError: e,
      );
    }
  }
  /// Subscribes to media changes via Realtime
  /// 
  /// Creates a Realtime subscription to listen for INSERT and DELETE
  /// events on the media table for the specified user.
  /// 
  /// [userId] - The user ID to listen for changes
  /// [onEvent] - Callback function called when media events occur
  /// 
  /// Returns RealtimeChannel for cleanup
  /// 
  /// Validates Requirements 15.1
  RealtimeChannel subscribeToMediaChanges(
    String userId,
    void Function(MediaEvent) onEvent,
  ) {
    final channel = _client
        .channel('media_changes_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'media',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              final event = MediaEvent.fromRealtimeEvent(
                eventType: 'INSERT',
                record: payload.newRecord,
              );
              onEvent(event);
            } catch (e) {
              debugPrint('Error processing media insert event: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'media',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              final event = MediaEvent.fromRealtimeEvent(
                eventType: 'DELETE',
                record: payload.oldRecord,
              );
              onEvent(event);
            } catch (e) {
              debugPrint('Error processing media delete event: $e');
            }
          },
        )
        .subscribe();
    
    return channel;
  }
  
  /// Unsubscribes from media changes
  /// 
  /// Properly cleans up the Realtime subscription to prevent memory leaks.
  /// 
  /// [channel] - The RealtimeChannel to unsubscribe from
  /// 
  /// Validates Requirements 15.1
  Future<void> unsubscribeFromMediaChanges(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
  /// Extracts file path from storage URL for deletion
  /// 
  /// Supabase storage URLs have format:
  /// https://project.supabase.co/storage/v1/object/public/bucket/path
  /// This method extracts the path part for storage operations.
  /// 
  /// [imageUrl] - The full storage URL
  /// [userId] - The user ID for validation
  /// 
  /// Returns the file path within the bucket
  String _extractFilePathFromUrl(String imageUrl, String userId) {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the bucket segment and extract path after it
      final bucketIndex = pathSegments.indexOf('gallery');
      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        throw MediaException('Geçersiz resim URL formatı');
      }
      
      // Extract path segments after bucket name
      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
      
      // Validate that the path starts with user ID for security
      if (!filePath.startsWith(userId)) {
        throw MediaException('Yetkisiz dosya erişimi');
      }
      
      return filePath;
      
    } catch (e) {
      throw MediaException(
        'Dosya yolu çıkarılırken hata oluştu',
        originalError: e,
      );
    }
  }
  
  /// Maps PostgreSQL error codes to user-friendly messages
  /// 
  /// [code] - The PostgreSQL error code
  /// 
  /// Returns user-friendly error message in Turkish
  String _getErrorMessage(String? code) {
    switch (code) {
      case '23505': // unique_violation
        return 'Bu kayıt zaten mevcut';
      case '23503': // foreign_key_violation
        return 'İlişkili kayıt bulunamadı';
      case '42501': // insufficient_privilege
        return 'Bu işlem için yetkiniz yok';
      case 'PGRST116': // no rows returned
        return 'Kayıt bulunamadı';
      default:
        return 'Bir hata oluştu';
    }
  }
}