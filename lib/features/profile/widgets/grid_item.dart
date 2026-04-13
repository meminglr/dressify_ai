import 'package:flutter/material.dart';
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
        child: Material(
          color: Colors.transparent,
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
                
                // Tag overlay (if tag exists)
                if (media.tag != null) _buildTagOverlay(),
                
                // Hover/press overlay
                _buildHoverOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the media image with NetworkImage
  Widget _buildImage() {
    return Image.network(
      media.imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        
        return Container(
          color: const Color(0xFFF8F9FA),
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF742FE5),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFFF8F9FA),
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: Color(0xFF5A6062),
            ),
          ),
        );
      },
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
