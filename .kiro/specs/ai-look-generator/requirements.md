# Requirements Document: AI Look Generator

## Introduction

The AI Look Generator is a new feature for the Dressify Flutter fashion app that enables users to create AI-generated outfit visualizations by combining their model photos with wardrobe items. The feature uses multi-garment virtual try-on technology powered by n8n workflows and Gemini AI to generate realistic outfit combinations. This feature will be placed in the 3rd tab (index 2) of the bottom navigation bar, replacing the current placeholder content.

The feature follows a single-page selection flow where users can select a model photo and 1-5 wardrobe items on the same screen. When the user taps "Oluştur", the app navigates to a separate generation screen that shows the loading state and displays the result when complete. After generation (30-90 seconds), the result is saved to the user's profile as an AI Look.

## Glossary

- **AI_Look_Generator**: The main feature system that orchestrates model selection, wardrobe selection, and AI generation on a single screen
- **Model_Photo**: A user-uploaded photo of a person stored in the media table with type='MODEL'
- **Wardrobe_Item**: A clothing item that is either user-uploaded (type='UPLOAD') or a saved Trendyol product (type='TRENDYOL_PRODUCT')
- **Generation_Request**: An API request to the n8n multi-garment endpoint containing model photo URL and 1-5 garment URLs
- **AI_Look**: The generated outfit visualization saved to media table with type='AI_CREATION' and style_tag='virtual_tryon_multi'
- **Selection_State**: The current state of user selections including selected model ID and list of selected wardrobe item IDs
- **Model_Carousel**: Horizontal scrollable carousel displaying user's model photos with card-based UI
- **Wardrobe_Grid**: 2-column masonry-style grid displaying wardrobe items with selection capability
- **Generate_Button**: Fixed bottom action button that triggers navigation to generation screen when enabled
- **Generation_Screen**: Separate full-screen page that shows loading state during generation and displays the result
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

### Requirement 3: Generation Screen Navigation

**User Story:** As a user, I want to navigate to a separate generation screen when I tap "Oluştur", so that I can see the loading progress and result without distractions.

#### Acceptance Criteria

1. WHEN a model is selected AND at least 1 Wardrobe_Item is selected, THE Generate_Button SHALL be enabled on the Selection_Screen
2. WHEN the Generate_Button is tapped, THE AI_Look_Generator SHALL validate that Selection_State contains a model ID and 1-5 wardrobe item IDs
3. IF validation fails, THEN THE AI_Look_Generator SHALL show an error toast with the specific issue
4. WHEN validation succeeds, THE AI_Look_Generator SHALL navigate to the Generation_Screen using a full-screen page route
5. THE Generation_Screen SHALL immediately start the AI generation process upon navigation
6. THE Selection_Screen SHALL remain in the navigation stack so users can return with the back button
7. THE Generate_Button SHALL be disabled IF no model is selected OR no wardrobe items are selected

### Requirement 4: AI Generation Process

**User Story:** As a user, I want to see the generation progress on a dedicated screen, so that I know the app is working and can wait comfortably.

#### Acceptance Criteria

1. WHEN the Generation_Screen loads, THE AI_Look_Generator SHALL immediately call n8n_Service.generateMultiGarmentLook with the Generation_Request
2. THE Generation_Screen SHALL display a full-screen loading state with a circular progress indicator
3. THE Generation_Screen SHALL display the text "Look oluşturuluyor..." prominently
4. THE Generation_Screen SHALL display the text "Bu işlem 30-90 saniye sürebilir" as secondary information
5. THE Generation_Screen SHALL prevent back navigation WHILE generation is in progress (show confirmation dialog if user tries to go back)
6. WHEN generation completes successfully, THE Generation_Screen SHALL automatically transition to show the result
7. THE Generation_Screen SHALL handle the entire generation lifecycle from start to completion or error

### Requirement 5: n8n API Integration

**User Story:** As a developer, I want to integrate with the n8n multi-garment endpoint, so that the app can generate AI looks.

#### Acceptance Criteria

1. THE n8n_Service SHALL send POST requests to https://n8n.emniva.com/webhook/tryon-multi
2. THE Generation_Request SHALL include user_id (UUID), person_image_url (model photo URL), and garments array (1-5 items)
3. FOR EACH Wardrobe_Item in Selection_State, THE n8n_Service SHALL include image_url, category, and optional product_name in the garments array
4. THE n8n_Service SHALL map Wardrobe_Item types to appropriate category strings (e.g., "Tişört", "Pantolon", "Ayakkabı")
5. WHEN the n8n API returns success=true, THE n8n_Service SHALL return the image_url and media_id
6. IF the n8n API returns an error OR times out after 180 seconds, THEN THE n8n_Service SHALL throw an exception with a descriptive error message
7. THE n8n_Service SHALL include proper error handling for network failures, timeouts, and invalid responses

