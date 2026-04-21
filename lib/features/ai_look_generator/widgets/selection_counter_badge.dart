import 'package:flutter/material.dart';

/// Badge widget displaying the current wardrobe selection count.
///
/// Shows "X / 5 SEÇİLDİ" in green. Announces changes to screen readers
/// via [Semantics.liveRegion].
class SelectionCounterBadge extends StatelessWidget {
  /// Number of currently selected wardrobe items (0–5).
  final int selectedCount;

  const SelectionCounterBadge({
    super.key,
    required this.selectedCount,
  });

  static const int _maxCount = 5;
  // Figma: bg #d1fae5, text #3d6151
  static const Color _bgColor = Color(0xFFD1FAE5);
  static const Color _textColor = Color(0xFF3D6151);

  @override
  Widget build(BuildContext context) {
    final label = '$selectedCount / $_maxCount SEÇİLDİ';

    return Semantics(
      liveRegion: true,
      label: '$selectedCount kıyafet seçildi, maksimum $_maxCount',
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Liberation Serif',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _textColor,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
