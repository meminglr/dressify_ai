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
  late ProfileViewModel profileViewModel; // Singleton ViewModel
  late ProductSearchViewModel productSearchViewModel; // Singleton ViewModel

  @override
  void initState() {
    super.initState();
    currentPage = 0;
    tabController = TabController(length: 4, vsync: this);
    
    // Initialize ProfileViewModel
    profileViewModel = ProfileViewModel(
      profileService: ProfileService.instance(),
      mediaService: MediaService(
        SupabaseService.instance.client,
        StorageService(SupabaseService.instance.client),
      ),
      storageService: StorageService(SupabaseService.instance.client),
    );
    
    // Initialize ProductSearchViewModel
    productSearchViewModel = ProductSearchViewModel(
      trendyolService: TrendyolService(),
      savedProductService: SavedProductService(),
    );
    
    tabController.animation!.addListener(() {
      final value = tabController.animation!.value.round();
      if (value != currentPage && mounted) {
        // Tab değişince navbar'ı göster
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
    return PopScope(
      // Ana sayfadayken (tab 0) geri tuşu uygulamadan çıksın,
      // diğer tablardayken tab 0'a dönsün.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (tabController.index != 0) {
          tabController.animateTo(0);
        } else {
          // Ana sayfadayız, uygulamadan çık
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      appBar: AppBar(toolbarHeight: 0 ),
      body: BottomBar(
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
        body: (context, controller) => Stack(
          children: [
            TabBarView(
              controller: tabController,
              dragStartBehavior: DragStartBehavior.down,
              physics: const BouncingScrollPhysics(),
              children: [
                HomeScreen(controller: controller),
                ChangeNotifierProvider.value(
                  value: productSearchViewModel,
                  child: ProductSearchScreen(scrollController: controller),
                ),
                // Tab index 2: AI Look Generator — kendi scroll controller'ını kullanır
                // böylece BottomBar bu tab'da scroll'u izlemez ve gizlenmez
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
            // Global overlay: persists across all tabs
            ChangeNotifierProvider.value(
              value: GenerationQueueViewModel.instance,
              child: const GenerationBottomSheetOverlay(),
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
