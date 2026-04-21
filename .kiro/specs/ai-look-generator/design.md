# Design Document: AI Look Generator

## Overview

The AI Look Generator is a new feature for the Dressify Flutter app that enables users to create AI-generated outfit visualizations by combining model photos with wardrobe items. The feature integrates multi-garment virtual try-on technology powered by n8n workflows and Gemini AI.

### Key Design Principles

1. **MVVM Architecture**: Strict separation between View, ViewModel, and Model layers following existing ProfileViewModel patterns
2. **Reactive State Management**: Use ValueListenable and ChangeNotifier for efficient, selective UI updates
3. **Performance First**: Minimize rebuilds, use lazy loading, implement efficient caching
4. **Persistent Bottom Sheet**: Global overlay that persists across tab navigation (YouTube mini player style)
5. **Sequential Queue Processing**: FIFO queue system for handling multiple generation requests
6. **Reuse Existing Services**: Leverage ProfileViewModel, MediaService, StorageService

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         Home Widget                          │
│  ┌────────────┬────────────┬────────────┬────────────┐     │
│  │  Tab 0     │  Tab 1     │  Tab 2     │  Tab 3     │     │
│  │  Home      │  Trendyol  │  AI Look   │  Profile   │     │
│  │            │            │  Generator │            │     │
│  └────────────┴────────────┴────────────┴────────────┘     │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │      GenerationBottomSheet (Global Overlay)         │   │
│  │  Managed by GenerationQueueViewModel (Singleton)    │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘

Data Flow:
ProfileViewModel (Singleton)
  ├─> modelsListenable → SelectionScreen → Model Carousel
  └─> wardrobeListenable → SelectionScreen → Wardrobe Grid

SelectionViewModel
  ├─> Selection State (selectedModelId, selectedWardrobeIds)
  └─> Validation Logic

GenerationQueueViewModel (Singleton)
  ├─> Generation Queue (FIFO)
  ├─> Generation History (Session-based)
  ├─> Active Generation State
  └─> N8nService → n8n API
```

## Architecture

### Layer Structure

#### 1. Presentation Layer (View)

**SelectionScreen** (`lib/features/ai_look_generator/screens/selection_screen.dart`)
- Main screen replacing tab index 2 placeholder
- Displays model carousel and wardrobe grid
- Handles user selection interactions
- Shows fixed bottom "Oluştur" button

**GenerationBottomSheet** (`lib/features/ai_look_generator/widgets/generation_bottom_sheet.dart`)
- Global overlay widget persisting across tabs
- Two states: Mini Player (minimized) and Full Sheet (expanded)
- Displays generation progress, queue, and history
- Handles drag gestures for minimize/expand

**MiniPlayer** (`lib/features/ai_look_generator/widgets/mini_player.dart`)
- Minimized bottom sheet state (80-100px height)
- Shows progress indicator, status text, expand/close buttons
- Persists above navigation bar across all tabs

**Components:**
- `ModelCarousel` - Horizontal scrollable carousel for model selection
- `WardrobeGrid` - 2-column masonry grid for wardrobe selection
- `GenerationProgressView` - Animated progress display
- `QueueListView` - List of queued generations
- `HistoryListView` - List of completed generations
- `EmptyStateWidget` - Reusable empty state component

#### 2. ViewModel Layer

**SelectionViewModel** (`lib/features/ai_look_generator/viewmodels/selection_view_model.dart`)
- Manages selection state (selectedModelId, selectedWardrobeIds)
- Validates selections (1 model + 1-5 wardrobe items)
- Provides reactive state via ChangeNotifier
- Communicates with GenerationQueueViewModel to queue generations

**GenerationQueueViewModel** (`lib/features/ai_look_generator/viewmodels/generation_queue_view_model.dart`)
- **Singleton** - Accessible globally for persistent bottom sheet
- Manages generation queue (FIFO processing)
- Manages generation history (session-based)
- Tracks active generation state
- Communicates with N8nService for API calls
- Provides reactive state for bottom sheet UI

#### 3. Service Layer

**N8nService** (`lib/features/ai_look_generator/services/n8n_service.dart`)
- Handles HTTP communication with n8n webhook
- Constructs generation requests with proper payload format
- Implements timeout handling (180 seconds)
- Provides error handling and retry logic

**Existing Services (Reused):**
- `ProfileViewModel` - Access to models and wardrobe via reactive listeners
- `MediaService` - No direct usage (n8n handles media creation)
- `StorageService` - No direct usage (n8n handles storage)

#### 4. Model Layer

**GenerationRequest** (`lib/features/ai_look_generator/models/generation_request.dart`)
- Represents a generation request payload
- Contains: userId, personImageUrl, garments array

**GenerationQueueItem** (`lib/features/ai_look_generator/models/generation_queue_item.dart`)
- Represents a single item in the queue
- Contains: id, request, status, timestamp, result, error

**GenerationStatus** (enum)
- `queued` - Waiting in queue
- `processing` - Currently being generated
- `completed` - Successfully completed
- `failed` - Failed with error

**GarmentData** (`lib/features/ai_look_generator/models/garment_data.dart`)
- Represents a single garment in the request
- Contains: imageUrl, category, productName (optional)

## Components and Interfaces

### SelectionViewModel

```dart
class SelectionViewModel extends ChangeNotifier {
  final ProfileViewModel _profileViewModel;
  final GenerationQueueViewModel _generationQueueViewModel;
  
