import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../models/generation_status.dart';
import '../viewmodels/generation_queue_view_model.dart';

/// Minimized state of the Generation Bottom Sheet.
///
/// Persists above the navigation bar across all tabs as a global overlay.
/// Height: 80–90px. Layout:
///   [Left: status indicator] [Center: status text + secondary] [Right: expand + close]
///
/// States:
/// - Processing: purple circular progress + "Look oluşturuluyor..." + queue info
/// - Success:    green checkmark + "Look hazır! Görüntüle"
/// - Error:      red error icon + "Hata oluştu. Tekrar dene"
/// - Idle:       hidden (controlled by GenerationQueueViewModel.isBottomSheetVisible)
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GenerationQueueViewModel>(
      builder: (context, vm, _) {
        if (!vm.isBottomSheetVisible) return const SizedBox.shrink();

        final active = vm.activeGeneration;
        final status = active?.status ??
            (vm.history.isNotEmpty ? vm.history.first.status : null);

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            vm.expandBottomSheet();
          },
          onVerticalDragEnd: (details) {
            // Swipe down to close
            if (details.primaryVelocity != null &&
                details.primaryVelocity! > 300) {
              _handleClose(context, vm);
            }
          },
          child: Container(
            height: 88,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.onSurface.withAlpha(20),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Left: status indicator
                  _StatusIndicator(status: status),
                  const SizedBox(width: 12),

                  // Center: text
                  Expanded(
                    child: _StatusText(vm: vm, status: status),
                  ),

                  // Right: expand + close buttons
                  _ActionButtons(vm: vm),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleClose(BuildContext context, GenerationQueueViewModel vm) {
    if (vm.isProcessing) {
      showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Oluşturma devam ediyor'),
          content: const Text(
            'Oluşturma işlemi arka planda devam edecek. '
            'Mini player\'ı kapatmak istiyor musun?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text('Kapat'),
            ),
          ],
        ),
      ).then((confirmed) {
        if (confirmed == true) vm.hideBottomSheet();
      });
    } else {
      vm.hideBottomSheet();
    }
  }
}

// -----------------------------------------------------------------------------
// Status Indicator (left side)
// -----------------------------------------------------------------------------

class _StatusIndicator extends StatelessWidget {
  final GenerationStatus? status;

  const _StatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: switch (status) {
        GenerationStatus.processing || null => _ProcessingIndicator(),
        GenerationStatus.completed => _IconBadge(
            icon: Iconsax.tick_circle5,
            color: const Color(0xFF10B981), // green
          ),
        GenerationStatus.failed => _IconBadge(
            icon: Iconsax.warning_2,
            color: const Color(0xFFEF4444), // red
          ),
        GenerationStatus.queued => _IconBadge(
            icon: Iconsax.clock,
            color: AppColors.outlineVariant,
          ),
      },
    );
  }
}

class _ProcessingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        backgroundColor: AppColors.primary.withAlpha(30),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// -----------------------------------------------------------------------------
// Status Text (center)
// -----------------------------------------------------------------------------

class _StatusText extends StatelessWidget {
  final GenerationQueueViewModel vm;
  final GenerationStatus? status;

  const _StatusText({required this.vm, required this.status});

  @override
  Widget build(BuildContext context) {
    final (primary, secondary) = _getTexts();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          primary,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (secondary != null) ...[
          const SizedBox(height: 2),
          Text(
            secondary,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.outlineVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  (String, String?) _getTexts() {
    switch (status) {
      case GenerationStatus.processing:
        final total = vm.totalPending;
        final secondary = total > 1
            ? '${vm.history.length + 1}/$total oluşturuluyor'
            : 'Bu işlem 30-90 saniye sürebilir';
        return ('Look oluşturuluyor...', secondary);

      case GenerationStatus.completed:
        return ('Look hazır! Görüntüle', null);

      case GenerationStatus.failed:
        final msg = vm.history.isNotEmpty
            ? vm.history.first.errorMessage
            : null;
        return ('Hata oluştu. Tekrar dene', msg);

      case GenerationStatus.queued:
        return ('Sırada bekliyor...', '${vm.queue.length} işlem sırada');

      case null:
        return ('Look oluşturuluyor...', null);
    }
  }
}

// -----------------------------------------------------------------------------
// Action Buttons (right side)
// -----------------------------------------------------------------------------

class _ActionButtons extends StatelessWidget {
  final GenerationQueueViewModel vm;

  const _ActionButtons({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Expand button
        Semantics(
          label: 'Genişlet',
          button: true,
          child: SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              icon: const Icon(
                Iconsax.arrow_up_2,
                size: 20,
                color: AppColors.outlineVariant,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                vm.expandBottomSheet();
              },
              tooltip: 'Genişlet',
            ),
          ),
        ),

        // Close button
        Semantics(
          label: 'Kapat',
          button: true,
          child: SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              icon: const Icon(
                Iconsax.close_circle,
                size: 20,
                color: AppColors.outlineVariant,
              ),
              onPressed: () => _handleClose(context),
              tooltip: 'Kapat',
            ),
          ),
        ),
      ],
    );
  }

  void _handleClose(BuildContext context) {
    HapticFeedback.lightImpact();
    if (vm.isProcessing) {
      showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Oluşturma devam ediyor'),
          content: const Text(
            'Oluşturma işlemi arka planda devam edecek. '
            'Mini player\'ı kapatmak istiyor musun?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text('Kapat'),
            ),
          ],
        ),
      ).then((confirmed) {
        if (confirmed == true) vm.hideBottomSheet();
      });
    } else {
      vm.hideBottomSheet();
    }
  }
}
