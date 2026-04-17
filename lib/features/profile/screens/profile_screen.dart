import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../viewmodels/profile_view_model.dart';
import '../widgets/flexible_space_bar_widget.dart';
import '../widgets/profile_tab_bar.dart';
import '../widgets/masonry_grid_view.dart';
import '../widgets/masonry_shimmer.dart';
import '../widgets/carousel_view.dart';
import '../models/media.dart';
import '../../../screens/settings/settings_screen.dart';
import '../../trendyol/screens/product_detail_screen.dart';
import '../../trendyol/viewmodels/product_detail_view_model.dart';
import '../../trendyol/services/trendyol_service.dart';
import '../../trendyol/services/saved_product_service.dart';

/// ProfileScreen displays the user profile page with all features.
///
/// This screen implements:
/// - CustomScrollView with Slivers architecture
/// - SliverAppBar with FlexibleSpaceBar (expandedHeight: 480px)
/// - SliverPersistentHeader with TabBar (pinned)
/// - PrimaryActionButton for "Yeni Üret"
/// - MasonryGridView for media items
/// - Loading, error, and empty states
/// - Pull-to-refresh support
/// - Accessibility support
///
/// ## Usage:
/// ```dart
/// ChangeNotifierProvider(
///   create: (_) => ProfileViewModel(),
///   child: ProfileScreen(userId: 'user_123'),
/// )
/// ```
///
/// Validates Requirements 1, 2, 4, 5, 6, 7, 11, 12, 13, 16, 17, 18
class ProfileScreen extends StatefulWidget {
  /// User ID to display profile for (null = current user)
  final String? userId;
  
  /// Scroll controller for bottom bar integration
  final ScrollController? scrollController;

  /// Parent tab controller for navigation bar integration
  final TabController? parentTabController;

  const ProfileScreen({
    super.key,
    this.userId,
    this.scrollController,
    this.parentTabController,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _nestedScrollController = ScrollController();
  bool _isCollapsed = false;
  late ProfileViewModel _viewModel;
  bool _viewModelListenerAttached = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Listen to scroll changes to update AppBar state
    _nestedScrollController.addListener(_onScroll);
    
    // Load profile data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _viewModel = context.read<ProfileViewModel>();
      _viewModel.loadProfile(widget.userId);
      if (!_viewModelListenerAttached) {
        _viewModel.addListener(_onViewModelChanged);
        _viewModelListenerAttached = true;
      }
    });
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    final viewModel = context.read<ProfileViewModel>();

