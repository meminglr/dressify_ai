# Implementation Plan: AI Look Generator

## Overview

This implementation plan breaks down the AI Look Generator feature into discrete coding tasks following the MVVM architecture pattern. The feature enables users to create AI-generated outfit visualizations by combining model photos with wardrobe items through a single-page selection flow and a persistent, minimizable bottom sheet for generation progress.

**Key Implementation Constraints:**
- Follow MVVM architecture strictly
- Use selective rebuilds (no unnecessary widget rebuilds)
- Reuse existing ProfileViewModel.modelsListenable and ProfileViewModel.wardrobeListenable
- Replace placeholder content at tab index 2
- GenerationQueueViewModel must be a singleton
- Generation bottom sheet must persist as global overlay across tabs

## Tasks

- [x] 1. Set up project structure and core models
  - Create feature directory structure: `lib/features/ai_look_generator/`
  - Create subdirectories: `models/`, `services/`, `viewmodels/`, `screens/`, `widgets/`, `utils/`
  - Define `GenerationStatus` enum (queued, processing, completed, failed)
  - Create `GarmentData` model with imageUrl, category, productName fields
  - Create `GenerationRequest` model with userId, personImageUrl, garments array and toJson() method
  - Create `GenerationQueueItem` model with id, request, status, timestamp, result fields, and copyWith() method
  - Create `CategoryMapper` utility class with Turkish category mapping (Tişört, Pantolon, etc.)
  - _Requirements: 1.1, 2.1, 6.2, 6.3, 6.4, 15.1, 15.2_

- [x] 2. Implement N8nService for API integration
  - [x] 2.1 Create N8nService class with HTTP client
    - Implement singleton pattern for N8nService
    - Define constants: baseUrl, endpoint, 180-second timeout
    - Create `generateLook()` method with userId, personImageUrl, garments parameters
    - Implement request payload construction using GenerationRequest.toJson()
    - Implement category mapping logic using CategoryMapper
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 15.1_

  - [x] 2.2 Implement error handling and timeout logic
    - Add try-catch for TimeoutException with Turkish error message "İstek zaman aşımına uğradı"
    - Add try-catch for SocketException with Turkish error message "İnternet bağlantınızı kontrol edin"
    - Add HTTP status code error handling (4xx, 5xx)
    - Create custom N8nException class for error wrapping
    - Parse success response and extract image_url and media_id
    - _Requirements: 6.5, 6.6, 6.7, 8.1, 8.2, 8.3, 19.3_

  - [ ]* 2.3 Write unit tests for N8nService
    - Test request payload construction
    - Test category mapping for all supported categories
    - Test timeout handling
    - Test error response handling
    - Test success response parsing

- [x] 3. Implement SelectionViewModel
  - [x] 3.1 Create SelectionViewModel class extending ChangeNotifier
    - Add dependencies: ProfileViewModel, GenerationQueueViewModel
    - Implement selection state: _selectedModelId (String?), _selectedWardrobeIds (Set<String>)
    - Create getters: selectedModelId, selectedWardrobeIds, canGenerate, selectedCount
    - Implement validation logic: canGenerate returns true when 1 model + 1-5 wardrobe items selected
    - _Requirements: 1.3, 1.4, 2.3, 2.4, 10.1, 10.2, 18.1, 18.2, 18.3_

  - [x] 3.2 Implement selection methods
    - Create `selectModel(String modelId)` method that updates _selectedModelId and calls notifyListeners()
    - Create `toggleWardrobeItem(String itemId)` method with 5-item maximum enforcement
    - Show toast "Maksimum 5 kıyafet seçebilirsiniz" when limit exceeded
    - Create `clearSelections()` method to reset state
    - _Requirements: 1.3, 2.3, 2.4, 2.8, 18.4_

  - [x] 3.3 Implement generateLook() method
    - Validate selections before proceeding
    - Extract model Media object from ProfileViewModel.modelsListenable
    - Extract wardrobe Media objects from ProfileViewModel.wardrobeListenable
    - Map wardrobe items to GarmentData using CategoryMapper
    - Create GenerationRequest with user_id, model image URL, garments array
    - Call GenerationQueueViewModel.instance.addToQueue() with request
    - Call clearSelections() after successful queue addition
    - _Requirements: 1.1, 2.1, 6.2, 6.3, 7.9, 10.5, 18.5_

  - [ ]* 3.4 Write unit tests for SelectionViewModel
    - Test model selection updates state
    - Test wardrobe toggle adds/removes items
    - Test 5-item maximum enforcement
    - Test canGenerate validation logic
    - Test clearSelections resets state

