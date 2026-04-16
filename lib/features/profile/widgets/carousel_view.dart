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

  /// Trendyol ürününe tıklanınca çağrılır (productId ile)
  /// true dönerse CarouselView de kapanır (ürün gardıroptan çıkarıldı)
  final Future<bool> Function(String productId)? onTrendyolTap;

  const MediaCarouselView({
    super.key,
    required this.mediaList,
    required this.initialIndex,
    required this.heroTag,
    this.onTrendyolTap,
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

  bool _isTrendyolItem(int index) {
    final media = widget.mediaList[index];
    return media.type == MediaType.trendyolProduct && media.tag != null;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    const kToolbarHeight = 56.0; // standard AppBar height
    final availableHeight = screenHeight - kToolbarHeight - topPadding;

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
        // Trendyol ürünü gösteriliyorsa AppBar'da "Ürünü Gör" butonu
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: _currentIndexNotifier,
            builder: (context, currentIndex, child) {
              if (!_isTrendyolItem(currentIndex)) return const SizedBox.shrink();
              final productId = widget.mediaList[currentIndex].tag!;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: () async {
                    if (widget.onTrendyolTap != null) {
                      final removed = await widget.onTrendyolTap!(productId);
                      if (removed && context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    }
                  },
                  icon: const Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: Color(0xFFF27A1A),
                  ),
                  label: const Text(
                    'Ürünü Gör',
                    style: TextStyle(
                      color: Color(0xFFF27A1A),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF27A1A).withAlpha(20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            final sh = MediaQuery.of(context).size.height;
            final tp = MediaQuery.of(context).padding.top;
            const th = 56.0;
            final itemHeight = sh - th - tp - 80;
            if (itemHeight <= 0) return false;
            // Kaydırma ortasını geçince index güncelle (0.5 threshold)
            final newIndex = ((notification.metrics.pixels + itemHeight * 0.5) / itemHeight)
                .floor()
                .clamp(0, widget.mediaList.length - 1);
            if (newIndex != _currentIndexNotifier.value) {
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
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
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
      memCacheHeight: 1200,
      maxHeightDiskCache: 1200,
    );

    if (isHeroItem) {
      return Hero(
        tag: widget.heroTag,
        createRectTween: (begin, end) => RectTween(begin: begin, end: end),
        child: Material(
          color: Colors.transparent,
          type: MaterialType.transparency,
          child: image,
        ),
        flightShuttleBuilder: (_, __, ___, ____, _____) {
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