  String? _selectedModelId;
  Set<String> _selectedWardrobeIds = {};
  
  // Getters
  String? get selectedModelId => _selectedModelId;
  Set<String> get selectedWardrobeIds => Set.unmodifiable(_selectedWardrobeIds);
  bool get canGenerate => _selectedModelId != null && 
                          _selectedWardrobeIds.isNotEmpty && 
                          _selectedWardrobeIds.length <= 5;
  int get selectedCount => _selectedWardrobeIds.length;
  
  // Selection methods
  void selectModel(String modelId);
  void toggleWardrobeItem(String itemId);
  void clearSelections();
  
  // Generation
  Future<void> generateLook();
}
```

### GenerationQueueViewModel

```dart
class GenerationQueueViewModel extends ChangeNotifier {
  static GenerationQueueViewModel? _instance;
  static GenerationQueueViewModel get instance => _instance ??= GenerationQueueViewModel._();
  
  final N8nService _n8nService;
  final List<GenerationQueueItem> _queue = [];
  final List<GenerationQueueItem> _history = [];
  GenerationQueueItem? _activeGeneration;
  
  // Getters
  List<GenerationQueueItem> get queue => List.unmodifiable(_queue);
  List<GenerationQueueItem> get history => List.unmodifiable(_history);
  GenerationQueueItem? get activeGeneration => _activeGeneration;
  bool get isProcessing => _activeGeneration != null;
  bool get hasQueue => _queue.isNotEmpty;
  
  // Queue management
  Future<void> addToQueue(GenerationRequest request);
  void cancelQueuedItem(String itemId);
  void retryFailedItem(String itemId);
  void clearHistory();
  void removeFromHistory(String itemId);
  
  // Bottom sheet state
  bool _isBottomSheetVisible = false;
  bool _isMinimized = false;
  
  bool get isBottomSheetVisible => _isBottomSheetVisible;
  bool get isMinimized => _isMinimized;
  
  void showBottomSheet();
  void hideBottomSheet();
  void minimizeBottomSheet();
  void expandBottomSheet();
  
  // Internal processing
  Future<void> _processQueue();
  Future<void> _processItem(GenerationQueueItem item);
}
```

### N8nService

```dart
class N8nService {
  static const String _baseUrl = 'https://n8n.emniva.com';
  static const String _endpoint = '/webhook/tryon-multi';
  static const Duration _timeout = Duration(seconds: 180);
  
  final http.Client _client;
  
  Future<GenerationResult> generateLook({
    required String userId,
    required String personImageUrl,
    required List<GarmentData> garments,
  });
  
