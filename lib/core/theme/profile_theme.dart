import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Profile page specific theme constants based on Figma design
/// File Key: hBpOrjOf5YWhR9TXrERITn, Node ID: 1-2
class ProfileTheme {
  // ============================================================================
  // COLORS
  // ============================================================================
  
  /// Primary color - Used for main buttons and highlights
  static const Color primary = Color(0xFF742FE5);
  
  /// Primary light color - Used for stat numbers
  static const Color primaryLight = Color(0xFFCEB5FF);
  
  /// Background color - Page background
  static const Color background = Color(0xFFF8F9FA);
  
  /// Surface color - Card backgrounds
  static const Color surface = Color(0xFFFFFFFF);
  
  /// Primary text color
  static const Color textPrimary = Color(0xFF000000);
  
  /// Secondary text color
  static const Color textSecondary = Color(0xFF5A6062);
  
  /// Text on dark backgrounds
  static const Color textOnDark = Color(0xFFFFFFFF);
  
  /// Secondary text on dark backgrounds
  static const Color textOnDarkSecondary = Color(0xCCFFFFFF); // rgba(255,255,255,0.8)
  
  /// Overlay color for blur effects
  static const Color overlay = Color(0x4D000000); // rgba(0,0,0,0.3)
  
  /// Border color
  static const Color border = Color(0x1AFFFFFF); // rgba(255,255,255,0.1)

  // ============================================================================
  // TYPOGRAPHY
  // ============================================================================
  
  /// Heading 1 - User name (Manrope Regular, 36px, -0.9px letter spacing)
  static TextStyle heading1({Color? color}) => GoogleFonts.manrope(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.9,
        color: color ?? textPrimary,
        height: 1.2,
      );
  
