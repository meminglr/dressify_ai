import 'package:flutter/material.dart';
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
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = CarouselController(initialItem: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            ? Text(
                '${_currentIndex + 1} / ${widget.mediaList.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
        centerTitle: true,
      ),
      body: CarouselView.weighted(
        controller: _controller,
        scrollDirection: Axis.vertical,
        flexWeights: const [1, 7, 1],
        itemSnapping: true,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        onTap: (index) => setState(() => _currentIndex = index),
        children: List.generate(widget.mediaList.length, (index) {
          final media = widget.mediaList[index];
          return _buildMediaItem(media, index == widget.initialIndex);
        }),
      ),
    );
  }

  Widget _buildMediaItem(Media media, bool isHeroItem) {
    final image = Image.network(
      media.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFFEEEEEE),
          child: Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
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
    );

    if (isHeroItem) {
      return Hero(tag: widget.heroTag, child: image);
    }
    return image;
  }
}