- [x] 4. Implement GenerationQueueViewModel singleton
  - [x] 4.1 Create GenerationQueueViewModel class with singleton pattern
    - Implement singleton pattern with private constructor and static instance getter
    - Add dependency: N8nService
    - Create state variables: _queue (List), _history (List), _activeGeneration (GenerationQueueItem?)
    - Create bottom sheet state: _isBottomSheetVisible, _isMinimized
    - Create getters: queue, history, activeGeneration, isProcessing, hasQueue, isBottomSheetVisible, isMinimized
    - _Requirements: 4.1, 4.2, 10.3, 10.4, 10.10, 14.9_

  - [x] 4.2 Implement queue management methods
    - Create `addToQueue(GenerationRequest request)` method
    - Generate unique ID using uuid package
    - Extract thumbnails from request for UI display
    - Create GenerationQueueItem with status=queued
    - Add item to _queue and call notifyListeners()
    - Call showBottomSheet() and _processQueue()
    - Implement duplicate detection (same model + same wardrobe items)
    - Enforce maximum queue size of 10 items with toast message
    - _Requirements: 4.1, 4.2, 4.6, 18.9, 18.10_

  - [x] 4.3 Implement queue processing logic
    - Create `_processQueue()` method that processes items sequentially (FIFO)
    - Check if already processing, return early if true
    - Take first item from queue, set as _activeGeneration
    - Update item status to processing and call notifyListeners()
    - Call `_processItem(item)` and await result
    - On success: update item with result, move to history, start next in queue
    - On failure: update item with error, move to history, start next in queue
    - _Requirements: 4.2, 4.6, 7.12, 13.8_

  - [x] 4.4 Implement generation processing
    - Create `_processItem(GenerationQueueItem item)` async method
    - Call N8nService.generateLook() with request data
    - Handle success: update item with resultImageUrl and resultMediaId, status=completed
    - Handle errors: update item with errorMessage, status=failed
    - Refresh ProfileViewModel to show new AI look in profile
    - _Requirements: 6.1, 6.5, 6.6, 7.10_

  - [x] 4.5 Implement history and bottom sheet state methods
    - Create `cancelQueuedItem(String itemId)` - remove from queue if status=queued
    - Create `retryFailedItem(String itemId)` - find in history, create new request, add to queue
    - Create `clearHistory()` - clear _history list
    - Create `removeFromHistory(String itemId)` - remove specific item from history
    - Create `showBottomSheet()`, `hideBottomSheet()`, `minimizeBottomSheet()`, `expandBottomSheet()`
    - Implement auto-minimize logic: minimize 3-5 seconds after generation starts
    - _Requirements: 3.7, 4.7, 5.5, 5.10, 8.8, 12.9_

  - [ ]* 4.6 Write unit tests for GenerationQueueViewModel
    - Test singleton pattern
    - Test queue FIFO processing
    - Test cancel queued item
    - Test retry failed item
    - Test bottom sheet state management
    - Test auto-minimize timing

