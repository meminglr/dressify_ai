import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../models/generation_queue_item.dart';
import '../models/generation_request.dart';
import '../models/generation_status.dart';
import '../services/n8n_exception.dart';
import '../services/n8n_service.dart';

/// Singleton ViewModel managing the AI look generation queue, history, and
/// the persistent bottom sheet state.
///
/// Because the bottom sheet must persist across tab navigation, this ViewModel
/// is a singleton — a single instance lives for the entire app session and is
/// accessible via [GenerationQueueViewModel.instance].
///
/// Queue processing is sequential (FIFO): only one generation runs at a time
/// to avoid overwhelming the n8n API.
///
/// Session-based: the queue and history are cleared when the app is closed.
class GenerationQueueViewModel extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------

  static GenerationQueueViewModel? _instance;

  /// Returns the shared [GenerationQueueViewModel] instance.
  static GenerationQueueViewModel get instance =>
      _instance ??= GenerationQueueViewModel._();

  /// Private constructor — use [GenerationQueueViewModel.instance].
  GenerationQueueViewModel._() : _n8nService = N8nService.instance;

  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------

  final N8nService _n8nService;
  final _uuid = const Uuid();

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  /// Items waiting to be processed (FIFO order).
  final List<GenerationQueueItem> _queue = [];

  /// Completed (success or failed) items for the current session.
  final List<GenerationQueueItem> _history = [];

  /// The item currently being processed, or null if idle.
  GenerationQueueItem? _activeGeneration;

  /// Whether the bottom sheet is currently visible.
  bool _isBottomSheetVisible = false;

  /// Whether the bottom sheet is in minimized (mini player) state.
  bool _isMinimized = false;

  /// Whether the queue is currently being processed.
  bool _isProcessingQueue = false;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  List<GenerationQueueItem> get queue => List.unmodifiable(_queue);
  List<GenerationQueueItem> get history => List.unmodifiable(_history);
  GenerationQueueItem? get activeGeneration => _activeGeneration;
  bool get isProcessing => _activeGeneration != null;
  bool get hasQueue => _queue.isNotEmpty;
  bool get isBottomSheetVisible => _isBottomSheetVisible;
  bool get isMinimized => _isMinimized;

  /// Total number of items in queue + active generation.
  int get totalPending => _queue.length + (isProcessing ? 1 : 0);

  // ---------------------------------------------------------------------------
  // Queue management
  // ---------------------------------------------------------------------------

  /// Adds a new generation request to the queue.
  ///
  /// Enforces:
  /// - Maximum queue size of 10 items (returns false if exceeded)
  /// - Duplicate detection (same model + same wardrobe items)
  ///
  /// Returns `true` if the item was added, `false` otherwise.
  Future<bool> addToQueue({
    required GenerationRequest request,
    required String modelThumbnail,
    required List<String> wardrobeThumbnails,
  }) async {
    // Enforce max queue size (active + queued)
    if (totalPending >= 10) {
      debugPrint('GenerationQueueViewModel: queue is full (max 10)');
      return false;
    }

    // Duplicate detection: same personImageUrl + same garment URLs
    final isDuplicate = _isDuplicateRequest(request);
    if (isDuplicate) {
      debugPrint('GenerationQueueViewModel: duplicate request ignored');
      return false;
    }

    final item = GenerationQueueItem(
      id: _uuid.v4(),
      request: request,
      status: GenerationStatus.queued,
      timestamp: DateTime.now(),
      modelThumbnail: modelThumbnail,
      wardrobeThumbnails: wardrobeThumbnails,
    );

    _queue.add(item);
    showBottomSheet();
    notifyListeners();

    // Start processing if not already running
    _processQueue();
    return true;
  }

  /// Cancels a queued item (only items with [GenerationStatus.queued] can be cancelled).
  ///
  /// Returns `true` if the item was found and removed, `false` otherwise.
  bool cancelQueuedItem(String itemId) {
    final index = _queue.indexWhere(
      (item) => item.id == itemId && item.status == GenerationStatus.queued,
    );
    if (index == -1) return false;

    _queue.removeAt(index);
    notifyListeners();
    return true;
  }

  /// Re-queues a failed item from history.
  ///
  /// Finds the item in [history] by [itemId] and adds a fresh copy to the queue.
  Future<bool> retryFailedItem(String itemId) async {
    final historyItem = _history.cast<GenerationQueueItem?>().firstWhere(
          (item) => item?.id == itemId,
          orElse: () => null,
        );
    if (historyItem == null) return false;

    return addToQueue(
      request: historyItem.request,
      modelThumbnail: historyItem.modelThumbnail,
      wardrobeThumbnails: historyItem.wardrobeThumbnails,
    );
  }

  /// Removes a specific item from history.
  void removeFromHistory(String itemId) {
    final before = _history.length;
    _history.removeWhere((item) => item.id == itemId);
    if (_history.length != before) notifyListeners();
  }

  /// Clears all history items.
  void clearHistory() {
    if (_history.isEmpty) return;
    _history.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Bottom sheet state
  // ---------------------------------------------------------------------------

  void showBottomSheet() {
    if (_isBottomSheetVisible) return;
    _isBottomSheetVisible = true;
    _isMinimized = false;
    notifyListeners();
  }

  void hideBottomSheet() {
    if (!_isBottomSheetVisible) return;
    _isBottomSheetVisible = false;
    notifyListeners();
  }

  void minimizeBottomSheet() {
    if (_isMinimized) return;
    _isMinimized = true;
    notifyListeners();
  }

  void expandBottomSheet() {
    if (!_isMinimized) return;
    _isMinimized = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Queue processing (internal)
  // ---------------------------------------------------------------------------

  /// Processes the queue sequentially (FIFO).
  ///
  /// Guards against concurrent invocations with [_isProcessingQueue].
  Future<void> _processQueue() async {
    if (_isProcessingQueue || _queue.isEmpty) return;
    _isProcessingQueue = true;

    while (_queue.isNotEmpty) {
      final item = _queue.removeAt(0);
      await _processItem(item);
    }

    _isProcessingQueue = false;
    _activeGeneration = null;
    notifyListeners();
  }

  /// Processes a single queue item: calls the n8n API and updates state.
  Future<void> _processItem(GenerationQueueItem item) async {
    // Mark as processing
    _activeGeneration = item.copyWith(status: GenerationStatus.processing);
    notifyListeners();

    // Auto-minimize after 4 seconds so the user can continue browsing
    Future.delayed(const Duration(seconds: 4), () {
      if (_isBottomSheetVisible && !_isMinimized) {
        minimizeBottomSheet();
      }
    });

    try {
      final result = await _n8nService.generateLook(request: item.request);

      final imageUrl = result['image_url'] as String?;
      final mediaId = result['media_id'] as String?;

      final completed = _activeGeneration!.copyWith(
        status: GenerationStatus.completed,
        resultImageUrl: imageUrl,
        resultMediaId: mediaId,
      );

      _activeGeneration = completed;

      // Haptic feedback: generation complete
      HapticFeedback.heavyImpact();

      _moveActiveToHistory();
      notifyListeners();
    } on N8nException catch (e) {
      debugPrint('GenerationQueueViewModel: generation failed — ${e.message}');
      final failed = _activeGeneration!.copyWith(
        status: GenerationStatus.failed,
        errorMessage: e.message,
      );
      _activeGeneration = failed;
      // Haptic feedback: generation failed
      HapticFeedback.mediumImpact();
      _moveActiveToHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('GenerationQueueViewModel: unexpected error — $e');
      final failed = _activeGeneration!.copyWith(
        status: GenerationStatus.failed,
        errorMessage: 'Bir hata oluştu: ${e.toString()}',
      );
      _activeGeneration = failed;
      // Haptic feedback: generation failed
      HapticFeedback.mediumImpact();
      _moveActiveToHistory();
      notifyListeners();
    }
  }

  /// Moves the active generation to history and clears [_activeGeneration].
  void _moveActiveToHistory() {
    if (_activeGeneration == null) return;
    // Insert at the front so history is ordered most-recent-first
    _history.insert(0, _activeGeneration!);
    _activeGeneration = null;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns true if an identical request (same model + same garments) is
  /// already active or queued.
  bool _isDuplicateRequest(GenerationRequest request) {
    bool matches(GenerationQueueItem item) {
      if (item.request.personImageUrl != request.personImageUrl) return false;
      if (item.request.garments.length != request.garments.length) return false;
      final existingUrls =
          item.request.garments.map((g) => g.imageUrl).toSet();
      final newUrls = request.garments.map((g) => g.imageUrl).toSet();
      return existingUrls.containsAll(newUrls) &&
          newUrls.containsAll(existingUrls);
    }

    if (_activeGeneration != null && matches(_activeGeneration!)) return true;
    return _queue.any(matches);
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    // Singleton — intentionally not disposed during normal app lifecycle.
    // Called only if the singleton is explicitly reset (e.g. in tests).
    super.dispose();
  }
}
