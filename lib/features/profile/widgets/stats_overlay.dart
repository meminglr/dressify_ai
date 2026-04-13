import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// StatsOverlay widget displays user statistics with blur and shadow effects.
///
/// This widget shows three statistics (AI Looks, Uploads, Models) with:
/// - 12px backdrop blur effect
/// - Shadow effect (0px 25px 50px -12px rgba(0,0,0,0.25))
/// - 16px border radius
/// - Figma design colors and typography
///
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
    return Container(
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
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 41, vertical: 21),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatItem('AI LOOKS', aiLooksCount),
                const SizedBox(width: 32),
                _buildStatItem('UPLOADS', uploadsCount),
                const SizedBox(width: 32),
                _buildStatItem('MODELS', modelsCount),
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
