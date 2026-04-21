import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../profile/models/media.dart';
import 'empty_state_widget.dart';

/// 2-column grid displaying the user's wardrobe items with selection capability.
///
/// - Shows shimmer placeholders while [isLoading] is true.
/// - Shows [EmptyStateWidget] when [wardrobe] is empty and not loading.
/// - Each item is fixed at 163px height in a 2-column layout.
/// - Tapping an item calls [onItemToggled] with the item's ID.
/// - Selected items are highlighted via [SelectionIndicator].
///
/// Uses [SliverGrid] so it can be embedded inside a [CustomScrollView]
/// alongside other slivers (e.g. the section header).
class WardrobeGrid extends StatelessWidget {
  /// List of wardrobe media items to display.
  final List<Media> wardrobe;

  /// Set of currently selected item IDs.
  final Set<String> selectedIds;

  /// Called when the user taps an item. Returns the item ID.
  final ValueChanged<String> onItemToggled;

  /// Whether data is still loading (shows shimmer).
  final bool isLoading;

  /// Called when the user taps "Fotoğraf Yükle" in the empty state.
  final VoidCallback? onUploadPhotoTap;

  /// Called when the user taps "Trendyol'da Ara" in the empty state.
  final VoidCallback? onBrowseTrendyolTap;

  const WardrobeGrid({
    super.key,
    required this.wardrobe,
    required this.selectedIds,
    required this.onItemToggled,
    this.isLoading = false,
    this.onUploadPhotoTap,
    this.onBrowseTrendyolTap,
  });

  static const double _itemHeight = 163.0;
  static const double _crossAxisSpacing = 12.0;
  static const double _mainAxisSpacing = 12.0;
  // Matches project card radius convention (24px)
  static const double _cardRadius = 24.0;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildShimmer(context);
    if (wardrobe.isEmpty) return _buildEmptyState();
    return _buildGrid(context);
  }

  Widget _buildGrid(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = 24.0 * 2;
    final itemWidth =
        (screenWidth - horizontalPadding - _crossAxisSpacing) / 2;
    final childAspectRatio = itemWidth / _itemHeight;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: _crossAxisSpacing,
        mainAxisSpacing: _mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: wardrobe.length,
      itemBuilder: (context, index) {
        final item = wardrobe[index];
        final isSelected = selectedIds.contains(item.id);
        return _WardrobeItemCard(
          item: item,
          isSelected: isSelected,
          index: index,
          onTap: () => onItemToggled(item.id),
        );
      },
    );
  }

  Widget _buildShimmer(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = 24.0 * 2;
    final itemWidth =
        (screenWidth - horizontalPadding - _crossAxisSpacing) / 2;
    final childAspectRatio = itemWidth / _itemHeight;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: _crossAxisSpacing,
        mainAxisSpacing: _mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.surfaceContainerLow,
          highlightColor: AppColors.surfaceContainerLowest,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(_cardRadius),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Iconsax.bag_2,
      title: 'Gardırobunda kıyafet yok',
      description:
          'Kıyafet eklemek için fotoğraf yükle veya Trendyol\'dan ürün kaydet',
      primaryButtonLabel: 'Fotoğraf Yükle',
      onPrimaryTap: onUploadPhotoTap,
      secondaryButtonLabel: 'Trendyol\'da Ara',
      onSecondaryTap: onBrowseTrendyolTap,
    );
  }
}

class _WardrobeItemCard extends StatelessWidget {
  final Media item;
  final bool isSelected;
  final int index;
  final VoidCallback onTap;

  const _WardrobeItemCard({
    required this.item,
    required this.isSelected,
    required this.index,
    required this.onTap,
  });

  String get _semanticLabel {
    final typeLabel = item.type == MediaType.trendyolProduct
        ? 'Trendyol ürünü'
        : item.tag ?? 'Kıyafet';
    return '$typeLabel ${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _semanticLabel,
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(WardrobeGrid._cardRadius),
            border: isSelected
                ? Border.all(color: AppColors.primary, width: 2.5)
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(WardrobeGrid._cardRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image with opacity when unselected
                Opacity(
                  opacity: isSelected ? 1.0 : 0.6,
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.cover,
                    memCacheHeight: WardrobeGrid._itemHeight.toInt(),
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
                        size: 32,
                      ),
                    ),
                  ),
                ),

                // Selection badge (top-right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: isSelected
                      ? Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(25),
                                blurRadius: 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Iconsax.tick_circle,
                            color: AppColors.onPrimary,
                            size: 16,
                          ),
                        )
                      : Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(204), // 80%
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Iconsax.add,
                            color: AppColors.primary,
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
