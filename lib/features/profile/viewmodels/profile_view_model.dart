import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

class ProfileViewModel extends ChangeNotifier {
  final ProfileService _profileService;
  final MediaService _mediaService;
  final StorageService _storageService;
  final ImagePicker _imagePicker = ImagePicker();

  ui.Profile? _profile;
  ui.UserStats? _stats;
  List<ui.Media> _mediaList = [];

  bool _isProfileLoading = false;
  bool _isMediaLoading = false;
  bool _isUploading = false;
  bool _isError = false;
  String? _errorMessage;
  String? _successMessage;
  int _selectedTabIndex = 0;

  RealtimeChannel? _profileChannel;
  RealtimeChannel? _mediaChannel;

  ProfileViewModel({
    required ProfileService profileService,
    required MediaService mediaService,
    required StorageService storageService,
  })  : _profileService = profileService,
        _mediaService = mediaService,
        _storageService = storageService;

  ui.Profile? get profile => _profile;
  ui.UserStats? get stats => _stats;
  List<ui.Media> get mediaList => List.unmodifiable(_mediaList);
  bool get isProfileLoading => _isProfileLoading;
  bool get isMediaLoading => _isMediaLoading;
  bool get isUploading => _isUploading;
  bool get isError => _isError;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  int get selectedTabIndex => _selectedTabIndex;

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
        _isMediaLoading = true; // prevent empty state flash before media loads
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

  Future<void> refreshProfile() async {
    _profile = null;
    _stats = null;
    _mediaList = [];
    notifyListeners();
    await loadProfile(null);
  }

  void selectTab(int index) {
    if (_selectedTabIndex != index) {
      _selectedTabIndex = index;
      notifyListeners();
    }
  }

  void clearError() {
    _isError = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccessMessage() {
    _successMessage = null;
    notifyListeners();
  }

  Future<void> uploadGardiropPhoto(BuildContext context) async {
    final file = await _pickPhoto(context);
    if (file == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      _isUploading = true;
      notifyListeners();

      final newMedia = await _mediaService.addMedia(
        userId: userId,
        imageFile: file,
        type: lib_media.MediaType.upload,
      );

      _mediaList = [_mapMedia(newMedia), ..._mediaList];
      _isUploading = false;
      _successMessage = 'Kıyafet başarıyla eklendi';
      notifyListeners();
    } catch (error) {
      _handleError(error);
    }
  }

  Future<void> uploadModelPhoto(BuildContext context) async {
    final file = await _pickPhoto(context);
    if (file == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      _isUploading = true;
      notifyListeners();

      final newMedia = await _mediaService.addMedia(
        userId: userId,
        imageFile: file,
        type: lib_media.MediaType.model,
      );

      _mediaList = [_mapMedia(newMedia), ..._mediaList];
      _isUploading = false;
      _successMessage = 'Model başarıyla eklendi';
      notifyListeners();
    } catch (error) {
      _handleError(error);
    }
  }

  Future<void> uploadAvatarPhoto(BuildContext context) async {
    final file = await _pickPhoto(context);
    if (file == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final previousAvatarUrl = _profile?.avatarUrl;

    try {
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

      _profile = _mapProfile(updatedProfile, userId);
      _isUploading = false;
      _successMessage = 'Profil fotoğrafı güncellendi';
      notifyListeners();
    } catch (error) {
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
  // Photo picking — native image_picker
  // ---------------------------------------------------------------------------

  /// Shows a bottom sheet to choose gallery or camera, then returns the File.
  Future<File?> _pickPhoto(BuildContext context) async {
    final source = await _showSourcePicker(context);
    if (source == null) return null;

    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (picked == null) return null;

      final file = File(picked.path);
      final size = await file.length();
      if (size > 10 * 1024 * 1024) {
        throw MediaException('Fotoğraf çok büyük (maksimum 10MB)');
      }
      return file;
    } catch (e) {
      if (e is MediaException) rethrow;
      _isError = true;
      _errorMessage = 'Fotoğraf seçilirken bir hata oluştu.';
      notifyListeners();
      return null;
    }
  }

  Future<ImageSource?> _showSourcePicker(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFAEB3B5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Fotoğraf Ekle',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E3335),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _SourceButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Galeri',
                    onTap: () =>
                        Navigator.of(context).pop(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SourceButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'Kamera',
                    onTap: () =>
                        Navigator.of(context).pop(ImageSource.camera),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Media list
  // ---------------------------------------------------------------------------

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

  void _subscribeToProfileChanges(String userId) {
    _profileChannel = _profileService.subscribeToProfileChanges(
      userId,
      (updatedProfile) {
        _profile = _mapProfile(updatedProfile, userId);
        notifyListeners();
      },
    );
  }

  void _subscribeToMediaChanges(String userId) {
    _mediaChannel = _mediaService.subscribeToMediaChanges(
      userId,
      (event) {
        if (event.type == MediaEventType.insert && event.media != null) {
          final uiMedia = _mapMedia(event.media!);
          if (!_mediaList.any((m) => m.id == uiMedia.id)) {
            _mediaList = [uiMedia, ..._mediaList];
            notifyListeners();
          }
        } else if (event.type == MediaEventType.delete &&
            event.media != null) {
          _mediaList =
              _mediaList.where((m) => m.id != event.media!.id).toList();
          notifyListeners();
        }
      },
    );
  }

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
  // Model mapping
  // ---------------------------------------------------------------------------

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

  ui.UserStats _mapStats(dynamic serviceStats) {
    return ui.UserStats(
      aiLooksCount: serviceStats.aiLooksCount,
      uploadsCount: serviceStats.uploadsCount,
      modelsCount: serviceStats.modelsCount,
    );
  }

  ui.Media _mapMedia(dynamic serviceMedia) {
    ui.MediaType uiType;
    switch (serviceMedia.type.value) {
      case 'AI_CREATION':
        uiType = ui.MediaType.aiLook;
        break;
      case 'MODEL':
        uiType = ui.MediaType.model;
        break;
      default:
        uiType = ui.MediaType.upload;
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

  String _mapPostgrestError(String? code) {
    switch (code) {
      case 'PGRST116':
        return 'Kayıt bulunamadı.';
      case '23505':
        return 'Bu kayıt zaten mevcut.';
      case '23503':
        return 'İlişkili kayıt bulunamadı.';
      case '42501':
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

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF742FE5).withAlpha(15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF742FE5), size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF742FE5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
