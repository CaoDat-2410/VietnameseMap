import 'package:flutter/material.dart';

/// Design System - Typography
/// Consistent text styles based on Vietnamese-inspired modern minimalist design
class AppTypography {
  AppTypography._();

  // ============================================
  // FONT FAMILY
  // ============================================
  static const String fontFamily = 'Roboto';
  static const String fontFamilyMono = 'RobotoMono';

  // ============================================
  // FONT WEIGHTS
  // ============================================
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // ============================================
  // DISPLAY STYLES (Large headlines)
  // ============================================
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: bold,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: bold,
    letterSpacing: 0,
    height: 1.16,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.22,
  );

  // ============================================
  // HEADLINE STYLES (Section headers)
  // ============================================
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.29,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.33,
  );

  // ============================================
  // TITLE STYLES (Card titles, list items)
  // ============================================
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: medium,
    letterSpacing: 0,
    height: 1.27,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: medium,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // ============================================
  // BODY STYLES (Primary content)
  // ============================================
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: regular,
    letterSpacing: 0.5,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: regular,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // ============================================
  // LABEL STYLES (Buttons, chips, tabs)
  // ============================================
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // ============================================
  // SPECIALTY STYLES
  // ============================================

  // KPI Numbers (large metrics)
  static const TextStyle kpiLarge = TextStyle(
    fontSize: 48,
    fontWeight: bold,
    letterSpacing: -1,
    height: 1.0,
  );

  static const TextStyle kpiMedium = TextStyle(
    fontSize: 32,
    fontWeight: bold,
    letterSpacing: -0.5,
    height: 1.1,
  );

  // Caption / Helper text
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // Overline (uppercase labels)
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: medium,
    letterSpacing: 1.5,
    height: 1.6,
  );
}
