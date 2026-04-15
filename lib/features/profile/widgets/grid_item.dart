import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/media.dart';

/// GridItem widget for displaying media items in the masonry grid layout.
///
/// This widget displays a media image with optional tag overlay, ripple effect,
/// hero animation support, and performance optimization via RepaintBoundary.
///
/// Validates Requirements 5, 8, 15
class GridItem extends StatelessWidget {
  /// The media item to display
  final Media media;

  /// Callback when the item is tapped
  final VoidCallback onTap;

  /// Unique hero tag for hero animation
  final String heroTag;

  const GridItem({
    super.key,
    required this.media,
    required this.onTap,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary improves scroll performance by isolating repaints
    return RepaintBoundary(
      child: Hero(
        tag: heroTag,
        // Disable default Hero overlay/scrim for clean transition
        createRectTween: (begin, end) {
          return RectTween(begin: begin, end: end);
        },
        child: Material(
          color: Colors.transparent,
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Media image
                _buildImage(),
                
                // Trendyol badge (top-right corner)
                if (media.type == MediaType.trendyolProduct)
                  _buildTrendyolBadge(),
                
                // Tag overlay (if tag exists and not Trendyol product)
                if (media.tag != null && media.type != MediaType.trendyolProduct) 
                  _buildTagOverlay(),
                
                // Hover/press overlay
                _buildHoverOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the media image with CachedNetworkImage for better performance
  Widget _buildImage() {
    return CachedNetworkImage(
      imageUrl: media.imageUrl,
      fit: BoxFit.cover,
      fadeInDuration: Duration.zero, // No fade animation for instant display
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      // No placeholder - instant display from cache or network
      errorWidget: (context, url, error) => Container(
        color: const Color(0xFFF8F9FA),
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: Color(0xFF5A6062),
          ),
        ),
      ),
      memCacheWidth: 400, // Optimize memory usage
      maxWidthDiskCache: 400, // Optimize disk cache
    );
  }

  /// Builds the tag overlay with blur effect
  Widget _buildTagOverlay() {
    return Positioned(
      left: 8,
      bottom: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0x4D000000), // rgba(0,0,0,0.3)
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          media.tag!,
          style: const TextStyle(
            fontFamily: 'Be Vietnam Pro',
            fontWeight: FontWeight.w700, // Bold
            fontSize: 8,
            letterSpacing: 0.8,
            color: Colors.white,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  /// Builds Trendyol badge for product items
  Widget _buildTrendyolBadge() {
    return Positioned(
      top: 6,
      right: 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF27A1A), // Trendyol orange
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          'T',
          style: TextStyle(
            fontFamily: 'Be Vietnam Pro',
            fontWeight: FontWeight.w700,
            fontSize: 10,
            color: Colors.white,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  /// Builds the hover/press overlay effect
  Widget _buildHoverOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
