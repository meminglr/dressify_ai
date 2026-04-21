import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../profile/models/media.dart';
import 'empty_state_widget.dart';

/// Horizontal scrollable carousel displaying the user's model photos using PageView.
///
/// - Shows shimmer placeholders while [isLoading] is true.
/// - Shows [EmptyStateWidget] when [models] is empty and not loading.
/// - Each card is 312×416px with 48px border radius and a gradient overlay.
/// - Tapping a card calls [onModelSelected] with the model's ID.
/// - Uses PageView with viewportFraction for smooth scrolling and reliable tap detection.
class ModelCarousel extends StatefulWidget {
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
  State<ModelCarousel> createState() => _ModelCarouselState();
}

class _ModelCarouselState extends State<ModelCarousel> {
  @override
  Widget build(BuildContext context) {
    // Eğer loading ve liste boşsa shimmer göster
    if (widget.isLoading && widget.models.isEmpty) return _buildShimmer();
    // Eğer loading değil ve liste boşsa empty state göster
    if (widget.models.isEmpty && !widget.isLoading) return _buildEmptyState();
    // Diğer durumlarda carousel göster (veriler varsa veya yükleniyorsa)
    return _buildCarousel();
  }

  Widget _buildCarousel() {
    return SizedBox(
      height: ModelCarousel._carouselHeight,
      child: PageView.builder(
        controller: PageController(
          viewportFraction: 0.85, // Ana kart %85, yanlar görünür
          initialPage: 0,
        ),
        padEnds: false, // Padding'i manuel kontrol edeceğiz
        itemCount: widget.models.length,
        itemBuilder: (context, index) {
          final model = widget.models[index];
          final isSelected = model.id == widget.selectedModelId;
          
          // İlk kart için sol padding ekle (Step header ile aynı hizada)
          final leftPadding = index == 0 ? 24.0 : 8.0;
          
          return Padding(
            padding: EdgeInsets.only(left: leftPadding, right: 8),
            child: _ModelCard(
              model: model,
              isSelected: isSelected,
              index: index,
              onTap: () {
                debugPrint('ModelCarousel: Toggling model ${model.id}');
                widget.onModelSelected(model.id);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return SizedBox(
      height: ModelCarousel._carouselHeight,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.85),
        padEnds: false, // Padding'i manuel kontrol edeceğiz
        itemCount: 3, // 3 shimmer kart göster
        itemBuilder: (context, index) {
          // İlk kart için sol padding ekle (Step header ile aynı hizada)
          final leftPadding = index == 0 ? 24.0 : 8.0;
          
          return Padding(
            padding: EdgeInsets.only(left: leftPadding, right: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow, // Shimmer için daha koyu renk
                borderRadius: BorderRadius.circular(ModelCarousel._cardRadius),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: ModelCarousel._carouselHeight,
      child: EmptyStateWidget(
        icon: Iconsax.profile_circle,
        title: 'Model fotoğrafı eklemelisin',
        description: 'AI look oluşturmak için önce bir model fotoğrafı ekle',
        primaryButtonLabel: 'Model Ekle',
        onPrimaryTap: widget.onAddModelTap,
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
          debugPrint('_ModelCard: Toggle tap detected for model ${model.id}');
          HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ModelCarousel._cardRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ModelCarousel._cardRadius),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(color: AppColors.primary, width: 3)
                    : null,
                borderRadius: BorderRadius.circular(ModelCarousel._cardRadius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ModelCarousel._cardRadius - (isSelected ? 3 : 0)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image with zoom animation
                    AnimatedScale(
                      scale: isSelected ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      child: CachedNetworkImage(
                        imageUrl: model.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        placeholderFadeInDuration: Duration.zero,
                        // Yüksek çözünürlük için cache boyutlarını arttırdık
                        memCacheHeight: (ModelCarousel._cardHeight * 2).toInt(), // 2x daha yüksek
                        maxHeightDiskCache: (ModelCarousel._cardHeight * 2).toInt(), // 2x daha yüksek
                        memCacheWidth: (ModelCarousel._cardWidth * 2).toInt(), // 2x daha geniş
                        maxWidthDiskCache: (ModelCarousel._cardWidth * 2).toInt(), // 2x daha geniş
                        placeholder: (context, url) => Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow, // Görünür shimmer rengi
                            borderRadius: BorderRadius.circular(ModelCarousel._cardRadius - (isSelected ? 3 : 0)),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.surfaceContainerLow, // Görünür error rengi
                          child: const Icon(
                            Iconsax.image,
                            color: AppColors.outlineVariant,
                            size: 40,
                          ),
                        ),
                      ),
                    ),

                    // Selection indicator
                    if (isSelected)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: AnimatedScale(
                          scale: isSelected ? 1.2 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.elasticOut,
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
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
