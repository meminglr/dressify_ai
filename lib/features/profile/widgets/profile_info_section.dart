import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/profile.dart';
import '../models/user_stats.dart';
import 'stats_overlay.dart';

/// ProfileInfoSection widget displays user profile information.
///
/// This widget shows:
/// - Avatar (CircleAvatar, 80px diameter)
/// - Full name (Manrope Regular, 36px, -0.9px letter spacing)
/// - Bio (Be Vietnam Pro Medium, 14px) - if available
/// - StatsOverlay with user statistics
///
/// Handles null avatarUrl and bio gracefully.
/// Validates Requirements 3, 10
class ProfileInfoSection extends StatelessWidget {
  final Profile profile;
  final UserStats stats;

  const ProfileInfoSection({
    super.key,
    required this.profile,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Full Name
        Text(
          profile.fullName,
          style: GoogleFonts.manrope(
            fontSize: 36,
            fontWeight: FontWeight.w400,
            color: const Color(0xFFFFFFFF),
            letterSpacing: -0.9,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        
        // Bio (if available)
        if (profile.bio != null && profile.bio!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              profile.bio!,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        
        const SizedBox(height: 16),
        
        // Stats Overlay
        StatsOverlay(
          aiLooksCount: stats.aiLooksCount,
          uploadsCount: stats.uploadsCount,
          modelsCount: stats.modelsCount,
        ),
      ],
    );
  }
}
