import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onPrimary: AppColors.onPrimary,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.manrope(
          color: AppColors.onSurface,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.02 * 57, // Appx relative to display size
        ),
        headlineLarge: GoogleFonts.manrope(
          color: AppColors.onSurface,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.02 * 32,
        ),
        headlineMedium: GoogleFonts.manrope(
          color: AppColors.onSurface,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.manrope(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: GoogleFonts.beVietnamPro(color: AppColors.onSurface),
        bodyMedium: GoogleFonts.beVietnamPro(color: AppColors.onSurface),
        labelLarge: GoogleFonts.beVietnamPro(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: GoogleFonts.beVietnamPro(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(48), // Pill shape 3rem
          ),
          textStyle: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        hintStyle: GoogleFonts.beVietnamPro(color: AppColors.outlineVariant),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24), // 1.5rem
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: AppColors.primary.withAlpha(76), // ~30% opacity ghost border
            width: 2,
          ),
        ),
      ),
    );
  }
}
