import 'package:dressifyai/screens/home/home_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
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

  // PanelController burada yaşar — widget lifecycle'ına bağlı
  final PanelController _panelController = PanelController();

  // SlidingUpPanel panel boyutları
  static const double _panelMinSize = 88.0; // Mini player yüksekliği

  @override
  void initState() {
    super.initState();
    currentPage = 0;
    tabController = TabController(length: 4, vsync: this);

    // PanelController'ı ViewModel'e bağla
    GenerationQueueViewModel.instance.attachPanelController(_panelController);

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
        setState(() {
          currentPage = value;
        });
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
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final panelMaxSize = screenHeight * 0.82;

    return ChangeNotifierProvider.value(
      value: GenerationQueueViewModel.instance,
      child: Consumer<GenerationQueueViewModel>(
        builder: (context, queueVm, _) {
          final panelMinHeight = queueVm.isBottomSheetVisible
              ? _panelMinSize + bottomPadding
              : 0.0;

          // BottomBar'ı mini player yüksekliği kadar yukarı itmek için
          // sadece içerik yüksekliğini (88px) kullanıyoruz.
          // bottomPadding _buildTabBody içinde barOffset'e ekleniyor.
          final barBottomLift =
              queueVm.isBottomSheetVisible ? _panelMinSize : 0.0;

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
            // Material: Scaffold dışına çıkınca kaybolan text decoration,
            // ink splash ve animasyon context'ini geri sağlar.
            child: Material(
              color: AppColors.background,
              child: SlidingUpPanel(
                controller: _panelController,
                minHeight: panelMinHeight,
                maxHeight: panelMaxSize,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                backdropEnabled: true,
                backdropOpacity: 0.3,
                backdropColor: AppColors.onSurface,
                backdropTapClosesPanel: true,
                color: AppColors.surfaceContainerLowest,
                boxShadow: const [],
                isDraggable: true,
                renderPanelSheet: false,
                onPanelClosed: () {
                  if (!queueVm.isMinimized) queueVm.onPanelCollapsed();
                },
                onPanelOpened: () {
                  if (queueVm.isMinimized) queueVm.onPanelExpanded();
                },
                panelBuilder: (scrollController) => GenerationCombinedPanel(
                  queueVm: queueVm,
                  scrollController: scrollController,
                ),
                // body: Scaffold burada — kendi SafeArea/padding'ini yönetir
                body: Scaffold(
                  backgroundColor: AppColors.background,
                  body: _buildTabBody(context, barBottomLift),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBody(BuildContext context, double barBottomLift) {
    // SlidingUpPanel artık Scaffold'un dışında olduğu için BottomBar'ın
    // SafeArea'sı gerçek bottomPadding'i görür.
    // barBottomLift: mini player görünürken 88px, yoksa 0.
    // MediaQuery.padding.bottom'ı SafeArea zaten kapsıyor,
    // biz sadece mini player için ek lift ekliyoruz.
    final existingPadding = MediaQuery.of(context).padding;
    final adjustedPadding = existingPadding.copyWith(
      bottom: existingPadding.bottom + barBottomLift,
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
