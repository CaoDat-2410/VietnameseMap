import 'package:flutter/material.dart';

/// Design System - Shadow Definitions
/// Soft, subtle shadows for depth without harshness
class AppShadows {
  AppShadows._();

  // ============================================
  // LIGHT MODE SHADOWS
  // ============================================

  /// No shadow - for flat design
  static const List<BoxShadow> none = [];

  /// XS: Subtle card shadow
  static const List<BoxShadow> shadowXs = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  /// SM: Card hover, elevated buttons
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// Base: Elevated cards, dialogs
  static const List<BoxShadow> shadowBase = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  /// MD: Floating elements, tooltips
  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x19000000),
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];

  /// LG: Modal dialogs, floating buttons
  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  /// XL: Full page overlays
  static const List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Color(0x28000000),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];

  // ============================================
  // DARK MODE SHADOWS (more subtle, tinted)
  // ============================================

  static const List<BoxShadow> shadowDarkXs = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowDarkSm = [
    BoxShadow(
      color: Color(0x50000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowDarkBase = [
    BoxShadow(
      color: Color(0x60000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> shadowDarkMd = [
    BoxShadow(
      color: Color(0x70000000),
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> shadowDarkLg = [
    BoxShadow(
      color: Color(0x80000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  // ============================================
  // GLASSMORPHISM SHADOWS
  // ============================================

  static const List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> glassShadowDark = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  // ============================================
  // FOCUS RING SHADOWS (accessibility)
  // ============================================

  static const List<BoxShadow> focusRing = [
    BoxShadow(
      color: Color(0x40B91C1C),
      blurRadius: 0,
      spreadRadius: 2,
    ),
  ];

  // ============================================
  // INNER SHADOWS (for pressed states)
  // ============================================

  static const List<BoxShadow> innerShadow = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 2,
      offset: Offset(0, 1),
      spreadRadius: -1,
    ),
  ];

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Get shadow for elevation level
  static List<BoxShadow> forElevation(double elevation) {
    switch (elevation) {
      case 0:
        return none;
      case 1:
        return shadowXs;
      case 2:
        return shadowSm;
      case 4:
        return shadowBase;
      case 8:
        return shadowMd;
      case 16:
        return shadowLg;
      case 24:
        return shadowXl;
      default:
        return shadowBase;
    }
  }

  /// Get shadow based on brightness
  static List<BoxShadow> forTheme(Brightness brightness, double elevation) {
    return brightness == Brightness.dark
        ? forElevationDark(elevation)
        : forElevation(elevation);
  }

  static List<BoxShadow> forElevationDark(double elevation) {
    switch (elevation) {
      case 0:
        return none;
      case 1:
        return shadowDarkXs;
      case 2:
        return shadowDarkSm;
      case 4:
        return shadowDarkBase;
      case 8:
        return shadowDarkMd;
      case 16:
        return shadowDarkLg;
      default:
        return shadowDarkBase;
    }
  }
}
