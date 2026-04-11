import 'package:flutter_test/flutter_test.dart';

// Import all test files
import 'services/profile_service_test.dart' as profile_service_tests;
import 'services/media_service_test.dart' as media_service_tests;

/// Test runner for Profile Backend System
/// 
/// This file runs all unit tests for the profile backend system.
/// Integration tests should be run separately with proper Supabase setup.
void main() {
  group('Profile Backend System Tests', () {
    group('Service Layer Tests', () {
      profile_service_tests.main();
      media_service_tests.main();
    });
  });
}