import 'package:flutter/foundation.dart';
import '../models/profile.dart';
import '../models/user_stats.dart';
import '../models/media.dart';
import '../data/mock_profile_data.dart';

/// ProfileViewModel manages the business logic and state for the profile page.
///
/// This ViewModel follows the MVVM architecture pattern and extends ChangeNotifier
/// for state management. It handles data fetching, tab filtering, and error states.
///
/// Validates Requirements 7, 9, 11, 12
class ProfileViewModel extends ChangeNotifier {
  // Data state
  Profile? _profile;
  UserStats? _stats;
  List<Media> _mediaList = [];

  // UI state
  bool _isLoading = false;
  bool _isError = false;
  String? _errorMessage;
  int _selectedTabIndex = 0;

  // Getters
  Profile? get profile => _profile;
  UserStats? get stats => _stats;
  List<Media> get mediaList => _filteredMediaList;
  bool get isLoading => _isLoading;
  bool get isError => _isError;
  String? get errorMessage => _errorMessage;
  int get selectedTabIndex => _selectedTabIndex;

  /// Computed getter that filters media list based on selected tab index.
  ///
  /// Tab filtering logic:
  /// - 0 (All): Returns all media items
  /// - 1 (AI Looks): Returns only AI-generated looks
  /// - 2 (Uploads): Returns only user uploads
  ///
  /// Validates Requirement 7
  List<Media> get _filteredMediaList {
    switch (_selectedTabIndex) {
      case 0:
        return _mediaList; // All
      case 1:
        return _mediaList
            .where((m) => m.type == MediaType.aiLook)
            .toList(); // AI Looks
      case 2:
        return _mediaList
            .where((m) => m.type == MediaType.upload)
            .toList(); // Uploads
      default:
        return _mediaList;
    }
  }

  /// Loads profile data for the specified user ID.
  ///
  /// If [userId] is null, loads the current user's profile.
  /// Uses MockProfileData for test data during development.
  ///
  /// Sets loading state, fetches data, and handles errors.
  /// Validates Requirements 7, 9, 11
  Future<void> loadProfile(String? userId) async {
    _isLoading = true;
    _isError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Load mock data
      _profile = MockProfileData.getMockProfile();
      _stats = MockProfileData.getMockStats();
      _mediaList = MockProfileData.getMockMediaList();

      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _handleError(error);
    }
  }

  /// Refreshes the profile data.
  ///
  /// This method is called when the user performs pull-to-refresh.
  /// It reloads the profile data without showing the initial loading indicator.
  ///
  /// Validates Requirement 13
  Future<void> refreshProfile() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Reload mock data
      _profile = MockProfileData.getMockProfile();
      _stats = MockProfileData.getMockStats();
      _mediaList = MockProfileData.getMockMediaList();

      notifyListeners();
    } catch (error) {
      _handleError(error);
    }
  }

  /// Selects a tab and filters the media list accordingly.
  ///
  /// [index] should be:
  /// - 0 for "All"
  /// - 1 for "AI Looks"
  /// - 2 for "Uploads"
  ///
  /// Only notifies listeners if the tab index actually changed (performance optimization).
  /// Validates Requirements 7, 8
  void selectTab(int index) {
    if (_selectedTabIndex != index) {
      _selectedTabIndex = index;
      notifyListeners();
    }
  }

  /// Handles errors and sets appropriate error state with Turkish error messages.
  ///
  /// Converts different error types to user-friendly Turkish messages.
  /// Validates Requirement 12
  void _handleError(dynamic error) {
    _isLoading = false;
    _isError = true;

    // In a real app, you would check for specific error types
    // For now, we use a generic error message
    _errorMessage = 'Bir hata oluştu. Lütfen tekrar deneyin.';

    notifyListeners();
  }

  /// Clears the error state.
  ///
  /// This method is called when the user dismisses an error or retries an operation.
  /// Validates Requirement 12
  void clearError() {
    _isError = false;
    _errorMessage = null;
    notifyListeners();
  }
}
