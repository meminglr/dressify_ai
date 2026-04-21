# Media Cache Optimization Bugfix Design

## Overview

This bugfix eliminates unnecessary database queries when navigating between the profile page and selection screen by implementing a cache-aware loading mechanism in ProfileViewModel. The solution ensures that media data (models, wardrobe items) loaded once is reused across page transitions, reducing network requests and improving performance. The implementation strictly follows MVVM architecture principles and includes rebuild optimization to prevent unnecessary widget updates.

The fix targets the `ProfileViewModel.loadProfile()` method to check if `_mediaList` is already populated before executing database queries. The existing Realtime subscription mechanism continues to keep the cache synchronized with server-side changes, ensuring data consistency without manual cache invalidation.

## Glossary

- **Bug_Condition (C)**: The condition that triggers unnecessary database queries - when `loadProfile()` is called with already-cached media data
- **Property (P)**: The desired behavior - `loadProfile()` should skip database queries when `_mediaList` is already populated
- **Preservation**: Existing behaviors that must remain unchanged - explicit refresh, Realtime updates, first-time loading, and immediate UI updates on upload/delete
- **ProfileViewModel**: The ViewModel in `lib/features/profile/viewmodels/profile_view_model.dart` that manages profile and media state
- **_mediaList**: The cached list of media items (models, wardrobe, AI looks) stored in ProfileViewModel
- **loadProfile()**: The method that loads profile and media data from the database
- **_loadMediaList()**: The internal method that fetches media from MediaService
- **Realtime subscription**: The Supabase Realtime channel that listens for INSERT/DELETE events on the media table
- **MVVM Architecture**: Model-View-ViewModel pattern where Views observe ViewModels, ViewModels manage business logic, and Models represent data
- **notifyListeners()**: ChangeNotifier method that triggers widget rebuilds - should only be called when data actually changes
- **ValueListenable**: Reactive observable that notifies listeners only when its value changes - used for filtered media lists

## Bug Details

### Bug Condition

The bug manifests when `ProfileViewModel.loadProfile()` is called after media data has already been loaded. The method unconditionally executes `_loadMediaList()`, which queries the database via `MediaService.getMediaList()`, even though `_mediaList` already contains the data.

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type LoadProfileCall
  OUTPUT: boolean
  
  RETURN input.method == 'loadProfile'
         AND _mediaList.isNotEmpty
         AND NOT input.isExplicitRefresh
         AND databaseQueryExecuted(input)
