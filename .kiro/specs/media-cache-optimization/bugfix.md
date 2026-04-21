# Bugfix Requirements Document

## Introduction

This bugfix addresses unnecessary database queries when navigating from the profile page to the selection screen. Currently, media data (models and wardrobe items) that has already been loaded in ProfileViewModel is being reloaded from the database when the user navigates to the selection screen, causing redundant network requests and database queries. This impacts performance and user experience, especially on slower connections.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN the user opens the profile page THEN ProfileViewModel loads media data (models, wardrobe) from the database

1.2 WHEN the user navigates to the selection screen THEN the same media data is loaded again from the database via `profileViewModel.loadProfile(null)` in `selection_screen.dart`'s `initState`

1.3 WHEN `ProfileViewModel.loadProfile()` is called THEN it executes `_loadMediaList()` without checking if data is already cached

1.4 WHEN every page transition occurs THEN unnecessary network requests and database queries are made even though the data is already available in memory

### Expected Behavior (Correct)

2.1 WHEN media data has already been loaded in ProfileViewModel THEN subsequent calls to `loadProfile()` SHALL use the cached data instead of querying the database

2.2 WHEN the user navigates to the selection screen THEN the system SHALL check if `_mediaList` is already populated before making database queries

2.3 WHEN cached data exists and is valid THEN the system SHALL return immediately without making network requests

2.4 WHEN new data is added (via upload or Trendyol save) THEN the cache SHALL be updated automatically via the existing Realtime subscription mechanism

2.5 WHEN the user explicitly triggers a refresh (via `refreshProfile()`) THEN the system SHALL reload data from the database

### Unchanged Behavior (Regression Prevention)

3.1 WHEN the user explicitly calls `refreshProfile()` THEN the system SHALL CONTINUE TO clear the cache and reload all data from the database

3.2 WHEN Realtime events (INSERT/DELETE) are received THEN the system SHALL CONTINUE TO update `_mediaList` automatically

3.3 WHEN the ProfileViewModel is first initialized THEN the system SHALL CONTINUE TO load data from the database on the first call to `loadProfile()`

3.4 WHEN profile data (`_profile` and `_stats`) is null THEN the system SHALL CONTINUE TO load it from the database

3.5 WHEN media is uploaded or deleted THEN the system SHALL CONTINUE TO update the local `_mediaList` immediately for responsive UI

### Architecture and Performance Constraints

4.1 WHEN implementing the cache mechanism THEN the solution SHALL strictly follow MVVM architecture pattern with clear separation between View, ViewModel, and Model layers

4.2 WHEN the cache state changes THEN the system SHALL ONLY notify listeners when actual data changes occur, preventing unnecessary widget rebuilds

4.3 WHEN using ValueListenable for reactive updates THEN the system SHALL ensure that listeners are only triggered when the filtered data (models, wardrobe) actually changes

4.4 WHEN implementing cache checks THEN the logic SHALL reside entirely in the ViewModel layer, keeping Views free from business logic

4.5 WHEN notifyListeners() is called THEN it SHALL only be invoked when there is a meaningful state change that requires UI updates, not on every method call
