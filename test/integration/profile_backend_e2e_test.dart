import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../lib/services/profile_service.dart';
import '../../lib/services/media_service.dart';
import '../../lib/services/storage_service.dart';
import '../../lib/models/profile.dart';
import '../../lib/models/media.dart';
import '../../lib/models/media_event.dart';
import '../../lib/exceptions/profile_exception.dart';
import '../../lib/exceptions/media_exception.dart';

/// End-to-End Integration Tests for Profile Backend System
/// 
/// These tests validate the complete backend flow including:
/// 1. User registration → automatic profile creation → profile viewing
/// 2. Profile updates → realtime events → UI updates
/// 3. Media upload → storage upload → DB insert → realtime events
/// 4. Media deletion → DB delete → storage delete
/// 
/// Note: These tests require a running Supabase instance with proper configuration
void main() {
  group('Profile Backend E2E Tests', () {
    late SupabaseClient supabaseClient;
    late ProfileService profileService;
    late MediaService mediaService;
    late StorageService storageService;
    
    // Test user credentials
    const testEmail = 'test@example.com';
    const testPassword = 'testpassword123';
    String? testUserId;
    
    setUpAll(() async {
      // Initialize Supabase (this would normally be done in main.dart)
      // For testing, we assume environment variables are set
      await Supabase.initialize(
        url: const String.fromEnvironment('SUPABASE_URL'),
        anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      );
      
      supabaseClient = Supabase.instance.client;
      storageService = StorageService(supabaseClient);
      mediaService = MediaService(supabaseClient, storageService);
      profileService = ProfileService(supabaseClient);
    });
    
    tearDownAll(() async {
      // Clean up test user if created
      if (testUserId != null) {
        try {
          await supabaseClient.auth.signOut();
        } catch (e) {
          // Ignore cleanup errors
        }
      }
    });
    
    group('Flow 1: User Registration → Profile Creation → Profile Viewing', () {
      test('should automatically create profile when user registers', () async {
        // Step 1: Register new user
        final authResponse = await supabaseClient.auth.signUp(
          email: testEmail,
          password: testPassword,
          data: {'full_name': 'Test User'},
        );
        
        expect(authResponse.user, isNotNull);
        testUserId = authResponse.user!.id;
        
        // Step 2: Wait for trigger to create profile (small delay)
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Step 3: Verify profile was automatically created
        final profileWithStats = await profileService.getProfile(testUserId!);
        
        expect(profileWithStats, isNotNull);
        expect(profileWithStats!.profile.id, equals(testUserId));
        expect(profileWithStats.profile.fullName, equals('Test User'));
        expect(profileWithStats.stats.aiLooksCount, equals(0));
        expect(profileWithStats.stats.uploadsCount, equals(0));
        expect(profileWithStats.stats.modelsCount, equals(0));
      });
    });
    
    group('Flow 2: Profile Update → Realtime Event → UI Update', () {
      test('should update profile and trigger realtime event', () async {
        // Ensure we have a test user
        if (testUserId == null) {
          await supabaseClient.auth.signUp(
            email: testEmail,
            password: testPassword,
            data: {'full_name': 'Test User'},
          );
          testUserId = supabaseClient.auth.currentUser!.id;
        }
        
        // Step 1: Set up realtime subscription
        Profile? realtimeUpdatedProfile;
        final channel = profileService.subscribeToProfileChanges(
          testUserId!,
          (updatedProfile) {
            realtimeUpdatedProfile = updatedProfile;
          },
        );
        
        // Wait for subscription to be established
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Step 2: Update profile
        const newFullName = 'Updated Test User';
        const newBio = 'This is my updated bio';
        
        final updatedProfile = await profileService.updateProfile(
          userId: testUserId!,
          fullName: newFullName,
          bio: newBio,
        );
        
        // Step 3: Verify direct update response
        expect(updatedProfile.fullName, equals(newFullName));
        expect(updatedProfile.bio, equals(newBio));
        
        // Step 4: Wait for realtime event
        await Future.delayed(const Duration(seconds: 2));
        
        // Step 5: Verify realtime event was received
        expect(realtimeUpdatedProfile, isNotNull);
        expect(realtimeUpdatedProfile!.fullName, equals(newFullName));
        expect(realtimeUpdatedProfile!.bio, equals(newBio));
        
        // Cleanup
        await profileService.unsubscribeFromProfileChanges(channel);
      });
    });
    
    group('Flow 3: Media Upload → Storage Upload → DB Insert → Realtime Event', () {
      test('should upload media and trigger realtime event', () async {
        // Ensure we have a test user
        if (testUserId == null) {
          await supabaseClient.auth.signUp(
            email: testEmail,
            password: testPassword,
            data: {'full_name': 'Test User'},
          );
          testUserId = supabaseClient.auth.currentUser!.id;
        }
        
        // Step 1: Create a test image file
        final testImageFile = await _createTestImageFile();
        
        // Step 2: Set up realtime subscription for media changes
        MediaEvent? realtimeEvent;
        final channel = mediaService.subscribeToMediaChanges(
          testUserId!,
          (event) {
            realtimeEvent = event;
          },
        );
        
        // Wait for subscription to be established
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Step 3: Upload media
        final addedMedia = await mediaService.addMedia(
          userId: testUserId!,
          imageFile: testImageFile,
          type: MediaType.upload,
          styleTag: 'casual',
        );
        
        // Step 4: Verify media was added to database
        expect(addedMedia.userId, equals(testUserId));
        expect(addedMedia.type, equals(MediaType.upload));
        expect(addedMedia.styleTag, equals('casual'));
        expect(addedMedia.imageUrl, isNotEmpty);
        
        // Step 5: Verify file was uploaded to storage
        // We can't directly check storage, but the URL should be valid
        expect(addedMedia.imageUrl, contains('gallery'));
        expect(addedMedia.imageUrl, contains(testUserId!));
        
        // Step 6: Wait for realtime event
        await Future.delayed(const Duration(seconds: 2));
        
        // Step 7: Verify realtime event was received
        expect(realtimeEvent, isNotNull);
        expect(realtimeEvent!.type, equals(MediaEventType.insert));
        expect(realtimeEvent!.media, isNotNull);
        expect(realtimeEvent!.media!.id, equals(addedMedia.id));
        
        // Step 8: Verify media appears in user's media list
        final mediaList = await mediaService.getMediaList(
          userId: testUserId!,
          type: MediaType.upload,
        );
        
        expect(mediaList, isNotEmpty);
        expect(mediaList.any((m) => m.id == addedMedia.id), isTrue);
        
        // Cleanup
        await mediaService.unsubscribeFromMediaChanges(channel);
        await testImageFile.delete();
      });
    });
    
    group('Flow 4: Media Delete → DB Delete → Storage Delete', () {
      test('should delete media from both database and storage', () async {
        // Ensure we have a test user
        if (testUserId == null) {
          await supabaseClient.auth.signUp(
            email: testEmail,
            password: testPassword,
            data: {'full_name': 'Test User'},
          );
          testUserId = supabaseClient.auth.currentUser!.id;
        }
        
        // Step 1: First upload a media item to delete
        final testImageFile = await _createTestImageFile();
        
        final addedMedia = await mediaService.addMedia(
          userId: testUserId!,
          imageFile: testImageFile,
          type: MediaType.model,
          styleTag: 'formal',
        );
        
        // Step 2: Set up realtime subscription for delete events
        MediaEvent? deleteEvent;
        final channel = mediaService.subscribeToMediaChanges(
          testUserId!,
          (event) {
            if (event.type == MediaEventType.delete) {
              deleteEvent = event;
            }
          },
        );
        
        // Wait for subscription to be established
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Step 3: Delete the media
        await mediaService.deleteMedia(
          userId: testUserId!,
          mediaId: addedMedia.id,
        );
        
        // Step 4: Wait for realtime event
        await Future.delayed(const Duration(seconds: 2));
        
        // Step 5: Verify realtime delete event was received
        expect(deleteEvent, isNotNull);
        expect(deleteEvent!.type, equals(MediaEventType.delete));
        
        // Step 6: Verify media is no longer in database
        final mediaList = await mediaService.getMediaList(
          userId: testUserId!,
          type: MediaType.model,
        );
        
        expect(mediaList.any((m) => m.id == addedMedia.id), isFalse);
        
        // Step 7: Verify attempting to delete again throws error
        expect(
          () => mediaService.deleteMedia(
            userId: testUserId!,
            mediaId: addedMedia.id,
          ),
          throwsA(isA<MediaException>()),
        );
        
        // Cleanup
        await mediaService.unsubscribeFromMediaChanges(channel);
        await testImageFile.delete();
      });
    });
    
    group('Error Handling and Edge Cases', () {
      test('should handle unauthorized access attempts', () async {
        // Create a different user ID to test RLS
        const unauthorizedUserId = 'unauthorized-user-id';
        
        // Should throw exception when trying to access another user's profile
        expect(
          () => profileService.updateProfile(
            userId: unauthorizedUserId,
            fullName: 'Hacker',
          ),
          throwsA(isA<ProfileException>()),
        );
        
        // Should throw exception when trying to access another user's media
        expect(
          () => mediaService.getMediaList(userId: unauthorizedUserId),
          throwsA(isA<MediaException>()),
        );
      });
      
      test('should handle non-existent profile gracefully', () async {
        const nonExistentUserId = 'non-existent-user-id';
        
        final profile = await profileService.getProfile(nonExistentUserId);
        expect(profile, isNull);
      });
      
      test('should validate media type constraints', () async {
        if (testUserId == null) {
          await supabaseClient.auth.signUp(
            email: testEmail,
            password: testPassword,
            data: {'full_name': 'Test User'},
          );
          testUserId = supabaseClient.auth.currentUser!.id;
        }
        
        final testImageFile = await _createTestImageFile();
        
        // Test all valid media types
        for (final mediaType in MediaType.values) {
          final media = await mediaService.addMedia(
            userId: testUserId!,
            imageFile: testImageFile,
            type: mediaType,
          );
          
          expect(media.type, equals(mediaType));
          
          // Clean up
          await mediaService.deleteMedia(
            userId: testUserId!,
            mediaId: media.id,
          );
        }
        
        await testImageFile.delete();
      });
    });
    
    group('Statistics and Aggregation', () {
      test('should correctly calculate user statistics', () async {
        if (testUserId == null) {
          await supabaseClient.auth.signUp(
            email: testEmail,
            password: testPassword,
            data: {'full_name': 'Test User'},
          );
          testUserId = supabaseClient.auth.currentUser!.id;
        }
        
        // Add different types of media
        final testImageFile = await _createTestImageFile();
        
        // Add AI creations
        await mediaService.addMedia(
          userId: testUserId!,
          imageFile: testImageFile,
          type: MediaType.aiCreation,
        );
        await mediaService.addMedia(
          userId: testUserId!,
          imageFile: testImageFile,
          type: MediaType.aiCreation,
        );
        
        // Add uploads
        await mediaService.addMedia(
          userId: testUserId!,
          imageFile: testImageFile,
          type: MediaType.upload,
        );
        
        // Add models
        await mediaService.addMedia(
          userId: testUserId!,
          imageFile: testImageFile,
          type: MediaType.model,
        );
        await mediaService.addMedia(
          userId: testUserId!,
          imageFile: testImageFile,
          type: MediaType.model,
        );
        await mediaService.addMedia(
          userId: testUserId!,
          imageFile: testImageFile,
          type: MediaType.model,
        );
        
        // Wait for database to update
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Check statistics
        final profileWithStats = await profileService.getProfile(testUserId!);
        
        expect(profileWithStats, isNotNull);
        expect(profileWithStats!.stats.aiLooksCount, equals(2));
        expect(profileWithStats.stats.uploadsCount, equals(1));
        expect(profileWithStats.stats.modelsCount, equals(3));
        
        await testImageFile.delete();
      });
    });
  });
}