  // Category mapping
  String _mapCategory(String? styleTag, MediaType type);
}
```

### SelectionScreen

```dart
class SelectionScreen extends StatelessWidget {
  final ScrollController scrollController;
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SelectionViewModel(
        profileViewModel: context.read<ProfileViewModel>(),
        generationQueueViewModel: GenerationQueueViewModel.instance,
      ),
      child: Scaffold(
        appBar: AppBar(title: Text('AI Look Oluştur')),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    _ModelSelectionSection(),
                    _WardrobeSelectionSection(),
                  ],
                ),
              ),
            ),
            _GenerateButton(),
          ],
        ),
      ),
    );
  }
}
```

### GenerationBottomSheet

```dart
class GenerationBottomSheet extends StatefulWidget {
  @override
  State<GenerationBottomSheet> createState() => _GenerationBottomSheetState();
}

class _GenerationBottomSheetState extends State<GenerationBottomSheet> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  Widget build(BuildContext context) {
    return Consumer<GenerationQueueViewModel>(
      builder: (context, viewModel, child) {
        if (!viewModel.isBottomSheetVisible) return SizedBox.shrink();
        
        if (viewModel.isMinimized) {
          return MiniPlayer();
        } else {
          return _FullSheet();
        }
      },
    );
  }
}
```

## Data Models

### GenerationRequest

```dart
class GenerationRequest {
  final String userId;
  final String personImageUrl;
  final List<GarmentData> garments;
  
  GenerationRequest({
    required this.userId,
    required this.personImageUrl,
    required this.garments,
  });
  
  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'person_image_url': personImageUrl,
    'garments': garments.map((g) => g.toJson()).toList(),
  };
}
```

### GenerationQueueItem

```dart
class GenerationQueueItem {
  final String id;
  final GenerationRequest request;
  final GenerationStatus status;
  final DateTime timestamp;
  final String? resultImageUrl;
  final String? resultMediaId;
  final String? errorMessage;
  
  // For UI display
  final String modelThumbnail;
  final List<String> wardrobeThumbnails;
  
  GenerationQueueItem({
    required this.id,
    required this.request,
    required this.status,
    required this.timestamp,
    required this.modelThumbnail,
    required this.wardrobeThumbnails,
    this.resultImageUrl,
    this.resultMediaId,
    this.errorMessage,
  });
  
  GenerationQueueItem copyWith({...});
}
```

### GarmentData

```dart
class GarmentData {
  final String imageUrl;
  final String category;
  final String? productName;
  
  GarmentData({
    required this.imageUrl,
    required this.category,
    this.productName,
  });
  
  Map<String, dynamic> toJson() => {
    'image_url': imageUrl,
    'category': category,
    if (productName != null) 'product_name': productName,
  };
}
```

### Category Mapping

```dart
class CategoryMapper {
  static const Map<String, String> _categoryMap = {
    'tshirt': 'Tişört',
    'blouse': 'Bluz',
    'shirt': 'Gömlek',
    'pants': 'Pantolon',
    'jeans': 'Jeans',
    'shorts': 'Şort',
    'skirt': 'Etek',
    'dress': 'Elbise',
    'jumpsuit': 'Tulum',
    'jacket': 'Ceket',
    'coat': 'Mont',
    'cardigan': 'Hırka',
    'shoes': 'Ayakkabı',
    'boots': 'Bot',
    'sneakers': 'Sneaker',
    'accessories': 'Aksesuar',
    'belt': 'Kemer',
    'bag': 'Çanta',
    'hat': 'Şapka',
  };
  
