import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart' as ui;
import '../models/user_stats.dart' as ui;
import '../models/media.dart' as ui;
import '../../../models/media_event.dart';
import '../../../models/media.dart' as lib_media;
import '../../../services/profile_service.dart';
import '../../../services/media_service.dart';
import '../../../services/storage_service.dart';
import '../../../exceptions/profile_exception.dart';
import '../../../exceptions/media_exception.dart';
import '../../../exceptions/storage_exception.dart' as app_storage;

/// ProfileViewModel manages the business logic and state for the profile page.
///
/// This ViewModel follows the MVVM architecture pattern and extends ChangeNotifier
/// for state management. It handles data fetching, tab filtering, realtime
/// subscriptions, and error states.
///
/// Validates Requirements 7, 9, 11, 12
class ProfileViewModel extends ChangeNotifier {
  final ProfileService _profileService;
  final MediaService _mediaService;
  final StorageService _storageService;

  // Data state
  ui.Profile? _profile;
  ui.UserStats? _stats;
  List<ui.Media> _mediaList = [];

  // UI state
  bool _isProfileLoading = false;
  bool _isMediaLoading = false;
  bool _isUploading = false;
  bool _isError = false;
  String? _errorMessage;
  String? _successMessage;
  int _selectedTabIndex = 0;

  // Realtime channels
  RealtimeChannel? _profileChannel;
  RealtimeChannel? _mediaChannel;

  ProfileViewModel({
    required ProfileService profileService,
    required MediaService mediaService,
    required StorageService storageService,
  })  : _profileService = profileService,
        _mediaService = mediaService,
        _storageService = storageService;

  // Getters
  ui.Profile? get profile => _profile;
  ui.UserStats? get stats => _stats;
  /// Returns ALL media items unfiltered — Screen handles per-tab filtering
  List<ui.Media> get mediaList => List.unmodifiable(_mediaList);
  bool get isProfileLoading => _isProfileLoading;
  bool get isMediaLoading => _isMediaLoading;
  bool get isUploading => _isUploading;
  bool get isError => _isError;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  int get selectedTabIndex => _selectedTabIndex;

  /// Computed getter that filters media list based on selected tab index.
  ///
  /// Validates Requirement 7
  // NOTE: Filtering is done in ProfileScreen per-tab. This getter is kept
  // for potential future use but not exposed publicly.

  /// Loads profile data for the specified user ID.
  ///
  /// If [userId] is null, loads the current authenticated user's profile.
  /// Validates Requirements 7, 9, 11
  Future<void> loadProfile(String? userId) async {
    _isError = false;
    _errorMessage = null;

    final resolvedUserId =
        userId ?? Supabase.instance.client.auth.currentUser?.id;

    if (resolvedUserId == null) {
      _isError = true;
      _errorMessage = 'Kullanıcı oturumu bulunamadı.';
      notifyListeners();
      return;
    }

    try {
      if (_profile == null || _stats == null) {
        _isProfileLoading = true;
        notifyListeners();

        final profileWithStats =
            await _profileService.getProfile(resolvedUserId);

        if (profileWithStats != null) {
          _profile = _mapProfile(profileWithStats.profile, resolvedUserId);
          _stats = _mapStats(profileWithStats.stats);
        }

        _isProfileLoading = false;
        notifyListeners();
      }

      await _loadMediaList(resolvedUserId);
      _subscribeToProfileChanges(resolvedUserId);
      _subscribeToMediaChanges(resolvedUserId);
    } catch (error) {
      _handleError(error);
    }
  }

  /// Refreshes the profile data by resetting state and reloading.
  ///
  /// Validates Requirement 13
  Future<void> refreshProfile() async {
    _profile = null;
    _stats = null;
    _mediaList = [];
    notifyListeners();
    await loadProfile(null);
  }

