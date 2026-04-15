import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
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
/// - Reviews list
/// - "Gardıroba Ekle" button
/// - Loading and error states
/// 
/// Validates Requirements: 8, 9, 10, 11, 16, 17, 27, 29
class ProductDetailScreen extends StatefulWidget {
  final Product? product;
  final String? productId;

  const ProductDetailScreen({
    super.key,
    this.product,
    this.productId,
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
      
      // If product is provided, set it directly and only load reviews
      if (widget.product != null) {
        _viewModel.setProduct(widget.product!);
        _viewModel.loadReviews(widget.product!.id);
      } else if (widget.productId != null) {
        // Fallback: Load product with reviews from API
        _viewModel.loadProductWithReviews(widget.productId!);
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

    // Show success SnackBar
    if (_viewModel.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.successMessage!),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _viewModel.clearSuccess();
    }

    // Show error SnackBar
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
            
            // Reviews section
            _buildReviewsSection(viewModel),
            
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
            
            // Seller info
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.shop,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Satıcı',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.outlineVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.seller,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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

  /// Builds reviews section (Sub-task 11.5)
  Widget _buildReviewsSection(ProductDetailViewModel viewModel) {
    return SliverToBoxAdapter(
      child: Container(
        color: AppColors.surfaceContainerLowest,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reviews header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Değerlendirmeler',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (viewModel.hasReviews)
                  Text(
                    '${viewModel.reviews.length} yorum',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.outlineVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Reviews list or loading/empty state
            if (viewModel.isLoadingReviews)
              const _ReviewsLoadingSkeleton()
            else if (viewModel.hasReviews)
              ...viewModel.reviews.map((review) => _ReviewItem(review: review))
            else
              const _EmptyReviewsWidget(),
          ],
        ),
      ),
    );
  }

  /// Builds "Gardıroba Ekle" button (Sub-task 11.4)
  Widget _buildSaveButton(ProductDetailViewModel viewModel) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 20,
      child: SafeArea(
        child: ElevatedButton(
          onPressed: viewModel.isSaving
              ? null
              : () {
                  if (viewModel.isProductSaved) {
                    viewModel.removeFromWardrobe();
                  } else {
                    viewModel.saveToWardrobe();
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: viewModel.isProductSaved
                ? AppColors.secondaryContainer
                : AppColors.primary,
            foregroundColor: viewModel.isProductSaved
                ? AppColors.secondary
                : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            elevation: 4,
          ),
          child: viewModel.isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      viewModel.isProductSaved
                          ? Iconsax.tick_circle5
                          : Iconsax.bag_2,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      viewModel.isProductSaved
                          ? 'Gardıroptan Çıkar'
                          : 'Gardıroba Ekle',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
                viewModel.loadProductWithReviews(id);
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

// Private widgets for better performance and reusability

/// Review item widget - extracted for better performance
class _ReviewItem extends StatelessWidget {
  final Review review;

  const _ReviewItem({required this.review});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'tr_TR');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User name and rating
          Row(
            children: [
              Expanded(
                child: Text(
                  review.userName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating.floor()
                        ? Iconsax.star5
                        : Iconsax.star,
                    size: 12,
                    color: const Color(0xFFFFA500),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Comment text
          Text(
            review.comment,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.onSurface.withAlpha(179),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          
          // Date
          Text(
            dateFormat.format(review.createdAt),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reviews loading skeleton widget
class _ReviewsLoadingSkeleton extends StatelessWidget {
  const _ReviewsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User name skeleton
              Container(
                width: 120,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              
              // Comment skeleton
              Container(
                width: double.infinity,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              
              // Date skeleton
              Container(
                width: 80,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Empty reviews widget
class _EmptyReviewsWidget extends StatelessWidget {
  const _EmptyReviewsWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: const Column(
        children: [
          Icon(
            Iconsax.message_text,
            size: 48,
            color: AppColors.outlineVariant,
          ),
          SizedBox(height: 16),
          Text(
            'Henüz değerlendirme yok',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}
