import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/supabase_service.dart';
import '../models/profile.dart';
import '../models/user_stats.dart';
import '../models/profile_with_stats.dart';
import '../exceptions/profile_exception.dart';

/// Service for managing user profile operations with Supabase
/// 
/// This service handles profile CRUD operations, statistics fetching,
/// and realtime subscriptions following the MVVM architecture pattern.
/// Validates Requirements 8.1, 9.1
class ProfileService {
  final SupabaseClient _client;
  
  /// Creates a new ProfileService instance
  /// 
  /// [client] - The Supabase client instance for database operations
  ProfileService(this._client);
  
  /// Factory constructor using the singleton SupabaseService
  factory ProfileService.instance() {
    return ProfileService(SupabaseService.instance.client);
  }
  
  /// Fetches user profile with statistics
  /// 
  /// Combines profile data from profiles table with user statistics
  /// from user_stats view to provide complete profile information.
  /// 
  /// [userId] - The user ID to fetch profile for
  /// 
  /// Returns [ProfileWithStats] if profile exists, null otherwise
  /// Throws [ProfileException] on database errors
  Future<ProfileWithStats?> getProfile(String userId) async {
    try {
      // Fetch profile data
      final profileResponse = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (profileResponse == null) {
        return null;
      }
      
      // Fetch user statistics
      final statsResponse = await _client
          .from('user_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      // Create profile model
      final profile = Profile.fromJson(profileResponse);
      
      // Create stats model (default to zeros if no stats found)
      final stats = statsResponse != null 
          ? UserStats.fromJson(statsResponse)
          : UserStats(
              userId: userId,
              aiLooksCount: 0,
              uploadsCount: 0,
              modelsCount: 0,
            );
      
      return ProfileWithStats(profile: profile, stats: stats);
      
    } on PostgrestException catch (e) {
      debugPrint('ProfileService.getProfile error: ${e.message}');
      throw ProfileException(
        _getErrorMessage(e.code),
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      debugPrint('ProfileService.getProfile unexpected error: $e');
      throw ProfileException(
        'Profil bilgileri alınırken bir hata oluştu',
        originalError: e,
      );
    }
  }
  
  /// Updates user profile information
  /// 
  /// Updates the profiles table with new information and returns
  /// the updated profile data. The updated_at field is automatically
  /// updated by database trigger.
  /// 
  /// [userId] - The user ID whose profile to update
  /// [fullName] - Optional new full name
  /// [bio] - Optional new biography
  /// [avatarUrl] - Optional new avatar URL
  /// 
  /// Returns updated [Profile] object
  /// Throws [ProfileException] on database errors or RLS violations
  Future<Profile> updateProfile({
    required String userId,
    String? fullName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      // Prepare update data (only include non-null values)
      final updateData = <String, dynamic>{};
      
      if (fullName != null) {
        updateData['full_name'] = fullName;
      }
      if (bio != null) {
        updateData['bio'] = bio;
      }
      if (avatarUrl != null) {
        updateData['avatar_url'] = avatarUrl;
      }
      
      // If no data to update, return current profile
      if (updateData.isEmpty) {
        final currentProfile = await getProfile(userId);
        if (currentProfile == null) {
          throw ProfileException('Profil bulunamadı');
        }
        return currentProfile.profile;
      }
      
      // Update profile in database
      final response = await _client
          .from('profiles')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();
      
      return Profile.fromJson(response);
      
    } on PostgrestException catch (e) {
      debugPrint('ProfileService.updateProfile error: ${e.message}');
      throw ProfileException(
        _getErrorMessage(e.code),
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      debugPrint('ProfileService.updateProfile unexpected error: $e');
      throw ProfileException(
        'Profil güncellenirken bir hata oluştu',
        originalError: e,
      );
    }
  }
  
  /// Subscribes to profile changes via Supabase Realtime
  /// 
  /// Creates a realtime channel to listen for profile updates
  /// and calls the provided callback when changes occur.
  /// 
  /// [userId] - The user ID to monitor for changes
  /// [onUpdate] - Callback function called when profile updates
  /// 
  /// Returns [RealtimeChannel] for cleanup purposes
  RealtimeChannel subscribeToProfileChanges(
    String userId,
    void Function(Profile) onUpdate,
  ) {
    final channel = _client
        .channel('profile_changes_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            try {
              final updatedProfile = Profile.fromJson(payload.newRecord);
              onUpdate(updatedProfile);
            } catch (e) {
              debugPrint('Error processing profile update: $e');
            }
          },
        )
        .subscribe();
    
    return channel;
  }
  
  /// Unsubscribes from profile changes
  /// 
  /// Properly cleans up the realtime channel to prevent memory leaks.
  /// 
  /// [channel] - The RealtimeChannel to unsubscribe from
  Future<void> unsubscribeFromProfileChanges(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
  
  /// Converts PostgreSQL error codes to user-friendly messages
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
      case 'PGRST301': // row level security violation
        return 'Bu işlem için yetkiniz yok';
      default:
        return 'Bir hata oluştu';
    }
  }
}