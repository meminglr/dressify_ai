import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/generation_queue_item.dart';
import '../models/generation_request.dart';
import '../models/generation_status.dart';
import '../services/n8n_exception.dart';
import '../services/n8n_service.dart';
import '../services/generation_queue_service.dart';

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
/// **Supabase Integration**: Queue and history are persisted to Supabase,
/// allowing users to see their generation history across sessions.
class GenerationQueueViewModel extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------

  static GenerationQueueViewModel? _instance;

  /// Returns the shared [GenerationQueueViewModel] instance.
  static GenerationQueueViewModel get instance =>
      _instance ??= GenerationQueueViewModel._();

  /// Private constructor — use [GenerationQueueViewModel.instance].
  GenerationQueueViewModel._()
      : _n8nService = N8nService.instance,
        _queueService = GenerationQueueService();

  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------

  final N8nService _n8nService;
  final GenerationQueueService _queueService;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  /// Items waiting to be processed (FIFO order).
  final List<GenerationQueueItem> _queue = [];

  /// Completed (success or failed) items - loaded from Supabase.
  final List<GenerationQueueItem> _history = [];

  /// The item currently being processed, or null if idle.
  GenerationQueueItem? _activeGeneration;

  /// Whether the queue is currently being processed.
  bool _isProcessingQueue = false;

  /// Whether data is being loaded from Supabase.
  bool _isLoading = false;

  /// Realtime subscription channel.
  RealtimeChannel? _realtimeChannel;

  /// Whether the ViewModel has been initialized (data loaded from Supabase).
  bool _isInitialized = false;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  List<GenerationQueueItem> get queue => List.unmodifiable(_queue);
  List<GenerationQueueItem> get history => List.unmodifiable(_history);
  GenerationQueueItem? get activeGeneration => _activeGeneration;
  bool get isProcessing => _activeGeneration != null;
  bool get hasQueue => _queue.isNotEmpty;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  /// Total number of items in queue + active generation.
  int get totalPending => _queue.length + (isProcessing ? 1 : 0);

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initializes the ViewModel by loading queue and history from Supabase.
  ///
  /// Should be called once when the app starts. Subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Load active queue and history from Supabase
      final activeQueue = await _queueService.fetchActiveQueue();
      final historyItems = await _queueService.fetchHistory();

      _queue.clear();
      _history.clear();

      // Separate active item from queue
      if (activeQueue.isNotEmpty) {
        final processingItem = activeQueue.firstWhere(
          (item) => item.status == GenerationStatus.processing,
          orElse: () => activeQueue.first,
        );

        if (processingItem.status == GenerationStatus.processing) {
          _activeGeneration = processingItem;
          _queue.addAll(activeQueue.where((item) => item.id != processingItem.id));
        } else {
          _queue.addAll(activeQueue);
        }
      }

      _history.addAll(historyItems);

      // Subscribe to realtime updates
      _subscribeToRealtimeUpdates();

      // Resume processing if there's an active item or queued items
      if (_activeGeneration != null || _queue.isNotEmpty) {
        if (_activeGeneration != null) {
          _isProcessingQueue = true;
          _resumeProcessing(_activeGeneration!);
        } else if (_queue.isNotEmpty) {
          _processQueue();
        }
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('GenerationQueueViewModel: initialization failed — $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
    required String modelMediaId,
    required List<String> wardrobeMediaIds,
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

    try {
      // Create item in Supabase
      final item = await _queueService.createQueueItem(
        modelMediaId: modelMediaId,
        modelThumbnail: modelThumbnail,
        wardrobeMediaIds: wardrobeMediaIds,
        wardrobeThumbnails: wardrobeThumbnails,
        request: request,
      );

      _queue.add(item);

      // Eğer queue boşsa (ilk item), hemen processing'e al
      final shouldStartImmediately = !_isProcessingQueue && _queue.length == 1;

      notifyListeners();

      // Start processing if not already running
      if (shouldStartImmediately) {
        // İlk item'ı hemen processing'e al (senkron)
        _activeGeneration = _queue.removeAt(0);
        _isProcessingQueue = true;
        
        // Mark as processing in Supabase
        await _queueService.markAsProcessing(_activeGeneration!.id);
        _activeGeneration = _activeGeneration!.copyWith(
          status: GenerationStatus.processing,
        );
        notifyListeners();

        // Async processing'i başlat
        _processItem(_activeGeneration!).then((_) {
          _isProcessingQueue = false;
          _activeGeneration = null;
          notifyListeners();
          // Sırada başka item varsa devam et
          if (_queue.isNotEmpty) _processQueue();
        });
      } else if (!_isProcessingQueue) {
        _processQueue();
      }

      return true;
    } catch (e) {
      debugPrint('GenerationQueueViewModel: failed to add to queue — $e');
      return false;
    }
  }

  /// Cancels a queued item (only items with [GenerationStatus.queued] can be cancelled).
  ///
  /// Returns `true` if the item was found and removed, `false` otherwise.
  Future<bool> cancelQueuedItem(String itemId) async {
    final index = _queue.indexWhere(
      (item) => item.id == itemId && item.status == GenerationStatus.queued,
    );
    if (index == -1) return false;

    try {
      await _queueService.deleteQueueItem(itemId);
      _queue.removeAt(index);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('GenerationQueueViewModel: failed to cancel item — $e');
      return false;
    }
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

    // Extract media IDs from the request (we need to get them from somewhere)
    // For now, we'll create a new request without media IDs
    // This is a limitation - we should store media IDs in the request
    return addToQueue(
      request: historyItem.request,
      modelThumbnail: historyItem.modelThumbnail,
      wardrobeThumbnails: historyItem.wardrobeThumbnails,
      modelMediaId: '', // TODO: Store media IDs in request
      wardrobeMediaIds: [],
    );
  }

  /// Removes a specific item from history.
  Future<void> removeFromHistory(String itemId) async {
    try {
      await _queueService.deleteQueueItem(itemId);
      final before = _history.length;
      _history.removeWhere((item) => item.id == itemId);
      if (_history.length != before) notifyListeners();
    } catch (e) {
      debugPrint('GenerationQueueViewModel: failed to remove from history — $e');
    }
  }

  /// Clears all history items.
  Future<void> clearHistory() async {
    if (_history.isEmpty) return;
    try {
      await _queueService.clearHistory();
      _history.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('GenerationQueueViewModel: failed to clear history — $e');
    }
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

      // Mark as processing in Supabase
      await _queueService.markAsProcessing(item.id);
      
      // İlk item için hemen processing durumuna geç (await öncesi)
      _activeGeneration = item.copyWith(status: GenerationStatus.processing);
      notifyListeners();

      await _processItem(item);
    }

    _isProcessingQueue = false;
    _activeGeneration = null;
    notifyListeners();
  }

  /// Resumes processing an item that was interrupted (e.g., app restart).
  Future<void> _resumeProcessing(GenerationQueueItem item) async {
    await _processItem(item);
    _isProcessingQueue = false;
    _activeGeneration = null;
    notifyListeners();
    
    // Continue with queue if there are more items
    if (_queue.isNotEmpty) _processQueue();
  }

  /// Processes a single queue item: calls the n8n API and updates state.
  Future<void> _processItem(GenerationQueueItem item) async {
    final startTime = DateTime.now();
    
    try {
      final result = await _n8nService.generateLook(request: item.request);

      final imageUrl = result['image_url'] as String?;
      final mediaId = result['media_id'];

      // Double-check: N8nService should have validated these, but be defensive
      if (imageUrl == null || imageUrl.isEmpty) {
        throw N8nException('Görüntü URL\'si alınamadı');
      }
      if (mediaId == null) {
        throw N8nException('Medya ID\'si alınamadı');
      }

      // Update in Supabase
      await _queueService.markAsCompleted(
        itemId: item.id,
        resultImageUrl: imageUrl,
        resultMediaId: mediaId.toString(),
        startedAt: startTime,
      );

      final completed = _activeGeneration!.copyWith(
        status: GenerationStatus.completed,
        resultImageUrl: imageUrl,
        resultMediaId: mediaId.toString(),
      );

      _activeGeneration = completed;

      // Haptic feedback: generation complete
      HapticFeedback.heavyImpact();

      _moveActiveToHistory();
      notifyListeners();
    } on N8nException catch (e) {
      debugPrint('GenerationQueueViewModel: generation failed — ${e.message}');
      
      // Update in Supabase
      await _queueService.markAsFailed(
        itemId: item.id,
        errorMessage: e.message,
        startedAt: startTime,
      );

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
      
      // Update in Supabase
      await _queueService.markAsFailed(
        itemId: item.id,
        errorMessage: 'Bir hata oluştu: ${e.toString()}',
        startedAt: startTime,
      );

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

  /// Subscribes to realtime updates from Supabase.
  void _subscribeToRealtimeUpdates() {
    _realtimeChannel = _queueService.subscribeToQueue(
      onInsert: (item) {
        // New item added (possibly from another device/session)
        if (item.status == GenerationStatus.queued) {
          _queue.add(item);
          notifyListeners();
          
          // Start processing if not already running
          if (!_isProcessingQueue) {
            _processQueue();
          }
        }
      },
      onUpdate: (item) {
        // Item status updated
        if (item.status == GenerationStatus.completed || 
            item.status == GenerationStatus.failed) {
          // Move to history if not already there
          if (!_history.any((h) => h.id == item.id)) {
            _history.insert(0, item);
          }
          
          // Remove from queue if present
          _queue.removeWhere((q) => q.id == item.id);
          
          // Update active generation if it's the same item
          if (_activeGeneration?.id == item.id) {
            _activeGeneration = item;
          }
          
          notifyListeners();
        }
      },
      onDelete: (itemId) {
        // Item deleted
        _queue.removeWhere((item) => item.id == itemId);
        _history.removeWhere((item) => item.id == itemId);
        
        if (_activeGeneration?.id == itemId) {
          _activeGeneration = null;
        }
        
        notifyListeners();
      },
    );
  }

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
    // Unsubscribe from realtime updates
    if (_realtimeChannel != null) {
      _queueService.unsubscribe(_realtimeChannel!);
      _realtimeChannel = null;
    }
    
    // Singleton — intentionally not disposed during normal app lifecycle.
    // Called only if the singleton is explicitly reset (e.g. in tests).
    super.dispose();
  }
}
