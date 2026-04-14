import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ProfileTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final TabController? controller;
  final int aiLooksCount;
  final int uploadsCount;
  final int modelsCount;

  const ProfileTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.controller,
    this.aiLooksCount = 0,
    this.uploadsCount = 0,
    this.modelsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
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
            color: const Color(0xFF742FE5),
            borderRadius: BorderRadius.circular(50),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(4),
          labelPadding: EdgeInsets.zero,
          tabs: [
            _buildTab('AI', aiLooksCount),
            _buildTab('Gardırop', uploadsCount),
            _buildTab('Modellerim', modelsCount),
          ],
          labelStyle: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF5A6062),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    final formatted = count > 999
        ? '${(count / 1000).toStringAsFixed(1)}B'
        : NumberFormat.decimalPattern('tr').format(count);

    return Tab(
      height: 44,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 5),
            Builder(
              builder: (ctx) {
                final color = DefaultTextStyle.of(ctx).style.color ??
                    const Color(0xFF742FE5);
                final isWhite = (color.r * 255).round() > 200 &&
                    (color.g * 255).round() > 200 &&
                    (color.b * 255).round() > 200;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isWhite
                        ? Colors.white.withAlpha(50)
                        : const Color(0xFF742FE5).withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    formatted,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
