# Profile Backend System Tests

This directory contains comprehensive tests for the Profile Backend System, validating all the flows specified in the final checkpoint task.

## Test Structure

### 1. Unit Tests (Model & Logic Tests)
- **Location**: `test/services/`
- **Purpose**: Test data models, business logic, and error handling without external dependencies
- **Files**:
  - `profile_service_test.dart` - Profile model and business logic tests
  - `media_service_test.dart` - Media model and business logic tests

### 2. Integration Tests (End-to-End Tests)
- **Location**: `test/integration/`
- **Purpose**: Test complete backend flows with live Supabase connection
- **Files**:
  - `profile_backend_e2e_test.dart` - Complete end-to-end flow tests

## Running Tests

### Unit Tests (No External Dependencies)
```bash
# Run all unit tests
flutter test test/services/

# Run specific test file
flutter test test/services/profile_service_test.dart
flutter test test/services/media_service_test.dart

# Run with verbose output
flutter test test/services/ --reporter=expanded
```

### Integration Tests (Requires Supabase Setup)
```bash
# Set environment variables first
export SUPABASE_URL="your-supabase-project-url"
export SUPABASE_ANON_KEY="your-supabase-anon-key"

# Run integration tests
flutter test test/integration/profile_backend_e2e_test.dart
```

### All Tests
```bash
# Run all tests (unit tests will pass, integration tests need setup)
flutter test
```

## Test Coverage

### Flow 1: User Registration → Profile Creation → Profile Viewing
✅ **Tested in**: `profile_backend_e2e_test.dart`
- Validates automatic profile creation trigger
- Verifies profile data integrity
- Tests user statistics initialization

### Flow 2: Profile Update → Realtime Event → UI Update
✅ **Tested in**: `profile_backend_e2e_test.dart`
- Tests profile update operations
- Validates realtime subscription setup
- Verifies event propagation

### Flow 3: Media Upload → Storage Upload → DB Insert → Realtime Event
✅ **Tested in**: `profile_backend_e2e_test.dart`
- Tests complete media upload flow
- Validates storage integration
- Verifies database record creation
- Tests realtime event emission

### Flow 4: Media Delete → DB Delete → Storage Delete
✅ **Tested in**: `profile_backend_e2e_test.dart`
- Tests complete media deletion flow
- Validates storage cleanup
- Verifies database record removal
- Tests realtime delete events

### Additional Test Coverage
✅ **Error Handling**: RLS violations, unauthorized access, invalid data
✅ **Edge Cases**: Non-existent records, null values, invalid formats
✅ **Data Models**: JSON serialization/deserialization, type validation
✅ **Business Logic**: Statistics calculation, media type constraints
✅ **Security**: User isolation, path validation, access control

## Test Data Models

### Profile Model Tests
- ✅ JSON serialization/deserialization
- ✅ Null value handling
- ✅ Timestamp formatting
- ✅ Required field validation

### Media Model Tests
- ✅ MediaType enum validation
- ✅ JSON round-trip conversion
- ✅ URL format validation
- ✅ Style tag handling

### Exception Tests
- ✅ ProfileException error details
- ✅ MediaException error details
- ✅ StorageException error details

## Integration Test Requirements

To run integration tests, you need:

1. **Supabase Project Setup**:
   - Running Supabase instance (local or cloud)
   - Database migrations applied
   - RLS policies configured
   - Storage buckets created

2. **Environment Variables**:
   ```bash
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```

3. **Test User Cleanup**:
   - Integration tests create temporary users
   - Cleanup is handled automatically
   - Manual cleanup may be needed if tests fail

## Test Results Interpretation

### Unit Test Results
- **All Passing**: Models and business logic are working correctly
- **Failures**: Check data model implementations or business logic

### Integration Test Results
- **All Passing**: Complete backend system is working end-to-end
- **Connection Failures**: Check Supabase configuration and network
- **RLS Failures**: Check database policies and user permissions
- **Storage Failures**: Check bucket configuration and file permissions

## Debugging Test Failures

### Common Issues

1. **Timestamp Format Mismatches**:
   - Dart DateTime.toIso8601String() adds milliseconds
   - Tests expect `.000Z` format

2. **RLS Policy Violations**:
   - Check user authentication in tests
   - Verify policy configuration matches test expectations

3. **Storage Permission Issues**:
   - Verify bucket RLS policies
   - Check file path format (user_id/filename)

4. **Realtime Subscription Issues**:
   - Increase wait times for event propagation
   - Check channel subscription setup

### Debug Commands
```bash
# Run single test with detailed output
flutter test test/integration/profile_backend_e2e_test.dart --reporter=expanded

# Run with debug prints
flutter test test/integration/profile_backend_e2e_test.dart --debug

# Check test coverage
flutter test --coverage
```

## Test Maintenance

### Adding New Tests
1. Follow existing test patterns
2. Use descriptive test names
3. Include setup and teardown
4. Test both success and failure cases

### Updating Tests
1. Update tests when models change
2. Maintain test data consistency
3. Update documentation
4. Verify all flows still work

### Performance Considerations
- Integration tests are slower (network calls)
- Unit tests should be fast and isolated
- Use appropriate timeouts for realtime events
- Clean up test data to avoid accumulation

## Conclusion

This test suite provides comprehensive coverage of the Profile Backend System, validating all critical flows and edge cases. The combination of unit tests and integration tests ensures both individual component correctness and end-to-end system functionality.

For questions or issues with tests, refer to the service implementations in `lib/services/` and model definitions in `lib/models/`.