/// Creates a test image file for upload testing
Future<File> _createTestImageFile() async {
  final tempDir = Directory.systemTemp;
  final testFile = File('${tempDir.path}/test_image.png');
  
  // Create a simple PNG file (1x1 pixel)
  final pngBytes = [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
    0x00, 0x00, 0x00, 0x0D, // IHDR chunk length
    0x49, 0x48, 0x44, 0x52, // IHDR
    0x00, 0x00, 0x00, 0x01, // Width: 1
    0x00, 0x00, 0x00, 0x01, // Height: 1
    0x08, 0x02, 0x00, 0x00, 0x00, // Bit depth, color type, etc.
    0x90, 0x77, 0x53, 0xDE, // CRC
    0x00, 0x00, 0x00, 0x0C, // IDAT chunk length
    0x49, 0x44, 0x41, 0x54, // IDAT
    0x08, 0x99, 0x01, 0x01, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0x00,
    0x02, 0x00, 0x01, // IDAT data
    0xE2, 0x21, 0xBC, 0x33, // CRC
    0x00, 0x00, 0x00, 0x00, // IEND chunk length
    0x49, 0x45, 0x4E, 0x44, // IEND
    0xAE, 0x42, 0x60, 0x82, // CRC
  ];
  
  await testFile.writeAsBytes(pngBytes);
  return testFile;
}