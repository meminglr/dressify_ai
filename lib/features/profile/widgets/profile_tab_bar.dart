import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ProfileTabBar widget displays a tab bar with three tabs.
///
/// This widget shows three tabs (AI Görünümler, Gardırop, Modellerim) with:
/// - Modern pill-style design matching the app's navigation bar
/// - Tab Label Typography: Be Vietnam Pro Bold, 14px
/// - Active Tab: Primary color background with white text
/// - Inactive Tab: Transparent background with secondary text
/// - Smooth animations
/// - Rounded corners and shadows
///
/// Designed to be used in SliverPersistentHeader (pinned: true)
///
/// Validates Requirements 4, 10
class ProfileTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final TabController? controller;

  const ProfileTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA), // Background color
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF), // White background
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1D1F).withAlpha(15),
              blurRadius: 48,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: TabBar(
          controller: controller,
          onTap: onTabSelected,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: const Color(0xFF742FE5), // Primary color
            borderRadius: BorderRadius.circular(50),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(4),
          labelPadding: EdgeInsets.zero,
          tabs: [
            _buildTab('AI Görünümler', 0),
            _buildTab('Gardırop', 1),
            _buildTab('Modellerim', 2),
          ],
          labelStyle: GoogleFonts.beVietnamPro(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: GoogleFonts.beVietnamPro(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          labelColor: Colors.white, // Active tab text color
          unselectedLabelColor: const Color(0xFF5A6062), // Inactive tab text color
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    return Tab(
      height: 44,
      child: Center(
        child: Text(label),
      ),
    );
  }
}
