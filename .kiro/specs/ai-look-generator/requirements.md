# Requirements Document: AI Look Generator

## Introduction

The AI Look Generator is a new feature for the Dressify Flutter fashion app that enables users to create AI-generated outfit visualizations by combining their model photos with wardrobe items. The feature uses multi-garment virtual try-on technology powered by n8n workflows and Gemini AI to generate realistic outfit combinations. This feature will be placed in the 3rd tab (index 2) of the bottom navigation bar, replacing the current placeholder content.

The feature follows a single-page selection flow where users can select a model photo and 1-5 wardrobe items on the same screen. When the user taps "Oluştur", a minimizable bottom sheet (similar to YouTube's mini player or Spotify's now playing bar) appears showing generation progress. The bottom sheet can be minimized to allow users to continue browsing the app while generation happens in the background. Users can queue multiple generations, and the bottom sheet displays both active generation and generation history. After generation (30-90 seconds), the result is saved to the user's profile as an AI Look and can be viewed by expanding the bottom sheet.

## Glossary

- **AI_Look_Generator**: The main feature system that orchestrates model selection, wardrobe selection, and AI generation on a single screen
- **Model_Photo**: A user-uploaded photo of a person stored in the media table with type='MODEL'
- **Wardrobe_Item**: A clothing item that is either user-uploaded (type='UPLOAD') or a saved Trendyol product (type='TRENDYOL_PRODUCT')
- **Generation_Request**: An API request to the n8n multi-garment endpoint containing model photo URL and 1-5 garment URLs
- **AI_Look**: The generated outfit visualization saved to media table with type='AI_CREATION' and style_tag='virtual_tryon_multi'
- **Selection_State**: The current state of user selections including selected model ID and list of selected wardrobe item IDs
- **Model_Carousel**: Horizontal scrollable carousel displaying user's model photos with card-based UI
- **Wardrobe_Grid**: 2-column masonry-style grid displaying wardrobe items with selection capability
- **Generate_Button**: Fixed bottom action button that triggers generation and opens the Generation_Bottom_Sheet
- **Generation_Bottom_Sheet**: Minimizable bottom sheet (similar to YouTube mini player) that shows generation progress, queue, and history
- **Mini_Player**: Minimized state of the bottom sheet (80-100px height) showing current generation progress
- **Full_Sheet**: Expanded state of the bottom sheet showing detailed progress, animations, and generation history
- **Generation_Queue**: List of pending generation requests waiting to be processed
- **Generation_History**: List of completed (successful or failed) generations in the current session
- **Queue_Item**: A single generation request with status (queued, processing, completed, failed)
- **Selection_Screen**: Main screen where users select model and wardrobe items (replaces tab index 2)
- **n8n_Service**: Service layer that communicates with the n8n multi-garment webhook endpoint
- **ProfileViewModel**: Existing ViewModel that provides access to user's media list (models, wardrobe, AI looks)
- **Supabase_Storage**: Cloud storage service storing all media files in gallery/{user_id}/ paths
- **Media_Table**: Database table storing media metadata including URLs, types, and tags

## Requirements

### Requirement 1: Model Photo Selection

**User Story:** As a user, I want to select one of my model photos on the main screen, so that the AI can generate outfits on that model.

#### Acceptance Criteria

1. WHEN the Selection_Screen loads, THE Model_Carousel SHALL display all Model_Photos from ProfileViewModel.modelsListenable at the top of the screen
2. THE Model_Carousel SHALL display cards with 312px width, 1:1 aspect ratio, 48px border radius, and gradient overlay
3. WHEN a user taps a model card, THE AI_Look_Generator SHALL update Selection_State with the selected model ID
4. THE AI_Look_Generator SHALL display a visual indicator (purple border or checkmark) on the selected model card
5. WHEN no Model_Photos exist, THE AI_Look_Generator SHALL display an empty state with "Model fotoğrafı ekle" button in the carousel area
6. WHEN the "Model fotoğrafı ekle" button is tapped, THE AI_Look_Generator SHALL navigate to the profile screen models tab
7. THE Model_Carousel SHALL remain visible and accessible while the user selects wardrobe items below

### Requirement 2: Wardrobe Item Selection

**User Story:** As a user, I want to select 1-5 wardrobe items on the same screen as model selection, so that I can quickly create outfit combinations.

#### Acceptance Criteria