END FUNCTION
```

### Examples

- **Example 1**: User opens profile page → `loadProfile()` loads media from DB → User navigates to selection screen → `loadProfile()` called again in `initState` → **Database queried again** (expected: use cached data)

- **Example 2**: User opens selection screen directly → `loadProfile()` loads media from DB → User switches tabs back and forth → **Database queried on each navigation** (expected: use cached data after first load)

- **Example 3**: User uploads a new model photo → Realtime subscription updates `_mediaList` → User navigates to selection screen → `loadProfile()` called → **Database queried unnecessarily** (expected: use already-updated cache)

- **Edge Case**: User explicitly calls `refreshProfile()` → Cache cleared → `loadProfile()` called → **Database queried** (expected: this is correct behavior, should continue working)

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Explicit refresh via `refreshProfile()` must continue to clear cache and reload from database
- Realtime subscriptions must continue to update `_mediaList` automatically on INSERT/DELETE events
- First-time loading (when `_mediaList` is empty) must continue to query the database
- Immediate UI updates on upload/delete operations must continue to work
- Profile and stats loading behavior must remain unchanged

**Scope:**
All calls to `loadProfile()` that do NOT involve an empty `_mediaList` should skip database queries and use cached data. This includes:
- Navigation from profile to selection screen
- Tab switching between home tabs
- Returning to profile after viewing other screens
- Any scenario where media data is already loaded and valid

**MVVM Architecture Requirements:**
- Cache logic must reside entirely in the ViewModel layer
- Views must only observe ViewModel state via `watch()`, `read()`, or `ValueListenable`
- No business logic in View layer (selection_screen.dart)
- Clear separation: View renders UI, ViewModel manages state and cache, Model represents data

**Rebuild Optimization Requirements:**
- `notifyListeners()` must only be called when `_mediaList`, `_profile`, `_stats`, or loading states actually change
- ValueListenable wrappers (`modelsListenable`, `wardrobeListenable`, etc.) must only notify when their filtered data changes
- Avoid calling `notifyListeners()` in methods that don't change observable state
- Use `RepaintBoundary` in Views to isolate widget subtrees from unnecessary rebuilds

## Hypothesized Root Cause

Based on the bug description and code analysis, the most likely issues are:

1. **Missing Cache Check**: The `loadProfile()` method does not check if `_mediaList` is already populated before calling `_loadMediaList()`. It only checks if `_profile` and `_stats` are null, but always loads media data regardless of cache state.

2. **Unconditional Media Loading**: The current implementation has this logic:
   ```dart
   if (_profile == null || _stats == null) {
     // Load profile and stats
   }
   await _loadMediaList(resolvedUserId); // Always executes
   ```
   The media loading happens outside the null check, causing it to run on every call.

3. **No Cache Invalidation Strategy**: There's no explicit cache invalidation mechanism, but this is actually correct - the Realtime subscription handles updates automatically. The bug is that the cache isn't being used when it should be.

4. **Initialization Logic in View**: The `selection_screen.dart` calls `loadProfile()` in `initState` without checking if data is already loaded, but this is acceptable if the ViewModel properly handles cache checks internally.

## Correctness Properties

Property 1: Bug Condition - Cache-Aware Loading

_For any_ call to `loadProfile()` where `_mediaList` is already populated (not empty) and the call is not an explicit refresh, the fixed method SHALL skip the database query and use the cached `_mediaList` data, avoiding unnecessary network requests while maintaining data consistency through Realtime subscriptions.

**Validates: Requirements 2.1, 2.2, 2.3**

Property 2: Preservation - Explicit Refresh Behavior

_For any_ call to `refreshProfile()` or the first call to `loadProfile()` when `_mediaList` is empty, the fixed code SHALL produce exactly the same behavior as the original code, querying the database and loading fresh data as expected.

**Validates: Requirements 3.1, 3.3, 3.4**

Property 3: Preservation - Realtime Update Behavior

_For any_ Realtime event (INSERT or DELETE) received via the media subscription, the fixed code SHALL continue to update `_mediaList` automatically without requiring manual cache invalidation, preserving the existing reactive data synchronization mechanism.

**Validates: Requirements 3.2, 3.5**

Property 4: MVVM Architecture Compliance

_For any_ cache-related logic or state management, the implementation SHALL reside entirely in the ViewModel layer (ProfileViewModel), with Views only observing state changes via `watch()`, `read()`, or `ValueListenable`, maintaining strict separation of concerns.

**Validates: Requirements 4.1, 4.4**

Property 5: Rebuild Optimization

_For any_ state change in ProfileViewModel, `notifyListeners()` SHALL only be called when observable data (`_mediaList`, `_profile`, `_stats`, loading states) actually changes, and ValueListenable wrappers SHALL only notify when their filtered data changes, preventing unnecessary widget rebuilds.

**Validates: Requirements 4.2, 4.3, 4.5**

## Fix Implementation

### Changes Required

Assuming our root cause analysis is correct:

**File**: `lib/features/profile/viewmodels/profile_view_model.dart`

**Function**: `loadProfile(String? userId)`

**Specific Changes**:

1. **Add Cache Check for Media Loading**: Wrap the `_loadMediaList()` call in a conditional that checks if `_mediaList` is empty:
   ```dart
   // Only load media if cache is empty
   if (_mediaList.isEmpty) {
     await _loadMediaList(resolvedUserId);
   }
   ```

2. **Preserve Profile/Stats Loading Logic**: Keep the existing null check for `_profile` and `_stats` unchanged:
   ```dart
   if (_profile == null || _stats == null) {
     _isProfileLoading = true;
     _isMediaLoading = true;
     notifyListeners();
     // Load profile and stats
   }
   ```

3. **Ensure Explicit Refresh Clears Cache**: Verify that `refreshProfile()` correctly clears `_mediaList` before calling `loadProfile()`:
   ```dart
   Future<void> refreshProfile() async {
     _profile = null;
     _stats = null;
     _mediaList = []; // Ensures cache is cleared
     notifyListeners();
     await loadProfile(null);
   }
   ```

4. **Optimize notifyListeners() Calls**: Review all methods to ensure `notifyListeners()` is only called when data actually changes:
   - In `selectTab()`: Already has conditional check ✓
   - In `clearError()`: Already has conditional check ✓
   - In `clearSuccessMessage()`: Already has conditional check ✓
   - In `removeTrendyolProductFromList()`: Add length check before notifying
   - In `_loadMediaList()`: Only notify if data actually loaded

5. **Optimize ValueListenable Updates**: Ensure `_MediaListNotifier._update()` only triggers when filtered data changes:
   ```dart
   void _update() {
     final newValue = _selector();
     // Only update if the filtered list actually changed
     if (!_listsEqual(value, newValue)) {
       value = newValue;
     }
   }
   
   bool _listsEqual(List<T> a, List<T> b) {
     if (a.length != b.length) return false;
     for (int i = 0; i < a.length; i++) {
       if (a[i].id != b[i].id) return false;
     }
     return true;
   }
   ```

6. **Maintain MVVM Separation**: Ensure no cache logic leaks into `selection_screen.dart` - the View should only call `loadProfile()` and trust the ViewModel to handle caching internally.

### Implementation Notes

- The fix is minimal and surgical - only adds a cache check without changing the overall architecture
- Realtime subscriptions continue to work as-is, automatically updating the cache
- The `_isMediaLoading` flag should only be set to `true` when actually loading from the database
- No changes needed to MediaService or other layers - this is purely a ViewModel optimization
- The fix maintains backward compatibility - all existing call sites continue to work

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the bug on unfixed code by observing redundant database queries, then verify the fix eliminates unnecessary queries while preserving all existing behaviors (explicit refresh, Realtime updates, first-time loading).

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate unnecessary database queries BEFORE implementing the fix. Confirm or refute the root cause analysis. If we refute, we will need to re-hypothesize.

**Test Plan**: Write tests that simulate navigation flows and monitor database query execution. Use mocking or logging to track when `MediaService.getMediaList()` is called. Run these tests on the UNFIXED code to observe redundant queries.

**Test Cases**:
1. **Profile to Selection Navigation Test**: Load profile page → navigate to selection screen → assert `getMediaList()` called twice (will fail on unfixed code - should be called once)
2. **Tab Switching Test**: Load selection screen → switch to Trendyol tab → switch back → assert `getMediaList()` called multiple times (will fail on unfixed code)
3. **Post-Upload Navigation Test**: Upload model photo → Realtime updates cache → navigate to selection screen → assert `getMediaList()` called again (will fail on unfixed code - cache should be used)
4. **Empty Cache Test**: First call to `loadProfile()` with empty `_mediaList` → assert `getMediaList()` called (should pass on unfixed code - this is correct behavior)

**Expected Counterexamples**:
- Database queries executed when `_mediaList` is already populated
- Multiple calls to `getMediaList()` during navigation flows
- Possible causes: missing cache check, unconditional media loading, no cache-aware logic

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds (cached data exists), the fixed function skips database queries and uses cached data.

**Pseudocode:**
```
FOR ALL call WHERE isBugCondition(call) DO
  result := loadProfile_fixed(call.userId)
  ASSERT NOT databaseQueryExecuted(call)
  ASSERT result.mediaList == cachedMediaList
