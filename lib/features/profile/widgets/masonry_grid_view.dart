import 'package:flutter/material.dart';
import '../models/media.dart';
import 'grid_item.dart';

/// MasonryGridView widget for displaying media items in a responsive grid layout.
///
/// This widget returns a SliverGrid for use in CustomScrollView, with responsive
/// column count based on screen width and lazy loading for performance.
///
/// Validates Requirements 5, 8, 14
class MasonryGridView extends StatelessWidget {
  /// List of media items to display
  final List<Media> mediaList;

  /// Callback when a grid item is tapped
  final Function(int index) onItemTap;

  const MasonryGridView({
    super.key,
    required this.mediaList,
    required this.onItemTap,
  });

  /// Calculates responsive column count based on screen width
  ///
  /// - <600px: 3 columns (mobile)
  /// - 600-900px: 4 columns (tablet)
  /// - >900px: 5 columns (desktop)
  int _calculateColumnCount(double screenWidth) {
    if (screenWidth < 600) {
      return 3;
    } else if (screenWidth < 900) {
      return 4;
    } else {
      return 5;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columnCount = _calculateColumnCount(screenWidth);

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        crossAxisSpacing: 12, // Grid gap
        mainAxisSpacing: 12, // Grid gap
        childAspectRatio: 1.0, // Square items for masonry effect
      ),
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          final media = mediaList[index];
          
          return GridItem(
            media: media,
            onTap: () => onItemTap(index),
            heroTag: 'media_${media.id}',
          );
        },
        childCount: mediaList.length,
      ),
    );
  }
}