1. WHEN the Selection_Screen loads, THE Wardrobe_Grid SHALL display all Wardrobe_Items from ProfileViewModel.wardrobeListenable below the Model_Carousel
2. THE Wardrobe_Grid SHALL use a 2-column masonry layout with 163px item height
3. WHEN a user taps an unselected wardrobe item, THE AI_Look_Generator SHALL add the item ID to Selection_State IF the count is less than 5
4. WHEN a user taps a selected wardrobe item, THE AI_Look_Generator SHALL remove the item ID from Selection_State
5. THE AI_Look_Generator SHALL display a purple checkmark overlay on selected items
6. THE AI_Look_Generator SHALL display a plus icon and 60% opacity on unselected items
7. THE AI_Look_Generator SHALL display a selection counter badge showing "X / 5 SEÇİLDİ" in green above the grid
8. IF a user attempts to select more than 5 items, THEN THE AI_Look_Generator SHALL show a toast message "Maksimum 5 kıyafet seçebilirsiniz"
9. WHEN no Wardrobe_Items exist, THE AI_Look_Generator SHALL display an empty state with "Gardıroba kıyafet ekle" button
10. WHEN the "Gardıroba kıyafet ekle" button is tapped, THE AI_Look_Generator SHALL show options to upload photo or browse Trendyol
11. THE Wardrobe_Grid SHALL be scrollable independently while the Model_Carousel remains visible at the top

### Requirement 3: Minimizable Generation Bottom Sheet

