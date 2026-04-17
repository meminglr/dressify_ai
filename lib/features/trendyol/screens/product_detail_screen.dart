import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import '../viewmodels/product_detail_view_model.dart';
import '../models/models.dart';
import '../../../core/theme/app_colors.dart';

/// ProductDetailScreen - Ürün detay sayfası
/// 
/// Features:
/// - CustomScrollView with Sliver architecture
/// - Hero animation from ProductCard
/// - CarouselView for product images
/// - Product information display
/// - "Gardıroba Ekle" button
/// - Loading and error states
/// 
/// Validates Requirements: 8, 9, 10, 11, 16, 17, 27, 29
class ProductDetailScreen extends StatefulWidget {
  final Product? product;
  final String? productId;
  /// Gardıroptan açıldıysa true - çıkarılınca pop(true) döner
  final bool fromWardrobe;

  const ProductDetailScreen({
    super.key,
    this.product,
    this.productId,
    this.fromWardrobe = false,
  }) : assert(product != null || productId != null,
           'Either product or productId must be provided');

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late ProductDetailViewModel _viewModel;
  bool _viewModelListenerAttached = false;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _viewModel = context.read<ProductDetailViewModel>();
      
      // If product is provided, set it directly
      if (widget.product != null) {
        _viewModel.setProduct(widget.product!);
      } else if (widget.productId != null) {
        // Gardıroptan açılıyorsa önce saved_products'tan yükle, API'ye gitme
        _viewModel.loadFromSavedProduct(widget.productId!);
      }
      
