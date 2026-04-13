import 'dart:ui';
import 'package:flutter/material.dart';

/// Primary action button widget with icon and text
/// 
/// Implements Figma design specifications:
/// - Background: #742fe5 (primary purple)
/// - Text: #ffffff (white)
/// - Typography: Manrope Regular, 14px
/// - Border Radius: 9999px (pill shape)
/// - Padding: 24px horizontal, 10px vertical
/// - Shadow: 0px 4px 6px -1px rgba(116,47,229,0.3), 0px 2px 4px -2px rgba(116,47,229,0.3)
/// - Blur: 6px backdrop blur
/// 
/// Example usage:
/// ```dart
/// PrimaryActionButton(
///   label: 'Yeni Üret',
///   icon: Icons.add,
///   onPressed: () {
///     // Handle button press
///     Navigator.push(context, ...);
///   },
/// )
/// ```
class PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9999),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(116, 47, 229, 0.3),
            offset: Offset(0, 4),
            blurRadius: 6,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: Color.fromRGBO(116, 47, 229, 0.3),
            offset: Offset(0, 2),
            blurRadius: 4,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF742FE5),
              foregroundColor: const Color(0xFFFFFFFF),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFFFFFFFF),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