- [x] 5. Create reusable UI components
  - [x] 5.1 Create EmptyStateWidget
    - Accept parameters: icon, title, description, primaryButton, secondaryButton
    - Use Manrope font for title, Liberation Serif for description
    - Follow design system colors and spacing
    - _Requirements: 1.5, 2.9, 16.1-16.10_

  - [x] 5.2 Create SelectionIndicator widget
    - Show purple checkmark overlay for selected items
    - Show plus icon with 60% opacity for unselected items
    - Use AppColors.primary (#742FE5) for selected state
    - Add haptic feedback on selection change
    - _Requirements: 1.4, 2.5, 2.6, 12.8_

  - [x] 5.3 Create ModelCarousel widget
    - Accept List<Media> models parameter
    - Implement horizontal scrollable ListView with 312px card width
    - Cards: 1:1 aspect ratio, 48px border radius, gradient overlay
    - Use CachedNetworkImage with memory caching (memCacheWidth: 312)
    - Show SelectionIndicator on selected card
    - Show EmptyStateWidget when models list is empty
    - Add semantic labels "Model fotoğrafı {index}"
    - _Requirements: 1.1, 1.2, 1.4, 1.5, 1.6, 9.9, 12.1, 13.1_

  - [x] 5.4 Create WardrobeGrid widget
    - Accept List<Media> wardrobe and Set<String> selectedIds parameters
    - Implement 2-column masonry layout with 163px item height
    - Use CachedNetworkImage with memory caching
    - Show SelectionIndicator on each item
    - Show EmptyStateWidget when wardrobe list is empty
    - Add semantic labels with item category
    - Implement lazy loading (ListView.builder)
    - _Requirements: 2.1, 2.2, 2.5, 2.6, 2.9, 9.10, 12.2, 13.2, 13.10_

  - [x] 5.5 Create selection counter badge widget
    - Display "X / 5 SEÇİLDİ" text in green
    - Position at top right of wardrobe section
    - Announce changes to screen readers
    - _Requirements: 2.7, 12.5_

- [x] 6. Implement SelectionScreen
  - [x] 6.1 Create SelectionScreen widget structure
    - Create StatelessWidget with ChangeNotifierProvider for SelectionViewModel
    - Inject ProfileViewModel and GenerationQueueViewModel.instance as dependencies
    - Create Scaffold with AppBar title "AI Look Oluştur"
    - Use AppColors.background (#F8F9FA) for screen background
    - _Requirements: 1.1, 10.1, 10.7, 11.2, 14.1, 14.7_

  - [x] 6.2 Implement model selection section
    - Add section header "Model Seç" (Manrope ExtraBold, 30px)
    - Use ValueListenableBuilder with ProfileViewModel.modelsListenable
    - Render ModelCarousel with models data
    - Use Consumer<SelectionViewModel> to get selectedModelId
    - Handle model card tap: call viewModel.selectModel(modelId)
    - Show shimmer placeholders while loading
    - _Requirements: 1.1, 1.2, 1.3, 9.9, 10.7, 10.8, 13.3_

  - [x] 6.3 Implement wardrobe selection section
    - Add section header "Kıyafet Seç" (Manrope ExtraBold, 30px)
    - Add selection counter badge at top right
    - Add "Yeni Ekle" button at top right
    - Use ValueListenableBuilder with ProfileViewModel.wardrobeListenable
    - Render WardrobeGrid with wardrobe data and selectedWardrobeIds
    - Handle item tap: call viewModel.toggleWardrobeItem(itemId)
    - Show shimmer placeholders while loading
    - _Requirements: 2.1, 2.2, 2.3, 2.7, 9.10, 10.7, 10.8, 13.3_

  - [x] 6.4 Implement fixed bottom Generate button
    - Create fixed bottom button with "Oluştur" label
    - Use Consumer<SelectionViewModel> to get canGenerate state
    - Enable button only when canGenerate is true
    - Implement debouncing (1 second) to prevent duplicate taps
    - On tap: call viewModel.generateLook()
    - Follow design system button styling (AppColors.primary)
    - Add semantic label "Look oluştur"
    - _Requirements: 1.1, 2.1, 11.7, 12.3, 18.1, 18.8_

  - [x] 6.5 Implement empty state navigation
    - "Model Ekle" button navigates to profile screen models tab
    - "Fotoğraf Yükle" button shows upload options
    - "Trendyol'da Ara" button navigates to Trendyol search
    - _Requirements: 1.6, 2.10, 16.4, 16.8_

- [x] 7. Checkpoint - Ensure selection flow works
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Implement MiniPlayer widget
  - [x] 8.1 Create MiniPlayer widget structure
    - Create StatelessWidget with 80-100px fixed height
    - Position at bottom of screen above navigation bar
    - Use white/light gray background with subtle shadow
    - Implement tap gesture to expand bottom sheet
    - _Requirements: 3.8, 3.9, 11.8_

  - [x] 8.2 Implement MiniPlayer layout
    - Left: Circular progress indicator (40px) or status icon
    - Center: Status text (primary) and secondary text
    - Right: Expand icon (^) and close icon (X)
    - Use Consumer<GenerationQueueViewModel> for reactive updates
    - _Requirements: 3.9, 9.7, 9.8, 12.4, 12.10_

  - [x] 8.3 Implement MiniPlayer status display
    - Processing state: purple progress indicator, "Look oluşturuluyor...", estimated time
    - Success state: green checkmark, "Look hazır! Görüntüle"
    - Error state: red error icon, "Hata oluştu. Tekrar dene"
    - Queue state: show "X/Y oluşturuluyor" when multiple items in queue
    - _Requirements: 3.9, 4.10, 7.1, 7.2, 8.1, 8.2, 11.9, 19.8_

  - [x] 8.4 Implement MiniPlayer gestures
    - Tap anywhere: call GenerationQueueViewModel.instance.expandBottomSheet()
    - Tap close icon: show confirmation dialog if processing, then call hideBottomSheet()
    - Add semantic labels for all interactive elements
    - _Requirements: 3.10, 12.4, 17.2, 17.6, 17.7_

- [x] 9. Implement GenerationBottomSheet full sheet
  - [x] 9.1 Create GenerationBottomSheet widget structure
    - Create StatefulWidget with AnimationController for transitions
    - Implement DraggableScrollableSheet for drag gestures
    - Set initial height to 70-80% of screen
    - Add drag handle (horizontal bar) at top
    - Use Consumer<GenerationQueueViewModel> for reactive updates
    - _Requirements: 3.1, 3.2, 12.9, 17.1, 17.4_

  - [x] 9.2 Implement tab bar for "Şu An" and "Geçmiş"
    - Create TabBar with two tabs: "Şu An" and "Geçmiş"
    - Use TabBarView for tab content
    - Follow design system styling
    - _Requirements: 5.8, 5.9, 19.9_

  - [x] 9.3 Implement "Şu An" tab - processing state
    - Display generation animations (Lottie or custom animations)
    - Show circular/linear progress indicator
    - Display "Look oluşturuluyor..." (Manrope Bold, 24px)
    - Display "Bu işlem 30-90 saniye sürebilir" (Liberation Serif, 14px, gray)
    - Show small thumbnail previews of model and wardrobe items
    - _Requirements: 3.3, 3.4, 3.5, 3.6, 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.11_

  - [x] 9.4 Implement "Şu An" tab - queue list
    - Display list of queued items below active generation
    - Each item shows: model thumbnail, wardrobe thumbnails, status badge, cancel button
    - Status badges: "Sırada" (gray), "İşleniyor" (purple)
    - Implement cancel button: call GenerationQueueViewModel.instance.cancelQueuedItem()
    - Show confirmation dialog for processing items (cannot cancel)
    - _Requirements: 4.3, 4.4, 4.7, 4.8_

  - [x] 9.5 Implement "Şu An" tab - success state
    - Display full-width AI look image with proper aspect ratio
    - Show creation timestamp below image
    - Add "Profilde Görüntüle" button (primary, purple)
    - Add "Yeni Look Oluştur" button (secondary, outlined)
    - "Profilde Görüntüle": close bottom sheet, navigate to profile AI Looks tab
    - "Yeni Look Oluştur": close bottom sheet, reset SelectionViewModel
    - _Requirements: 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9, 7.11_

  - [x] 9.6 Implement "Şu An" tab - error state
    - Display error icon (Iconsax.warning_2, 64px, red)
    - Show error message (Manrope Medium, 16px)
    - Add "Tekrar Dene" button: call GenerationQueueViewModel.instance.retryFailedItem()
    - Add "Kapat" button: move item to history, close bottom sheet
    - _Requirements: 8.1, 8.2, 8.4, 8.5, 8.6, 8.7, 8.8, 8.12_

  - [x] 9.7 Implement "Geçmiş" tab
    - Display scrollable list of completed generations (history)
    - Order by completion time (most recent first)
    - Each item shows: result thumbnail or error icon, model/wardrobe thumbnails, status, timestamp
    - Success items: "Görüntüle" button to expand result
    - Failed items: "Tekrar Dene" button to re-queue
    - Implement swipe left to delete: call removeFromHistory()
    - Show EmptyStateWidget when history is empty: "Henüz geçmiş yok"
    - Use lazy loading (ListView.builder)
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.10, 13.10, 16.10_

  - [x] 9.8 Implement bottom sheet gestures and animations
    - Swipe down gesture: call minimizeBottomSheet()
    - Use spring animations for smooth transitions
    - Prevent accidental dismissal during processing (confirmation dialog)
    - _Requirements: 12.9, 17.1, 17.3, 17.9, 17.10_

- [x] 10. Checkpoint - Ensure bottom sheet works
  - Ensure all tests pass, ask the user if questions arise.

- [x] 11. Integrate with Home widget and global overlay
  - [x] 11.1 Replace tab index 2 placeholder in lib/home.dart
    - Replace placeholder widget at tab index 2 with SelectionScreen
    - Pass necessary dependencies (ProfileViewModel)
    - _Requirements: 14.7_

  - [x] 11.2 Implement global overlay for persistent bottom sheet
    - Add Stack in Home widget to overlay GenerationBottomSheet
    - Position bottom sheet above navigation bar
    - Ensure bottom sheet persists across tab navigation
    - Use Consumer<GenerationQueueViewModel> to control visibility
    - _Requirements: 3.8, 3.12, 10.10, 14.8_

  - [x] 11.3 Test tab navigation with persistent bottom sheet
    - Verify bottom sheet remains visible when switching tabs
    - Verify mini player stays above navigation bar
    - Verify generation continues in background during tab switches
    - _Requirements: 3.12, 10.10_

- [x] 12. Add animations, polish, and accessibility
  - [x] 12.1 Add generation animations
    - Integrate Lottie animations or create custom animations for generation progress
    - Ensure animations run at 60fps
    - _Requirements: 9.1, 9.2, 13.6_

  - [x] 12.2 Add haptic feedback
    - Selection/deselection: HapticFeedback.selectionClick()
    - Generation start: HapticFeedback.mediumImpact()
    - Generation complete: HapticFeedback.heavyImpact()
    - _Requirements: 12.8_

  - [x] 12.3 Add accessibility labels
    - Verify all semantic labels are in place
    - Test with screen reader
    - Verify color contrast meets WCAG AA standards
    - Verify touch targets are minimum 44x44 points
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6, 12.7, 12.10_

  - [x] 12.4 Optimize performance
    - Verify selective rebuilds (use Flutter DevTools)
    - Verify image caching is working
    - Verify lazy loading for grids and lists
    - Test on mid-range device for 60fps scrolling
    - _Requirements: 13.1, 13.2, 13.3, 13.5, 13.6, 13.7, 13.9_

- [x] 13. Final integration testing and bug fixes
  - [x] 13.1 Test complete user flow
    - Test selection flow: model selection, wardrobe selection, validation
    - Test generation flow: queue, processing, success, error
    - Test bottom sheet: minimize, expand, close, persistence
    - Test empty states and error handling
    - _Requirements: All_

  - [x] 13.2 Test edge cases
    - Test with no models or wardrobe items
    - Test with maximum 5 wardrobe items
    - Test queue maximum (10 items)
    - Test duplicate generation prevention
    - Test session expiration during generation
    - Test network failures and timeouts
    - _Requirements: 8.1-8.12, 16.1-16.10, 18.1-18.10_

  - [x] 13.3 Performance testing
    - Measure initial screen load time (target: < 500ms)
    - Measure selection feedback time (target: < 100ms)
    - Verify 60fps scrolling on mid-range device
    - Verify bottom sheet animations run smoothly
    - _Requirements: 13.1, 13.2, 13.3, 13.5, 13.6_

  - [x] 13.4 Fix any bugs discovered during testing
    - Address any crashes or errors
    - Fix any UI/UX issues
    - Optimize any performance bottlenecks

- [x] 14. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Implementation follows MVVM architecture strictly
- Reuse existing ProfileViewModel for data access
- GenerationQueueViewModel is a singleton for global bottom sheet state
- Use selective rebuilds with Consumer and ValueListenableBuilder
- Follow design system colors, typography, and spacing
- All UI text must be in Turkish
