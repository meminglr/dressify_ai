import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../models/models.dart';
import '../../../core/theme/app_colors.dart';

/// ProductCard - Reusable product card widget
/// 
/// Features:
/// - Hero animation for smooth transition to detail screen
/// - CachedNetworkImage for performance optimization
/// - Displays product name, brand, price, rating
/// - Shows discount badge if applicable
/// - Shows free shipping badge if applicable
/// - Responsive layout with proper styling
/// - Handles image loading errors gracefully
/// 
/// Validates Requirements: 4, 20, 27
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withAlpha(5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Hero animation
            Expanded(
              child: _buildProductImage(),
            ),
            
            // Product info
            _buildProductInfo(),
          ],
        ),
      ),
    );
  }

  /// Builds the product image with Hero animation and caching
  Widget _buildProductImage() {
    return Stack(
      children: [
        // Hero wrapped image
        Hero(
          tag: 'product_${product.id}',
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: product.images.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: product.images.first,
                    cacheKey: 'product_${product.id}_thumb',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    // Memory optimization
                    memCacheWidth: 400,
                    memCacheHeight: 400,
                    // Placeholder while loading
                    placeholder: (context, url) => Container(
                      color: AppColors.surfaceContainerLow,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    // Error widget
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.surfaceContainerLow,
                      child: const Center(
                        child: Icon(
                          Iconsax.image,
                          color: AppColors.outlineVariant,
                          size: 32,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: AppColors.surfaceContainerLow,
                    child: const Center(
                      child: Icon(
                        Iconsax.image,
                        color: AppColors.outlineVariant,
                        size: 32,
                      ),
                    ),
                  ),
          ),
        ),
        
        // Discount badge (top-left)
        if (product.discountPct > 0)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
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
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Builds the product information section
  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand name
          Text(
            product.brand,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.outlineVariant,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          
          // Product name
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.onSurface,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          
          // Rating (if available)
          if (product.rating > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.star5,
                    size: 12,
                    color: Color(0xFFFFA500),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    product.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${product.reviewCount})',
                    style: const TextStyle(
                      fontSize: 10,
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
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              
              // Original price (if discounted)
              if (product.discountPct > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '${product.originalPrice.toStringAsFixed(0)} ${product.currency}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.outlineVariant,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
          
          // Free shipping badge
          if (product.freeShipping) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Ücretsiz Kargo',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
