import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/media.dart';

/// MediaCarouselView - Material 3 Hero Carousel layout.
///
/// Opens as a normal page within the app (not full-screen black modal).
/// Uses app scaffold background color, with a back button in the AppBar.
/// CarouselView.weighted with Hero layout shows peek of next/prev items.
///
/// Validates Requirements 6, 15
class MediaCarouselView extends StatefulWidget {
  final List<Media> mediaList;
  final int initialIndex;
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
  late final CarouselController _controller;
  late final ValueNotifier<int> _currentIndexNotifier;

  @override
  void initState() {
    super.initState();
    _currentIndexNotifier = ValueNotifier<int>(widget.initialIndex);
    _controller = CarouselController(initialItem: widget.initialIndex);
  }

  @override
  void dispose() {
    _currentIndexNotifier.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height + MediaQuery.of(context).padding.top;
    final availableHeight = screenHeight - appBarHeight;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Geri',
        ),
        title: widget.mediaList.length > 1
            ? ValueListenableBuilder<int>(
                valueListenable: _currentIndexNotifier,
                builder: (context, currentIndex, child) {
                  return Text(
                    '${currentIndex + 1} / ${widget.mediaList.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              )
            : null,
        centerTitle: true,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification) {
            // Calculate current page when scroll ends
            final screenHeight = MediaQuery.of(context).size.height;
            final appBarHeight = AppBar().preferredSize.height + MediaQuery.of(context).padding.top;
            final availableHeight = screenHeight - appBarHeight;
            final itemHeight = availableHeight - 80;
            
            final scrollPosition = notification.metrics.pixels;
            final newIndex = (scrollPosition / itemHeight).round();
            
            if (newIndex != _currentIndexNotifier.value && newIndex >= 0 && newIndex < widget.mediaList.length) {
              _currentIndexNotifier.value = newIndex;
            }
          }
          return false;
        },
        child: CarouselView(
          controller: _controller,
          scrollDirection: Axis.vertical,
          itemSnapping: true,
          // Main item size (slightly smaller to show peek)
          itemExtent: availableHeight - 80, // Leave space for peek
          // Shrink amount for non-focused items (creates peek effect)
          shrinkExtent: availableHeight - 120, // Smaller = more visible peek
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: List.generate(widget.mediaList.length, (index) {
            final media = widget.mediaList[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: _buildMediaItem(media, index == widget.initialIndex),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMediaItem(Media media, bool isHeroItem) {
    final image = CachedNetworkImage(
      imageUrl: media.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      fadeInDuration: Duration.zero, // No fade-in animation
      fadeOutDuration: Duration.zero, // No fade-out animation
      placeholderFadeInDuration: Duration.zero, // No placeholder fade
      // Remove placeholder completely for instant display
      errorWidget: (context, url, error) => Container(
        color: const Color(0xFFEEEEEE),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined, size: 48, color: Colors.black26),
              SizedBox(height: 8),
              Text(
                'Görsel yüklenemedi',
                style: TextStyle(color: Colors.black38, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
      memCacheHeight: 1200, // Optimize for carousel full-screen size
      maxHeightDiskCache: 1200,
    );

    if (isHeroItem) {
      return Hero(
        tag: widget.heroTag,
        // Disable default Hero overlay/scrim
        createRectTween: (begin, end) {
          return RectTween(begin: begin, end: end);
        },
        // Use Material to ensure smooth transition
        child: Material(
          color: Colors.transparent,
          type: MaterialType.transparency,
          child: image,
        ),
        flightShuttleBuilder: (
          BuildContext flightContext,
          Animation<double> animation,
          HeroFlightDirection flightDirection,
          BuildContext fromHeroContext,
          BuildContext toHeroContext,
        ) {
          // Use the cached image during flight for smooth animation
          return Material(
            color: Colors.transparent,
            type: MaterialType.transparency,
            child: CachedNetworkImage(
              imageUrl: media.imageUrl,
              fit: BoxFit.cover,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              memCacheHeight: 1200,
            ),
          );
        },
      );
    }
    return image;
  }
}
