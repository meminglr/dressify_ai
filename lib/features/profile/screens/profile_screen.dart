import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/profile_view_model.dart';
import '../widgets/flexible_space_bar_widget.dart';
import '../widgets/profile_tab_bar.dart';
import '../widgets/masonry_grid_view.dart';
import '../widgets/masonry_shimmer.dart';
import '../widgets/carousel_view.dart';
import '../models/media.dart';
import '../../../screens/settings/settings_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Listen to scroll changes to update AppBar state
    _nestedScrollController.addListener(_onScroll);
    
    // Load profile data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().loadProfile(widget.userId);
    });
  }

  void _onScroll() {
    // Check if the flexible space is collapsed
    final screenWidth = MediaQuery.of(context).size.width;
    const collapsedHeight = 56.0;
    final scrollOffset = _nestedScrollController.hasClients 
        ? _nestedScrollController.offset 
        : 0.0;
    
    final isNowCollapsed = scrollOffset > (screenWidth - collapsedHeight - 50);
    
    if (isNowCollapsed != _isCollapsed) {
      setState(() {
        _isCollapsed = isNowCollapsed;
      });
    }
  }

  @override
  void dispose() {
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
          // Error state - only show if critical error
          if (viewModel.isError && viewModel.profile == null) {
            return _buildErrorState(viewModel);
          }

          // Show content immediately with skeleton/shimmer for loading parts
          return _buildMainContent(viewModel);
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
            ),
            _buildTabContent(
              viewModel,
              viewModel.mediaList.where((m) => m.type == MediaType.upload).toList(),
            ),
            _buildTabContent(
              viewModel,
              viewModel.mediaList.where((m) => m.type == MediaType.model).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds content for each tab
  Widget _buildTabContent(ProfileViewModel viewModel, List<Media> mediaList) {
    // Show shimmer skeleton if media is still loading
    if (viewModel.isMediaLoading) {
      return const MasonryShimmer();
    }

    if (mediaList.isEmpty) {
      return _buildEmptyMediaState();
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
          sliver: MasonryGridView(
            mediaList: mediaList,
            onItemTap: (index) {
              _openCarousel(context, viewModel, index, mediaList);
            },
          ),
        ),
      ],
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
      expandedHeight: screenWidth, // 1:1 aspect ratio
      pinned: true,
      floating: false,
      backgroundColor: const Color(0xFFF8F9FA),
      foregroundColor: const Color(0xFF1A1D1F),
      flexibleSpace: FlexibleSpaceBar(
        title: AnimatedOpacity(
          opacity: _isCollapsed ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Text(
            viewModel.profile!.fullName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1D1F),
            ),
          ),
        ),
        centerTitle: true,
        background: FlexibleSpaceBarWidget(
          profile: viewModel.profile!,
          stats: viewModel.stats!,
        ),
        collapseMode: CollapseMode.parallax,
      ),
      actions: [
        // Settings button with dynamic color
        Semantics(
          label: 'Ayarlar',
          button: true,
          child: IconButton(
            icon: Icon(
              Icons.settings,
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
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Stats skeleton
                    Container(
                      width: 300,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
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
          icon: const Icon(Icons.settings, color: Colors.white),
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
        tabBar: ProfileTabBar(
          controller: _tabController,
          selectedIndex: _tabController.index,
          onTabSelected: (index) {
            // TabController handles the selection
          },
        ),
      ),
    );
  }

  /// Opens carousel view (Sub-task 11.5)
  void _openCarousel(
    BuildContext context,
    ProfileViewModel viewModel,
    int index,
    List<Media> mediaList,
  ) {
    final media = mediaList[index];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MediaCarouselView(
          mediaList: mediaList,
          initialIndex: index,
          heroTag: 'media_${media.id}',
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
                Icons.error_outline,
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
              Icons.photo_library_outlined,
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
}

/// Custom SliverPersistentHeaderDelegate for TabBar
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final ProfileTabBar tabBar;
  final int selectedIndex;

  _TabBarDelegate({
    required this.tabBar,
    required this.selectedIndex,
  });

  @override
  double get minExtent => 68.0; // Increased for new design

  @override
  double get maxExtent => 68.0; // Increased for new design

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return tabBar;
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return selectedIndex != oldDelegate.selectedIndex;
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
