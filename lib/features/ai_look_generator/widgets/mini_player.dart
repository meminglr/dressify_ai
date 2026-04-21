import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_colors.dart';
import '../models/generation_status.dart';
import '../viewmodels/generation_queue_view_model.dart';

/// Mini player — WeSlide'ın panelHeader'ı olarak kullanılır.
///
/// Yükseklik: 88px. Kullanıcı bu alana dokunarak veya yukarı kaydırarak
/// full sheet'i açabilir. Aşağı kaydırarak kapatabilir.
///
/// Durumlar:
/// - İşleniyor: mor dönen progress + "Look oluşturuluyor..."
/// - Tamamlandı: yeşil checkmark + "Look hazır! Görüntüle"
/// - Hata: kırmızı ikon + "Hata oluştu. Tekrar dene"
/// - Sırada: gri saat ikonu + "Sırada bekliyor..."
class MiniPlayerContent extends StatelessWidget {
  final GenerationQueueViewModel queueVm;

  const MiniPlayerContent({super.key, required this.queueVm});

  @override
  Widget build(BuildContext context) {
    final active = queueVm.activeGeneration;
    final status = active?.status ??
        (queueVm.history.isNotEmpty ? queueVm.history.first.status : null);
    // Android gesture nav / iOS home indicator için alt padding
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        queueVm.expandBottomSheet();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        // 88px içerik + sistem padding
        height: 88 + bottomPadding,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withAlpha(18),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant.withAlpha(120),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // İçerik satırı — sabit 88px alanın içinde
            SizedBox(
              height: 62, // 88 - 10(top) - 6(bottom) - 10(drag handle)
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _MiniStatusIndicator(status: status),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _MiniStatusText(vm: queueVm, status: status),
                    ),
                    _MiniActionButtons(vm: queueVm),
                  ],
                ),
              ),
            ),
            // Sistem navigation bar için boşluk
            SizedBox(height: bottomPadding),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Durum göstergesi (sol)
// ---------------------------------------------------------------------------

class _MiniStatusIndicator extends StatelessWidget {
  final GenerationStatus? status;

  const _MiniStatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: switch (status) {
        GenerationStatus.processing || null => const _SpinningProgress(),
        GenerationStatus.completed => _StatusIconBadge(
            icon: Iconsax.tick_circle5,
            color: const Color(0xFF10B981),
          ),
        GenerationStatus.failed => _StatusIconBadge(
            icon: Iconsax.warning_2,
            color: const Color(0xFFEF4444),
          ),
        GenerationStatus.queued => _StatusIconBadge(
            icon: Iconsax.clock,
            color: AppColors.outlineVariant,
          ),
      },
    );
  }
}

class _SpinningProgress extends StatelessWidget {
  const _SpinningProgress();

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

class _StatusIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _StatusIconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// ---------------------------------------------------------------------------
// Durum metni (orta)
// ---------------------------------------------------------------------------

class _MiniStatusText extends StatelessWidget {
  final GenerationQueueViewModel vm;
  final GenerationStatus? status;

  const _MiniStatusText({required this.vm, required this.status});

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

// ---------------------------------------------------------------------------
// Aksiyon butonları (sağ)
// ---------------------------------------------------------------------------

class _MiniActionButtons extends StatelessWidget {
  final GenerationQueueViewModel vm;

  const _MiniActionButtons({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Genişlet butonu
        Semantics(
          label: 'Genişlet',
          button: true,
          child: SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Iconsax.arrow_up_2,
                size: 18,
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
        // Kapat butonu
        Semantics(
          label: 'Kapat',
          button: true,
          child: SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Iconsax.close_circle,
                size: 18,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Oluşturma devam ediyor',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w700,
            ),
          ),
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
