import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../profile/models/media.dart';
import 'empty_state_widget.dart';

/// Horizontal scrollable carousel displaying the user's model photos.
///
/// - Shows shimmer placeholders while [isLoading] is true.
/// - Shows [EmptyStateWidget] when [models] is empty and not loading.
/// - Each card is 312×312px with 48px border radius and a gradient overlay.
/// - Tapping a card calls [onModelSelected] with the model's ID.
/// - The selected card is highlighted via [SelectionIndicator].
class ModelCarousel extends StatelessWidget {
  /// List of model media items to display.
  final List<Media> models;

  /// ID of the currently selected model, or null if none.
  final String? selectedModelId;

  /// Called when the user taps a model card.
  final ValueChanged<String> onModelSelected;

  /// Whether data is still loading (shows shimmer).
  final bool isLoading;

  /// Called when the user taps "Model Ekle" in the empty state.
  final VoidCallback? onAddModelTap;

  const ModelCarousel({
    super.key,
    required this.models,
    required this.selectedModelId,
    required this.onModelSelected,
    this.isLoading = false,
    this.onAddModelTap,
  });

  static const double _cardWidth = 312.0;
  static const double _cardHeight = 416.0;
  static const double _cardRadius = 48.0;
  static const double _carouselHeight = _cardHeight;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildShimmer();
    if (models.isEmpty) return _buildEmptyState();
    return _buildCarousel();
  }

  Widget _buildCarousel() {
    return SizedBox(
      height: _carouselHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: models.length,
        itemBuilder: (context, index) {
          final model = models[index];
          final isSelected = model.id == selectedModelId;
          return Padding(
            padding: EdgeInsets.only(right: index < models.length - 1 ? 16 : 0),
            child: _ModelCard(
              model: model,
              isSelected: isSelected,
              index: index,
              onTap: () => onModelSelected(model.id),
            ),
          );
        },      ),
    );
  }

  Widget _buildShimmer() {
    return SizedBox(
      height: _carouselHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: index < 2 ? 16 : 0),
            child: Shimmer.fromColors(
              baseColor: AppColors.surfaceContainerLow,
              highlightColor: AppColors.surfaceContainerLowest,
              child: Container(
                width: _cardWidth,
                height: _cardHeight,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(_cardRadius),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: _carouselHeight,
      child: EmptyStateWidget(
        icon: Iconsax.profile_circle,
        title: 'Model fotoğrafı eklemelisin',
        description: 'AI look oluşturmak için önce bir model fotoğrafı ekle',
        primaryButtonLabel: 'Model Ekle',
        onPrimaryTap: onAddModelTap,
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  final Media model;
  final bool isSelected;
  final int index;
  final VoidCallback onTap;

  const _ModelCard({
    required this.model,
    required this.isSelected,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Model fotoğrafı ${index + 1}',
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: ModelCarousel._cardWidth,
          height: ModelCarousel._cardHeight,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(ModelCarousel._cardRadius),
            border: isSelected
                ? Border.all(color: AppColors.primary, width: 3)
                : null,
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withAlpha(15),
                blurRadius: 48,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ModelCarousel._cardRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                CachedNetworkImage(
                  imageUrl: model.imageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: ModelCarousel._cardWidth.toInt(),
                  memCacheHeight: ModelCarousel._cardHeight.toInt(),
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: AppColors.surfaceContainerLow,
                    highlightColor: AppColors.surfaceContainerLowest,
                    child: Container(color: AppColors.surfaceContainerLow),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.surfaceContainerLow,
                    child: const Icon(
                      Iconsax.image,
                      color: AppColors.outlineVariant,
                      size: 40,
                    ),
                  ),
                ),

                // Gradient overlay (bottom half, dark)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: ModelCarousel._cardHeight * 0.5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF2E3335).withAlpha(153), // 60% opacity
                        ],
                      ),
                    ),
                  ),
                ),

                // Selected checkmark badge (top-right)
                if (isSelected)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.tick_circle,
                        color: AppColors.onPrimary,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
