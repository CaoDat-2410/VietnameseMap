import 'package:flutter/material.dart';

/// Design System - Color Palette
/// Soft Minimalism + Bento Cards style with Vietnamese-inspired warm tones
class AppColors {
  AppColors._();

  // ============================================
  // PRIMARY PALETTE - Warm Vietnamese Red
  // ============================================
  static const Color primary = Color(0xFFB91C1C);
  static const Color primaryLight = Color(0xFFDC2626);
  static const Color primaryDark = Color(0xFF991B1B);
  static const Color primaryContainer = Color(0xFFFEE2E2);
  static const Color onPrimaryContainer = Color(0xFF7F1D1D);

  // ============================================
  // SECONDARY PALETTE - Warm Gold/Amber
  // ============================================
  static const Color secondary = Color(0xFFD97706);
  static const Color secondaryLight = Color(0xFFFB923C);
  static const Color secondaryDark = Color(0xFFB45309);
  static const Color secondaryContainer = Color(0xFFFEF3C7);
  static const Color onSecondaryContainer = Color(0xFF92400E);

  // ============================================
  // TERTIARY - Accent Blue
  // ============================================
  static const Color tertiary = Color(0xFFF59E0B);
  static const Color tertiaryContainer = Color(0xFFFEF9C3);

  // ============================================
  // SURFACE COLORS - Light Mode
  // ============================================
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLight = Color(0xFFF8FAFC);
  static const Color surfaceContainerHighLight = Color(0xFFF1F5F9);
  static const Color surfaceContainerHighestLight = Color(0xFFE2E8F0);

  // ============================================
  // SURFACE COLORS - Dark Mode
  // ============================================
  static const Color surfaceDark = Color(0xFF000000);
  static const Color surfaceContainerDark = Color(0xFF1C1C1E);
  static const Color surfaceContainerHighDark = Color(0xFF2C2C2E);
  static const Color surfaceContainerHighestDark = Color(0xFF3A3A3C);

  // ============================================
  // TEXT COLORS - Light Mode
  // ============================================
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textTertiaryLight = Color(0xFF94A3B8);
  static const Color textDisabledLight = Color(0xFFCBD5E1);

  // ============================================
  // TEXT COLORS - Dark Mode
  // ============================================
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textTertiaryDark = Color(0xFF94A3B8);
  static const Color textDisabledDark = Color(0xFF64748B);

  // ============================================
  // BORDER COLORS
  // ============================================
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF3A3A3C);
  static const Color borderFocused = Color(0xFFB91C1C);

  // ============================================
  // STATUS COLORS
  // ============================================
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color successDark = Color(0xFF166534);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFF92400E);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFF991B1B);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF1E40AF);

  // ============================================
  // BENTO CARD COLORS
  // ============================================
  static const Color bentoBackground = Color(0xFFFFFFFF);
  static const Color bentoBackgroundDark = Color(0xFF1C1C1E);

  // Card accent colors for variety
  static const List<Color> bentoAccents = [
    Color(0xFFFEF3C7), // Amber
    Color(0xFFDCFCE7), // Green
    Color(0xFFDBEAFE), // Blue
    Color(0xFFFEE2E2), // Red
    Color(0xFFF3E8FF), // Purple
    Color(0xFFCCEFFF), // Cyan
  ];

  // ============================================
  // GLASSMORPHISM COLORS
  // ============================================
  static const Color glassLight = Color(0x80FFFFFF);
  static const Color glassDark = Color(0x401C1C1E);
  static const Color glassBorderLight = Color(0x40FFFFFF);
  static const Color glassBorderDark = Color(0x403A3A3C);

  // ============================================
  // SHIMMER COLORS
  // ============================================
  static const Color shimmerBaseLight = Color(0xFFE2E8F0);
  static const Color shimmerHighlightLight = Color(0xFFF8FAFC);
  static const Color shimmerBaseDark = Color(0xFF2C2C2E);
  static const Color shimmerHighlightDark = Color(0xFF3A3A3C);

  // ============================================
  // CHART COLORS
  // ============================================
  static const List<Color> chartColors = [
    Color(0xFFB91C1C), // Primary Red
    Color(0xFFD97706), // Secondary Gold
    Color(0xFF22C55E), // Green
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
    Color(0xFFF97316), // Orange
  ];
}
