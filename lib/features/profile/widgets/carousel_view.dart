import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:share_plus/share_plus.dart';
import '../models/media.dart';

/// MediaCarouselView - Material 3 Hero Carousel layout.
///
/// mediaListenable ile ProfileViewModel'deki listeyi reaktif olarak dinler.
/// Sil/çıkar işlemleri sonrası carousel otomatik güncellenir.
///
/// Validates Requirements 6, 15
class MediaCarouselView extends StatefulWidget {
  /// Reaktif medya listesi — ProfileViewModel'den ValueListenable olarak gelir
  final ValueListenable<List<Media>> mediaListenable;
  final int initialIndex;
  final String heroTag;

  final Future<bool> Function(String productId)? onTrendyolTap;
  final Future<void> Function(String mediaId)? onDeleteMedia;
  final Future<void> Function(String productId)? onRemoveTrendyolProduct;

  const MediaCarouselView({
    super.key,
    required this.mediaListenable,
    required this.initialIndex,
    required this.heroTag,
    this.onTrendyolTap,
    this.onDeleteMedia,
    this.onRemoveTrendyolProduct,
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
    widget.mediaListenable.addListener(_onMediaListChanged);
  }

  @override
  void dispose() {
    widget.mediaListenable.removeListener(_onMediaListChanged);
    _currentIndexNotifier.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Liste değişince index'i sınırla (silinen öğe sonrası taşma önlenir)
  void _onMediaListChanged() {
    final list = widget.mediaListenable.value;
    if (list.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final clamped = _currentIndexNotifier.value.clamp(0, list.length - 1);
    if (clamped != _currentIndexNotifier.value) {
      _currentIndexNotifier.value = clamped;
    }
  }

  bool _isTrendyolItem(List<Media> list, int index) {
    if (index >= list.length) return false;
    final media = list[index];
    return media.type == MediaType.trendyolProduct && media.tag != null;
  }

  bool _isUserUpload(List<Media> list, int index) {
    if (index >= list.length) return false;
    final type = list[index].type;
    return type == MediaType.upload || type == MediaType.model;
  }

  Future<void> _shareImage(String imageUrl) async {
    await SharePlus.instance.share(ShareParams(uri: Uri.parse(imageUrl)));
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    const kToolbarHeight = 56.0;
    final availableHeight = screenHeight - kToolbarHeight - topPadding;

    return ValueListenableBuilder<List<Media>>(
      valueListenable: widget.mediaListenable,
      builder: (context, mediaList, child) {
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
            title: mediaList.length > 1
                ? ValueListenableBuilder<int>(
                    valueListenable: _currentIndexNotifier,
                    builder: (context, currentIndex, child) {
                      return Text(
                        '${currentIndex + 1} / ${mediaList.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  )
                : null,
            centerTitle: true,
            actions: [
              ValueListenableBuilder<int>(
                valueListenable: _currentIndexNotifier,
                builder: (context, currentIndex, child) {
                  final isTrendyol = _isTrendyolItem(mediaList, currentIndex);
                  final isUpload = _isUserUpload(mediaList, currentIndex);
                  if (currentIndex >= mediaList.length) {
                    return const SizedBox.shrink();
                  }
                  final media = mediaList[currentIndex];

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isTrendyol)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: TextButton.icon(
                            onPressed: () async {
                              if (widget.onTrendyolTap != null) {
                                final removed =
                                    await widget.onTrendyolTap!(media.tag!);
                                if (removed && context.mounted) {
                                  Navigator.of(context).pop(true);
                                }
                              }
                            },
                            icon: const Icon(
                              Iconsax.eye,
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
                              backgroundColor:
                                  const Color(0xFFF27A1A).withAlpha(20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                            ),
                          ),
                        ),
                      if (isTrendyol || isUpload)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: PullDownButton(
                            routeTheme: const PullDownMenuRouteTheme(
                              backgroundColor: Color(0xFFFFFFFF),
                            ),
                            itemBuilder: (context) => [
                              PullDownMenuItem(
                                title: 'Paylaş',
                                icon: Iconsax.export_3,
                                onTap: () => _shareImage(media.imageUrl),
                              ),
                              if (isTrendyol)
                                PullDownMenuItem(
                                  title: 'Gardıroptan Çıkar',
                                  icon: Iconsax.minus_cirlce,
                                  isDestructive: true,
                                  onTap: () async {
                                    if (widget.onRemoveTrendyolProduct !=
                                        null) {
                                      await widget
                                          .onRemoveTrendyolProduct!(media.tag!);
                                    }
                                  },
                                ),
                              if (isUpload)
                                PullDownMenuItem(
                                  title: 'Sil',
                                  icon: Iconsax.trash,
                                  isDestructive: true,
                                  onTap: () async {
                                    if (widget.onDeleteMedia != null) {
                                      await widget.onDeleteMedia!(media.id);
                                    }
                                  },
                                ),
                            ],
                            buttonBuilder: (context, showMenu) =>
                                GestureDetector(
                              onTap: showMenu,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 8),
                                child: Transform.rotate(
                                  angle: 1.5708,
                                  child: const Icon(Iconsax.more, size: 22),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
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
                final newIndex = ((notification.metrics.pixels +
                            itemHeight * 0.5) /
                        itemHeight)
                    .floor()
                    .clamp(0, mediaList.length - 1);
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
              itemExtent: availableHeight - 80,
              shrinkExtent: availableHeight - 120,
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: List.generate(mediaList.length, (index) {
                final media = mediaList[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: _buildMediaItem(media, index == widget.initialIndex),
                  ),
                );
              }),
            ),
          ),
        );
      },
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
              Icon(Icons.broken_image_outlined,
                  size: 48, color: Colors.black26),
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
      );
    }
    return image;
  }
}
