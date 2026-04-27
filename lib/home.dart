import 'package:dressifyai/screens/home/home_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:sheet/sheet.dart';
import 'core/theme/app_colors.dart';
import 'core/services/supabase_service.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/viewmodels/profile_view_model.dart';
import 'features/trendyol/screens/product_search_screen.dart';
import 'features/trendyol/viewmodels/product_search_view_model.dart';
import 'features/trendyol/services/trendyol_service.dart';
import 'features/trendyol/services/saved_product_service.dart';
import 'features/ai_look_generator/screens/selection_screen.dart';
import 'features/ai_look_generator/viewmodels/generation_queue_view_model.dart';
import 'features/ai_look_generator/widgets/generation_bottom_sheet.dart';
import 'services/profile_service.dart';
import 'services/media_service.dart';
import 'services/storage_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late int currentPage;
  late TabController tabController;
  final BottomBarController _bottomBarController = BottomBarController();
  late ProfileViewModel profileViewModel;
  late ProductSearchViewModel productSearchViewModel;

  static const double _miniPlayerHeight = 80.0;

  @override
  void initState() {
    super.initState();
    currentPage = 0;
    tabController = TabController(length: 4, vsync: this);

    profileViewModel = ProfileViewModel(
      profileService: ProfileService.instance(),
      mediaService: MediaService(
        SupabaseService.instance.client,
        StorageService(SupabaseService.instance.client),
      ),
      storageService: StorageService(SupabaseService.instance.client),
    );

    productSearchViewModel = ProductSearchViewModel(
      trendyolService: TrendyolService(),
      savedProductService: SavedProductService(),
    );

    tabController.animation!.addListener(() {
      final value = tabController.animation!.value.round();
      if (value != currentPage && mounted) {
        _bottomBarController.show();
        setState(() => currentPage = value);
      }
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    _bottomBarController.dispose();
    profileViewModel.dispose();
    productSearchViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: GenerationQueueViewModel.instance,
      child: Consumer<GenerationQueueViewModel>(
        builder: (context, queueVm, _) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              if (queueVm.isBottomSheetVisible && !queueVm.isMinimized) {
                queueVm.minimizeBottomSheet();
                return;
              }
              if (tabController.index != 0) {
                tabController.animateTo(0);
              } else {
                SystemNavigator.pop();
              }
            },
            child: Material(
              color: AppColors.background,
              child: Stack(
                children: [
                  // ── Ana içerik ───────────────────────────────────────────
                  _buildTabBody(context, queueVm),

                  // ── Queue panel (her zaman render, visibility ile kontrol) ──
                  _QueuePanel(
                    queueVm: queueVm,
                    miniPlayerHeight: _miniPlayerHeight,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBody(
      BuildContext context, GenerationQueueViewModel queueVm) {
    final existingPadding = MediaQuery.of(context).padding;
    final miniLift =
        queueVm.isBottomSheetVisible ? _miniPlayerHeight : 0.0;
    final adjustedPadding = existingPadding.copyWith(
      bottom: existingPadding.bottom + miniLift,
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(padding: adjustedPadding),
      child: BottomBar(
        controller: _bottomBarController,
        fit: StackFit.expand,
        borderRadius: BorderRadius.circular(40),
        duration: const Duration(milliseconds: 300),
        curve: Curves.decelerate,
        showIcon: false,
        width: MediaQuery.of(context).size.width * 0.8,
        barColor: AppColors.surfaceContainerLowest,
        barDecoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withAlpha(15),
              blurRadius: 48,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        start: 2,
        end: 0,
        offset: 10,
        barAlignment: Alignment.bottomCenter,
        iconHeight: 35,
        iconWidth: 35,
        reverse: false,
        hideOnScroll: true,
        scrollOpposite: false,
        onBottomBarHidden: () {},
        onBottomBarShown: () {},
        body: (context, controller) => TabBarView(
          controller: tabController,
          dragStartBehavior: DragStartBehavior.down,
          physics: const BouncingScrollPhysics(),
          children: [
            HomeScreen(controller: controller),
            ChangeNotifierProvider.value(
              value: productSearchViewModel,
              child: ProductSearchScreen(scrollController: controller),
            ),
            ChangeNotifierProvider.value(
              value: profileViewModel,
              child: SelectionScreen(tabController: tabController),
            ),
            ChangeNotifierProvider.value(
              value: profileViewModel,
              child: ProfileScreen(
                scrollController: controller,
                parentTabController: tabController,
              ),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TabBar(
            dividerColor: Colors.transparent,
            indicatorPadding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
            controller: tabController,
            indicator: UnderlineTabIndicator(
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 3),
              insets: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            ),
            tabs: [
              _buildTab(Iconsax.home, 0),
              _buildTab(Iconsax.shop, 1),
              _buildTab(Iconsax.category, 2),
              _buildTab(Iconsax.user, 3),
            ],
          ),
        ),
      ),
    );
  }

  SizedBox _buildTab(IconData icon, int index) {
    return SizedBox(
      height: 55,
      width: 40,
      child: Center(
        child: Icon(
          icon,
          color: currentPage == index
              ? AppColors.primary
              : AppColors.outlineVariant,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _QueuePanel  —  sheet paketi ile physics-based smooth panel
// ---------------------------------------------------------------------------

class _QueuePanel extends StatefulWidget {
  final GenerationQueueViewModel queueVm;
  final double miniPlayerHeight;

  const _QueuePanel({
    required this.queueVm,
    required this.miniPlayerHeight,
  });

  @override
  State<_QueuePanel> createState() => _QueuePanelState();
}

class _QueuePanelState extends State<_QueuePanel> {
  late SheetController _sheetController;

  // Snap pozisyonları (pixel) — build'de hesaplanır
  late double _miniExtent;
  late double _maxExtent;
  bool _extentsReady = false;

  // İlk görünürlük animasyonu için
  bool _hasBeenVisible = false;

  @override
  void initState() {
    super.initState();
    _sheetController = SheetController();

    // ViewModel callback'lerini bağla
    widget.queueVm.onExpandRequested = _expand;
    widget.queueVm.onMinimizeRequested = _minimize;
  }

  @override
  void dispose() {
    widget.queueVm.onExpandRequested = null;
    widget.queueVm.onMinimizeRequested = null;
    _sheetController.dispose();
    super.dispose();
  }

  void _expand() {
    if (!_extentsReady) return;
    _sheetController.animateTo(
      _maxExtent,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
    widget.queueVm.onPanelExpanded();
  }

  void _minimize() {
    if (!_extentsReady) return;
    _sheetController.animateTo(
      _miniExtent,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
    widget.queueVm.onPanelCollapsed();
  }

  void _show() {
    if (!_extentsReady || _hasBeenVisible) return;
    _hasBeenVisible = true;
    // Direkt animate et — microtask bekleme
    if (mounted && _sheetController.animation.value < 1) {
      _sheetController.animateTo(
        _miniExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _hide() {
    if (!_extentsReady) return;
    // Mini extent'ten 0'a animate et
    _sheetController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // BottomBar offset=10, mini player bottom bar'ın hemen üstünde
    const barOffset = 10.0;

    _miniExtent = widget.miniPlayerHeight + barOffset + bottomPadding;
    _maxExtent = screenHeight * 0.92;
    _extentsReady = true;

    // Visibility değişikliklerini izle
    final isVisible = widget.queueVm.isBottomSheetVisible;
    if (isVisible && !_hasBeenVisible) {
      _show();
    } else if (!isVisible && _hasBeenVisible) {
      _hide();
      _hasBeenVisible = false;
    }

    return AnimatedBuilder(
      animation: _sheetController.animation,
      builder: (context, _) {
        // Progress hesaplama
        final currentExtent = _sheetController.animation.value;
        final progress = (currentExtent / _maxExtent).clamp(0.0, 1.0);
        final isExpanded = currentExtent > _miniExtent * 1.2;

        return Stack(
          children: [
            // Backdrop (sadece expanded'da)
            if (progress > 0.15)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _minimize,
                  child: Container(
                    color: AppColors.onSurface.withAlpha(
                      (progress * 80).round(),
                    ),
                  ),
                ),
              ),

            // Sheet (her zaman render, extent 0 olunca zaten görünmez)
            Sheet(
              controller: _sheetController,
              initialExtent: 0,
              minExtent: 0,
              maxExtent: _maxExtent,
              fit: SheetFit.expand,
              physics: SnapSheetPhysics(
                stops: [0, _miniExtent, _maxExtent],
                relative: false,
                parent: BouncingSheetPhysics(
                  parent: ScrollPhysics(),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24 + 8 * progress),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.onSurface.withAlpha(
                        (20 + 20 * progress).round(),
                      ),
                      blurRadius: 16 + 16 * progress,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: GenerationCombinedPanel(
                  queueVm: widget.queueVm,
                  scrollController: null,
                  isExpanded: isExpanded,
                  onMiniTap: () {
                    HapticFeedback.lightImpact();
                    _expand();
                    widget.queueVm.expandBottomSheet();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