  /// Heading 2 - Button text (Manrope Regular, 14px)
  static TextStyle heading2({Color? color}) => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color ?? textPrimary,
        height: 1.4,
      );
  
  /// Body - Bio text (Be Vietnam Pro Medium, 14px)
  static TextStyle body({Color? color}) => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color ?? textSecondary,
        height: 1.5,
      );
  
  /// Caption - Stats labels (Be Vietnam Pro Bold, 9px, 0.9px letter spacing, uppercase)
  static TextStyle caption({Color? color}) => GoogleFonts.beVietnamPro(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.9,
        color: color ?? textOnDarkSecondary,
        height: 1.3,
      );
  
  /// Tab label - Tab bar text (Be Vietnam Pro Bold, 12px)
  static TextStyle tabLabel({Color? color}) => GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color ?? textPrimary,
        height: 1.4,
      );
  
  /// Tag label - Media tag text (Be Vietnam Pro Bold, 8px, 0.8px letter spacing, uppercase)
  static TextStyle tagLabel({Color? color}) => GoogleFonts.beVietnamPro(
        fontSize: 8,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: color ?? textOnDark,
        height: 1.2,
      );

  // ============================================================================
  // SPACING
  // ============================================================================
  
  /// Section gap between major sections
  static const double sectionGap = 32.0;
  
  /// Card padding
  static const double cardPadding = 16.0;
  
  /// Button horizontal padding
  static const double buttonPaddingHorizontal = 24.0;
  
  /// Button vertical padding
  static const double buttonPaddingVertical = 10.0;
  
  /// Stats overlay horizontal padding
  static const double statsPaddingHorizontal = 41.0;
  
  /// Stats overlay vertical padding
  static const double statsPaddingVertical = 21.0;
  
  /// Grid gap for masonry layout
  static const double gridGap = 12.0;

  // ============================================================================
  // BORDER RADIUS
  // ============================================================================
  
  /// Hero header border radius
  static const double heroHeaderRadius = 40.0;
  
  /// Card border radius
  static const double cardRadius = 16.0;
  
  /// Button border radius (pill shape)
  static const double buttonRadius = 9999.0;
  
  /// Stats overlay border radius
  static const double statsOverlayRadius = 16.0;

  // ============================================================================
  // SHADOWS
  // ============================================================================
  
  /// Hero header shadow
  static List<BoxShadow> get heroHeaderShadow => [
        BoxShadow(
          color: Color(0x40000000), // rgba(0,0,0,0.25)
          offset: Offset(0, 25),
          blurRadius: 50,
          spreadRadius: -12,
        ),
      ];
  
  /// Primary button shadow
  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: Color(0x4D742FE5), // rgba(116,47,229,0.3)
          offset: Offset(0, 4),
          blurRadius: 6,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: Color(0x4D742FE5), // rgba(116,47,229,0.3)
          offset: Offset(0, 2),
          blurRadius: 4,
          spreadRadius: -2,
        ),
      ];
  
  /// Card shadow
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Color(0x0D000000), // rgba(0,0,0,0.05)
          offset: Offset(0, 1),
          blurRadius: 2,
          spreadRadius: 0,
        ),
      ];
  
  /// Stats overlay shadow
  static List<BoxShadow> get statsOverlayShadow => [
        BoxShadow(
          color: Color(0x40000000), // rgba(0,0,0,0.25)
          offset: Offset(0, 25),
          blurRadius: 50,
          spreadRadius: -12,
        ),
      ];

  // ============================================================================
  // BLUR EFFECTS
  // ============================================================================
  
  /// Stats overlay backdrop blur
  static const double statsOverlayBlur = 12.0;
  
  /// Button backdrop blur (for header button)
  static const double buttonBlur = 6.0;
  
  /// Image overlay blur
  static const double imageOverlayBlur = 10.0;

  // ============================================================================
  // DIMENSIONS
  // ============================================================================
  
  /// FlexibleSpaceBar expanded height
  static const double expandedHeaderHeight = 480.0;
  
  /// Avatar size
  static const double avatarSize = 80.0;
  
  /// Grid item minimum width
  static const double gridItemMinWidth = 100.0;

  // ============================================================================
  // RESPONSIVE BREAKPOINTS
  // ============================================================================
  
  /// Small screen breakpoint (< 600px)
  static const double smallScreenBreakpoint = 600.0;
  
  /// Medium screen breakpoint (600px - 900px)
  static const double mediumScreenBreakpoint = 900.0;
  
  /// Grid columns for small screens
  static const int gridColumnsSmall = 3;
  
  /// Grid columns for medium screens
  static const int gridColumnsMedium = 4;
  
  /// Grid columns for large screens
  static const int gridColumnsLarge = 5;
  
  /// Calculate grid column count based on screen width
  static int getGridColumnCount(double screenWidth) {
    if (screenWidth < smallScreenBreakpoint) {
      return gridColumnsSmall;
    } else if (screenWidth < mediumScreenBreakpoint) {
      return gridColumnsMedium;
    } else {
      return gridColumnsLarge;
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Create a gradient overlay for hero header
  static LinearGradient get heroGradientOverlay => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          overlay,
        ],
        stops: [0.5, 1.0],
      );
  
  /// Create edge insets for card padding
  static EdgeInsets get cardPaddingInsets => EdgeInsets.all(cardPadding);
  
  /// Create edge insets for button padding
  static EdgeInsets get buttonPaddingInsets => EdgeInsets.symmetric(
        horizontal: buttonPaddingHorizontal,
        vertical: buttonPaddingVertical,
      );
  
  /// Create edge insets for stats overlay padding
  static EdgeInsets get statsPaddingInsets => EdgeInsets.symmetric(
        horizontal: statsPaddingHorizontal,
        vertical: statsPaddingVertical,
      );
  
  /// Create border radius for hero header
  static BorderRadius get heroHeaderBorderRadius => BorderRadius.circular(heroHeaderRadius);
  
  /// Create border radius for cards
  static BorderRadius get cardBorderRadius => BorderRadius.circular(cardRadius);
  
  /// Create border radius for buttons
  static BorderRadius get buttonBorderRadius => BorderRadius.circular(buttonRadius);
  
  /// Create border radius for stats overlay
  static BorderRadius get statsOverlayBorderRadius => BorderRadius.circular(statsOverlayRadius);
}