      // Listen to ViewModel changes
      if (!_viewModelListenerAttached) {
        _viewModel.addListener(_onViewModelChanged);
        _viewModelListenerAttached = true;
      }
    });
  }

  void _onViewModelChanged() {
    if (!mounted) return;

    // Gardıroptan açıldıysa ve ürün çıkarıldıysa geri dön
    if (widget.fromWardrobe && _viewModel.wasRemovedFromWardrobe) {
      Navigator.of(context).pop(true);
      return;
    }

    // Başarı snackbar'ı kaldırıldı - buton durumu zaten gösteriyor
    if (_viewModel.successMessage != null) {
      _viewModel.clearSuccess();
    }

    // Sadece hata durumunda snackbar göster
    if (_viewModel.errorMessage != null && _viewModel.product != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Tamam',
            textColor: Colors.white,
            onPressed: () => _viewModel.clearError(),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    if (_viewModelListenerAttached) {
      _viewModel.removeListener(_onViewModelChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: Consumer<ProductDetailViewModel>(
        builder: (context, viewModel, child) {
          // Error state (no product loaded)
          if (viewModel.errorMessage != null && viewModel.product == null) {
            return _buildErrorState(viewModel);
          }

          // Loading state (initial load)
          if (viewModel.isLoading && viewModel.product == null) {
            return _buildLoadingState();
          }

          // Main content
          if (viewModel.product != null) {
            return _buildMainContent(viewModel);
          }

          // Fallback
          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Builds the main content with product details
  Widget _buildMainContent(ProductDetailViewModel viewModel) {
    final product = viewModel.product!;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // Back button AppBar (pinned, no image)
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.surfaceContainerLowest,
              foregroundColor: AppColors.onSurface,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Iconsax.arrow_left_2),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Iconsax.share),
                  onPressed: () {},
                ),
              ],
            ),

            // Hero + CarouselView.weighted (400:600 oran, 1:7:1 ağırlık)
            SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  // Ortadaki item genişliği: toplam 9 birim, 7 birim orta
                  // padding 8px her iki yanda
                  final mainItemWidth = screenWidth * 7 / 9;
                  final itemHeight = mainItemWidth * 600 / 400;

                  return SizedBox(
                    height: itemHeight,
                    child: CarouselView.weighted(
                      flexWeights: const [7, 1],
                      itemSnapping: true,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      children: product.images.isEmpty
                          ? [
                              Container(
                                color: AppColors.surfaceContainerLow,
                                child: const Center(
                                  child: Icon(
                                    Iconsax.image,
                                    color: AppColors.outlineVariant,
                                    size: 48,
                                  ),
                                ),
                              ),
                            ]
                          : product.images.asMap().entries.map((entry) {
                              final url = entry.value;
                              final isFirstImage = entry.key == 0;
                              return ClipRRect(
                                child: CachedNetworkImage(
                                  imageUrl: url,
                                  // İlk görsel için ProductCard'daki cache key'i kullan
                                  // → network isteği olmadan cache'den gelir
                                  cacheKey: isFirstImage
                                      ? 'product_${product.id}_thumb'
                                      : 'product_${product.id}_img_${entry.key}',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  // Bellek optimizasyonu için boyut sınırı
                                  memCacheWidth: 800,
                                  memCacheHeight: 1200,
                                  placeholder: (_, __) => Container(
                                    color: AppColors.surfaceContainerLow,
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    color: AppColors.surfaceContainerLow,
                                    child: const Center(
                                      child: Icon(
                                        Iconsax.image,
                                        color: AppColors.outlineVariant,
                                        size: 48,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                    ),
                  );
                },
              ),
            ),
            
            // Product info section
            _buildProductInfoSection(product),
            
            // Bottom padding for FAB
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
        
        // "Gardıroba Ekle" button
        _buildSaveButton(viewModel),
      ],
    );
  }

  /// Builds product information section (Sub-task 11.3)
  Widget _buildProductInfoSection(Product product) {
    return SliverToBoxAdapter(
      child: Container(
        color: AppColors.surfaceContainerLowest,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand
            Text(
              product.brand,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.outlineVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            
            // Product name
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 20,
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            
            // Rating and review count
            if (product.rating > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < product.rating.floor()
                            ? Iconsax.star5
                            : Iconsax.star,
                        size: 16,
                        color: const Color(0xFFFFA500),
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      product.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${product.reviewCount} değerlendirme)',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.outlineVariant,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Price section
            Row(
              children: [
                // Current price
                Text(
                  '${product.price.toStringAsFixed(2)} ${product.currency}',
                  style: const TextStyle(
                    fontSize: 24,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                
                // Original price and discount
                if (product.discountPct > 0) ...[
                  const SizedBox(width: 12),
                  Text(
                    '${product.originalPrice.toStringAsFixed(0)} ${product.currency}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.outlineVariant,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '-%${product.discountPct}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            
            // Badges
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (product.freeShipping)
                  _buildBadge('Ücretsiz Kargo', Iconsax.truck_fast),
                if (product.hasGift)
                  _buildBadge('Hediye', Iconsax.gift),
                if (product.cargoDays != null)
                  _buildBadge(
                    '${product.cargoDays} gün içinde kargo',
                    Iconsax.clock,
                  ),
              ],
            ),
            
            // Description
            if (product.description.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Ürün Açıklaması',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                product.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.outlineVariant,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds a badge widget
  Widget _buildBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds "Gardıroba Ekle" / "Gardıroptan Çıkar" button
  Widget _buildSaveButton(ProductDetailViewModel viewModel) {
    final isSaved = viewModel.isProductSaved;
    // isLoading: kayıt durumu DB'den kontrol edilirken buton disabled
    final isBusy = viewModel.isSaving || viewModel.isLoading;

    final color = isSaved ? const Color(0xFFE53935) : AppColors.primary;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 20,
      child: SafeArea(
        child: Align(
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: isBusy ? color.withAlpha(160) : color,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(60),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(50),
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: isBusy
                    ? null
                    : () {
                        if (isSaved) {
                          viewModel.removeFromWardrobe();
                        } else {
                          viewModel.saveToWardrobe();
                        }
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: isBusy
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            key: ValueKey(isSaved),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSaved
                                    ? Iconsax.minus_cirlce
                                    : Iconsax.bag_2,
                                size: 20,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isSaved
                                    ? 'Gardıroptan Çıkar'
                                    : 'Gardıroba Ekle',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds loading state (Sub-task 11.6)
  Widget _buildLoadingState() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return CustomScrollView(
      slivers: [
        // Skeleton AppBar
        SliverAppBar(
          expandedHeight: screenWidth,
          pinned: true,
          backgroundColor: AppColors.surfaceContainerLowest,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: AppColors.surfaceContainerLow,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
        
        // Skeleton content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand skeleton
                Container(
                  width: 100,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Name skeleton
                Container(
                  width: double.infinity,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Price skeleton
                Container(
                  width: 150,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Builds error state (Sub-task 11.6)
  Widget _buildErrorState(ProductDetailViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Iconsax.warning_2,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              viewModel.errorMessage ?? 'Ürün yüklenemedi',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.outlineVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                viewModel.clearError();
                final id = widget.product?.id ?? widget.productId!;
                viewModel.loadProductDetail(id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
