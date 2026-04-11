import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/media.dart';
import '../../lib/models/media_event.dart';
import '../../lib/exceptions/media_exception.dart';
import '../../lib/exceptions/storage_exception.dart';

/// Unit tests for Media-related models and business logic
/// 
/// These tests validate the media models and business logic
/// without requiring external dependencies.
void main() {
  group('Media Backend Model Tests', () {
    group('MediaType Enum', () {
      test('should have correct string values', () {
        expect(MediaType.aiCreation.value, equals('AI_CREATION'));
        expect(MediaType.model.value, equals('MODEL'));
        expect(MediaType.upload.value, equals('UPLOAD'));
      });
      
      test('should parse from string correctly', () {
        expect(MediaType.fromString('AI_CREATION'), equals(MediaType.aiCreation));
        expect(MediaType.fromString('MODEL'), equals(MediaType.model));
        expect(MediaType.fromString('UPLOAD'), equals(MediaType.upload));
      });
      
      test('should throw error for invalid string', () {
        expect(
          () => MediaType.fromString('INVALID_TYPE'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
    
    group('Media Model', () {
      test('should create Media from JSON correctly', () {
        // Arrange
        final json = {
          'id': 'media-123',
          'user_id': 'user-456',
          'image_url': 'https://example.com/image.jpg',
          'type': 'AI_CREATION',
          'style_tag': 'casual',
          'created_at': '2024-01-01T12:00:00Z',
        };
        
        // Act
        final media = Media.fromJson(json);
        
        // Assert
        expect(media.id, equals('media-123'));
        expect(media.userId, equals('user-456'));
        expect(media.imageUrl, equals('https://example.com/image.jpg'));
        expect(media.type, equals(MediaType.aiCreation));
        expect(media.styleTag, equals('casual'));
        expect(media.createdAt, equals(DateTime.parse('2024-01-01T12:00:00Z')));
      });
      
      test('should handle null style_tag', () {
        // Arrange
        final json = {
          'id': 'media-123',
          'user_id': 'user-456',
          'image_url': 'https://example.com/image.jpg',
          'type': 'UPLOAD',
          'style_tag': null,
          'created_at': '2024-01-01T12:00:00Z',
        };
        
        // Act
        final media = Media.fromJson(json);
        
        // Assert
        expect(media.styleTag, isNull);
        expect(media.type, equals(MediaType.upload));
      });
      
      test('should convert Media to JSON correctly', () {
        // Arrange
        final media = Media(
          id: 'media-123',
          userId: 'user-456',
          imageUrl: 'https://example.com/image.jpg',
          type: MediaType.model,
          styleTag: 'formal',
          createdAt: DateTime.parse('2024-01-01T12:00:00Z'),
        );
        
        // Act
        final json = media.toJson();
        
        // Assert
        expect(json['id'], equals('media-123'));
        expect(json['user_id'], equals('user-456'));
        expect(json['image_url'], equals('https://example.com/image.jpg'));
        expect(json['type'], equals('MODEL'));
        expect(json['style_tag'], equals('formal'));
        expect(json['created_at'], equals('2024-01-01T12:00:00.000Z'));
      });
    });
    
    group('MediaEvent Model', () {
      test('should create MediaEvent from realtime INSERT event', () {
        // Arrange
        final record = {
          'id': 'media-123',
          'user_id': 'user-456',
          'image_url': 'https://example.com/image.jpg',
          'type': 'AI_CREATION',
          'style_tag': 'casual',
          'created_at': '2024-01-01T12:00:00Z',
        };
        
        // Act
        final event = MediaEvent.fromRealtimeEvent(
          eventType: 'INSERT',
          record: record,
        );
        
        // Assert
        expect(event.type, equals(MediaEventType.insert));
        expect(event.media, isNotNull);
        expect(event.media!.id, equals('media-123'));
        expect(event.media!.type, equals(MediaType.aiCreation));
      });
      
      test('should create MediaEvent from realtime DELETE event', () {
        // Arrange
        final record = {
          'id': 'media-123',
          'user_id': 'user-456',
          'image_url': 'https://example.com/image.jpg',
          'type': 'UPLOAD',
          'style_tag': null,
          'created_at': '2024-01-01T12:00:00Z',
        };
        
        // Act
        final event = MediaEvent.fromRealtimeEvent(
          eventType: 'DELETE',
          record: record,
        );
        
        // Assert
        expect(event.type, equals(MediaEventType.delete));
        expect(event.media, isNotNull);
        expect(event.media!.id, equals('media-123'));
        expect(event.media!.type, equals(MediaType.upload));
      });
      
      test('should handle null record in realtime event', () {
        // Act
        final event = MediaEvent.fromRealtimeEvent(
          eventType: 'DELETE',
          record: null,
        );
        
        // Assert
        expect(event.type, equals(MediaEventType.delete));
        expect(event.media, isNull);
      });
      
      test('should throw error for unsupported event type', () {
        expect(
          () => MediaEvent.fromRealtimeEvent(
            eventType: 'UPDATE',
            record: {},
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
    
    group('Exception Classes', () {
      test('MediaException should store message and details', () {
        // Arrange & Act
        final exception = MediaException(
          'Media operation failed',
          code: 'MEDIA_ERROR',
          originalError: Exception('Original error'),
        );
        
        // Assert
        expect(exception.message, equals('Media operation failed'));
        expect(exception.code, equals('MEDIA_ERROR'));
        expect(exception.originalError, isA<Exception>());
        expect(exception.toString(), equals('MediaException: Media operation failed'));
      });
      
      test('StorageException should store message and details', () {
        // Arrange & Act
        final exception = StorageException(
          'Storage operation failed',
          code: 'STORAGE_ERROR',
          originalError: Exception('Storage error'),
        );
        
        // Assert
        expect(exception.message, equals('Storage operation failed'));
        expect(exception.code, equals('STORAGE_ERROR'));
        expect(exception.originalError, isA<Exception>());
        expect(exception.toString(), equals('StorageException: Storage operation failed'));
      });
    });
    
    group('Business Logic Validation', () {
      test('should validate media type constraints', () {
        // Test that all MediaType values can be used
        for (final mediaType in MediaType.values) {
          final media = Media(
            id: 'test-id',
            userId: 'test-user',
            imageUrl: 'https://example.com/image.jpg',
            type: mediaType,
            styleTag: 'test-style',
            createdAt: DateTime.now(),
          );
          
          expect(media.type, equals(mediaType));
          
          // Test JSON serialization round-trip
          final json = media.toJson();
          final recreated = Media.fromJson(json);
          expect(recreated.type, equals(mediaType));
        }
      });
      
      test('should handle media creation timestamps', () {
        final now = DateTime.now();
        final media = Media(
          id: 'test-id',
          userId: 'test-user',
          imageUrl: 'https://example.com/image.jpg',
          type: MediaType.upload,
          styleTag: null,
          createdAt: now,
        );
        
        expect(media.createdAt, equals(now));
        
        // Test that created_at is preserved in JSON
        final json = media.toJson();
        final recreated = Media.fromJson(json);
        expect(recreated.createdAt, equals(now));
      });
      
      test('should validate URL formats', () {
        // Test various URL formats that might be used
        final validUrls = [
          'https://example.com/image.jpg',
          'https://project.supabase.co/storage/v1/object/public/gallery/user/image.png',
          'https://cdn.example.com/uploads/photo.webp',
        ];
        
        for (final url in validUrls) {
          final media = Media(
            id: 'test-id',
            userId: 'test-user',
            imageUrl: url,
            type: MediaType.upload,
            styleTag: null,
            createdAt: DateTime.now(),
          );
          
          expect(media.imageUrl, equals(url));
          expect(media.imageUrl, startsWith('https://'));
        }
      });
      
      test('should handle style tag variations', () {
        final styleTags = [
          'casual',
          'formal',
          'business',
          'party',
          null, // No style tag
        ];
        
        for (final styleTag in styleTags) {
          final media = Media(
            id: 'test-id',
            userId: 'test-user',
            imageUrl: 'https://example.com/image.jpg',
            type: MediaType.aiCreation,
            styleTag: styleTag,
            createdAt: DateTime.now(),
          );
          
          expect(media.styleTag, equals(styleTag));
          
          // Test JSON round-trip
          final json = media.toJson();
          final recreated = Media.fromJson(json);
          expect(recreated.styleTag, equals(styleTag));
        }
      });
    });
    
    group('File Path Extraction Logic', () {
      test('should extract correct path from Supabase storage URL', () {
        // This tests the logic that would be used in MediaService
        const userId = 'user-123';
        const storageUrl = 'https://project.supabase.co/storage/v1/object/public/gallery/user-123/subfolder/image.jpg';
        
        // Simulate the path extraction logic
        final uri = Uri.parse(storageUrl);
        final pathSegments = uri.pathSegments;
        final bucketIndex = pathSegments.indexOf('gallery');
        
        expect(bucketIndex, greaterThan(-1));
        
        if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
          final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
          expect(filePath, equals('user-123/subfolder/image.jpg'));
          expect(filePath, startsWith(userId));
        }
      });
      
      test('should handle various storage URL formats', () {
        final testCases = [
          {
            'url': 'https://project.supabase.co/storage/v1/object/public/gallery/user-123/image.jpg',
            'expectedPath': 'user-123/image.jpg',
          },
          {
            'url': 'https://project.supabase.co/storage/v1/object/public/gallery/user-123/folder/subfolder/image.png',
            'expectedPath': 'user-123/folder/subfolder/image.png',
          },
        ];
        
        for (final testCase in testCases) {
          final uri = Uri.parse(testCase['url']!);
          final pathSegments = uri.pathSegments;
          final bucketIndex = pathSegments.indexOf('gallery');
          
          if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
            final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
            expect(filePath, equals(testCase['expectedPath']));
          }
        }
      });
    });
  });
}