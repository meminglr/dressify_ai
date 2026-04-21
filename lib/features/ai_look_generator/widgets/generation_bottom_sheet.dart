import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../models/generation_queue_item.dart';
import '../models/generation_status.dart';
import '../viewmodels/generation_queue_view_model.dart';
import 'empty_state_widget.dart';

/// SlidingUpPanel'ın `panelBuilder` içeriği — mini player header + full sheet tek widget'ta.
///
/// - Üst kısım: mini player (drag handle + durum satırı) — her zaman görünür
/// - Alt kısım: full sheet içeriği (tab bar + tab view) — panel açıldığında görünür
///
/// [scrollController] SlidingUpPanel'dan gelir; panel içindeki scroll ile
/// panel pozisyonunu senkronize eder.
class GenerationCombinedPanel extends StatefulWidget {
  final GenerationQueueViewModel queueVm;
  final ScrollController? scrollController;

  const GenerationCombinedPanel({
    super.key,
    required this.queueVm,
    this.scrollController,
  });

  @override
  State<GenerationCombinedPanel> createState() =>
      _GenerationCombinedPanelState();
}

class _GenerationCombinedPanelState extends State<GenerationCombinedPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnimatedBuilder(
      animation: widget.queueVm,
      builder: (context, _) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // ── Mini player header (her zaman görünür) ──────────────────
              _MiniHeader(
                queueVm: widget.queueVm,
                bottomPadding: bottomPadding,
              ),

              // ── Full sheet içeriği (panel açıldığında görünür) ──────────
              Expanded(
                child: Column(
                  children: [
                    _SheetTabBar(controller: _tabController),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _NowTab(
                            vm: widget.queueVm,
                            scrollController: widget.scrollController,
                          ),
                          _HistoryTab(
                            vm: widget.queueVm,
                            scrollController: widget.scrollController,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Panel'in tepesindeki mini player header kısmı.
/// Drag handle + durum satırı içerir.
class _MiniHeader extends StatelessWidget {
  final GenerationQueueViewModel queueVm;
  final double bottomPadding;

  const _MiniHeader({
    required this.queueVm,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    final active = queueVm.activeGeneration;
    final status = active?.status ??
        (queueVm.history.isNotEmpty ? queueVm.history.first.status : null);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        queueVm.expandBottomSheet();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 88,
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
            // Durum satırı
            Expanded(
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
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab bar
// ---------------------------------------------------------------------------

class _SheetTabBar extends StatelessWidget {
  final TabController controller;

  const _SheetTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      dividerColor: Colors.transparent,
      indicatorColor: AppColors.primary,
      indicatorWeight: 2.5,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.outlineVariant,
      labelStyle: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      tabs: const [
        Tab(text: 'Şu An'),
        Tab(text: 'Geçmiş'),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// "Şu An" sekmesi
// ---------------------------------------------------------------------------

class _NowTab extends StatelessWidget {
  final GenerationQueueViewModel vm;
  final ScrollController? scrollController;

  const _NowTab({required this.vm, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final active = vm.activeGeneration;

    if (active == null && vm.queue.isEmpty) {
      return const EmptyStateWidget(
        icon: Iconsax.magic_star,
        title: 'Henüz look oluşturmadın',
        description: 'Model ve kıyafet seçerek ilk AI look\'unu oluştur',
      );
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      children: [
        if (active != null) ...[
          _ActiveGenerationCard(item: active, vm: vm),
          const SizedBox(height: 24),
        ],
        if (vm.queue.isNotEmpty) ...[
          const Text(
            'Sıradakiler',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...vm.queue.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _QueueItemCard(item: item, vm: vm),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Aktif üretim kartı — duruma göre farklı widget gösterir
// ---------------------------------------------------------------------------

class _ActiveGenerationCard extends StatelessWidget {
  final GenerationQueueItem item;
  final GenerationQueueViewModel vm;

  const _ActiveGenerationCard({required this.item, required this.vm});

  @override
  Widget build(BuildContext context) {
    return switch (item.status) {
      GenerationStatus.processing => _ProcessingCard(item: item),
      GenerationStatus.completed => _SuccessCard(item: item, vm: vm),
      GenerationStatus.failed => _ErrorCard(item: item, vm: vm),
      GenerationStatus.queued => _QueueItemCard(item: item, vm: vm),
    };
  }
}

// ---------------------------------------------------------------------------
// İşleniyor kartı — pulse animasyonu + progress bar
// ---------------------------------------------------------------------------

class _ProcessingCard extends StatefulWidget {
  final GenerationQueueItem item;

  const _ProcessingCard({required this.item});

  @override
  State<_ProcessingCard> createState() => _ProcessingCardState();
}

class _ProcessingCardState extends State<_ProcessingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withAlpha(12),
            AppColors.primary.withAlpha(5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withAlpha(30),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Küçük önizlemeler — pulse animasyonlu
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) => Opacity(
              opacity: _pulseAnim.value,
              child: child,
            ),
            child: _ThumbnailsRow(
              modelUrl: widget.item.modelThumbnail,
              wardrobeUrls: widget.item.wardrobeThumbnails,
            ),
          ),
          const SizedBox(height: 20),

          // Başlık
          const Text(
            'Look oluşturuluyor...',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bu işlem 30-90 saniye sürebilir',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.outlineVariant,
            ),
          ),
          const SizedBox(height: 20),

          // Animasyonlu progress bar
          _AnimatedProgressBar(controller: _pulseCtrl),
        ],
      ),
    );
  }
}

/// Mor renkte smooth indeterminate progress bar
class _AnimatedProgressBar extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedProgressBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        minHeight: 6,
        backgroundColor: AppColors.primary.withAlpha(25),
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Başarı kartı
// ---------------------------------------------------------------------------

class _SuccessCard extends StatelessWidget {
  final GenerationQueueItem item;
  final GenerationQueueViewModel vm;

  const _SuccessCard({required this.item, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başarı rozeti
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withAlpha(20),
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.tick_circle5, size: 16, color: Color(0xFF10B981)),
              SizedBox(width: 6),
              Text(
                'Look hazır!',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Sonuç görseli
        if (item.resultImageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: CachedNetworkImage(
                imageUrl: item.resultImageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.surfaceContainerLow,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.surfaceContainerLow,
                  child: const Icon(Iconsax.image, size: 48),
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),

        // Zaman damgası
        Text(
          DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(item.timestamp),
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.outlineVariant,
          ),
        ),
        const SizedBox(height: 20),

        // Aksiyon butonları
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => vm.hideBottomSheet(),
            icon: const Icon(Iconsax.user, size: 18),
            label: const Text('Profilde Görüntüle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(48),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () => vm.hideBottomSheet(),
            icon: const Icon(Iconsax.magic_star, size: 18),
            label: const Text('Yeni Look Oluştur'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(48),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hata kartı
// ---------------------------------------------------------------------------

class _ErrorCard extends StatelessWidget {
  final GenerationQueueItem item;
  final GenerationQueueViewModel vm;

  const _ErrorCard({required this.item, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withAlpha(10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFEF4444).withAlpha(40),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(Iconsax.warning_2, size: 56, color: Color(0xFFEF4444)),
          const SizedBox(height: 16),
          Text(
            item.errorMessage ?? 'Bir hata oluştu',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => vm.retryFailedItem(item.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(48),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Tekrar Dene'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {
                vm.removeFromHistory(item.id);
                vm.hideBottomSheet();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(48),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Kapat'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sıra kartı
// ---------------------------------------------------------------------------

class _QueueItemCard extends StatelessWidget {
  final GenerationQueueItem item;
  final GenerationQueueViewModel vm;

  const _QueueItemCard({required this.item, required this.vm});

  @override
  Widget build(BuildContext context) {
    final isProcessing = item.status == GenerationStatus.processing;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _ThumbnailsRow(
            modelUrl: item.modelThumbnail,
            wardrobeUrls: item.wardrobeThumbnails,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(child: _StatusBadge(status: item.status)),
          if (!isProcessing)
            IconButton(
              icon: const Icon(
                Iconsax.close_circle,
                size: 20,
                color: AppColors.outlineVariant,
              ),
              onPressed: () => vm.cancelQueuedItem(item.id),
              tooltip: 'İptal et',
            )
          else
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Geçmiş" sekmesi
// ---------------------------------------------------------------------------

class _HistoryTab extends StatelessWidget {
  final GenerationQueueViewModel vm;
  final ScrollController? scrollController;

  const _HistoryTab({required this.vm, this.scrollController});

  @override
  Widget build(BuildContext context) {
    if (vm.history.isEmpty) {
      return const EmptyStateWidget(
        icon: Iconsax.clock,
        title: 'Henüz geçmiş yok',
        description: 'Oluşturduğun looklar burada görünecek',
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      itemCount: vm.history.length,
      itemBuilder: (context, index) {
        final item = vm.history[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            key: Key(item.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withAlpha(20),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Iconsax.trash, color: Color(0xFFEF4444)),
            ),
            onDismissed: (_) => vm.removeFromHistory(item.id),
            child: _HistoryItemCard(item: item, vm: vm),
          ),
        );
      },
    );
  }
}

class _HistoryItemCard extends StatelessWidget {
  final GenerationQueueItem item;
  final GenerationQueueViewModel vm;

  const _HistoryItemCard({required this.item, required this.vm});

  @override
  Widget build(BuildContext context) {
    final isSuccess = item.status == GenerationStatus.completed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Sonuç küçük resmi veya hata ikonu
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: isSuccess && item.resultImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.resultImageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceContainerLow,
                        child: const Icon(Iconsax.image, size: 24),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFEF4444).withAlpha(15),
                      child: const Icon(
                        Iconsax.warning_2,
                        color: Color(0xFFEF4444),
                        size: 24,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Bilgi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusBadge(status: item.status),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM, HH:mm', 'tr_TR').format(item.timestamp),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.outlineVariant,
                  ),
                ),
              ],
            ),
          ),

          // Aksiyon butonu
          if (isSuccess)
            TextButton(
              onPressed: () => vm.expandBottomSheet(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text(
                'Görüntüle',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            TextButton(
              onPressed: () => vm.retryFailedItem(item.id),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text(
                'Tekrar Dene',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Paylaşılan yardımcı widget'lar
// ---------------------------------------------------------------------------

class _ThumbnailsRow extends StatelessWidget {
  final String modelUrl;
  final List<String> wardrobeUrls;
  final double size;

  const _ThumbnailsRow({
    required this.modelUrl,
    required this.wardrobeUrls,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final allUrls = [modelUrl, ...wardrobeUrls.take(4)];

    return SizedBox(
      height: size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: allUrls.asMap().entries.map((entry) {
          final i = entry.key;
          final url = entry.value;
          return Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.25),
              child: SizedBox(
                width: size,
                height: size,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.surfaceContainerLow,
                    child: const Icon(Iconsax.image, size: 16),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final GenerationStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      GenerationStatus.queued => ('Sırada', AppColors.outlineVariant),
      GenerationStatus.processing => ('İşleniyor', AppColors.primary),
      GenerationStatus.completed => ('Tamamlandı', const Color(0xFF10B981)),
      GenerationStatus.failed => ('Hata', const Color(0xFFEF4444)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mini header yardımcı widget'ları
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
        final msg =
            vm.history.isNotEmpty ? vm.history.first.errorMessage : null;
        return ('Hata oluştu. Tekrar dene', msg);
      case GenerationStatus.queued:
        return ('Sırada bekliyor...', '${vm.queue.length} işlem sırada');
      case null:
        return ('Look oluşturuluyor...', null);
    }
  }
}

class _MiniActionButtons extends StatelessWidget {
  final GenerationQueueViewModel vm;

  const _MiniActionButtons({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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

/// Eski overlay widget — geriye dönük uyumluluk için tutuldu.
/// Artık SlidingUpPanel entegrasyonu ile kullanılmıyor.
@Deprecated('SlidingUpPanel entegrasyonu ile artık kullanılmıyor')
class GenerationBottomSheetOverlay extends StatelessWidget {
  const GenerationBottomSheetOverlay({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}