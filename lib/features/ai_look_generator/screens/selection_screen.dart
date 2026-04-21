import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../profile/models/media.dart';
import '../../profile/viewmodels/profile_view_model.dart';
import '../viewmodels/generation_queue_view_model.dart';
import '../viewmodels/selection_view_model.dart';
import '../widgets/model_carousel.dart';
import '../widgets/selection_counter_badge.dart';
import '../widgets/wardrobe_grid.dart';

/// Main selection screen for the AI Look Generator feature.
///
/// Uses a [CustomScrollView] with slivers for a rich scroll experience:
/// - SliverAppBar: collapsing app bar with "Oluştur" action
/// - Step 1 header: pinned — stays visible while carousel scrolls away
/// - Model carousel: scrolls out of view
/// - Step 2 header: pinned — stays visible while wardrobe grid scrolls
/// - Wardrobe grid: SliverGrid for native sliver performance
class SelectionScreen extends StatefulWidget {
  /// Home widget'ındaki TabController — tab navigasyonu için gerekli.
  final TabController? tabController;

  const SelectionScreen({super.key, this.tabController});

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  @override
  void initState() {
    super.initState();
    
    // Load profile data if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final profileViewModel = context.read<ProfileViewModel>();
      
      // Only load if mediaList is empty (not loaded yet)
      if (profileViewModel.mediaList.isEmpty && !profileViewModel.isMediaLoading) {
        profileViewModel.loadProfile(null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SelectionViewModel(
        profileViewModel: context.read<ProfileViewModel>(),
        queueViewModel: GenerationQueueViewModel.instance,
      ),
      child: const _SelectionScreenBody(),
    );
  }
}

class _SelectionScreenBody extends StatefulWidget {
  const _SelectionScreenBody();

  @override
  State<_SelectionScreenBody> createState() => _SelectionScreenBodyState();
}

class _SelectionScreenBodyState extends State<_SelectionScreenBody> {
  // Access tabController from ancestor SelectionScreen
  TabController? get _tabController =>
      context.findAncestorWidgetOfExactType<SelectionScreen>()?.tabController;

  @override
  Widget build(BuildContext context) {
    // Only watch SelectionViewModel for button state
    final selectionViewModel = context.watch<SelectionViewModel>();
    
    // Read ProfileViewModel once (don't watch to avoid rebuilds)
    final profileViewModel = context.read<ProfileViewModel>();

    final screenWidth = MediaQuery.of(context).size.width;
    const horizontalPadding = 24.0 * 2;
    const crossAxisSpacing = 12.0;
    const mainAxisSpacing = 12.0;
    const itemHeight = 163.0;
    final itemWidth = (screenWidth - horizontalPadding - crossAxisSpacing) / 2;
    final childAspectRatio = itemWidth / itemHeight;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            pinned: true,
            title: const Text(
              'AI Look Oluştur',
              style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w800),
            ),
            centerTitle: false,
            actions: [
              _AppBarGenerateButton(selectionViewModel: selectionViewModel),
              const SizedBox(width: 8),
            ],
          ),

