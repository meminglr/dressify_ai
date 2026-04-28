import 'package:cached_network_image/cached_network_image.dart';
import 'package:dressifyai/screens/home/home_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_colors.dart';
import 'core/services/supabase_service.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/viewmodels/profile_view_model.dart';
import 'features/trendyol/screens/product_search_screen.dart';
import 'features/trendyol/viewmodels/product_search_view_model.dart';
import 'features/trendyol/services/trendyol_service.dart';
import 'features/trendyol/services/saved_product_service.dart';
import 'features/ai_look_generator/screens/selection_screen.dart';
import 'features/ai_look_generator/models/generation_queue_item.dart';
import 'features/ai_look_generator/models/generation_status.dart';
import 'features/ai_look_generator/viewmodels/generation_queue_view_model.dart';
import 'features/ai_look_generator/widgets/queue_bottom_sheet.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      GenerationQueueViewModel.instance.initialize();
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

  void _openQueueSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: GenerationQueueViewModel.instance,
        child: const QueueBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ChangeNotifierProvider sadece alt widget'ların context üzerinden
    // erişebilmesi için burada. Consumer KALDIRILDI — tüm Home'u rebuild
    // ettiriyordu. FAB kendi Consumer'ını yönetiyor.
    return ChangeNotifierProvider.value(
      value: GenerationQueueViewModel.instance,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
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
              _buildTabBody(context),
              _QueueFab(
                onTap: () => _openQueueSheet(context),
                bottomBarController: _bottomBarController,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBody(BuildContext context) {
    return BottomBar(
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
      body: (context, controller) {
        return TabBarView(
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
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TabBar(
          dividerColor: Colors.transparent,
          indicatorPadding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
          controller: tabController,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(color: AppColors.primary, width: 3),
            insets: EdgeInsets.fromLTRB(16, 0, 16, 8),
          ),
          tabs: [
            _buildTab(Iconsax.home, 0),
            _buildTab(Iconsax.shop, 1),
            _buildTab(Iconsax.category, 2),
            _buildTab(Iconsax.user, 3),
          ],
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
// _QueueFab
// ---------------------------------------------------------------------------

class _QueueFab extends StatefulWidget {
  final VoidCallback onTap;
  final BottomBarController bottomBarController;

  const _QueueFab({
    required this.onTap,
    required this.bottomBarController,
  });

  @override
  State<_QueueFab> createState() => _QueueFabState();
}

class _QueueFabState extends State<_QueueFab> {
  static const _duration = Duration(milliseconds: 300);
  static const _curve = Curves.decelerate;

  bool _barVisible = true;

  @override
  void initState() {
    super.initState();
    _barVisible = widget.bottomBarController.isVisible;
    widget.bottomBarController.addListener(_onBarVisibilityChanged);
  }

  @override
  void dispose() {
    widget.bottomBarController.removeListener(_onBarVisibilityChanged);
    super.dispose();
  }

  void _onBarVisibilityChanged() {
    if (mounted) {
      setState(() => _barVisible = widget.bottomBarController.isVisible);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    const barOffset = 10.0;
    const barHeight = 71.0;
    const fabHeight = barHeight;
    final fabWidth = screenWidth * 0.8;
    const fabRadius = 50.0;
    const gap = 10.0;

    final bottomWhenVisible = bottomPadding + barOffset + barHeight + gap;
    final bottomWhenHidden = bottomPadding + gap;

    // Selector: sadece displayItem değişince rebuild — queue/history/active
    // değişimlerinin tamamı yerine sadece gösterilecek item izleniyor.
    return Selector<GenerationQueueViewModel, GenerationQueueItem?>(
      selector: (_, vm) =>
          vm.activeGeneration ??
          (vm.queue.isNotEmpty ? vm.queue.first : null) ??
          (vm.history.isNotEmpty ? vm.history.first : null),
      builder: (context, displayItem, _) {
        final fabVisible = displayItem != null;

        return AnimatedPositioned(
          duration: _duration,
          curve: _curve,
          bottom: _barVisible ? bottomWhenVisible : bottomWhenHidden,
          left: (screenWidth - fabWidth) / 2,
          child: IgnorePointer(
            ignoring: !fabVisible,
            child: AnimatedOpacity(
              duration: _duration,
              curve: Curves.easeOutCubic,
              opacity: fabVisible ? 1.0 : 0.0,
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  width: fabWidth,
                  height: fabHeight,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(fabRadius),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.onSurface.withAlpha(15),
                        blurRadius: 48,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: displayItem != null
                              ? _FabStatusContent(item: displayItem)
                              : const _FabIdleContent(),
                        ),
                        if (displayItem != null) ...[
                          const SizedBox(width: 8),
                          _FabThumbnail(item: displayItem),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// FAB içerik widget'ları
// ---------------------------------------------------------------------------

class _FabIdleContent extends StatelessWidget {
  const _FabIdleContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Look Kuyruğu',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        Text(
          'Kuyruğu görüntüle',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.outlineVariant,
          ),
        ),
      ],
    );
  }
}

class _FabStatusContent extends StatelessWidget {
  final GenerationQueueItem item;

  const _FabStatusContent({required this.item});

  @override
  Widget build(BuildContext context) {
    final (title, subtitle, color) = switch (item.status) {
      GenerationStatus.processing => (
          'Oluşturuluyor...',
          '30-90 sn sürebilir',
          AppColors.primary,
        ),
      GenerationStatus.completed => (
          'Look hazır!',
          'Görüntülemek için dokun',
          const Color(0xFF10B981),
        ),
      GenerationStatus.failed => (
          'Hata oluştu',
          'Tekrar denemek için dokun',
          const Color(0xFFEF4444),
        ),
      GenerationStatus.queued => (
          'Sırada bekliyor',
          'İşlem başlayacak',
          AppColors.outlineVariant,
        ),
    };

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 13),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.outlineVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _FabThumbnail extends StatelessWidget {
  final GenerationQueueItem item;

  const _FabThumbnail({required this.item});

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.resultImageUrl ?? item.modelThumbnail;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 42,
            height: 42,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const ColoredBox(
                color: AppColors.surfaceContainerLow,
              ),
              errorWidget: (context, url, error) => const ColoredBox(
                color: AppColors.surfaceContainerLow,
                child: Icon(
                  Iconsax.image,
                  size: 16,
                  color: AppColors.outlineVariant,
                ),
              ),
            ),
          ),
        ),
        if (item.status == GenerationStatus.processing)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ColoredBox(
                color: Colors.black.withAlpha(60),
                child: const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