    // Show success SnackBar
    if (viewModel.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.successMessage!),
          backgroundColor: const Color(0xFF742FE5),
          behavior: SnackBarBehavior.floating,
        ),
      );
      viewModel.clearSuccessMessage();
    }

    // Show error SnackBar (non-critical errors only)
    if (viewModel.isError && viewModel.profile != null && viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Tamam',
            textColor: Colors.white,
            onPressed: () => viewModel.clearError(),
          ),
        ),
      );
    }
  }

  void _onScroll() {
    final screenWidth = MediaQuery.of(context).size.width;
    const collapsedHeight = 56.0;
    final scrollOffset = _nestedScrollController.hasClients
        ? _nestedScrollController.offset
        : 0.0;

    final maxScroll = screenWidth - collapsedHeight;
    final isNowCollapsed = scrollOffset > (maxScroll - 50);

    // Only rebuild when collapse state changes (not on every scroll pixel)
    if (isNowCollapsed != _isCollapsed) {
      setState(() {
        _isCollapsed = isNowCollapsed;
      });
    }
  }

  @override
  void dispose() {
    if (_viewModelListenerAttached) {
      _viewModel.removeListener(_onViewModelChanged);
    }
    _tabController.dispose();
    _nestedScrollController.removeListener(_onScroll);
    _nestedScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Consumer<ProfileViewModel>(
        builder: (context, viewModel, child) {
          return Stack(
            children: [
              // Main content
              () {
                if (viewModel.isError && viewModel.profile == null) {
                  return _buildErrorState(viewModel);
                }
                return _buildMainContent(viewModel);
              }(),
              // Upload loading overlay
              if (viewModel.isUploading)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AbsorbPointer(
                    absorbing: false, // allow scrolling, just show progress
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LinearProgressIndicator(
                          backgroundColor: const Color(0xFF742FE5).withAlpha(40),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF742FE5),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          color: const Color(0xFF742FE5).withAlpha(230),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Fotoğraf yükleniyor...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Builds the main content with NestedScrollView and TabBarView
  Widget _buildMainContent(ProfileViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: () => viewModel.refreshProfile(),
      color: const Color(0xFF742FE5),
      child: NestedScrollView(
        controller: _nestedScrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // SliverAppBar with FlexibleSpaceBar
            _buildSliverAppBar(viewModel),
            
            // TabBar as SliverPersistentHeader
            _buildTabBarHeader(viewModel),
          ];
        },
        body: _ProfileTabBarViewWithEdgeSwipe(
          tabController: _tabController,
          parentTabController: widget.parentTabController,
          children: [
            _buildTabContent(
              viewModel,
              viewModel.mediaList.where((m) => m.type == MediaType.aiLook).toList(),
              0,
              viewModel.aiLooksListenable,
            ),
            _buildTabContent(
              viewModel,
              viewModel.mediaList.where((m) => 
                m.type == MediaType.upload || m.type == MediaType.trendyolProduct
              ).toList(),
              1,
              viewModel.wardrobeListenable,
            ),
            _buildTabContent(
              viewModel,
              viewModel.mediaList.where((m) => m.type == MediaType.model).toList(),
              2,
              viewModel.modelsListenable,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds content for each tab
  Widget _buildTabContent(ProfileViewModel viewModel, List<Media> mediaList, int tabIndex, ValueListenable<List<Media>> mediaListenable) {
    // Show shimmer only during initial load (list is empty AND loading)
    if (viewModel.isMediaLoading && viewModel.mediaList.isEmpty) {
      return const MasonryShimmer();
    }

    // Still loading but we already have data — show existing data
    if (mediaList.isEmpty) {
      if (tabIndex == 1 || tabIndex == 2) {
        return _buildEmptyStateWithUpload(tabIndex);
      }
      return _buildEmptyMediaState();
    }

    final showUploadButton = tabIndex == 1 || tabIndex == 2;

    return CustomScrollView(
      slivers: [
        if (showUploadButton)
          SliverToBoxAdapter(
            child: _buildInlineUploadButton(tabIndex),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: MasonryGridView(
            mediaList: mediaList,
            onItemTap: (index) {
              _openCarousel(context, viewModel, index, mediaList, mediaListenable);
            },
          ),
        ),
      ],
    );
  }

  /// Inline upload button shown above the grid
  Widget _buildInlineUploadButton(int tabIndex) {
    final isGardirop = tabIndex == 1;
    final label = isGardirop ? 'Kıyafet Ekle' : 'Model Ekle';
    final icon = isGardirop ? Iconsax.gallery_add : Iconsax.camera;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Semantics(
        label: '$label butonu',
        button: true,
        hint: 'Fotoğraf yüklemek için dokunun',
        child: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () {
              final viewModel = context.read<ProfileViewModel>();
              if (tabIndex == 1) {
                viewModel.uploadGardiropPhoto(context);
              } else {
                viewModel.uploadModelPhoto(context);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF742FE5).withAlpha(20),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: const Color(0xFF742FE5), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF742FE5),
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

  /// Builds SliverAppBar with FlexibleSpaceBar (Sub-task 11.2)
  Widget _buildSliverAppBar(ProfileViewModel viewModel) {
    // Show skeleton if profile is loading
    if (viewModel.isProfileLoading || viewModel.profile == null) {
      return _buildSkeletonAppBar();
    }

    // 1:1 aspect ratio - height equals screen width
    final screenWidth = MediaQuery.of(context).size.width;

    return SliverAppBar(
      expandedHeight: screenWidth,
      pinned: true,
      floating: false,
      centerTitle: true,
      backgroundColor: const Color(0xFFF8F9FA),
      foregroundColor: const Color(0xFF1A1D1F),
      // This title shows only when collapsed, always centered
      title: _isCollapsed
          ? Text(
              viewModel.profile!.fullName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1D1F),
              ),
            )
          : null,
      flexibleSpace: FlexibleSpaceBar(
        background: FlexibleSpaceBarWidget(
          profile: viewModel.profile!,
        ),
        collapseMode: CollapseMode.parallax,
      ),
      actions: [
        // Camera/edit icon for avatar
        Semantics(
          label: 'Profil fotoğrafını düzenle',
          button: true,
          child: IconButton(
            icon: Icon(
              Iconsax.camera,
              color: _isCollapsed ? const Color(0xFF1A1D1F) : Colors.white,
            ),
            onPressed: () => viewModel.uploadAvatarPhoto(context),
            tooltip: 'Profil fotoğrafını değiştir',
          ),
        ),
        // Settings button with dynamic color
        Semantics(
          label: 'Ayarlar',
          button: true,
          child: IconButton(
            icon: Icon(
              Iconsax.setting_2,
              color: _isCollapsed ? const Color(0xFF1A1D1F) : Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            tooltip: 'Ayarlar',
          ),
        ),
      ],
    );
  }

  /// Builds skeleton AppBar while profile is loading
  Widget _buildSkeletonAppBar() {
    // 1:1 aspect ratio - height equals screen width
    final screenWidth = MediaQuery.of(context).size.width;
    
    return SliverAppBar(
      expandedHeight: screenWidth, // 1:1 aspect ratio
      pinned: true,
      floating: false,
      backgroundColor: const Color(0xFFF8F9FA),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFE0E0E0),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: Stack(
            children: [
              // Shimmer effect for the entire background
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFE0E0E0),
                          const Color(0xFFF5F5F5),
                          const Color(0xFFE0E0E0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              // Skeleton elements at the bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 60,
                child: Column(
                  children: [
                    // Name skeleton
                    Container(
                      width: 200,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Stats skeleton
                    Container(
                      width: 300,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Iconsax.camera, color: Colors.white),
          onPressed: null, // disabled while loading
        ),
        IconButton(
          icon: const Icon(Iconsax.setting_2, color: Colors.white),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Builds TabBar as SliverPersistentHeader (Sub-task 11.3)
  Widget _buildTabBarHeader(ProfileViewModel viewModel) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        selectedIndex: _tabController.index,
        aiLooksCount: viewModel.aiLooksCount,
        wardrobeCount: viewModel.wardrobeCount,
        modelsCount: viewModel.modelsCount,
        tabBar: ProfileTabBar(
          controller: _tabController,
          selectedIndex: _tabController.index,
          onTabSelected: (index) {},
          aiLooksCount: viewModel.aiLooksCount,
          uploadsCount: viewModel.wardrobeCount,
          modelsCount: viewModel.modelsCount,
        ),
      ),
    );
  }

  /// Opens carousel view or product detail (Sub-task 11.5)
  void _openCarousel(
    BuildContext context,
    ProfileViewModel viewModel,
    int index,
    List<Media> mediaList,
    ValueListenable<List<Media>> mediaListenable,
  ) {
    final media = mediaList[index];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MediaCarouselView(
          mediaListenable: mediaListenable,
          initialIndex: index,
          heroTag: 'media_${media.id}',
          onTrendyolTap: (productId) async {
            final removed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider(
                  create: (_) => ProductDetailViewModel(
                    trendyolService: TrendyolService(),
                    savedProductService: SavedProductService(),
                  ),
                  child: ProductDetailScreen(
                    productId: productId,
                    fromWardrobe: true,
                  ),
                ),
              ),
            );
            if (removed == true && context.mounted) {
              context
                  .read<ProfileViewModel>()
                  .removeTrendyolProductFromList(productId);
            }
            return removed == true;
          },
          onRemoveTrendyolProduct: (productId) async {
            if (context.mounted) {
              context.read<ProfileViewModel>().removeTrendyolProduct(productId);
            }
          },
          onDeleteMedia: (mediaId) async {
            if (context.mounted) {
              await context.read<ProfileViewModel>().deleteMedia(mediaId);
            }
          },
        ),
      ),
    );
  }

  /// Builds error state (Sub-task 11.6)
  Widget _buildErrorState(ProfileViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              label: 'Hata ikonu',
              child: const Icon(
                Iconsax.warning_2,
                size: 64,
                color: Color(0xFFE53935),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: 'Hata mesajı: ${viewModel.errorMessage}',
              child: Text(
                viewModel.errorMessage ?? 'Bir hata oluştu',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF5A6062),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              label: 'Tekrar dene butonu',
              button: true,
              hint: 'Profili yeniden yüklemek için dokunun',
              child: ElevatedButton(
                onPressed: () {
                  viewModel.clearError();
                  viewModel.loadProfile(widget.userId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF742FE5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('Tekrar Dene'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds empty media state (Sub-task 11.6)
  Widget _buildEmptyMediaState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(
            label: 'Henüz içerik yok ikonu',
            child: const Icon(
              Iconsax.gallery,
              size: 64,
              color: Color(0xFF5A6062),
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            label: 'Henüz içerik yok mesajı',
            child: const Text(
              'Henüz içerik yok',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF5A6062),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'İçerik ekleme önerisi',
            child: const Text(
              'İlk AI görünümünüzü oluşturmak için ana sayfaya gidin',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF5A6062),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds empty state with upload button for Gardırop and Modellerim tabs
  Widget _buildEmptyStateWithUpload(int tabIndex) {
    final isGardirop = tabIndex == 1;
    final title = isGardirop ? 'Gardırop Boş' : 'Model Eklenmemiş';
    final description = isGardirop
        ? 'Kıyafet fotoğrafları ekleyerek gardırobunuzu oluşturun'
        : 'Vücut fotoğrafınızı ekleyerek modelinizi oluşturun';
    final buttonText = isGardirop ? 'Kıyafet Ekle' : 'Model Ekle';
    final icon = isGardirop ? Iconsax.bag_2 : Iconsax.profile_circle;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              label: 'Boş durum ikonu',
              child: Icon(
                icon,
                size: 80,
                color: const Color(0xFF742FE5).withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              label: title,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1D1F),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              label: description,
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5A6062),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Semantics(
              label: '$buttonText butonu',
              button: true,
              hint: 'Fotoğraf yüklemek için dokunun',
              child: GestureDetector(
                onTap: () {
                  final viewModel = context.read<ProfileViewModel>();
                  if (tabIndex == 1) {
                    viewModel.uploadGardiropPhoto(context);
                  } else {
                    viewModel.uploadModelPhoto(context);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF742FE5).withAlpha(20),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGardirop ? Iconsax.gallery_add : Iconsax.camera,
                        color: const Color(0xFF742FE5),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        buttonText,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF742FE5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom SliverPersistentHeaderDelegate for TabBar
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final ProfileTabBar tabBar;
  final int selectedIndex;
  final int aiLooksCount;
  final int wardrobeCount;
  final int modelsCount;

  _TabBarDelegate({
    required this.tabBar,
    required this.selectedIndex,
    required this.aiLooksCount,
    required this.wardrobeCount,
    required this.modelsCount,
  });

  @override
  double get minExtent => 68.0;

  @override
  double get maxExtent => 68.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return tabBar;
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) {
    return selectedIndex != oldDelegate.selectedIndex ||
        aiLooksCount != oldDelegate.aiLooksCount ||
        wardrobeCount != oldDelegate.wardrobeCount ||
        modelsCount != oldDelegate.modelsCount;
  }
}

/// TabBarView with smart edge swipe:
/// - On "AI Görünümler" tab (index 0) + right swipe → delegates to parent (navigation bar)
/// - Otherwise → normal tab swipe with real-time animation
class _ProfileTabBarViewWithEdgeSwipe extends StatefulWidget {
  final TabController tabController;
  final TabController? parentTabController;
  final List<Widget> children;

  const _ProfileTabBarViewWithEdgeSwipe({
    required this.tabController,
    required this.children,
    this.parentTabController,
  });

  @override
  State<_ProfileTabBarViewWithEdgeSwipe> createState() =>
      _ProfileTabBarViewWithEdgeSwipeState();
}

class _ProfileTabBarViewWithEdgeSwipeState
    extends State<_ProfileTabBarViewWithEdgeSwipe> {
  bool _navigationTriggered = false;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Reset flag when drag starts
        if (notification is ScrollStartNotification) {
          _navigationTriggered = false;
        }

        // When on first tab and overscrolling right → trigger parent navigation once
        if (notification is OverscrollNotification &&
            notification.metrics.axis == Axis.horizontal &&
            widget.tabController.index == 0 &&
            notification.overscroll < 0 &&
            widget.parentTabController != null &&
            !_navigationTriggered) {
          _navigationTriggered = true;
          final newIndex = widget.parentTabController!.index - 1;
          if (newIndex >= 0) {
            widget.parentTabController!.animateTo(newIndex);
          }
          return true;
        }
        return false;
      },
      child: TabBarView(
        controller: widget.tabController,
        physics: _EdgeAwareTabPhysics(
          tabController: widget.tabController,
          parent: const BouncingScrollPhysics(),
        ),
        children: widget.children,
      ),
    );
  }
}

/// Custom ScrollPhysics: allows all tab swipes with real-time animation,
/// but on the first tab blocks the right-side boundary so the
/// OverscrollNotification fires and the parent can handle it.
class _EdgeAwareTabPhysics extends ScrollPhysics {
  final TabController tabController;

  const _EdgeAwareTabPhysics({
    required this.tabController,
    super.parent,
  });

  @override
  _EdgeAwareTabPhysics applyTo(ScrollPhysics? ancestor) {
    return _EdgeAwareTabPhysics(
      tabController: tabController,
      parent: buildParent(ancestor),
    );
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // On first tab, block scrolling past the left edge (right swipe)
    // This causes an OverscrollNotification which the parent can catch
    if (tabController.index == 0 && value < position.minScrollExtent) {
      return value - position.minScrollExtent;
    }
    return super.applyBoundaryConditions(position, value);
  }
}