### Requirement 6: Generation Result Display

**User Story:** As a user, I want to see the generated AI look on the same screen after loading completes, so that I can immediately view the result.

#### Acceptance Criteria

1. WHEN n8n_Service returns a successful response, THE Generation_Screen SHALL transition from loading state to result state
2. THE Generation_Screen SHALL display the AI_Look image at full width with proper aspect ratio
3. THE Generation_Screen SHALL include a "Profilde Görüntüle" button at the bottom
4. THE Generation_Screen SHALL include a "Yeni Look Oluştur" button at the bottom
5. WHEN "Profilde Görüntüle" is tapped, THE AI_Look_Generator SHALL navigate to the profile screen with AI Looks tab selected
6. WHEN "Yeni Look Oluştur" is tapped, THE AI_Look_Generator SHALL pop back to the Selection_Screen AND reset Selection_State
7. THE Generation_Screen SHALL display the creation timestamp below the image
8. THE AI_Look_Generator SHALL refresh ProfileViewModel to ensure the new AI_Look appears in the profile

### Requirement 7: Error Handling and User Feedback

**User Story:** As a user, I want clear feedback when errors occur during generation, so that I understand what went wrong and how to proceed.

#### Acceptance Criteria

1. IF the n8n API returns an error, THEN THE Generation_Screen SHALL display an error state with the message "Look oluşturulamadı. Lütfen tekrar deneyin."
2. IF the network request times out, THEN THE Generation_Screen SHALL display an error state with the message "İstek zaman aşımına uğradı. İnternet bağlantınızı kontrol edin."
3. IF the user has no Model_Photos on Selection_Screen, THEN THE AI_Look_Generator SHALL display an empty state with guidance to add model photos
4. IF the user has no Wardrobe_Items on Selection_Screen, THEN THE AI_Look_Generator SHALL display an empty state with guidance to add wardrobe items
5. WHEN an error state is displayed on Generation_Screen, THE AI_Look_Generator SHALL include a "Tekrar Dene" button to retry the generation
6. WHEN an error state is displayed on Generation_Screen, THE AI_Look_Generator SHALL include a "Geri Dön" button to return to Selection_Screen
7. THE AI_Look_Generator SHALL log all errors to the console for debugging purposes
8. WHEN the user taps "Tekrar Dene", THE Generation_Screen SHALL restart the generation process with the same selections

### Requirement 8: Loading States and Progress Indication

**User Story:** As a user, I want to see clear loading indicators during AI generation on the dedicated generation screen, so that I know the app is working and approximately how long to wait.

#### Acceptance Criteria

1. WHEN the Generation_Screen is in loading state, THE screen SHALL display a full-screen loading UI
2. THE loading UI SHALL include a large circular progress indicator centered on the screen
3. THE loading UI SHALL display the text "Look oluşturuluyor..." prominently below the progress indicator
4. THE loading UI SHALL display the text "Bu işlem 30-90 saniye sürebilir" as secondary information
5. THE loading UI SHALL use a clean, minimal design with the app's color scheme
6. WHEN the Model_Carousel is loading data on Selection_Screen, THE AI_Look_Generator SHALL display shimmer placeholders with the same card dimensions
7. WHEN the Wardrobe_Grid is loading data on Selection_Screen, THE AI_Look_Generator SHALL display shimmer placeholders in the 2-column grid layout
8. THE Generation_Screen SHALL NOT show a back button during loading to prevent accidental cancellation

### Requirement 9: Data Persistence and State Management

**User Story:** As a developer, I want proper state management for selections and generation state, so that the feature is reliable and maintainable.

#### Acceptance Criteria

1. THE AI_Look_Generator SHALL use a ChangeNotifier-based ViewModel following the MVVM pattern
2. THE Selection_State SHALL be stored in the ViewModel and persist during the user's session on Selection_Screen
3. WHEN the user navigates to Generation_Screen, THE Selection_State SHALL be passed as navigation arguments
4. WHEN the user taps "Yeni Look Oluştur" on Generation_Screen, THE Selection_State SHALL be cleared
5. WHEN the user returns to Selection_Screen from another tab, THE Selection_State SHALL start fresh (no selections)
6. THE ViewModel SHALL use ProfileViewModel.modelsListenable and ProfileViewModel.wardrobeListenable for reactive data access
7. THE ViewModel SHALL NOT trigger unnecessary rebuilds when Selection_State changes (use Consumer or ValueListenableBuilder selectively)
8. THE ViewModel SHALL properly dispose of listeners and resources when screens are disposed
9. THE Generation_Screen SHALL have its own ViewModel to manage generation state (loading, success, error)