  static String mapCategory(String? styleTag, MediaType type) {
    if (styleTag != null && _categoryMap.containsKey(styleTag.toLowerCase())) {
      return _categoryMap[styleTag.toLowerCase()]!;
    }
    
    // Default fallback based on type
    return type == MediaType.trendyolProduct ? 'Kıyafet' : 'Giysi';
  }
}
```

## Error Handling

### Error Types

1. **Network Errors**
   - Connection timeout
   - No internet connection
   - DNS resolution failure
   - Message: "İnternet bağlantınızı kontrol edin"

2. **API Errors**
   - 4xx client errors (invalid request)
   - 5xx server errors (n8n/Gemini failure)
   - Message: "Sunucu hatası. Lütfen tekrar deneyin"

3. **Timeout Errors**
   - Request exceeds 180 seconds
   - Message: "İstek zaman aşımına uğradı"

4. **Validation Errors**
   - Invalid image URLs
   - Missing required fields
   - Message: "Geçersiz veri. Lütfen tekrar deneyin"

5. **Authentication Errors**
   - Session expired
   - Message: "Oturumunuz sonlandı. Lütfen tekrar giriş yapın"

### Error Handling Strategy

```dart
class N8nService {
  Future<GenerationResult> generateLook({...}) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl$_endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return GenerationResult.success(
            imageUrl: data['image_url'],
            mediaId: data['media_id'],
          );
        } else {
          throw N8nException('API returned success=false');
        }
      } else {
        throw N8nException('HTTP ${response.statusCode}');
      }
    } on TimeoutException {
      throw N8nException('İstek zaman aşımına uğradı');
    } on SocketException {
      throw N8nException('İnternet bağlantınızı kontrol edin');
    } catch (e) {
      throw N8nException('Bir hata oluştu: ${e.toString()}');
    }
  }
}
```

### Error Recovery

1. **Retry Logic**: Users can manually retry failed generations via "Tekrar Dene" button
2. **Queue Preservation**: Failed items move to history but can be re-queued
3. **User Feedback**: Clear error messages with actionable guidance
4. **Logging**: All errors logged to console for debugging

## Testing Strategy

### Unit Tests

**SelectionViewModel Tests:**
- Model selection updates state correctly
- Wardrobe item toggle adds/removes from set
- Validation logic (canGenerate) works correctly
- Maximum 5 items enforced
- Clear selections resets state

**GenerationQueueViewModel Tests:**
- Queue items are processed in FIFO order
- Active generation state updates correctly
- History items are added after completion
- Cancel queued item removes from queue
- Retry failed item re-queues correctly
- Bottom sheet visibility state management

**N8nService Tests:**
- Request payload is constructed correctly
- Category mapping works for all types
- Timeout handling works
- Error responses are handled correctly
- Success responses are parsed correctly

**CategoryMapper Tests:**
- All category mappings return correct Turkish strings
- Fallback logic works for unknown categories
- Case-insensitive matching works

### Integration Tests

**Selection Flow:**
- User can select model from carousel
- User can select/deselect wardrobe items
- Generate button enables/disables correctly
- Empty states display when no data

**Generation Flow:**
- Tapping generate opens bottom sheet
- Bottom sheet shows progress correctly
- Bottom sheet minimizes automatically after 3-5 seconds
- Mini player persists across tab navigation
- Completed generation shows result
- Failed generation shows error

**Queue System:**
- Multiple generations queue correctly
- Queue processes sequentially
- Cancel queued item works
- Retry failed item works

### Widget Tests

**SelectionScreen:**
- Model carousel renders correctly
- Wardrobe grid renders correctly
- Selection indicators display correctly
- Empty states render correctly

**GenerationBottomSheet:**
- Mini player renders correctly
- Full sheet renders correctly
- Drag gestures work correctly
- Tab switching works (Şu An / Geçmiş)

**MiniPlayer:**
- Progress indicator displays
- Status text updates correctly
- Expand/close buttons work
- Color changes based on status

### Performance Tests

- Initial screen load < 500ms
- Selection feedback < 100ms
- Grid scrolling maintains 60fps
- Bottom sheet animations run at 60fps
- Memory usage stays reasonable with large queues

## Implementation Plan

### Phase 1: Core Models and Services (Day 1)

1. Create model classes:
   - `GenerationRequest`
   - `GenerationQueueItem`
   - `GarmentData`
   - `GenerationStatus` enum
   - `CategoryMapper`

2. Implement `N8nService`:
   - HTTP client setup
   - Request/response handling
   - Error handling
   - Timeout logic

3. Write unit tests for models and service

### Phase 2: ViewModels (Day 2)

1. Implement `SelectionViewModel`:
   - Selection state management
   - Validation logic
   - Integration with ProfileViewModel

2. Implement `GenerationQueueViewModel`:
   - Singleton pattern
   - Queue management (FIFO)
   - History management
   - Bottom sheet state
   - Integration with N8nService

3. Write unit tests for ViewModels

### Phase 3: UI Components (Day 3-4)

1. Create reusable widgets:
   - `ModelCarousel`
   - `WardrobeGrid`
   - `EmptyStateWidget`
   - `SelectionIndicator`

2. Implement `SelectionScreen`:
   - Layout structure
   - Model selection section
   - Wardrobe selection section
   - Generate button
   - Empty states

3. Write widget tests

### Phase 4: Bottom Sheet (Day 5-6)

1. Implement `MiniPlayer`:
   - Layout and styling
   - Progress indicator
   - Status text
   - Expand/close buttons

2. Implement `GenerationBottomSheet`:
   - Full sheet layout
   - Drag gestures
   - Tab bar (Şu An / Geçmiş)
   - Progress view
   - Result view
   - Error view

3. Implement queue and history lists

4. Write widget tests

### Phase 5: Integration (Day 7)

1. Replace tab index 2 placeholder in `home.dart`
2. Add global overlay for persistent bottom sheet
3. Integrate with existing ProfileViewModel
4. Test tab navigation with persistent bottom sheet
5. Test complete user flow

### Phase 6: Polish and Testing (Day 8)

1. Add animations and transitions
2. Implement haptic feedback
3. Add accessibility labels
4. Performance optimization
5. Integration testing
6. Bug fixes

## Performance Optimization

### Selective Rebuilds

```dart
// Use Consumer with specific selector to rebuild only when needed
Consumer<SelectionViewModel>(
  builder: (context, viewModel, child) {
    return Text('${viewModel.selectedCount} / 5 SEÇİLDİ');
  },
)

