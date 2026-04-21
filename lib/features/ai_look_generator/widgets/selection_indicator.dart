import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';

/// Overlay widget that shows selection state on model and wardrobe item cards.
///
/// - **Selected**: purple border + checkmark overlay
/// - **Unselected**: plus icon + 60% opacity dimming
///
/// Wrap this around (or stack it on top of) the card image.
class SelectionIndicator extends StatelessWidget {
  /// Whether this item is currently selected.
  final bool isSelected;

  /// The child widget (typically a card image) to overlay.
  final Widget child;

  /// Border radius to match the card's corners.
  final BorderRadius borderRadius;

  /// Called when the item is tapped. Haptic feedback is triggered automatically.
  final VoidCallback? onTap;

  /// Semantic label for accessibility.
  final String semanticLabel;

  const SelectionIndicator({
    super.key,
    required this.isSelected,
    required this.child,
    required this.semanticLabel,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap?.call();
        },
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              // Base content with opacity when unselected
              Opacity(
                opacity: isSelected ? 1.0 : 0.6,
                child: child,
              ),

              // Selected: purple border overlay
              if (isSelected)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 3,
                      ),
                    ),
                  ),
                ),

              // Selected: checkmark badge (top-right)
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 28,
                    height: 28,
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

              // Unselected: plus icon (center)
              if (!isSelected)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(200),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.add,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