### Requirement 10: UI Design System Compliance

**User Story:** As a designer, I want the AI Look Generator to follow the Dressify design system, so that it feels consistent with the rest of the app.

#### Acceptance Criteria

1. THE AI_Look_Generator SHALL use AppColors.primary (#742FE5) for primary actions and selected states
2. THE AI_Look_Generator SHALL use AppColors.background (#F8F9FA) for screen backgrounds
3. THE AI_Look_Generator SHALL use AppColors.onSurface (#2E3335) for primary text
4. THE AI_Look_Generator SHALL use 24px, 32px, or 48px border radius for cards and containers
5. THE AI_Look_Generator SHALL use Manrope font for headings and Liberation Serif for labels
6. THE AI_Look_Generator SHALL use subtle shadows with low opacity for elevated elements
7. THE Generate_Button SHALL follow the same style as existing primary action buttons in the app (e.g., "Yeni Üret" button)

### Requirement 11: Accessibility and Usability

**User Story:** As a user with accessibility needs, I want the AI Look Generator to be accessible, so that I can use all features effectively.

#### Acceptance Criteria

1. THE Model_Carousel cards SHALL include semantic labels describing "Model fotoğrafı {index}"
2. THE Wardrobe_Grid items SHALL include semantic labels describing the item type (e.g., "Tişört", "Pantolon")
3. THE Generate_Button SHALL include a semantic label "Look oluştur"
4. THE selection counter badge SHALL announce selection changes to screen readers
5. THE AI_Look_Generator SHALL support keyboard navigation for all interactive elements
6. THE AI_Look_Generator SHALL provide sufficient color contrast (WCAG AA minimum) for all text
7. THE AI_Look_Generator SHALL provide haptic feedback when items are selected or deselected

### Requirement 12: Performance and Optimization

**User Story:** As a user, I want the AI Look Generator to be fast and responsive, so that I have a smooth experience.

#### Acceptance Criteria

1. THE Model_Carousel SHALL load and display images efficiently using cached_network_image with memory caching
2. THE Wardrobe_Grid SHALL use lazy loading to render only visible items
3. THE AI_Look_Generator SHALL NOT rebuild the entire widget tree when Selection_State changes (use selective rebuilds)
4. THE AI_Look_Generator SHALL preload the next step's data in the background when the user is on step 1
5. THE AI_Look_Generator SHALL compress images before sending to n8n API IF the total payload exceeds 15MB
6. THE AI_Look_Generator SHALL cancel any in-progress generation request IF the user navigates away from the screen
7. THE AI_Look_Generator SHALL complete initial screen render within 500ms on mid-range devices

### Requirement 13: Integration with Existing Architecture

**User Story:** As a developer, I want the AI Look Generator to integrate seamlessly with existing code, so that it's maintainable and consistent.

#### Acceptance Criteria

1. THE AI_Look_Generator SHALL reuse ProfileViewModel for accessing models and wardrobe data
2. THE AI_Look_Generator SHALL reuse MediaService for any media-related operations
3. THE AI_Look_Generator SHALL reuse StorageService for any storage-related operations
4. THE AI_Look_Generator SHALL follow the existing MVVM architecture pattern (ViewModel + View separation)
5. THE AI_Look_Generator SHALL use existing reusable widgets (e.g., MasonryGridView) where applicable
6. THE AI_Look_Generator SHALL use existing services pattern (singleton services with dependency injection)
7. THE AI_Look_Generator SHALL replace the placeholder content at tab index 2 in lib/home.dart

### Requirement 14: Category Mapping for Garments

**User Story:** As a developer, I want to map wardrobe items to appropriate categories, so that the AI generates accurate results.

#### Acceptance Criteria

1. THE n8n_Service SHALL map wardrobe item types to Turkish category strings
2. THE category mapping SHALL support: Tişört, Bluz, Gömlek, Pantolon, Jeans, Şort, Etek, Elbise, Tulum, Ceket, Mont, Hırka, Ayakkabı, Bot, Sneaker, Aksesuar, Kemer, Çanta, Şapka
3. WHEN a Wardrobe_Item has a style_tag or metadata indicating category, THE n8n_Service SHALL use that category
4. WHEN a Wardrobe_Item has no category information, THE n8n_Service SHALL use a default category based on the item type
5. FOR Trendyol products, THE n8n_Service SHALL extract category from the product metadata IF available
6. THE n8n_Service SHALL include the product_name in the Generation_Request IF available to improve AI prompt quality
7. THE category mapping SHALL be configurable and extensible for future category additions

### Requirement 15: Empty State Handling

**User Story:** As a user, I want helpful guidance when I have no models or wardrobe items, so that I know what to do next.

#### Acceptance Criteria

1. WHEN the user has zero Model_Photos, THE AI_Look_Generator SHALL display an empty state illustration
2. THE empty state for models SHALL include the text "Model fotoğrafı eklemelisin"
3. THE empty state for models SHALL include a description "AI look oluşturmak için önce bir model fotoğrafı ekle"
4. THE empty state for models SHALL include a "Model Ekle" button that navigates to profile models tab
5. WHEN the user has zero Wardrobe_Items, THE AI_Look_Generator SHALL display an empty state illustration
6. THE empty state for wardrobe SHALL include the text "Gardırobunda kıyafet yok"
7. THE empty state for wardrobe SHALL include a description "Kıyafet eklemek için fotoğraf yükle veya Trendyol'dan ürün kaydet"
8. THE empty state for wardrobe SHALL include "Fotoğraf Yükle" and "Trendyol'da Ara" buttons

### Requirement 16: Generation Screen Features

**User Story:** As a user, I want to interact with the generated AI look on the generation screen, so that I can save, view in profile, or create new looks.

#### Acceptance Criteria

1. THE Generation_Screen SHALL display three states: loading, success, and error
2. IN loading state, THE Generation_Screen SHALL show progress indicator and loading messages
3. IN success state, THE Generation_Screen SHALL display the generated AI_Look image with proper aspect ratio and full width
4. IN success state, THE Generation_Screen SHALL include a "Profilde Görüntüle" button at the bottom
5. WHEN "Profilde Görüntüle" is tapped, THE AI_Look_Generator SHALL navigate to the profile screen with AI Looks tab selected
6. IN success state, THE Generation_Screen SHALL include a "Yeni Look Oluştur" button at the bottom
7. WHEN "Yeni Look Oluştur" is tapped, THE AI_Look_Generator SHALL pop back to Selection_Screen AND reset Selection_State
8. IN success state, THE Generation_Screen SHALL display the creation timestamp below the image
9. IN error state, THE Generation_Screen SHALL display error message with "Tekrar Dene" and "Geri Dön" buttons
10. THE Generation_Screen SHALL include a back button in the app bar that works only in success or error states

### Requirement 17: Validation and Business Rules

**User Story:** As a developer, I want to enforce business rules for AI generation, so that the feature works reliably.

#### Acceptance Criteria

1. THE Generate_Button on Selection_Screen SHALL be disabled UNLESS exactly 1 Model_Photo AND at least 1 Wardrobe_Item are selected
2. THE AI_Look_Generator SHALL require exactly 1 Model_Photo to be selected before enabling the Generate_Button
3. THE AI_Look_Generator SHALL require at least 1 Wardrobe_Item to be selected before enabling the Generate_Button
4. THE AI_Look_Generator SHALL enforce a maximum of 5 Wardrobe_Items per generation
5. THE AI_Look_Generator SHALL validate that all selected media items have valid image URLs before navigating to Generation_Screen
6. THE AI_Look_Generator SHALL validate that the user is authenticated before allowing any operations
7. IF the user's session expires during generation, THEN THE Generation_Screen SHALL show an error and provide option to return to login
8. THE Generate_Button SHALL be debounced to prevent duplicate generation requests (minimum 1 second between taps)

### Requirement 18: Turkish Language Support

**User Story:** As a Turkish-speaking user, I want all UI text in Turkish, so that I can understand and use the feature easily.

#### Acceptance Criteria

1. THE AI_Look_Generator SHALL display all UI text in Turkish
2. THE AI_Look_Generator SHALL use Turkish category names in the n8n API requests
3. THE error messages SHALL be in Turkish and user-friendly
4. THE loading messages SHALL be in Turkish
5. THE empty state messages SHALL be in Turkish
6. THE button labels SHALL be in Turkish
7. THE toast messages SHALL be in Turkish

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

### Generation Screen (Separate Full-Screen Page)

**Loading State:**
- Full-screen centered layout
- Large circular progress indicator
- "Look oluşturuluyor..." text (Manrope Bold, 24px)
- "Bu işlem 30-90 saniye sürebilir" text (Liberation Serif, 14px, gray)
- No back button during loading
- Clean, minimal design with app color scheme

**Success State:**
- App bar with back button and title "AI Look"
- Full-width AI look image with proper aspect ratio
- Creation timestamp below image (Liberation Serif, 12px, gray)
- Two action buttons at bottom:
  - "Profilde Görüntüle" (primary style, purple)
  - "Yeni Look Oluştur" (secondary style, outlined)

**Error State:**
- Centered error icon (Iconsax.warning_2, 64px, red)
- Error message text (Manrope Medium, 16px)
- Two action buttons:
  - "Tekrar Dene" (primary style, purple)
  - "Geri Dön" (secondary style, outlined)

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