// Use ValueListenableBuilder for ProfileViewModel data
ValueListenableBuilder<List<Media>>(
  valueListenable: profileViewModel.modelsListenable,
  builder: (context, models, child) {
    return ModelCarousel(models: models);
  },
)
```

### Image Caching

```dart
// Use cached_network_image with memory cache
CachedNetworkImage(
  imageUrl: media.imageUrl,
  memCacheWidth: 312, // Match display width
  memCacheHeight: 312,
  placeholder: (context, url) => ShimmerPlaceholder(),
  errorWidget: (context, url, error) => ErrorPlaceholder(),
)
```

### Lazy Loading

```dart
// Use ListView.builder for queue and history
ListView.builder(
  itemCount: viewModel.history.length,
  itemBuilder: (context, index) {
    final item = viewModel.history[index];
    return HistoryItemCard(item: item);
  },
)
```

### Debouncing

```dart
// Debounce generate button to prevent duplicate requests
Timer? _debounceTimer;

void _onGenerateTapped() {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(seconds: 1), () {
    viewModel.generateLook();
  });
}
```

## Accessibility

### Semantic Labels

```dart
// Model carousel cards
Semantics(
  label: 'Model fotoğrafı ${index + 1}',
  selected: isSelected,
  child: ModelCard(...),
)

// Wardrobe grid items
Semantics(
  label: '${category} kıyafeti',
  selected: isSelected,
  child: WardrobeItemCard(...),
)

// Generate button
Semantics(
  label: 'Look oluştur',
  enabled: canGenerate,
  button: true,
  child: GenerateButton(...),
)
```

### Color Contrast

- All text meets WCAG AA standards (4.5:1 for normal text)
- Primary purple (#742FE5) on white background: 4.8:1 ✓
- OnSurface (#2E3335) on white background: 13.2:1 ✓

### Touch Targets

- All interactive elements minimum 44x44 points
- Mini player expand/close buttons: 48x48 points
- Model carousel cards: 312x312 points
- Wardrobe grid items: 163x163 points

### Haptic Feedback

```dart
// On selection
HapticFeedback.selectionClick();

// On generation start
HapticFeedback.mediumImpact();