  /// Selects a tab and filters the media list accordingly.
  ///
  /// Validates Requirements 7, 8
  void selectTab(int index) {
    if (_selectedTabIndex != index) {
      _selectedTabIndex = index;
      notifyListeners();
    }
  }

  /// Clears the error state.
  void clearError() {
    _isError = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clears the success message.
  void clearSuccessMessage() {
    _successMessage = null;
    notifyListeners();
  }

  /// Picks and uploads a wardrobe (Gardırop) photo as MediaType.upload.
  Future<void> uploadGardiropPhoto(BuildContext context) async {
    final asset = await _pickPhoto(context);
    if (asset == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final file = await _assetToFile(asset);
      _isUploading = true;
      notifyListeners();

      final newMedia = await _mediaService.addMedia(
        userId: userId,
        imageFile: file,
        type: lib_media.MediaType.upload,
      );

      // Directly add to list — don't wait for realtime
      _mediaList = [_mapMedia(newMedia), ..._mediaList];
      _isUploading = false;
      _successMessage = 'Kıyafet başarıyla eklendi';
      notifyListeners();
    } catch (error) {
      _handleError(error);
    }
  }

  /// Picks and uploads a model photo as MediaType.model.
  Future<void> uploadModelPhoto(BuildContext context) async {
    final asset = await _pickPhoto(context);
    if (asset == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final file = await _assetToFile(asset);
      _isUploading = true;
      notifyListeners();

      final newMedia = await _mediaService.addMedia(
        userId: userId,
        imageFile: file,
        type: lib_media.MediaType.model,
      );

      // Directly add to list — don't wait for realtime
      _mediaList = [_mapMedia(newMedia), ..._mediaList];
      _isUploading = false;
      _successMessage = 'Model başarıyla eklendi';
      notifyListeners();
    } catch (error) {
      _handleError(error);
    }
  }

  /// Picks and uploads a new avatar photo, then updates the profile.
  Future<void> uploadAvatarPhoto(BuildContext context) async {
    final asset = await _pickPhoto(context);
    if (asset == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // Save current avatarUrl to restore on error
    final previousAvatarUrl = _profile?.avatarUrl;

    try {
      final file = await _assetToFile(asset);
      _isUploading = true;
      notifyListeners();

      final newAvatarUrl = await _storageService.uploadAvatar(
        userId: userId,
        imageFile: file,
      );

      final updatedProfile = await _profileService.updateProfile(
        userId: userId,
        avatarUrl: newAvatarUrl,
      );

      // Map updated service profile back to UI profile
      _profile = _mapProfile(updatedProfile, userId);
      _isUploading = false;
      _successMessage = 'Profil fotoğrafı güncellendi';
      notifyListeners();
    } catch (error) {
      // Restore previous avatar URL on error
      if (_profile != null && previousAvatarUrl != _profile!.avatarUrl) {
        _profile = ui.Profile(
          id: _profile!.id,
          fullName: _profile!.fullName,
          username: _profile!.username,
          bio: _profile!.bio,
          avatarUrl: previousAvatarUrl,
          coverImageUrl: _profile!.coverImageUrl,
          createdAt: _profile!.createdAt,
          updatedAt: _profile!.updatedAt,
        );
      }
      _handleError(error);
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Opens InstaAssetsPicker to let user pick a single image.
  /// Returns null if user cancels.
  Future<AssetEntity?> _pickPhoto(BuildContext context) async {
    try {
      final completer = Completer<AssetEntity?>();

      // Build a theme that matches the app's design system
      final base = InstaAssetPicker.themeData(const Color(0xFF742FE5));
      final pickerTheme = base.copyWith(
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: base.appBarTheme.copyWith(
          backgroundColor: const Color(0xFFFFFFFF),
          foregroundColor: const Color(0xFF742FE5),
          elevation: 0,
          titleTextStyle: const TextStyle(
            color: Color(0xFF742FE5),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF742FE5)),
        ),
        colorScheme: base.colorScheme.copyWith(
          primary: const Color(0xFF742FE5),
          surface: const Color(0xFFF8F9FA),
          onSurface: const Color(0xFF742FE5),
          secondary: const Color(0xFF742FE5),
          onSecondary: Colors.white,
        ),
        canvasColor: const Color(0xFFF8F9FA),
        cardColor: const Color(0xFFFFFFFF),
        iconTheme: const IconThemeData(color: Color(0xFF742FE5)),
        primaryIconTheme: const IconThemeData(color: Color(0xFF742FE5)),
        textTheme: base.textTheme.apply(
          bodyColor: const Color(0xFF742FE5),
          displayColor: const Color(0xFF742FE5),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF742FE5),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        chipTheme: base.chipTheme.copyWith(
          backgroundColor: const Color(0xFF742FE5).withAlpha(20),
          selectedColor: const Color(0xFF742FE5),
          labelStyle: const TextStyle(color: Color(0xFF742FE5)),
        ),
        dividerColor: const Color(0xFFF2F4F5),
      );

      InstaAssetPicker.pickAssets(
        context,
        maxAssets: 1,
        requestType: RequestType.image,
        pickerConfig: InstaAssetPickerConfig(
          cropDelegate: const InstaAssetCropDelegate(
            cropRatios: [1.0],
          ),
          pickerTheme: pickerTheme,
        ),
        onCompleted: (stream) {
          stream.listen(
            (details) {
              if (!completer.isCompleted) {
                if (context.mounted) Navigator.of(context).pop();
                completer.complete(
                  details.selectedAssets.isNotEmpty
                      ? details.selectedAssets.first
                      : null,
                );
              }
            },
            onDone: () {
              if (!completer.isCompleted) completer.complete(null);
            },
            onError: (_) {
              if (!completer.isCompleted) completer.complete(null);
            },
            cancelOnError: true,
          );
        },
      ).then((result) {
        // If picker was dismissed without confirming (result is null/empty),
        // complete the completer so we don't hang forever.
        if (!completer.isCompleted) {
          completer.complete(
            result != null && result.isNotEmpty ? result.first : null,
          );
        }
      });

      return completer.future;
    } catch (e) {
      _isError = true;
      _errorMessage = 'Galeri erişimi reddedildi. Lütfen ayarlardan izin verin.';
      notifyListeners();
      return null;
    }
  }

  /// Converts AssetEntity to File and validates size (max 10MB).
  /// Throws exception if file is too large or conversion fails.
  Future<File> _assetToFile(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) {
      throw MediaException('Fotoğraf dosyasına erişilemedi');
    }
    final fileSize = await file.length();
    if (fileSize > 10 * 1024 * 1024) {
      throw MediaException('Fotoğraf çok büyük (maksimum 10MB)');
    }
    return file;
  }

  /// Loads media list from the service and maps to UI models.
  Future<void> _loadMediaList(String userId) async {
    if (_mediaList.isEmpty) {
      _isMediaLoading = true;
      notifyListeners();
    }

    try {
      final serviceMediaList =
          await _mediaService.getMediaList(userId: userId);

      _mediaList = serviceMediaList.map(_mapMedia).toList();
      _isMediaLoading = false;
      notifyListeners();
    } catch (error) {
      _handleError(error);
    }
  }

  /// Subscribes to realtime profile changes.
  void _subscribeToProfileChanges(String userId) {
    _profileChannel = _profileService.subscribeToProfileChanges(
      userId,
      (updatedProfile) {
        _profile = _mapProfile(updatedProfile, userId);
        notifyListeners();
      },
    );
  }

  /// Subscribes to realtime media changes.
  void _subscribeToMediaChanges(String userId) {
    _mediaChannel = _mediaService.subscribeToMediaChanges(
      userId,
      (event) {
        if (event.type == MediaEventType.insert && event.media != null) {
          final uiMedia = _mapMedia(event.media!);
          // Avoid duplicate — only add if not already in list
          final alreadyExists = _mediaList.any((m) => m.id == uiMedia.id);
          if (!alreadyExists) {
            _mediaList = [uiMedia, ..._mediaList];
            notifyListeners();
          }
        } else if (event.type == MediaEventType.delete && event.media != null) {
          final deletedId = event.media!.id;
          _mediaList = _mediaList.where((m) => m.id != deletedId).toList();
          notifyListeners();
        }
      },
    );
  }

  /// Unsubscribes from all realtime channels.
  Future<void> _unsubscribeAll() async {
    if (_profileChannel != null) {
      await _profileService.unsubscribeFromProfileChanges(_profileChannel!);
      _profileChannel = null;
    }
    if (_mediaChannel != null) {
      await _mediaService.unsubscribeFromMediaChanges(_mediaChannel!);
      _mediaChannel = null;
    }
  }

  // ---------------------------------------------------------------------------
  // Model mapping helpers
  // ---------------------------------------------------------------------------

  /// Maps service-layer Profile to UI Profile.
  ui.Profile _mapProfile(dynamic serviceProfile, String userId) {
    return ui.Profile(
      id: serviceProfile.id,
      fullName: serviceProfile.fullName ?? '',
      username: serviceProfile.fullName ?? '',
      bio: serviceProfile.bio,
      avatarUrl: serviceProfile.avatarUrl,
      coverImageUrl: null,
      createdAt: serviceProfile.updatedAt,
      updatedAt: serviceProfile.updatedAt,
    );
  }

  /// Maps service-layer UserStats to UI UserStats.
  ui.UserStats _mapStats(dynamic serviceStats) {
    return ui.UserStats(
      aiLooksCount: serviceStats.aiLooksCount,
      uploadsCount: serviceStats.uploadsCount,
      modelsCount: serviceStats.modelsCount,
    );
  }

  /// Maps service-layer Media to UI Media.
  ui.Media _mapMedia(dynamic serviceMedia) {
    ui.MediaType uiType;
    switch (serviceMedia.type.value) {
      case 'AI_CREATION':
        uiType = ui.MediaType.aiLook;
        break;
      case 'MODEL':
        uiType = ui.MediaType.model;
        break;
      case 'UPLOAD':
      default:
        uiType = ui.MediaType.upload;
        break;
    }

    return ui.Media(
      id: serviceMedia.id,
      type: uiType,
      imageUrl: serviceMedia.imageUrl,
      tag: serviceMedia.styleTag,
      createdAt: serviceMedia.createdAt,
      width: null,
      height: null,
    );
  }

  // ---------------------------------------------------------------------------
  // Error handling
  // ---------------------------------------------------------------------------

  /// Handles errors and sets appropriate error state with Turkish error messages.
  ///
  /// Validates Requirement 12
  void _handleError(dynamic error) {
    _isProfileLoading = false;
    _isMediaLoading = false;
    _isUploading = false;
    _isError = true;

    if (error is ProfileException) {
      _errorMessage = error.message;
    } else if (error is MediaException) {
      _errorMessage = error.message;
    } else if (error is app_storage.StorageException) {
      _errorMessage = error.message;
    } else if (error is PostgrestException) {
      _errorMessage = _mapPostgrestError(error.code);
    } else {
      _errorMessage = 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }

    notifyListeners();
  }

  /// Maps PostgreSQL error codes to Turkish user-friendly messages.
  String _mapPostgrestError(String? code) {
    switch (code) {
      case 'PGRST116':
        return 'Kayıt bulunamadı.';
      case '23505':
        return 'Bu kayıt zaten mevcut.';
      case '23503':
        return 'İlişkili kayıt bulunamadı.';
      case '42501':
        return 'Bu işlem için yetkiniz yok.';
      case 'PGRST301':
        return 'Bu işlem için yetkiniz yok.';
      default:
        return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  @override
  void dispose() {
    _unsubscribeAll();
    super.dispose();
  }
}
