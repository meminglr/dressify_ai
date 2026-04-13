import 'package:flutter/material.dart';
import '../models/media.dart';

/// MediaCarouselView widget for displaying media items in a full-screen vertical carousel.
///
/// This widget provides a full-screen modal experience with vertical scrolling,
/// hero animation support, swipe-to-dismiss gesture, and a close button.
///
/// ## Features:
/// - Full-screen black background (#000000)
/// - Vertical PageView for scrolling through media
/// - Hero animation from GridItem
/// - Swipe down to dismiss (150px threshold)
/// - Close button (top-right corner)
/// - Page indicator (bottom center, hidden for single item)
/// - Image fit: contain (shows full image)
///
/// ## Usage Example:
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute(
///     builder: (_) => MediaCarouselView(
///       mediaList: mediaItems,
///       initialIndex: tappedIndex,
///       heroTag: 'media_${mediaItems[tappedIndex].id}',
///     ),
///   ),
/// );
/// ```
///
/// Validates Requirements 6, 15
class MediaCarouselView extends StatefulWidget {
  /// List of media items to display in the carousel
  final List<Media> mediaList;

  /// Initial index to start the carousel from
  final int initialIndex;

  /// Hero tag for hero animation (should match the GridItem's hero tag)
  final String heroTag;

  const MediaCarouselView({
    super.key,
    required this.mediaList,
    required this.initialIndex,
    required this.heroTag,
  });

  @override
  State<MediaCarouselView> createState() => _MediaCarouselViewState();
}

class _MediaCarouselViewState extends State<MediaCarouselView> {
  late PageController _pageController;
  late int _currentIndex;
  double _dragDistance = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Stack(
          children: [
            // PageView with vertical scroll
            _buildPageView(),
            
            // Close button
            _buildCloseButton(),
            
            // Page indicator
            _buildPageIndicator(),
            
            // Drag indicator (optional visual feedback)
            if (_isDragging) _buildDragIndicator(),
          ],
        ),
      ),
    );
  }

  /// Builds the vertical PageView with media items
  Widget _buildPageView() {
    return AnimatedOpacity(
      opacity: _isDragging ? 1.0 - (_dragDistance.abs() / 300).clamp(0.0, 0.5) : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Transform.translate(
        offset: Offset(0, _dragDistance),
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: widget.mediaList.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final media = widget.mediaList[index];
            final isInitialPage = index == widget.initialIndex;
            
            return _buildMediaPage(media, isInitialPage);
          },
        ),
      ),
    );
  }

  /// Builds a single media page with hero animation support
  Widget _buildMediaPage(Media media, bool isInitialPage) {
    final imageWidget = Image.network(
      media.imageUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 64,
            color: Colors.white54,
          ),
        );
      },
    );

    // Use Hero animation only for the initial page
    if (isInitialPage) {
      return Center(
        child: Hero(
          tag: widget.heroTag,
          child: imageWidget,
        ),
      );
    }

    return Center(child: imageWidget);
  }

  /// Builds the close button in the top-right corner
  Widget _buildCloseButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(
            Icons.close,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
          tooltip: 'Close',
        ),
      ),
    );
  }

  /// Builds a visual indicator for drag-to-dismiss
  Widget _buildDragIndicator() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Swipe down to close',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a page indicator showing current position
  Widget _buildPageIndicator() {
    if (widget.mediaList.length <= 1) return const SizedBox.shrink();
    
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 24,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${_currentIndex + 1} / ${widget.mediaList.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// Handles the start of a vertical drag gesture
  void _onVerticalDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragDistance = 0.0;
    });
  }

  /// Handles updates during a vertical drag gesture
  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragDistance += details.delta.dy;
      
      // Only allow downward drag (positive delta)
      if (_dragDistance < 0) {
        _dragDistance = 0;
      }
    });
  }

  /// Handles the end of a vertical drag gesture
  void _onVerticalDragEnd(DragEndDetails details) {
    const dismissThreshold = 150.0;
    
    if (_dragDistance > dismissThreshold) {
      // Dismiss the carousel
      Navigator.of(context).pop();
    } else {
      // Reset the drag
      setState(() {
        _isDragging = false;
        _dragDistance = 0.0;
      });
    }
  }
}