END FOR
```

**Test Cases**:
1. **Cached Data Navigation**: Load profile → populate `_mediaList` → call `loadProfile()` again → assert no database query executed
2. **Realtime-Updated Cache**: Receive INSERT event → `_mediaList` updated → call `loadProfile()` → assert no database query executed
3. **Multiple Navigation Cycles**: Navigate profile → selection → profile → selection → assert only one database query total
4. **MVVM Compliance**: Verify all cache logic resides in ViewModel, no business logic in Views
5. **Rebuild Optimization**: Verify `notifyListeners()` only called when data changes, not on cache hits

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold (explicit refresh, empty cache), the fixed function produces the same result as the original function.

**Pseudocode:**
```
FOR ALL call WHERE NOT isBugCondition(call) DO
  ASSERT loadProfile_original(call) = loadProfile_fixed(call)
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:
- It generates many test cases automatically across the input domain
- It catches edge cases that manual unit tests might miss
- It provides strong guarantees that behavior is unchanged for all non-buggy inputs

**Test Plan**: Observe behavior on UNFIXED code first for explicit refresh and first-time loading, then write property-based tests capturing that behavior.

**Test Cases**:
1. **Explicit Refresh Preservation**: Call `refreshProfile()` on unfixed code → observe database query → verify fixed code does the same
2. **First-Time Load Preservation**: Call `loadProfile()` with empty `_mediaList` on unfixed code → observe database query → verify fixed code does the same
3. **Realtime Update Preservation**: Trigger INSERT/DELETE events on unfixed code → observe `_mediaList` updates → verify fixed code does the same
4. **Upload/Delete Preservation**: Upload model photo on unfixed code → observe immediate UI update → verify fixed code does the same
5. **Profile/Stats Loading Preservation**: Call `loadProfile()` with null `_profile` on unfixed code → observe database query → verify fixed code does the same

### Unit Tests

- Test `loadProfile()` with empty `_mediaList` → should query database
- Test `loadProfile()` with populated `_mediaList` → should skip database query
- Test `refreshProfile()` → should clear cache and query database
- Test Realtime INSERT event → should update `_mediaList` without database query
- Test Realtime DELETE event → should remove item from `_mediaList` without database query
- Test `notifyListeners()` optimization → should only be called when data changes
- Test ValueListenable filtering → should only notify when filtered data changes

### Property-Based Tests

- Generate random navigation sequences and verify database queries are minimized
- Generate random Realtime event sequences and verify cache stays synchronized
- Generate random upload/delete operations and verify immediate UI updates work
- Test that all cache logic resides in ViewModel layer (MVVM compliance)
- Test that `notifyListeners()` is never called without actual data changes

### Integration Tests

- Test full user flow: open profile → navigate to selection → upload model → navigate back → verify only necessary database queries
- Test tab switching flow: selection → Trendyol → selection → verify cache reuse
- Test Realtime synchronization: open profile on device A → add media on device B → verify device A cache updates via Realtime
- Test explicit refresh flow: load profile → refresh → verify database queried
- Test MVVM architecture: verify Views only observe ViewModel, no business logic in Views
- Test rebuild optimization: verify minimal widget rebuilds during navigation
