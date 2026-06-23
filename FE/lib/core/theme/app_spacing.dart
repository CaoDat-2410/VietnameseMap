/// Design System - Spacing Constants
/// Consistent spacing scale based on 4px grid
class AppSpacing {
  AppSpacing._();

  // ============================================
  // BASE UNIT (4px)
  // ============================================
  static const double unit = 4.0;

  // ============================================
  // SPACING SCALE
  // ============================================
  static const double xxs = 2.0;   // 0.5x - minimal gap
  static const double xs = 4.0;    // 1x - tight spacing
  static const double sm = 8.0;    // 2x - small gap
  static const double md = 12.0;   // 3x - default gap
  static const double base = 16.0; // 4x - standard gap
  static const double lg = 20.0;   // 5x - large gap
  static const double xl = 24.0;   // 6x - extra large
  static const double xxl = 32.0;  // 8x - section gap
  static const double xxxl = 48.0; // 12x - page section

  // ============================================
  // SCREEN PADDING
  // ============================================
  static const double screenPaddingMobile = 16.0;
  static const double screenPaddingTablet = 24.0;
  static const double screenPaddingDesktop = 32.0;

  // ============================================
  // CARD PADDING
  // ============================================
  static const double cardPadding = 16.0;
  static const double cardPaddingCompact = 12.0;
  static const double cardPaddingSpacious = 20.0;

  // ============================================
  // BENTO GRID
  // ============================================
  static const double bentoGap = 12.0;
  static const double bentoRadius = 16.0;
  static const double bentoRadiusLg = 20.0;

  // ============================================
  // BORDER RADIUS
  // ============================================
  static const double radiusXs = 4.0;
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusBase = 10.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radius2xl = 20.0;
  static const double radius3xl = 24.0;
  static const double radiusFull = 999.0;

  // ============================================
  // ELEVATION (shadows)
  // ============================================
  static const double elevationNone = 0.0;
  static const double elevationXs = 1.0;
  static const double elevationSm = 2.0;
  static const double elevationBase = 4.0;
  static const double elevationMd = 8.0;
  static const double elevationLg = 16.0;
  static const double elevationXl = 24.0;

  // ============================================
  // ICON SIZES
  // ============================================
  static const double iconXs = 14.0;
  static const double iconSm = 16.0;
  static const double iconBase = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 28.0;
  static const double iconXl = 32.0;
  static const double icon2xl = 48.0;

  // ============================================
  // TOUCH TARGETS (WCAG 2.1 minimum 44px, we use 48px)
  // ============================================
  static const double touchTargetMin = 48.0;
  static const double touchTargetPreferred = 52.0;

  // ============================================
  // NAVIGATION
  // ============================================
  static const double navBarHeight = 64.0;
  static const double navRailWidth = 80.0;
  static const double navRailWidthExpanded = 256.0;
  static const double sideNavWidth = 280.0;

  // ============================================
  // BREAKPOINTS (matching responsive.dart)
  // ============================================
  static const double breakpointMobile = 600.0;
  static const double breakpointTablet = 900.0;
  static const double breakpointDesktop = 1200.0;
}