          // ── STEP 1 header — pinned ────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _StepHeaderDelegate(
              step: 'STEP 1',
              title: 'Model Seç',
              backgroundColor: AppColors.background,
              trailing: _ModelHeaderTrailing(
                selectionViewModel: selectionViewModel,
                onAddTap: () => profileViewModel.uploadModelPhoto(context),
              ),
            ),
          ),

          // ── Model carousel ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ValueListenableBuilder<List<Media>>(
                valueListenable: profileViewModel.modelsListenable,
                builder: (context, models, _) {
                  return RepaintBoundary(
                    child: ModelCarousel(
                      models: models,
                      selectedModelId: selectionViewModel.selectedModelId,
                      onModelSelected: selectionViewModel.toggleModel,
                      isLoading: profileViewModel.isMediaLoading &&
                          profileViewModel.mediaList.isEmpty,
                      onAddModelTap: () => profileViewModel.uploadModelPhoto(context),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── STEP 2 header — pinned ────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _StepHeaderDelegate(
              step: 'STEP 2',
              title: 'Kıyafet Seç',
              backgroundColor: AppColors.background,
              trailing: _WardrobeHeaderTrailing(
                selectionViewModel: selectionViewModel,
                onAddTap: () => _showAddWardrobeOptions(context),
              ),
            ),
          ),

          // ── Wardrobe grid ─────────────────────────────────────────────
          ValueListenableBuilder<List<Media>>(
            valueListenable: profileViewModel.wardrobeListenable,
            builder: (context, wardrobeItems, _) {
              final isLoading = profileViewModel.isMediaLoading && 
                                profileViewModel.mediaList.isEmpty;
              
              if (isLoading) {
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => _ShimmerCard(),
                      childCount: 6,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: crossAxisSpacing,
                      mainAxisSpacing: mainAxisSpacing,
                      childAspectRatio: childAspectRatio,
                    ),
                  ),
                );
              }
              
              if (wardrobeItems.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: WardrobeGrid(
                      wardrobe: const [],
                      selectedIds: selectionViewModel.selectedWardrobeIds,
                      onItemToggled: (_) {},
                      isLoading: false,
                      onUploadPhotoTap: () =>
                          profileViewModel.uploadGardiropPhoto(context),
                      onBrowseTrendyolTap: () => _navigateToTrendyolTab(context),
                    ),
                  ),
                );
              }
              
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = wardrobeItems[index];
                      final isSelected =
                          selectionViewModel.selectedWardrobeIds.contains(item.id);
                      return RepaintBoundary(
                        child: _WardrobeItemTile(
                          item: item,
                          isSelected: isSelected,
                          index: index,
                          onTap: () {
                            final success =
                                selectionViewModel.toggleWardrobeItem(item.id);
                            if (!success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Maksimum 5 kıyafet seçebilirsiniz'),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                    childCount: wardrobeItems.length,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: crossAxisSpacing,
                    mainAxisSpacing: mainAxisSpacing,
                    childAspectRatio: childAspectRatio,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _navigateToTrendyolTab(BuildContext context) {
    _tabController?.animateTo(1); // Trendyol tab
  }

  void _showAddWardrobeOptions(BuildContext context) {
    final profileViewModel = context.read<ProfileViewModel>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Kıyafet Ekle',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _OptionButton(
                    icon: Iconsax.gallery_add,
                    label: 'Fotoğraf Yükle',
                    onTap: () {
                      Navigator.of(context).pop();
                      profileViewModel.uploadGardiropPhoto(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OptionButton(
                    icon: Iconsax.shop,
                    label: "Trendyol'da Ara",
                    onTap: () {
                      Navigator.of(context).pop();
                      _navigateToTrendyolTab(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Pinned Step Header Delegate
// =============================================================================

/// [SliverPersistentHeaderDelegate] for the "STEP X / Title" section headers.
///
/// Stays pinned at the top while the content below scrolls. Optionally renders
/// a [trailing] widget on the right side (e.g. counter badge + add button).
class _StepHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String step;
  final String title;
  final Color backgroundColor;
  final Widget? trailing;

  static const double _expandedHeight = 88.0;
  static const double _collapsedHeight = 64.0;

  const _StepHeaderDelegate({
    required this.step,
    required this.title,
    required this.backgroundColor,
    this.trailing,
  });

  @override
  double get minExtent => _collapsedHeight;

  @override
  double get maxExtent => _expandedHeight;

  @override
  bool shouldRebuild(_StepHeaderDelegate old) =>
      old.step != step ||
      old.title != title ||
      old.trailing != trailing ||
      old.backgroundColor != backgroundColor;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // 0.0 = fully expanded, 1.0 = fully collapsed
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    // Title font size interpolates from 28 → 18
    final titleSize = lerpDouble(28.0, 18.0, t)!;

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Step label always visible
                  Text(
                    step,
                    style: TextStyle(
                      fontFamily: 'Liberation Serif',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.outlineVariant,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                      letterSpacing: -0.75,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Flexible(
                flex: 2,
                child: trailing!,
              ),
          ],
        ),
      ),
    );
  }
}

double? lerpDouble(double a, double b, double t) => a + (b - a) * t;

// =============================================================================
// Model header trailing (badge + add button)
// =============================================================================

class _ModelHeaderTrailing extends StatelessWidget {
  final SelectionViewModel selectionViewModel;
  final VoidCallback onAddTap;

  const _ModelHeaderTrailing({
    required this.selectionViewModel,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectionViewModel.selectedModelId != null;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NewItemIconButton(onTap: onAddTap),
        const SizedBox(width: 8),
        _ModelSelectionBadge(isSelected: hasSelection),
      ],
    );
  }
}

// =============================================================================
// Wardrobe header trailing (badge + add button)
// =============================================================================

class _WardrobeHeaderTrailing extends StatelessWidget {
  final SelectionViewModel selectionViewModel;
  final VoidCallback onAddTap;

  const _WardrobeHeaderTrailing({
    required this.selectionViewModel,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NewItemIconButton(onTap: onAddTap),
        const SizedBox(width: 8),
        SelectionCounterBadge(
          selectedCount: selectionViewModel.selectedCount,
        ),
      ],
    );
  }
}

// =============================================================================
// AppBar Generate Button
// =============================================================================

class _AppBarGenerateButton extends StatefulWidget {
  final SelectionViewModel selectionViewModel;

  const _AppBarGenerateButton({required this.selectionViewModel});

  @override
  State<_AppBarGenerateButton> createState() => _AppBarGenerateButtonState();
}

class _AppBarGenerateButtonState extends State<_AppBarGenerateButton> {
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onTap(BuildContext context) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 1), () async {
      final success = await widget.selectionViewModel.generateLook();
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen 1 model ve en az 1 kıyafet seçin'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.selectionViewModel,
      builder: (context, _) {
        final canGenerate = widget.selectionViewModel.canGenerate;
        return Semantics(
          label: 'Look oluştur',
          button: true,
          enabled: canGenerate,
          child: AnimatedOpacity(
            opacity: canGenerate ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: canGenerate ? () => _onTap(context) : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.magic_star,
                        size: 16, color: AppColors.onPrimary),
                    const SizedBox(width: 6),
                    Text(
                      'Oluştur',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// Wardrobe item tile (inline — avoids double-grid nesting)
// =============================================================================

class _WardrobeItemTile extends StatelessWidget {
  final Media item;
  final bool isSelected;
  final int index;
  final VoidCallback onTap;

  const _WardrobeItemTile({
    required this.item,
    required this.isSelected,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: AppColors.primary, width: 2.5)
                : null,
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24 - (isSelected ? 2.5 : 0)),
            child: Container(
              color: AppColors.surfaceContainerLow,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Iconsax.image,
                        color: AppColors.outlineVariant,
                        size: 32,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: AnimatedScale(
                      scale: isSelected ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      child: isSelected
                          ? Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Iconsax.tick_circle,
                                  color: AppColors.onPrimary, size: 16),
                            )
                          : Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(204),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Iconsax.add,
                                  color: AppColors.primary, size: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}

// =============================================================================
// Shared small widgets
// =============================================================================

class _ModelSelectionBadge extends StatelessWidget {
  final bool isSelected;

  const _ModelSelectionBadge({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    // Same green color as wardrobe badge
    const bgColor = Color(0xFFD1FAE5);
    const textColor = Color(0xFF3D6151);

    return Semantics(
      liveRegion: true,
      label: isSelected ? '1 model seçildi' : 'Model seçilmedi',
      child: AnimatedOpacity(
        opacity: isSelected ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            isSelected ? '1 SEÇİLDİ' : '0 SEÇİLDİ',
            style: const TextStyle(
              fontFamily: 'Liberation Serif',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _NewItemIconButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NewItemIconButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Yeni kıyafet ekle',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Iconsax.add,
            size: 16,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
