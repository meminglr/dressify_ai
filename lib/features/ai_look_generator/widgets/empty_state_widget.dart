import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// A reusable empty state widget for the AI Look Generator feature.
///
/// Displays an icon, title, description, and up to two action buttons.
/// Used for model carousel empty state, wardrobe grid empty state,
/// queue empty state, and history empty state.
class EmptyStateWidget extends StatelessWidget {
  /// Icon to display at the top.
  final IconData icon;

  /// Primary title text (Manrope bold).
  final String title;

  /// Secondary description text.
  final String description;

  /// Label for the primary action button (optional).
  final String? primaryButtonLabel;

  /// Callback for the primary action button.
  final VoidCallback? onPrimaryTap;

  /// Label for the secondary action button (optional).
  final String? secondaryButtonLabel;

  /// Callback for the secondary action button.
  final VoidCallback? onSecondaryTap;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.primaryButtonLabel,
    this.onPrimaryTap,
    this.secondaryButtonLabel,
    this.onSecondaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: AppColors.primary.withAlpha(180),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.outlineVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            // Buttons
            if (primaryButtonLabel != null) ...[
              const SizedBox(height: 24),
              _ActionButton(
                label: primaryButtonLabel!,
                onTap: onPrimaryTap,
                filled: true,
              ),
            ],
            if (secondaryButtonLabel != null) ...[
              const SizedBox(height: 12),
              _ActionButton(
                label: secondaryButtonLabel!,
                onTap: onSecondaryTap,
                filled: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool filled;

  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return Semantics(
        label: label,
        button: true,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: onTap,
            child: Text(label),
          ),
        ),
      );
    }

    // Outlined secondary button — matches project's outlined style
    return Semantics(
      label: label,
      button: true,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(48),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