**User Story:** As a user, I want to see generation progress in a minimizable bottom sheet (like YouTube's mini player), so that I can continue browsing the app while my look is being generated.

#### Acceptance Criteria

1. WHEN the Generate_Button is tapped, THE AI_Look_Generator SHALL open the Generation_Bottom_Sheet in full-screen mode
2. THE Generation_Bottom_Sheet SHALL display as a modal bottom sheet that can be dragged down to minimize
3. THE Full_Sheet SHALL display generation animations (Lottie or custom animations showing AI working)
4. THE Full_Sheet SHALL display a circular or linear progress indicator
5. THE Full_Sheet SHALL display "Look oluşturuluyor..." text prominently
6. THE Full_Sheet SHALL display small previews of the selected model and wardrobe items
7. AFTER 3-5 seconds of displaying animations, THE Generation_Bottom_Sheet SHALL automatically minimize to Mini_Player state
8. THE Mini_Player SHALL remain visible at the bottom of the screen (above navigation bar) across all tabs
9. THE Mini_Player SHALL have 80-100px height and display: progress indicator (left), status text (center), expand/close buttons (right)
10. WHEN the user taps the Mini_Player, THE Generation_Bottom_Sheet SHALL expand back to Full_Sheet
11. WHEN the user swipes down on Full_Sheet, THE Generation_Bottom_Sheet SHALL minimize to Mini_Player
12. THE Generation_Bottom_Sheet SHALL persist across tab navigation (remains visible when switching tabs)

### Requirement 4: Generation Queue System

**User Story:** As a user, I want to queue multiple look generations, so that I can create several looks without waiting for each one to complete.

#### Acceptance Criteria

1. WHEN the user taps "Oluştur" while a generation is already in progress, THE AI_Look_Generator SHALL add the new request to the Generation_Queue
2. THE Generation_Queue SHALL process requests sequentially (one at a time, FIFO order)
3. THE Full_Sheet SHALL display a "Kuyruk" tab showing all queued generations with their status
4. EACH Queue_Item SHALL display: model thumbnail, wardrobe item thumbnails, status (queued/processing/completed/failed), and timestamp
5. THE Mini_Player SHALL show the currently processing generation's progress
6. WHEN a generation completes, THE AI_Look_Generator SHALL automatically start the next queued generation
7. THE user SHALL be able to cancel queued generations (not yet started) by tapping a cancel button on the Queue_Item
8. THE user SHALL NOT be able to cancel a generation that is already processing (show confirmation dialog explaining this)
9. THE Generation_Queue SHALL persist during the app session but clear when the app is closed
10. THE Mini_Player status text SHALL show "X/Y oluşturuluyor" when multiple items are in queue (e.g., "2/5 oluşturuluyor")

### Requirement 5: Generation History

**User Story:** As a user, I want to see my recent generation history in the bottom sheet, so that I can quickly access completed looks without going to my profile.

#### Acceptance Criteria

1. THE Full_Sheet SHALL display a "Geçmiş" tab showing Generation_History for the current session
2. THE Generation_History SHALL include all completed generations (successful and failed) from the current app session
3. EACH history item SHALL display: result thumbnail (if successful), model thumbnail, wardrobe thumbnails, status, timestamp, and action buttons
4. FOR successful generations, THE history item SHALL include a "Görüntüle" button that expands the result in Full_Sheet
5. FOR failed generations, THE history item SHALL include a "Tekrar Dene" button that re-queues the generation
6. THE Generation_History SHALL be ordered by completion time (most recent first)
7. THE Generation_History SHALL clear when the app is closed (session-based, not persistent)
8. THE Full_Sheet SHALL show a tab bar with "Şu An" (current/queue) and "Geçmiş" (history) tabs
9. THE "Şu An" tab SHALL show the currently processing generation and queued items
10. THE user SHALL be able to delete items from Generation_History by swiping left on the item

### Requirement 6: n8n API Integration

**User Story:** As a developer, I want to integrate with the n8n multi-garment endpoint, so that the app can generate AI looks.

#### Acceptance Criteria

1. THE n8n_Service SHALL send POST requests to https://n8n.emniva.com/webhook/tryon-multi
2. THE Generation_Request SHALL include user_id (UUID), person_image_url (model photo URL), and garments array (1-5 items)
3. FOR EACH Wardrobe_Item in Selection_State, THE n8n_Service SHALL include image_url, category, and optional product_name in the garments array
4. THE n8n_Service SHALL map Wardrobe_Item types to appropriate category strings (e.g., "Tişört", "Pantolon", "Ayakkabı")
5. WHEN the n8n API returns success=true, THE n8n_Service SHALL return the image_url and media_id
6. IF the n8n API returns an error OR times out after 180 seconds, THEN THE n8n_Service SHALL throw an exception with a descriptive error message
7. THE n8n_Service SHALL include proper error handling for network failures, timeouts, and invalid responses
8. THE n8n_Service SHALL support concurrent generation tracking (multiple requests can be in flight for queue system)

### Requirement 7: Generation Completion and Result Display

**User Story:** As a user, I want to see the generated AI look in the bottom sheet when generation completes, so that I can immediately view and interact with the result.

#### Acceptance Criteria

1. WHEN a generation completes successfully, THE Mini_Player SHALL update to show success state with "Look hazır! Görüntüle" text and a checkmark icon
2. THE Mini_Player success state SHALL use green accent color to indicate completion
3. WHEN the user taps the Mini_Player in success state, THE Full_Sheet SHALL expand and display the result
4. THE Full_Sheet result view SHALL display the AI_Look image at full width with proper aspect ratio
5. THE Full_Sheet result view SHALL include a "Profilde Görüntüle" button
6. THE Full_Sheet result view SHALL include a "Yeni Look Oluştur" button
7. THE Full_Sheet result view SHALL display the creation timestamp below the image
8. WHEN "Profilde Görüntüle" is tapped, THE AI_Look_Generator SHALL close the bottom sheet AND navigate to the profile screen with AI Looks tab selected
9. WHEN "Yeni Look Oluştur" is tapped, THE AI_Look_Generator SHALL close the bottom sheet AND reset Selection_State on Selection_Screen
10. THE AI_Look_Generator SHALL refresh ProfileViewModel to ensure the new AI_Look appears in the profile
11. THE completed generation SHALL automatically move to Generation_History
12. IF there are more items in Generation_Queue, THE next generation SHALL start automatically

### Requirement 8: Error Handling and User Feedback

**User Story:** As a user, I want clear feedback when errors occur during generation, so that I understand what went wrong and how to proceed.

#### Acceptance Criteria

1. IF the n8n API returns an error, THEN THE Mini_Player SHALL update to show error state with "Hata oluştu. Tekrar dene" text and an error icon
2. THE Mini_Player error state SHALL use red accent color to indicate failure
3. IF the network request times out, THEN THE error message SHALL be "İstek zaman aşımına uğradı"
4. WHEN the user taps the Mini_Player in error state, THE Full_Sheet SHALL expand and display detailed error information
5. THE Full_Sheet error view SHALL display the error message prominently
6. THE Full_Sheet error view SHALL include a "Tekrar Dene" button to retry the failed generation
7. THE Full_Sheet error view SHALL include a "Kapat" button to dismiss and move the item to history
8. WHEN "Tekrar Dene" is tapped, THE AI_Look_Generator SHALL re-queue the generation with the same selections
9. IF the user has no Model_Photos on Selection_Screen, THEN THE AI_Look_Generator SHALL display an empty state with guidance to add model photos
10. IF the user has no Wardrobe_Items on Selection_Screen, THEN THE AI_Look_Generator SHALL display an empty state with guidance to add wardrobe items
11. THE AI_Look_Generator SHALL log all errors to the console for debugging purposes
12. THE failed generation SHALL move to Generation_History with failed status

### Requirement 9: Loading States and Progress Indication

**User Story:** As a user, I want to see clear loading indicators and animations during AI generation, so that I know the app is working and the experience feels engaging.

#### Acceptance Criteria

1. WHEN the Full_Sheet first opens, THE AI_Look_Generator SHALL display engaging generation animations (Lottie or custom animations)
2. THE animations SHALL show AI working, clothes combining, or similar visual metaphors for generation
3. THE Full_Sheet SHALL include a circular or linear progress indicator
4. THE Full_Sheet SHALL display "Look oluşturuluyor..." text prominently
5. THE Full_Sheet SHALL display "Bu işlem 30-90 saniye sürebilir" as secondary information
6. THE Full_Sheet SHALL display small thumbnail previews of the selected model and wardrobe items being combined
7. THE Mini_Player SHALL display a small circular progress indicator (40px) on the left side
8. THE Mini_Player SHALL display estimated time remaining in the center (e.g., "45 saniye kaldı")
9. WHEN the Model_Carousel is loading data on Selection_Screen, THE AI_Look_Generator SHALL display shimmer placeholders with the same card dimensions
10. WHEN the Wardrobe_Grid is loading data on Selection_Screen, THE AI_Look_Generator SHALL display shimmer placeholders in the 2-column grid layout
11. THE progress indicator SHALL be indeterminate (no specific percentage) since n8n doesn't provide progress updates

### Requirement 10: Data Persistence and State Management

**User Story:** As a developer, I want proper state management for selections, queue, and generation state, so that the feature is reliable and maintainable.

#### Acceptance Criteria

1. THE AI_Look_Generator SHALL use a ChangeNotifier-based ViewModel following the MVVM pattern
2. THE Selection_State SHALL be stored in the ViewModel and persist during the user's session on Selection_Screen
3. THE Generation_Queue and Generation_History SHALL be managed by a separate GenerationQueueViewModel
4. THE GenerationQueueViewModel SHALL be a singleton accessible globally (for persistent bottom sheet across tabs)
5. WHEN the user taps "Yeni Look Oluştur", THE Selection_State SHALL be cleared on Selection_Screen
6. WHEN the user returns to Selection_Screen from another tab, THE Selection_State SHALL start fresh (no selections)
7. THE ViewModel SHALL use ProfileViewModel.modelsListenable and ProfileViewModel.wardrobeListenable for reactive data access
8. THE ViewModel SHALL NOT trigger unnecessary rebuilds when Selection_State changes (use Consumer or ValueListenableBuilder selectively)
9. THE ViewModel SHALL properly dispose of listeners and resources when screens are disposed
10. THE Generation_Bottom_Sheet SHALL persist across tab navigation using a global overlay or persistent widget
11. THE Generation_Queue and Generation_History SHALL clear when the app is closed (session-based, not persistent storage)

### Requirement 11: UI Design System Compliance

**User Story:** As a designer, I want the AI Look Generator to follow the Dressify design system, so that it feels consistent with the rest of the app.

#### Acceptance Criteria

1. THE AI_Look_Generator SHALL use AppColors.primary (#742FE5) for primary actions and selected states
2. THE AI_Look_Generator SHALL use AppColors.background (#F8F9FA) for screen backgrounds
3. THE AI_Look_Generator SHALL use AppColors.onSurface (#2E3335) for primary text
4. THE AI_Look_Generator SHALL use 24px, 32px, or 48px border radius for cards and containers
5. THE AI_Look_Generator SHALL use Manrope font for headings and Liberation Serif for labels
6. THE AI_Look_Generator SHALL use subtle shadows with low opacity for elevated elements
7. THE Generate_Button SHALL follow the same style as existing primary action buttons in the app
8. THE Mini_Player SHALL use a white or light gray background with subtle shadow for floating effect
9. THE Mini_Player SHALL use purple gradient or accent color for progress indicators
10. THE Full_Sheet SHALL use consistent spacing, typography, and color scheme with the rest of the app

### Requirement 12: Accessibility and Usability

**User Story:** As a user with accessibility needs, I want the AI Look Generator to be accessible, so that I can use all features effectively.

#### Acceptance Criteria

1. THE Model_Carousel cards SHALL include semantic labels describing "Model fotoğrafı {index}"
2. THE Wardrobe_Grid items SHALL include semantic labels describing the item type (e.g., "Tişört", "Pantolon")
3. THE Generate_Button SHALL include a semantic label "Look oluştur"
4. THE Mini_Player SHALL include semantic labels for all interactive elements (expand, close, status)
5. THE selection counter badge SHALL announce selection changes to screen readers
6. THE AI_Look_Generator SHALL support keyboard navigation for all interactive elements
7. THE AI_Look_Generator SHALL provide sufficient color contrast (WCAG AA minimum) for all text
8. THE AI_Look_Generator SHALL provide haptic feedback when items are selected or deselected
9. THE Generation_Bottom_Sheet SHALL be draggable with smooth animations for minimize/expand gestures
10. THE Mini_Player SHALL have sufficient touch target size (minimum 44x44 points) for all interactive elements

### Requirement 13: Performance and Optimization

**User Story:** As a user, I want the AI Look Generator to be fast and responsive, so that I have a smooth experience.

#### Acceptance Criteria

1. THE Model_Carousel SHALL load and display images efficiently using cached_network_image with memory caching
2. THE Wardrobe_Grid SHALL use lazy loading to render only visible items
3. THE AI_Look_Generator SHALL NOT rebuild the entire widget tree when Selection_State changes (use selective rebuilds)
4. THE AI_Look_Generator SHALL compress images before sending to n8n API IF the total payload exceeds 15MB
5. THE AI_Look_Generator SHALL complete initial screen render within 500ms on mid-range devices
6. THE Generation_Bottom_Sheet animations SHALL run at 60fps for smooth minimize/expand transitions
7. THE Mini_Player SHALL update efficiently without causing jank in the main UI
8. THE Generation_Queue SHALL process items sequentially to avoid overwhelming the n8n API
9. THE AI_Look_Generator SHALL use efficient state management to prevent unnecessary rebuilds of the persistent bottom sheet
10. THE Full_Sheet SHALL use lazy loading for Generation_History items (render only visible items)

### Requirement 14: Integration with Existing Architecture

**User Story:** As a developer, I want the AI Look Generator to integrate seamlessly with existing code, so that it's maintainable and consistent.

#### Acceptance Criteria

1. THE AI_Look_Generator SHALL reuse ProfileViewModel for accessing models and wardrobe data
2. THE AI_Look_Generator SHALL reuse MediaService for any media-related operations
3. THE AI_Look_Generator SHALL reuse StorageService for any storage-related operations
4. THE AI_Look_Generator SHALL follow the existing MVVM architecture pattern (ViewModel + View separation)
5. THE AI_Look_Generator SHALL use existing reusable widgets (e.g., MasonryGridView) where applicable
6. THE AI_Look_Generator SHALL use existing services pattern (singleton services with dependency injection)
7. THE AI_Look_Generator SHALL replace the placeholder content at tab index 2 in lib/home.dart
8. THE Generation_Bottom_Sheet SHALL be implemented as a global overlay that persists across tab navigation
9. THE GenerationQueueViewModel SHALL be a singleton accessible from anywhere in the app

### Requirement 15: Category Mapping for Garments

**User Story:** As a developer, I want to map wardrobe items to appropriate categories, so that the AI generates accurate results.

#### Acceptance Criteria

1. THE n8n_Service SHALL map wardrobe item types to Turkish category strings
2. THE category mapping SHALL support: Tişört, Bluz, Gömlek, Pantolon, Jeans, Şort, Etek, Elbise, Tulum, Ceket, Mont, Hırka, Ayakkabı, Bot, Sneaker, Aksesuar, Kemer, Çanta, Şapka
3. WHEN a Wardrobe_Item has a style_tag or metadata indicating category, THE n8n_Service SHALL use that category
4. WHEN a Wardrobe_Item has no category information, THE n8n_Service SHALL use a default category based on the item type
5. FOR Trendyol products, THE n8n_Service SHALL extract category from the product metadata IF available
6. THE n8n_Service SHALL include the product_name in the Generation_Request IF available to improve AI prompt quality
7. THE category mapping SHALL be configurable and extensible for future category additions

### Requirement 16: Empty State Handling

**User Story:** As a user, I want helpful guidance when I have no models or wardrobe items, so that I know what to do next.

#### Acceptance Criteria

1. WHEN the user has zero Model_Photos, THE AI_Look_Generator SHALL display an empty state illustration in the carousel area
2. THE empty state for models SHALL include the text "Model fotoğrafı eklemelisin"
3. THE empty state for models SHALL include a description "AI look oluşturmak için önce bir model fotoğrafı ekle"
4. THE empty state for models SHALL include a "Model Ekle" button that navigates to profile models tab
5. WHEN the user has zero Wardrobe_Items, THE AI_Look_Generator SHALL display an empty state illustration in the grid area
6. THE empty state for wardrobe SHALL include the text "Gardırobunda kıyafet yok"
7. THE empty state for wardrobe SHALL include a description "Kıyafet eklemek için fotoğraf yükle veya Trendyol'dan ürün kaydet"
8. THE empty state for wardrobe SHALL include "Fotoğraf Yükle" and "Trendyol'da Ara" buttons
9. WHEN Generation_Queue is empty, THE "Şu An" tab SHALL display an empty state with "Henüz look oluşturmadın" message
10. WHEN Generation_History is empty, THE "Geçmiş" tab SHALL display an empty state with "Henüz geçmiş yok" message

### Requirement 17: Bottom Sheet Interaction and Gestures

**User Story:** As a user, I want intuitive gestures to control the generation bottom sheet, so that I can easily minimize, expand, or close it.

#### Acceptance Criteria

1. THE Generation_Bottom_Sheet SHALL support swipe down gesture to minimize from Full_Sheet to Mini_Player
2. THE Generation_Bottom_Sheet SHALL support tap gesture on Mini_Player to expand to Full_Sheet
3. THE Generation_Bottom_Sheet SHALL support swipe down gesture on Mini_Player to close the bottom sheet (with confirmation if generation is in progress)
4. THE Full_Sheet SHALL include a drag handle (horizontal bar) at the top for visual affordance
5. THE Mini_Player SHALL include an expand icon (^) on the right side
6. THE Mini_Player SHALL include a close icon (X) on the far right
7. WHEN the close icon is tapped during active generation, THE AI_Look_Generator SHALL show a confirmation dialog "Oluşturma iptal edilsin mi?"
8. WHEN the close icon is tapped after generation completes, THE bottom sheet SHALL close without confirmation
9. THE Generation_Bottom_Sheet SHALL use smooth spring animations for all transitions
10. THE Generation_Bottom_Sheet SHALL prevent accidental dismissal during critical operations (use confirmation dialogs)

### Requirement 18: Validation and Business Rules

**User Story:** As a developer, I want to enforce business rules for AI generation, so that the feature works reliably.

#### Acceptance Criteria

1. THE Generate_Button on Selection_Screen SHALL be disabled UNLESS exactly 1 Model_Photo AND at least 1 Wardrobe_Item are selected
2. THE AI_Look_Generator SHALL require exactly 1 Model_Photo to be selected before enabling the Generate_Button
3. THE AI_Look_Generator SHALL require at least 1 Wardrobe_Item to be selected before enabling the Generate_Button
4. THE AI_Look_Generator SHALL enforce a maximum of 5 Wardrobe_Items per generation
5. THE AI_Look_Generator SHALL validate that all selected media items have valid image URLs before adding to queue
6. THE AI_Look_Generator SHALL validate that the user is authenticated before allowing any operations
7. IF the user's session expires during generation, THEN THE Mini_Player SHALL show an error and provide option to return to login
8. THE Generate_Button SHALL be debounced to prevent duplicate generation requests (minimum 1 second between taps)
9. THE Generation_Queue SHALL have a maximum size of 10 items (show toast if user tries to exceed)
10. THE AI_Look_Generator SHALL prevent adding duplicate generations to the queue (same model + same wardrobe items)

## Non-Functional Requirements

### Performance

- Initial screen load SHALL complete within 500ms on mid-range devices
- Image loading SHALL use caching to minimize network requests
- Grid scrolling SHALL maintain 60fps on mid-range devices
- Generation request SHALL timeout after 180 seconds maximum

### Usability

- The 2-step wizard flow SHALL be intuitive and require no instructions
- Selection feedback SHALL be immediate (< 100ms)
- Error messages SHALL be clear and actionable
- Empty states SHALL provide clear guidance on next steps

### Accessibility

- All interactive elements SHALL have semantic labels
- Color contrast SHALL meet WCAG AA standards minimum
- Touch targets SHALL be at least 44x44 points
- Screen reader support SHALL be functional for all features

### Reliability

- The feature SHALL handle network failures gracefully
- The feature SHALL handle API errors gracefully
- The feature SHALL not crash if media data is incomplete
- The feature SHALL preserve user selections during navigation

### Maintainability

- Code SHALL follow MVVM architecture pattern
- Code SHALL follow existing Dressify code style and conventions
- Services SHALL be testable and mockable
- ViewModels SHALL have clear separation of concerns

## UI/UX Requirements

### Selection Screen (Main Screen - Tab Index 2)

- App bar with title "AI Look Oluştur"
- Scrollable content with two main sections:
  - **Model Selection Section:**
    - Section header: "Model Seç" (Manrope ExtraBold, 30px)
    - Horizontal carousel with 312px wide cards
    - Cards: 1:1 aspect ratio, 48px border radius, gradient overlay
    - Selected card: purple border (3px) or checkmark overlay
    - Empty state: illustration + "Model Ekle" button
  - **Wardrobe Selection Section:**
    - Section header: "Kıyafet Seç" (Manrope ExtraBold, 30px)
    - Selection counter badge: "X / 5 SEÇİLDİ" in green (top right)
    - "Yeni Ekle" button (top right, below counter)
    - 2-column masonry grid with 163px item height
    - Selected items: purple checkmark overlay
    - Unselected items: plus icon, 60% opacity
    - Empty state: illustration + "Fotoğraf Yükle" + "Trendyol'da Ara" buttons
- Fixed bottom action button: "Oluştur" (enabled when 1 model + 1-5 items selected)

### Generation Bottom Sheet - Mini Player (Minimized State)

- **Height:** 80-100px
- **Position:** Fixed at bottom of screen, above navigation bar
- **Persists:** Across all tabs (global overlay)
- **Layout:**
  - Left: Circular progress indicator (40px) or status icon
  - Center: Status text ("Look oluşturuluyor...", "Look hazır!", "Hata oluştu")
  - Center (secondary): Estimated time or queue position ("45 saniye kaldı", "2/5 oluşturuluyor")
  - Right: Expand icon (^) and close icon (X)
- **Colors:**
  - Processing: Purple gradient (#742FE5) or white with purple accent
  - Success: Green accent (#10B981)
  - Error: Red accent (#EF4444)
- **Shadow:** Subtle floating shadow for elevation
- **Gestures:**
  - Tap anywhere: Expand to full sheet
  - Swipe down: Close (with confirmation if processing)

### Generation Bottom Sheet - Full Sheet (Expanded State)

- **Height:** 70-80% of screen height (draggable)
- **Drag handle:** Horizontal bar at top (visual affordance)
- **Tab bar:** "Şu An" and "Geçmiş" tabs
- **Gestures:** Swipe down to minimize

#### "Şu An" Tab (Current/Queue)

**During Generation (Processing State):**
- Large generation animations (Lottie or custom)
- Circular/linear progress indicator
- "Look oluşturuluyor..." (Manrope Bold, 24px)
- "Bu işlem 30-90 saniye sürebilir" (Liberation Serif, 14px, gray)
- Small thumbnail previews of selected model + wardrobe items
- Queue list below (if multiple items queued)

**Queue List:**
- Each item shows: model thumbnail, wardrobe thumbnails, status badge, cancel button
- Status badges: "Sırada" (gray), "İşleniyor" (purple), "Tamamlandı" (green), "Hata" (red)

**Success State:**
- Full-width AI look image with proper aspect ratio
- Creation timestamp below image
- "Profilde Görüntüle" button (primary, purple)
- "Yeni Look Oluştur" button (secondary, outlined)

**Error State:**
- Error icon (Iconsax.warning_2, 64px, red)
- Error message (Manrope Medium, 16px)
- "Tekrar Dene" button (primary, purple)
- "Kapat" button (secondary, outlined)

#### "Geçmiş" Tab (History)

- Scrollable list of completed generations
- Each item shows:
  - Result thumbnail (if successful) or error icon
  - Model + wardrobe thumbnails
  - Status badge and timestamp
  - "Görüntüle" button (success) or "Tekrar Dene" button (failed)
- Swipe left to delete
- Empty state: "Henüz geçmiş yok" message

## Data Requirements

### Database Queries

- Load models: `SELECT * FROM media WHERE user_id = ? AND type = 'MODEL' ORDER BY created_at DESC`
- Load wardrobe: `SELECT * FROM media WHERE user_id = ? AND type IN ('UPLOAD', 'TRENDYOL_PRODUCT') ORDER BY created_at DESC`
- The feature SHALL use ProfileViewModel's existing reactive data access (no direct queries)

### Storage Requirements

- Generated AI looks are stored at: `gallery/{user_id}/tryon_multi_{timestamp}.jpg`
- Storage operations are handled by n8n workflow (no direct storage access from app)

### Media Table Schema

The feature relies on the existing media table structure:
- id (uuid, PK)
- user_id (uuid, FK)
- image_url (text)
- type (text) - 'AI_CREATION', 'MODEL', 'UPLOAD', 'TRENDYOL_PRODUCT'
- style_tag (text, nullable) - 'virtual_tryon_multi' for AI looks
- created_at (timestamptz)
- trendyol_product_id (text, nullable)

## Integration Requirements

### n8n API Integration

- Endpoint: `POST https://n8n.emniva.com/webhook/tryon-multi`
- Request timeout: 180 seconds
- Request format: JSON with user_id, person_image_url, garments array
- Response format: JSON with success, image_url, media_id
- Error handling: network failures, timeouts, API errors

### Supabase Integration

- Authentication: Use existing Supabase auth session
- Storage: Read-only access to gallery bucket (URLs provided by media table)
- Realtime: ProfileViewModel already subscribes to media changes

### Existing Services Integration

- ProfileViewModel: Access models and wardrobe via reactive listeners
- MediaService: No direct usage (n8n handles media creation)
- StorageService: No direct usage (n8n handles storage)
- TrendyolService: No direct usage (wardrobe already populated)

## Constraints & Assumptions

### Technical Constraints

- Maximum 5 wardrobe items per generation (n8n/Gemini 20MB limit)
- Generation time: 30-90 seconds (Gemini processing time)
- Image formats: JPEG/PNG only
- Network required: Feature cannot work offline

### Assumptions

- Users have already uploaded model photos and wardrobe items
- n8n webhook is always available and responsive
- Supabase storage URLs are publicly accessible
- ProfileViewModel is already initialized when AI Look Generator loads
- User is authenticated (checked by parent Home widget)

### Dependencies

- Flutter SDK 3.x
- Supabase Flutter SDK
- Provider package for state management
- cached_network_image for image loading
- http package for n8n API calls
- Existing ProfileViewModel and services

## Success Criteria

### User Success Metrics

- Users can complete the 2-step flow without confusion
- Users can generate AI looks successfully > 90% of the time
- Users understand error messages and can recover from errors
- Users find the feature intuitive (no support requests about usage)

### Technical Success Metrics

- Initial screen load < 500ms
- Selection feedback < 100ms
- Grid scrolling maintains 60fps
- Zero crashes related to AI Look Generator
- Proper error handling for all failure scenarios

### Business Success Metrics

- Feature adoption: > 50% of active users try the feature within first week
- Feature retention: > 30% of users who try it use it again within 7 days
- Generation success rate: > 90% of generation attempts succeed
- User satisfaction: Positive feedback in app reviews mentioning AI looks


### Requirement 19: Turkish Language Support

**User Story:** As a Turkish-speaking user, I want all UI text in Turkish, so that I can understand and use the feature easily.

#### Acceptance Criteria

1. THE AI_Look_Generator SHALL display all UI text in Turkish
2. THE AI_Look_Generator SHALL use Turkish category names in the n8n API requests
3. THE error messages SHALL be in Turkish and user-friendly
4. THE loading messages SHALL be in Turkish
5. THE empty state messages SHALL be in Turkish
6. THE button labels SHALL be in Turkish
7. THE toast messages SHALL be in Turkish
8. THE Mini_Player status messages SHALL be in Turkish (e.g., "Look oluşturuluyor...", "Look hazır!", "Hata oluştu")
9. THE Generation_Queue and Generation_History tab labels SHALL be in Turkish ("Şu An", "Geçmiş")
