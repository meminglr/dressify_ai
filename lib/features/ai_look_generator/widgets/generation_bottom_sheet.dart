import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../models/generation_queue_item.dart';
import '../models/generation_status.dart';
import '../viewmodels/generation_queue_view_model.dart';
import 'empty_state_widget.dart';
import 'mini_player.dart';

/// The persistent generation bottom sheet overlay.
///
/// Renders either the [MiniPlayer] (minimized) or the full sheet (expanded),
/// controlled by [GenerationQueueViewModel.isMinimized].
///
/// This widget is placed in a global [Stack] in the Home widget so it persists
/// across tab navigation.
class GenerationBottomSheetOverlay extends StatelessWidget {
  const GenerationBottomSheetOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GenerationQueueViewModel>(
      builder: (context, vm, _) {
        if (!vm.isBottomSheetVisible) return const SizedBox.shrink();

        if (vm.isMinimized) {
          // Mini player — positioned above nav bar by the parent Stack
          return const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 90), // above nav bar
              child: RepaintBoundary(
                child: MiniPlayer(),
              ),
            ),
          );
        }

        // Full sheet
        return const _FullSheet();
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Full Sheet
// -----------------------------------------------------------------------------

class _FullSheet extends StatefulWidget {
  const _FullSheet();

  @override
  State<_FullSheet> createState() => _FullSheetState();
}

class _FullSheetState extends State<_FullSheet>
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
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      // Swipe down to minimize
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity! > 400) {
          HapticFeedback.lightImpact();
          context.read<GenerationQueueViewModel>().minimizeBottomSheet();
        }
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: screenHeight * 0.78,
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A2E3335),
                blurRadius: 40,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              const _DragHandle(),

              // Tab bar
              _SheetTabBar(controller: _tabController),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    _NowTab(),
                    _HistoryTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.outlineVariant.withAlpha(100),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetTabBar extends StatelessWidget {
  final TabController controller;

  const _SheetTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      dividerColor: Colors.transparent,
      indicatorColor: AppColors.primary,
      indicatorWeight: 2,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.outlineVariant,
      labelStyle: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 14,
        fontWeight: FontWeight.w600,
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

// -----------------------------------------------------------------------------
// "Şu An" Tab
// -----------------------------------------------------------------------------

class _NowTab extends StatelessWidget {
  const _NowTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<GenerationQueueViewModel>(
      builder: (context, vm, _) {
        final active = vm.activeGeneration;

        // Empty state
        if (active == null && vm.queue.isEmpty) {
          return const EmptyStateWidget(
            icon: Iconsax.magic_star,
            title: 'Henüz look oluşturmadın',
            description:
                'Model ve kıyafet seçerek ilk AI look\'unu oluştur',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Active generation
            if (active != null) ...[
              _ActiveGenerationCard(item: active),
              const SizedBox(height: 24),
            ],

            // Queue list
            if (vm.queue.isNotEmpty) ...[
              Text(
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
                  child: _QueueItemCard(item: item),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// Active generation card — shows processing / success / error state
class _ActiveGenerationCard extends StatelessWidget {
  final GenerationQueueItem item;

  const _ActiveGenerationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return switch (item.status) {
      GenerationStatus.processing => _ProcessingCard(item: item),
      GenerationStatus.completed => _SuccessCard(item: item),
      GenerationStatus.failed => _ErrorCard(item: item),
      GenerationStatus.queued => _QueueItemCard(item: item),
    };
  }
}

// Processing state card
class _ProcessingCard extends StatefulWidget {
  final GenerationQueueItem item;

  const _ProcessingCard({required this.item});

  @override
  State<_ProcessingCard> createState() => _ProcessingCardState();
}

class _ProcessingCardState extends State<_ProcessingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnails row with pulse animation
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Opacity(
              opacity: _pulseAnimation.value,
              child: child,
            ),
            child: _ThumbnailsRow(
              modelUrl: widget.item.modelThumbnail,
              wardrobeUrls: widget.item.wardrobeThumbnails,
            ),
          ),
          const SizedBox(height: 20),

          // Animated progress bar
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) => LinearProgressIndicator(
              backgroundColor: AppColors.primary.withAlpha(30),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),

          // Status text
          const Text(
            'Look oluşturuluyor...',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bu işlem 30-90 saniye sürebilir',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// Success state card
class _SuccessCard extends StatelessWidget {
  final GenerationQueueItem item;

  const _SuccessCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<GenerationQueueViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Result image
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

        // Timestamp
        Text(
          DateFormat('dd MMM yyyy, HH:mm', 'tr_TR')
              .format(item.timestamp),
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.outlineVariant,
          ),
        ),
        const SizedBox(height: 20),

        // Action buttons
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              vm.hideBottomSheet();
              // Navigate to profile AI Looks tab
              // TabController navigation handled by parent
            },
            child: const Text('Profilde Görüntüle'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              vm.hideBottomSheet();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(48),
              ),
            ),
            child: const Text('Yeni Look Oluştur'),
          ),
        ),
      ],
    );
  }
}

// Error state card
class _ErrorCard extends StatelessWidget {
  final GenerationQueueItem item;

  const _ErrorCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<GenerationQueueViewModel>();

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
          const Icon(
            Iconsax.warning_2,
            size: 64,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(height: 16),
          Text(
            item.errorMessage ?? 'Bir hata oluştu',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => vm.retryFailedItem(item.id),
              child: const Text('Tekrar Dene'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
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
              ),
              child: const Text('Kapat'),
            ),
          ),
        ],
      ),
    );
  }
}

// Queue item card (queued status)
class _QueueItemCard extends StatelessWidget {
  final GenerationQueueItem item;

  const _QueueItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<GenerationQueueViewModel>();
    final isProcessing = item.status == GenerationStatus.processing;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Thumbnails
          _ThumbnailsRow(
            modelUrl: item.modelThumbnail,
            wardrobeUrls: item.wardrobeThumbnails,
            size: 40,
          ),
          const SizedBox(width: 12),

          // Status badge
          Expanded(
            child: _StatusBadge(status: item.status),
          ),

          // Cancel button (only for queued items)
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

// -----------------------------------------------------------------------------
// "Geçmiş" Tab
// -----------------------------------------------------------------------------

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<GenerationQueueViewModel>(
      builder: (context, vm, _) {
        if (vm.history.isEmpty) {
          return const EmptyStateWidget(
            icon: Iconsax.clock,
            title: 'Henüz geçmiş yok',
            description: 'Oluşturduğun looklar burada görünecek',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
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
                  child: const Icon(
                    Iconsax.trash,
                    color: Color(0xFFEF4444),
                  ),
                ),
                onDismissed: (_) => vm.removeFromHistory(item.id),
                child: _HistoryItemCard(item: item),
              ),
            );
          },
        );
      },
    );
  }
}

class _HistoryItemCard extends StatelessWidget {
  final GenerationQueueItem item;

  const _HistoryItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<GenerationQueueViewModel>();
    final isSuccess = item.status == GenerationStatus.completed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Result thumbnail or error icon
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

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusBadge(status: item.status),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM, HH:mm', 'tr_TR')
                      .format(item.timestamp),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.outlineVariant,
                  ),
                ),
              ],
            ),
          ),

          // Action button
          if (isSuccess)
            TextButton(
              onPressed: () {
                vm.expandBottomSheet();
                // TODO: scroll to result in "Şu An" tab
              },
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

// -----------------------------------------------------------------------------
// Shared helpers
// -----------------------------------------------------------------------------

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
