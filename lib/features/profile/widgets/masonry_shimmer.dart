import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// MasonryShimmer widget displays a shimmer loading effect for masonry grid.
///
/// This widget shows a skeleton loading state that mimics the masonry grid layout
/// with varying heights to create a realistic loading experience.
///
/// Used when media list is loading in the profile page tabs.
class MasonryShimmer extends StatelessWidget {
  const MasonryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0E0E0),
      highlightColor: const Color(0xFFF5F5F5),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 columns matching real grid
            crossAxisSpacing: 12, // Match real grid spacing
            mainAxisSpacing: 12, // Match real grid spacing
            childAspectRatio: 1.0, // Square items matching real grid
          ),
          itemCount: 9, // Show 9 skeleton items (3x3 grid)
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            );
          },
        ),
      ),
    );
  }
}
