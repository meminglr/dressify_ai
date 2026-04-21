import 'package:dressifyai/screens/home/home_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:we_slide/we_slide.dart';
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

  // WeSlideController burada yaşar — widget lifecycle'ına bağlı
  late WeSlideController _weSlideController;

  // WeSlide panel boyutları
  static const double _panelMinSize = 88.0; // Mini player yüksekliği

  @override
  void initState() {
    super.initState();
    currentPage = 0;
    tabController = TabController(length: 4, vsync: this);

    // WeSlideController'ı burada yarat ve ViewModel'e bağla
    _weSlideController = WeSlideController();
    GenerationQueueViewModel.instance.attachWeSlideController(_weSlideController);

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
    _weSlideController.dispose();
    profileViewModel.dispose();
    productSearchViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Android gesture nav bar / iOS home indicator yüksekliği
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // Mini player görünür yüksekliği + sistem padding'i
    final effectivePanelMinSize = _panelMinSize + bottomPadding;
    final panelMaxSize = screenHeight * 0.82;

    return ChangeNotifierProvider.value(
      value: GenerationQueueViewModel.instance,
      child: Consumer<GenerationQueueViewModel>(
        builder: (context, queueVm, _) {
          // Panel görünür değilse minSize = 0 (tamamen gizli)
          final panelMinSize =
              queueVm.isBottomSheetVisible ? effectivePanelMinSize : 0.0;

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              // Eğer full sheet açıksa önce minimize et
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
            child: Scaffold(
              appBar: AppBar(toolbarHeight: 0),
              body: WeSlide(
                controller: _weSlideController,
                panelMinSize: panelMinSize,
                panelMaxSize: panelMaxSize,
                panelWidth: MediaQuery.of(context).size.width,
                panelBorderRadiusBegin: 0,
                panelBorderRadiusEnd: 32,
                hidePanelHeader: true,
                hideFooter: true,
                parallax: false,
                overlay: true,
                overlayOpacity: 0.3,
                overlayColor: AppColors.onSurface,
                animateDuration: const Duration(milliseconds: 350),
                backgroundColor: AppColors.background,
                // panelHeader kullanılmıyor — her şey panel içinde yönetiliyor
                // Panel: mini player header + full sheet içeriği tek widget'ta
                panel: GenerationCombinedPanel(queueVm: queueVm),
                // Body: tab içerikleri (BottomBar kendi içinde yönetiliyor)
                body: _buildTabBody(context),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBody(BuildContext context) {
    // Android gesture nav / iOS home indicator için alt offset
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // BottomBar'ın navigation bar'dan uzaklığı: sabit 10px + sistem padding
    final barOffset = 10.0 + bottomPadding;

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
      offset: barOffset,
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
            borderSide: const BorderSide(color: AppColors.primary, width: 3),
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
