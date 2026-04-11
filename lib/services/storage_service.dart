import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' hide StorageException;
import 'package:uuid/uuid.dart';
import '../exceptions/storage_exception.dart';

/// Service for managing Supabase Storage operations
/// 
/// This service handles file uploads, deletions, and URL generation
/// for both avatar and gallery buckets with proper RLS security.
class StorageService {
  final SupabaseClient _client;
  final Uuid _uuid = const Uuid();
  
  /// Creates a new StorageService instance
  /// 
  /// [client] - The Supabase client instance for storage operations
  StorageService(this._client);
  
  /// Uploads avatar image to the avatars bucket
  /// 
  /// Deletes old avatar if exists and uploads new one.
  /// File path format: {userId}/{uuid}.{extension}
  /// 
  /// [userId] - The user ID for folder organization
  /// [imageFile] - The image file to upload
  /// 
  /// Returns the public URL of the uploaded avatar
  /// Throws [StorageException] on failure
  Future<String> uploadAvatar({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Get file extension
      final extension = _getFileExtension(imageFile.path);
      
      // Generate unique file path
      final filePath = _generateFilePath(userId, extension);
      
      // Delete old avatar if exists
      await _deleteOldAvatar(userId);
      
      // Upload new avatar
      await _client.storage
          .from('avatars')
          .upload(filePath, imageFile);
      
      // Get public URL
      final publicUrl = _client.storage
          .from('avatars')
          .getPublicUrl(filePath);
      
      return publicUrl;
      
    } on StorageException catch (e) {
      throw StorageException(
        'Avatar yüklenirken hata oluştu: ${e.message}',
        code: e.code,
        originalError: e.originalError,
      );
    } catch (e) {
      throw StorageException(
        'Avatar yüklenirken beklenmeyen bir hata oluştu',
        originalError: e,
      );
    }
  }
  
  /// Uploads image to the gallery bucket
  /// 
  /// File path format: {userId}/{uuid}.{extension}
  /// 
  /// [userId] - The user ID for folder organization
  /// [imageFile] - The image file to upload
  /// 
  /// Returns the public URL of the uploaded image
  /// Throws [StorageException] on failure
  Future<String> uploadToGallery({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Get file extension
      final extension = _getFileExtension(imageFile.path);
      
      // Generate unique file path
      final filePath = _generateFilePath(userId, extension);
      
      // Upload to gallery
      await _client.storage
          .from('gallery')
          .upload(filePath, imageFile);
      
      // Get public URL
      final publicUrl = _client.storage
          .from('gallery')
          .getPublicUrl(filePath);
      
      return publicUrl;
      
    } on StorageException catch (e) {
      throw StorageException(
        'Galeri resmi yüklenirken hata oluştu: ${e.message}',
        code: e.code,
        originalError: e.originalError,
      );
    } catch (e) {
      throw StorageException(
        'Galeri resmi yüklenirken beklenmeyen bir hata oluştu',
        originalError: e,
      );
    }
  }
  
  /// Deletes file from storage
  /// 
  /// [bucket] - The storage bucket name (avatars or gallery)
  /// [path] - The file path within the bucket
  /// 
  /// Throws [StorageException] on failure
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await _client.storage
          .from(bucket)
          .remove([path]);
          
    } on StorageException catch (e) {
      throw StorageException(
        'Dosya silinirken hata oluştu: ${e.message}',
        code: e.code,
        originalError: e.originalError,
      );
    } catch (e) {
      throw StorageException(
        'Dosya silinirken beklenmeyen bir hata oluştu',
        originalError: e,
      );
    }
  }
  
  /// Generates unique file path for storage
  /// 
  /// Format: {userId}/{uuid}.{extension}
  /// 
  /// [userId] - The user ID for folder organization
  /// [extension] - The file extension (without dot)
  /// 
  /// Returns the generated file path
  String _generateFilePath(String userId, String extension) {
    final uniqueId = _uuid.v4();
    return '$userId/$uniqueId.$extension';
  }
  
  /// Extracts file extension from file path
  /// 
  /// [filePath] - The full file path
  /// 
  /// Returns the file extension without the dot
  String _getFileExtension(String filePath) {
    final lastDotIndex = filePath.lastIndexOf('.');
    if (lastDotIndex == -1) {
      throw StorageException('Dosya uzantısı bulunamadı');
    }
    return filePath.substring(lastDotIndex + 1).toLowerCase();
  }
  
  /// Deletes old avatar files for the user
  /// 
  /// This method lists all files in the user's avatar folder
  /// and removes them to prevent accumulation of old avatars.
  /// 
  /// [userId] - The user ID whose old avatars should be deleted
  Future<void> _deleteOldAvatar(String userId) async {
    try {
      // List files in user's avatar folder
      final files = await _client.storage
          .from('avatars')
          .list(path: userId);
      
      if (files.isNotEmpty) {
        // Create list of file paths to delete
        final filePaths = files
            .map((file) => '$userId/${file.name}')
            .toList();
        
        // Delete all old avatar files
        await _client.storage
            .from('avatars')
            .remove(filePaths);
      }
    } catch (e) {
      // Log error but don't throw - old avatar deletion is not critical
      print('Warning: Could not delete old avatar for user $userId: $e');
    }
  }
}