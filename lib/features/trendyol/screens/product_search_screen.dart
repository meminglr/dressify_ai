import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final ScrollController? scrollController;
  
  const ProductSearchScreen({super.key, this.scrollController});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _historyAnimController;
  late Animation<double> _historyFadeAnim;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _historyAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _historyFadeAnim = CurvedAnimation(
      parent: _historyAnimController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _historyAnimController.dispose();
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
    if (_searchFocusNode.hasFocus) {
      _historyAnimController.forward();
    } else {
      _historyAnimController.reverse();
    }
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
              // Arama + Buton barı (tek SliverAppBar)
              _buildSearchBar(viewModel),
              
              // Sub-task 9.7: Arama geçmişi dropdown (animasyonlu)
              if (viewModel.searchHistory.isNotEmpty)
                _buildSearchHistorySliver(viewModel),
              
              // Sub-task 9.4 & 9.5: Ürün grid'i veya state'ler
              _buildContentSliver(viewModel),
            ],
          );
        },
      ),
    );
  }

  /// Arama çubuğu SliverAppBar
  Widget _buildSearchBar(ProductSearchViewModel viewModel) {
    final hasActiveFilters = viewModel.minPrice != null ||
        viewModel.maxPrice != null ||
        viewModel.freeShippingOnly ||
        viewModel.sortOption != SortOption.bestSeller;

    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: false,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 68,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Trendyol\'da ürün ara...',
            hintStyle: const TextStyle(
              color: AppColors.outlineVariant,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(
                Iconsax.search_normal_1,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: AppColors.outlineVariant,
                        size: 16,
                      ),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      viewModel.updateSearchQuery('');
                      setState(() {});
                    },
                  )
                : null,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: (value) {
            setState(() {});
            viewModel.updateSearchQuery(value);
          },
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              viewModel.cancelDebounceAndSearch();
              _searchFocusNode.unfocus();
            }
          },
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _showFilterBottomSheet(context, viewModel),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.filter, color: AppColors.primary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        hasActiveFilters ? 'Filtreler' : 'Filtrele',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      if (hasActiveFilters) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _getActiveFilterCount(viewModel).toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showLinkBottomSheet(context, viewModel),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.link, color: AppColors.primary, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Link ile Ekle',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sub-task 9.7: Arama geçmişi dropdown'unu ekle
  Widget _buildSearchHistorySliver(ProductSearchViewModel viewModel) {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _historyFadeAnim,
        child: SizeTransition(
          sizeFactor: _historyFadeAnim,
          axisAlignment: -1,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.onSurface.withAlpha(8),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
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
        ),
      ),
    );
  }

  int _getActiveFilterCount(ProductSearchViewModel viewModel) {
    int count = 0;
    if (viewModel.minPrice != null) count++;
    if (viewModel.maxPrice != null) count++;
    if (viewModel.freeShippingOnly) count++;
    if (viewModel.sortOption != SortOption.bestSeller) count++;
    return count;
  }

  void _showFilterBottomSheet(BuildContext context, ProductSearchViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filtreler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                if (_getActiveFilterCount(viewModel) > 0)
                  TextButton(
                    onPressed: () {
                      _minPriceController.clear();
                      _maxPriceController.clear();
                      viewModel.clearFilters();
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Temizle',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Sıralama
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Sıralama',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<SortOption>(
              value: viewModel.sortOption,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: SortOption.values.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(
                    option.label,
                    style: const TextStyle(fontSize: 15),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  viewModel.updateSortOption(value);
                }
              },
            ),
            const SizedBox(height: 24),
            
            // Fiyat aralığı
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Fiyat Aralığı',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Min',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: AppColors.outlineVariant,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (value) {
                      final minPrice = double.tryParse(value);
                      viewModel.updateFilters(minPrice: minPrice);
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '-',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.outlineVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _maxPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Max',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: AppColors.outlineVariant,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
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
            const SizedBox(height: 24),
            
            // Ücretsiz kargo
            GestureDetector(
              onTap: () {
                viewModel.updateFilters(freeShipping: !viewModel.freeShippingOnly);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: viewModel.freeShippingOnly
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: viewModel.freeShippingOnly
                        ? AppColors.primary
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      viewModel.freeShippingOnly
                          ? Iconsax.tick_circle5
                          : Iconsax.tick_circle,
                      color: viewModel.freeShippingOnly
                          ? AppColors.primary
                          : AppColors.outlineVariant,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Ücretsiz Kargo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Uygula butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (viewModel.searchQuery.isNotEmpty) {
                    viewModel.searchProducts();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Uygula',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          // Görsel 400:600 oranında + alt bilgi alanı (~110px)
          // Ekran genişliği - padding (32) - spacing (12) / 2 = kart genişliği
          mainAxisExtent: ((MediaQuery.of(context).size.width - 44) / 2) * (600 / 400) + 110,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Prefetch bitmemişse son item'da loading göster
            if (index == viewModel.products.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              );
            }
            final product = viewModel.products[index];
            return ProductCard(
              product: product,
              onTap: () {
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
          childCount: viewModel.products.length + (viewModel.isLoadingMore ? 1 : 0),
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

  /// Sub-task 9.6: Link ile Ekle bottom sheet
  void _showLinkBottomSheet(BuildContext context, ProductSearchViewModel viewModel) {
    final linkController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
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
                'Link ile Ürün Ekle',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Trendyol ürün linkini yapıştırın',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.outlineVariant,
                ),
              ),
              const SizedBox(height: 24),
              // URL input
              TextField(
                controller: linkController,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'https://www.trendyol.com/...',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: AppColors.outlineVariant,
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Iconsax.link,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: linkController,
                    builder: (_, val, __) => val.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.outlineVariant,
                              size: 18,
                            ),
                            onPressed: () => linkController.clear(),
                          )
                        : const SizedBox.shrink(),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Yapıştır butonu (küçük, pill)
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      linkController.text = data!.text!;
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.copy, color: AppColors.primary, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Panodan Yapıştır',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Ürünü Getir butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final url = linkController.text.trim();
                    if (url.isEmpty) return;
                    Navigator.pop(context);
                    final productId = viewModel.trendyolService.extractProductIdFromUrl(url);
                    if (productId != null && mounted) {
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
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Geçersiz Trendyol linki'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Ürünü Getir',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
