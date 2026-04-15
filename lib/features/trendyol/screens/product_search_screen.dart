import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../viewmodels/product_search_view_model.dart';
import '../viewmodels/product_detail_view_model.dart';
import '../models/models.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';
import '../../../core/theme/app_colors.dart';

/// ProductSearchScreen - Trendyol ürün arama sayfası
/// 
/// Bu sayfa şunları içerir:
/// - SliverAppBar ile arama çubuğu (floating, snap)
/// - Filtre ve sıralama UI'ı
/// - 2 sütunlu ürün grid'i
/// - Pagination desteği
/// - Loading, error ve empty state'ler
/// - "Link ile Ekle" butonu
/// - Arama geçmişi dropdown'u
/// 
/// Validates Requirements: 1, 2, 3, 4, 5, 6, 7, 13, 14, 15, 17, 18
class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSearchHistory = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Pagination: Load more when 80% scrolled
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      context.read<ProductSearchViewModel>().loadMoreProducts();
    }
  }

  void _onSearchFocusChanged() {
    setState(() {
      _showSearchHistory = _searchFocusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<ProductSearchViewModel>(
        builder: (context, viewModel, child) {
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Sub-task 9.2: SliverAppBar ve arama çubuğu
              _buildSliverAppBar(viewModel),
              
              // Sub-task 9.7: Arama geçmişi dropdown
              if (_showSearchHistory && viewModel.searchHistory.isNotEmpty)
                _buildSearchHistorySliver(viewModel),
              
              // Sub-task 9.3: Filtre ve sıralama UI
              _buildFiltersSliver(viewModel),
              
              // Sub-task 9.4 & 9.5: Ürün grid'i veya state'ler
              _buildContentSliver(viewModel),
            ],
          );
        },
      ),
      // Sub-task 9.6: "Link ile Ekle" butonu
      floatingActionButton: _buildLinkFAB(),
    );
  }

  /// Sub-task 9.2: SliverAppBar ve arama çubuğunu implement et
  Widget _buildSliverAppBar(ProductSearchViewModel viewModel) {
    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: false,
      backgroundColor: AppColors.surfaceContainerLowest,
      elevation: 0,
      expandedHeight: 80,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 8),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Ürün ara...',
              hintStyle: TextStyle(
                color: AppColors.outlineVariant,
                fontSize: 15,
              ),
              prefixIcon: const Icon(
                Iconsax.search_normal_1,
                color: AppColors.primary,
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AppColors.outlineVariant,
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        viewModel.updateSearchQuery('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              setState(() {}); // Update suffix icon
              viewModel.updateSearchQuery(value);
            },
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                viewModel.searchProducts();
                _searchFocusNode.unfocus();
              }
            },
          ),
        ),
      ),
    );
  }

  /// Sub-task 9.7: Arama geçmişi dropdown'unu ekle
  Widget _buildSearchHistorySliver(ProductSearchViewModel viewModel) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Son Aramalar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () => viewModel.clearSearchHistory(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Temizle',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...viewModel.searchHistory.map((query) {
              return InkWell(
                onTap: () {
                  _searchController.text = query;
                  viewModel.searchFromHistory(query);
                  _searchFocusNode.unfocus();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.clock,
                        size: 16,
                        color: AppColors.outlineVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          query,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      const Icon(
                        Iconsax.arrow_up_3,
                        size: 16,
                        color: AppColors.outlineVariant,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Sub-task 9.3: Filtre ve sıralama UI'ını implement et
  Widget _buildFiltersSliver(ProductSearchViewModel viewModel) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sıralama dropdown
            Row(
              children: [
                const Icon(
                  Iconsax.sort,
                  size: 18,
                  color: AppColors.onSurface,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<SortOption>(
                    value: viewModel.sortOption,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: SortOption.values.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(
                          option.label,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        viewModel.updateSortOption(value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Fiyat filtreleri
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Min Fiyat',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: AppColors.outlineVariant,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (value) {
                      final minPrice = double.tryParse(value);
                      viewModel.updateFilters(minPrice: minPrice);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Max Fiyat',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: AppColors.outlineVariant,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (value) {
                      final maxPrice = double.tryParse(value);
                      viewModel.updateFilters(maxPrice: maxPrice);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Ücretsiz kargo checkbox
            Row(
              children: [
                Checkbox(
                  value: viewModel.freeShippingOnly,
                  onChanged: (value) {
                    viewModel.updateFilters(freeShipping: value ?? false);
                  },
                  activeColor: AppColors.primary,
                ),
                const Text(
                  'Ücretsiz Kargo',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurface,
                  ),
                ),
                const Spacer(),
                
                // Filtreleri temizle butonu
                if (viewModel.minPrice != null ||
                    viewModel.maxPrice != null ||
                    viewModel.freeShippingOnly)
                  TextButton(
                    onPressed: () {
                      _minPriceController.clear();
                      _maxPriceController.clear();
                      viewModel.clearFilters();
                    },
                    child: const Text(
                      'Temizle',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Sub-task 9.4 & 9.5: Ürün grid'ini ve state'leri implement et
  Widget _buildContentSliver(ProductSearchViewModel viewModel) {
    // Sub-task 9.5: Loading state
    if (viewModel.isLoading && viewModel.products.isEmpty) {
      return _buildLoadingSliver();
    }

    // Sub-task 9.5: Error state
    if (viewModel.errorMessage != null && viewModel.products.isEmpty) {
      return _buildErrorSliver(viewModel);
    }

    // Sub-task 9.5: Empty state
    if (!viewModel.hasSearched) {
      return _buildEmptyStateSliver(
        icon: Iconsax.search_normal,
        title: 'Ürün Ara',
        message: 'Yukarıdaki arama çubuğunu kullanarak\nTrendyol\'da ürün arayabilirsiniz',
      );
    }

    if (viewModel.products.isEmpty && viewModel.hasSearched) {
      return _buildEmptyStateSliver(
        icon: Iconsax.box,
        title: 'Ürün Bulunamadı',
        message: 'Farklı arama terimleri veya\nfiltreler deneyebilirsiniz',
      );
    }

    // Sub-task 9.4: Ürün grid'i
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Show loading indicator at the end if loading more
            if (index == viewModel.products.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              );
            }

            final product = viewModel.products[index];
            return ProductCard(
              product: product,
              onTap: () {
                // Navigate to ProductDetailScreen with product object
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider(
                      create: (_) => ProductDetailViewModel(
                        trendyolService: context.read<ProductSearchViewModel>().trendyolService,
                        savedProductService: context.read<ProductSearchViewModel>().savedProductService,
                      ),
                      child: ProductDetailScreen(product: product),
                    ),
                  ),
                );
              },
            );
          },
          childCount: viewModel.products.length +
              (viewModel.isLoadingMore ? 1 : 0),
        ),
      ),
    );
  }

  /// Sub-task 9.5: Loading state (shimmer/skeleton)
  Widget _buildLoadingSliver() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
            );
          },
          childCount: 6,
        ),
      ),
    );
  }

  /// Sub-task 9.5: Error state
  Widget _buildErrorSliver(ProductSearchViewModel viewModel) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Iconsax.warning_2,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                viewModel.errorMessage ?? 'Bir hata oluştu',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  viewModel.clearError();
                  if (viewModel.searchQuery.isNotEmpty) {
                    viewModel.searchProducts();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sub-task 9.5: Empty state
  Widget _buildEmptyStateSliver({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 80,
                color: AppColors.outlineVariant,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.outlineVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sub-task 9.6: "Link ile Ekle" butonu
  Widget _buildLinkFAB() {
    return FloatingActionButton.extended(
      onPressed: () async {
        final viewModel = context.read<ProductSearchViewModel>();
        final productId = await viewModel.parseProductLinkFromClipboard();
        
        if (productId != null && mounted) {
          // Navigate to ProductDetailScreen with productId
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider(
                create: (_) => ProductDetailViewModel(
                  trendyolService: viewModel.trendyolService,
                  savedProductService: viewModel.savedProductService,
                ),
                child: ProductDetailScreen(productId: productId),
              ),
            ),
          );
        } else if (viewModel.errorMessage != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(viewModel.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Iconsax.link),
      label: const Text('Link ile Ekle'),
    );
  }
}