// On generation complete
HapticFeedback.heavyImpact();
```

## Security Considerations

1. **Authentication**: All API calls include user_id from authenticated session
2. **URL Validation**: Validate image URLs before sending to n8n
3. **Input Sanitization**: Sanitize any user input (though minimal in this feature)
4. **HTTPS Only**: All API calls use HTTPS
5. **Session Handling**: Handle expired sessions gracefully with re-authentication prompt

## Monitoring and Analytics

### Key Metrics to Track

1. **Feature Adoption**:
   - Number of users who open AI Look Generator tab
   - Percentage of active users who try the feature

2. **Generation Success Rate**:
   - Successful generations / Total generation attempts
   - Target: > 90%

3. **Error Rates**:
   - Network errors
   - API errors
   - Timeout errors

4. **Performance Metrics**:
   - Initial screen load time
   - Selection response time
   - Bottom sheet animation frame rate

5. **User Behavior**:
   - Average number of wardrobe items selected per generation
   - Queue usage (how many users queue multiple generations)
   - Retry rate for failed generations

### Logging

```dart
// Log generation attempts
logger.info('Generation started', {
  'user_id': userId,
  'model_id': modelId,
  'wardrobe_count': wardrobeIds.length,
});

// Log generation results
logger.info('Generation completed', {
  'user_id': userId,
  'duration_seconds': duration.inSeconds,
  'success': success,
});

// Log errors
logger.error('Generation failed', {
  'user_id': userId,
  'error': error.toString(),
  'error_type': errorType,
});
```

## Future Enhancements

1. **Persistent Queue**: Save queue to local storage to survive app restarts
2. **Background Processing**: Continue generation when app is in background
3. **Push Notifications**: Notify user when generation completes
4. **Batch Generation**: Generate multiple looks with different combinations automatically
5. **Style Presets**: Predefined style combinations (casual, formal, sporty)
6. **AI Suggestions**: Suggest wardrobe combinations based on model and occasion
7. **Social Sharing**: Share generated looks to social media
8. **Favorites**: Mark favorite generated looks for quick access
9. **Advanced Filters**: Filter wardrobe by category, color, season
10. **Generation History Persistence**: Save history across sessions

## Dependencies

### Required Packages

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0  # State management
  http: ^1.1.0  # HTTP client for n8n API
  cached_network_image: ^3.3.0  # Image caching
  uuid: ^4.0.0  # Generate unique IDs for queue items
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0  # Mocking for tests
  build_runner: ^2.4.0  # Code generation for mocks
```

### Existing Dependencies (Reused)

- `supabase_flutter` - Authentication and realtime
- `image_picker` - Not used directly (ProfileViewModel handles uploads)
- `iconsax` - Icons
- `flutter_floating_bottom_bar` - Bottom navigation

## File Structure

```
lib/features/ai_look_generator/
├── models/
│   ├── generation_request.dart
│   ├── generation_queue_item.dart
│   ├── generation_status.dart
│   ├── garment_data.dart
│   └── category_mapper.dart
├── services/
│   ├── n8n_service.dart
│   └── n8n_exception.dart
├── viewmodels/
│   ├── selection_view_model.dart
│   └── generation_queue_view_model.dart
├── screens/
│   └── selection_screen.dart
├── widgets/
│   ├── generation_bottom_sheet.dart
│   ├── mini_player.dart
│   ├── model_carousel.dart
│   ├── wardrobe_grid.dart
│   ├── generation_progress_view.dart
│   ├── queue_list_view.dart
│   ├── history_list_view.dart
│   ├── empty_state_widget.dart
│   └── selection_indicator.dart
└── utils/
    └── constants.dart

test/features/ai_look_generator/
├── models/
│   └── ...
├── services/
│   └── n8n_service_test.dart
├── viewmodels/
│   ├── selection_view_model_test.dart
│   └── generation_queue_view_model_test.dart
└── widgets/
    └── ...
```

## Conclusion

This design document provides a comprehensive blueprint for implementing the AI Look Generator feature following MVVM architecture, performance best practices, and the existing Dressify codebase patterns. The design emphasizes:

1. **Maintainability**: Clear separation of concerns with MVVM
2. **Performance**: Selective rebuilds, lazy loading, efficient caching
3. **User Experience**: Intuitive single-page flow, persistent bottom sheet, clear feedback
4. **Reliability**: Robust error handling, queue system, retry logic
5. **Scalability**: Extensible architecture for future enhancements

The implementation plan provides a clear roadmap for development over 8 days, with testing integrated throughout the process.
