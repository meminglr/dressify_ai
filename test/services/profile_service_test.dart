import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/profile.dart';
import '../../lib/models/user_stats.dart';
import '../../lib/models/profile_with_stats.dart';
import '../../lib/models/media.dart';
import '../../lib/exceptions/profile_exception.dart';
import '../../lib/exceptions/media_exception.dart';

/// Unit tests for Profile Backend Models and Logic
/// 
/// These tests validate the data models and business logic
/// without requiring external dependencies.
void main() {
  group('Profile Backend Model Tests', () {
    group('Profile Model', () {
      test('should create Profile from JSON correctly', () {
        // Arrange
        final json = {
          'id': 'test-user-id',
          'full_name': 'Test User',
          'bio': 'Test bio',
          'avatar_url': 'https://example.com/avatar.jpg',
          'updated_at': '2024-01-01T00:00:00Z',
        };
        
        // Act
        final profile = Profile.fromJson(json);
        
        // Assert
        expect(profile.id, equals('test-user-id'));
        expect(profile.fullName, equals('Test User'));
        expect(profile.bio, equals('Test bio'));
        expect(profile.avatarUrl, equals('https://example.com/avatar.jpg'));
        expect(profile.updatedAt, equals(DateTime.parse('2024-01-01T00:00:00Z')));
      });
      
      test('should handle null values in JSON', () {
        // Arrange
        final json = {
          'id': 'test-user-id',
          'full_name': null,
          'bio': null,
          'avatar_url': null,
          'updated_at': '2024-01-01T00:00:00Z',
        };
        
        // Act
        final profile = Profile.fromJson(json);
        
        // Assert
        expect(profile.id, equals('test-user-id'));
        expect(profile.fullName, isNull);
        expect(profile.bio, isNull);
        expect(profile.avatarUrl, isNull);
      });
      
      test('should convert Profile to JSON correctly', () {
        // Arrange
        final profile = Profile(
          id: 'test-user-id',
          fullName: 'Test User',
          bio: 'Test bio',
          avatarUrl: 'https://example.com/avatar.jpg',
          updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
        );
        
        // Act
        final json = profile.toJson();
        
        // Assert
        expect(json['id'], equals('test-user-id'));
        expect(json['full_name'], equals('Test User'));
        expect(json['bio'], equals('Test bio'));
        expect(json['avatar_url'], equals('https://example.com/avatar.jpg'));
        expect(json['updated_at'], equals('2024-01-01T00:00:00.000Z'));
      });
    });
    
    group('UserStats Model', () {
      test('should create UserStats from JSON correctly', () {
        // Arrange
        final json = {
          'user_id': 'test-user-id',
          'ai_looks_count': 5,
          'uploads_count': 3,
          'models_count': 2,
        };
        
        // Act
        final stats = UserStats.fromJson(json);
        
        // Assert
        expect(stats.userId, equals('test-user-id'));
        expect(stats.aiLooksCount, equals(5));
        expect(stats.uploadsCount, equals(3));
        expect(stats.modelsCount, equals(2));
      });
      
      test('should handle null counts as zero', () {
        // Arrange
        final json = {
          'user_id': 'test-user-id',
          'ai_looks_count': null,
          'uploads_count': null,
          'models_count': null,
        };
        
        // Act
        final stats = UserStats.fromJson(json);
        
        // Assert
        expect(stats.aiLooksCount, equals(0));
        expect(stats.uploadsCount, equals(0));
        expect(stats.modelsCount, equals(0));
      });
    });
    
    group('ProfileWithStats Model', () {
      test('should combine Profile and UserStats correctly', () {
        // Arrange
        final profile = Profile(
          id: 'test-user-id',
          fullName: 'Test User',
          bio: 'Test bio',
          avatarUrl: null,
          updatedAt: DateTime.now(),
        );
        
        final stats = UserStats(
          userId: 'test-user-id',
          aiLooksCount: 5,
          uploadsCount: 3,
          modelsCount: 2,
        );
        
        // Act
        final profileWithStats = ProfileWithStats(
          profile: profile,
          stats: stats,
        );
        
        // Assert
        expect(profileWithStats.profile.id, equals('test-user-id'));
        expect(profileWithStats.profile.fullName, equals('Test User'));
        expect(profileWithStats.stats.aiLooksCount, equals(5));
        expect(profileWithStats.stats.uploadsCount, equals(3));
        expect(profileWithStats.stats.modelsCount, equals(2));
      });
    });
    
    group('Media Model', () {
      test('should create Media from JSON correctly', () {
        // Arrange
        final json = {
          'id': 'media-id',
          'user_id': 'test-user-id',
          'image_url': 'https://example.com/image.jpg',
          'type': 'AI_CREATION',
          'style_tag': 'casual',
          'created_at': '2024-01-01T00:00:00Z',
        };
        
        // Act
        final media = Media.fromJson(json);
        
        // Assert
        expect(media.id, equals('media-id'));
        expect(media.userId, equals('test-user-id'));
        expect(media.imageUrl, equals('https://example.com/image.jpg'));
        expect(media.type, equals(MediaType.aiCreation));
        expect(media.styleTag, equals('casual'));
        expect(media.createdAt, equals(DateTime.parse('2024-01-01T00:00:00Z')));
      });
      
      test('should handle all MediaType values', () {
        final mediaTypes = [
          ('AI_CREATION', MediaType.aiCreation),
          ('MODEL', MediaType.model),
          ('UPLOAD', MediaType.upload),
        ];
        
        for (final (stringValue, enumValue) in mediaTypes) {
          // Test fromString
          expect(MediaType.fromString(stringValue), equals(enumValue));
          
          // Test enum value
          expect(enumValue.value, equals(stringValue));
        }
      });
      
      test('should throw error for invalid MediaType', () {
        expect(
          () => MediaType.fromString('INVALID_TYPE'),
          throwsA(isA<ArgumentError>()),
        );
      });
      
      test('should convert Media to JSON correctly', () {
        // Arrange
        final media = Media(
          id: 'media-id',
          userId: 'test-user-id',
          imageUrl: 'https://example.com/image.jpg',
          type: MediaType.upload,
          styleTag: 'formal',
          createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        );
        
        // Act
        final json = media.toJson();
        
        // Assert
        expect(json['id'], equals('media-id'));
        expect(json['user_id'], equals('test-user-id'));
        expect(json['image_url'], equals('https://example.com/image.jpg'));
        expect(json['type'], equals('UPLOAD'));
        expect(json['style_tag'], equals('formal'));
        expect(json['created_at'], equals('2024-01-01T00:00:00.000Z'));
      });
    });
    
    group('Exception Classes', () {
      test('ProfileException should store message and details', () {
        // Arrange & Act
        final exception = ProfileException(
          'Test error message',
          code: 'TEST_CODE',
          originalError: Exception('Original error'),
        );
        
        // Assert
        expect(exception.message, equals('Test error message'));
        expect(exception.code, equals('TEST_CODE'));
        expect(exception.originalError, isA<Exception>());
        expect(exception.toString(), equals('ProfileException: Test error message'));
      });
      
      test('MediaException should store message and details', () {
        // Arrange & Act
        final exception = MediaException(
          'Media error message',
          code: 'MEDIA_CODE',
          originalError: Exception('Original media error'),
        );
        
        // Assert
        expect(exception.message, equals('Media error message'));
        expect(exception.code, equals('MEDIA_CODE'));
        expect(exception.originalError, isA<Exception>());
        expect(exception.toString(), equals('MediaException: Media error message'));
      });
    });
    
    group('Business Logic Validation', () {
      test('should validate required profile fields', () {
        // Test that Profile can be created with minimal required fields
        final profile = Profile(
          id: 'test-id',
          fullName: null,
          bio: null,
          avatarUrl: null,
          updatedAt: DateTime.now(),
        );
        
        expect(profile.id, equals('test-id'));
        expect(profile.fullName, isNull);
        expect(profile.bio, isNull);
        expect(profile.avatarUrl, isNull);
      });
      
      test('should validate UserStats calculations', () {
        // Test that UserStats properly handles different count scenarios
        final stats = UserStats(
          userId: 'test-user',
          aiLooksCount: 10,
          uploadsCount: 5,
          modelsCount: 3,
        );
        
        // Calculate total items
        final totalItems = stats.aiLooksCount + stats.uploadsCount + stats.modelsCount;
        expect(totalItems, equals(18));
        
        // Verify individual counts
        expect(stats.aiLooksCount, greaterThan(0));
        expect(stats.uploadsCount, greaterThan(0));
        expect(stats.modelsCount, greaterThan(0));
      });
      
      test('should validate Media type constraints', () {
        // Test that all MediaType values are valid
        for (final mediaType in MediaType.values) {
          final media = Media(
            id: 'test-id',
            userId: 'test-user',
            imageUrl: 'https://example.com/image.jpg',
            type: mediaType,
            styleTag: 'test',
            createdAt: DateTime.now(),
          );
          
          expect(media.type, equals(mediaType));
          expect(MediaType.fromString(mediaType.value), equals(mediaType));
        }
      });
    });
  });
}