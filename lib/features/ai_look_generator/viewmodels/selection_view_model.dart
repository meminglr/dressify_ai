import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profile/models/media.dart' as ui;
import '../../profile/viewmodels/profile_view_model.dart';
import '../models/garment_data.dart';
import '../models/generation_request.dart';
import '../utils/category_mapper.dart';
import 'generation_queue_view_model.dart';

/// ViewModel managing the selection state on the AI Look Generator screen.
///
/// Tracks which model photo and wardrobe items the user has selected, validates
/// the selection, and delegates generation requests to [GenerationQueueViewModel].
///
/// Follows the MVVM pattern: the View observes this ViewModel via [Consumer] or
/// [ChangeNotifierProvider] and calls its methods in response to user actions.
/// Only the fields that actually changed trigger a [notifyListeners] call, so
/// widgets that read unrelated getters are never rebuilt unnecessarily.
class SelectionViewModel extends ChangeNotifier {
  final ProfileViewModel _profileViewModel;
  final GenerationQueueViewModel _queueViewModel;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  String? _selectedModelId;
  final Set<String> _selectedWardrobeIds = {};

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

  SelectionViewModel({
    required ProfileViewModel profileViewModel,
    required GenerationQueueViewModel queueViewModel,
  })  : _profileViewModel = profileViewModel,
        _queueViewModel = queueViewModel;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// The ID of the currently selected model photo, or null if none selected.
  String? get selectedModelId => _selectedModelId;

  /// Unmodifiable view of the selected wardrobe item IDs.
  Set<String> get selectedWardrobeIds => Set.unmodifiable(_selectedWardrobeIds);

  /// Number of selected wardrobe items.
  int get selectedCount => _selectedWardrobeIds.length;

  /// Whether the user has made a valid selection to trigger generation.
  ///
  /// Requires exactly 1 model and 1–5 wardrobe items.
  bool get canGenerate =>
      _selectedModelId != null &&
      _selectedWardrobeIds.isNotEmpty &&
      _selectedWardrobeIds.length <= 5;

  /// Whether a specific wardrobe item is selected.
  bool isWardrobeItemSelected(String itemId) =>
      _selectedWardrobeIds.contains(itemId);

  // ---------------------------------------------------------------------------
  // Selection methods
  // ---------------------------------------------------------------------------

  /// Selects the model photo with [modelId].
  ///
  /// If the same model is already selected, this is a no-op (no rebuild).
  void selectModel(String modelId) {
    if (_selectedModelId == modelId) return;
    _selectedModelId = modelId;
    notifyListeners();
  }

  /// Toggles the selection state of the wardrobe item with [itemId].
  ///
  /// - If the item is already selected, it is deselected.
  /// - If the item is not selected and fewer than 5 items are selected, it is added.
  /// - If 5 items are already selected, returns `false` so the caller can show
  ///   a toast ("Maksimum 5 kıyafet seçebilirsiniz").
  ///
  /// Returns `true` if the state changed, `false` if the limit was hit.
  bool toggleWardrobeItem(String itemId) {
    if (_selectedWardrobeIds.contains(itemId)) {
      _selectedWardrobeIds.remove(itemId);
      notifyListeners();
      return true;
    }

    if (_selectedWardrobeIds.length >= 5) {
      // Limit reached — caller should show toast
      return false;
    }

    _selectedWardrobeIds.add(itemId);
    notifyListeners();
    return true;
  }

  /// Clears all selections (model + wardrobe).
  ///
  /// Called after a generation is queued or when the user taps "Yeni Look Oluştur".
  void clearSelections() {
    if (_selectedModelId == null && _selectedWardrobeIds.isEmpty) return;
    _selectedModelId = null;
    _selectedWardrobeIds.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Generation
  // ---------------------------------------------------------------------------

  /// Validates the current selection, builds a [GenerationRequest], and adds it
  /// to the [GenerationQueueViewModel] queue.
  ///
  /// Returns `true` on success, `false` if validation fails.
  /// After a successful queue addition, [clearSelections] is called automatically.
  Future<bool> generateLook() async {
    if (!canGenerate) return false;

    // Resolve authenticated user
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;

    // Find selected model in ProfileViewModel's reactive list
    final models = _profileViewModel.modelsListenable.value;
    final ui.Media? modelMedia = models.cast<ui.Media?>().firstWhere(
          (m) => m?.id == _selectedModelId,
          orElse: () => null,
        );
    if (modelMedia == null || modelMedia.imageUrl.isEmpty) return false;

    // Find selected wardrobe items
    final wardrobe = _profileViewModel.wardrobeListenable.value;
    final selectedItems = wardrobe
        .where((m) => _selectedWardrobeIds.contains(m.id))
        .toList();

    if (selectedItems.isEmpty) return false;

    // Validate all URLs are non-empty
    if (selectedItems.any((m) => m.imageUrl.isEmpty)) return false;

    // Map wardrobe items to GarmentData using CategoryMapper
    final garments = selectedItems.map((m) {
      final mediaTypeValue = _mediaTypeToString(m.type);
      final category = CategoryMapper.mapCategory(m.tag, mediaTypeValue);
      return GarmentData(
        imageUrl: m.imageUrl,
        category: category,
        // productName is not stored in the profile media model currently
      );
    }).toList();

    final request = GenerationRequest(
      userId: userId,
      personImageUrl: modelMedia.imageUrl,
      garments: garments,
    );

    // Collect thumbnail URLs for the queue item UI
    final modelThumbnail = modelMedia.imageUrl;
    final wardrobeThumbnails = selectedItems.map((m) => m.imageUrl).toList();

    await _queueViewModel.addToQueue(
      request: request,
      modelThumbnail: modelThumbnail,
      wardrobeThumbnails: wardrobeThumbnails,
    );

    // Clear selections after successful queue addition
    clearSelections();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Converts the profile-layer [ui.MediaType] to the raw string value used by
  /// [CategoryMapper] (matches the database CHECK constraint values).
  String _mediaTypeToString(ui.MediaType type) {
    switch (type) {
      case ui.MediaType.trendyolProduct:
        return 'TRENDYOL_PRODUCT';
      case ui.MediaType.upload:
        return 'UPLOAD';
      case ui.MediaType.model:
        return 'MODEL';
      case ui.MediaType.aiLook:
        return 'AI_CREATION';
    }
  }
}
