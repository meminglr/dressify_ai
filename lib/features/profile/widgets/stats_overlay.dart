import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// StatsOverlay widget displays user statistics with optimized blur effect.
///
/// This widget shows three statistics (AI Görünümler, Gardırop, Modellerim) with:
/// - Optimized blur effect (using semi-transparent background instead of BackdropFilter)
/// - Shadow effect (0px 25px 50px -12px rgba(0,0,0,0.25))
/// - 16px border radius
/// - Figma design colors and typography
///
/// Performance optimized: Removed BackdropFilter for better FPS during tab switches
/// Validates Requirements 3, 10
class StatsOverlay extends StatelessWidget {
  final int aiLooksCount;
  final int uploadsCount;
  final int modelsCount;

  const StatsOverlay({
    super.key,
    required this.aiLooksCount,
    required this.uploadsCount,
    required this.modelsCount,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              offset: const Offset(0, 25),
              blurRadius: 50,
              spreadRadius: -12,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 41, vertical: 21),
            decoration: BoxDecoration(
              // Use frosted glass effect without expensive BackdropFilter
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatItem('AI GÖRÜNÜMLER', aiLooksCount),
                const SizedBox(width: 32),
                _buildStatItem('GARDIROP', uploadsCount),
                const SizedBox(width: 32),
                _buildStatItem('MODELLERIM', modelsCount),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.beVietnamPro(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFCEB5FF), // Primary light color
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.9,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
