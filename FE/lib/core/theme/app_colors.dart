import 'package:flutter/material.dart';

/// Design System - Color Palette
/// Soft Minimalism + Bento Cards style
/// Professional, clean, muted color palette
class AppColors {
  AppColors._();

  // ============================================
  // PRIMARY PALETTE - Muted Indigo
  // ============================================
  static const Color primary = Color(0xFF4F46E5);        // Indigo-600
  static const Color primaryLight = Color(0xFF818CF8);   // Indigo-400
  static const Color primaryDark = Color(0xFF4338CA);     // Indigo-700
  static const Color primaryContainer = Color(0xFFEEF2FF); // Indigo-50
  static const Color onPrimaryContainer = Color(0xFF312E81);

  // ============================================
  // SECONDARY PALETTE - Slate Gray
  // ============================================
  static const Color secondary = Color(0xFF64748B);       // Slate-500
  static const Color secondaryLight = Color(0xFF94A3B8);  // Slate-400
  static const Color secondaryDark = Color(0xFF475569);    // Slate-600
  static const Color secondaryContainer = Color(0xFFF1F5F9); // Slate-100
  static const Color onSecondaryContainer = Color(0xFF1E293B);

  // ============================================
  // TERTIARY - Teal accent
  // ============================================
  static const Color tertiary = Color(0xFF14B8A6);  // Teal-500
  static const Color tertiaryContainer = Color(0xFFCCFBF1); // Teal-100

  // ============================================
  // SURFACE COLORS - Light Mode (Slate-based)
  // ============================================
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLight = Color(0xFFF8FAFC);  // Slate-50
  static const Color surfaceContainerHighLight = Color(0xFFF1F5F9); // Slate-100
  static const Color surfaceContainerHighestLight = Color(0xFFE2E8F0); // Slate-200

  // ============================================
  // SURFACE COLORS - Dark Mode
  // ============================================
  static const Color surfaceDark = Color(0xFF0F172A);     // Slate-900
  static const Color surfaceContainerDark = Color(0xFF1E293B); // Slate-800
  static const Color surfaceContainerHighDark = Color(0xFF334155); // Slate-700
  static const Color surfaceContainerHighestDark = Color(0xFF475569); // Slate-600

  // ============================================
  // TEXT COLORS - Light Mode
  // ============================================
  static const Color textPrimaryLight = Color(0xFF0F172A);   // Slate-900
  static const Color textSecondaryLight = Color(0xFF334155);   // Slate-700
  static const Color textTertiaryLight = Color(0xFF64748B);   // Slate-500
  static const Color textDisabledLight = Color(0xFF64748B);    // Slate-500

  // ============================================
  // TEXT COLORS - Dark Mode
  // ============================================
  static const Color textPrimaryDark = Color(0xFFF8FAFC);   // Slate-50
  static const Color textSecondaryDark = Color(0xFFCBD5E1);  // Slate-300
  static const Color textTertiaryDark = Color(0xFF94A3B8);   // Slate-400
  static const Color textDisabledDark = Color(0xFF64748B);    // Slate-500

  // ============================================
  // BORDER COLORS
  // ============================================
  static const Color borderLight = Color(0xFFCBD5E1);     // Slate-300
  static const Color borderDark = Color(0xFF334155);     // Slate-700
  static const Color borderFocused = Color(0xFF4F46E5);  // Primary

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
  static const Color bentoBackgroundDark = Color(0xFF1E293B);

  // Card accent colors for variety (muted tones)
  static const List<Color> bentoAccents = [
    Color(0xFFEEF2FF), // Indigo-50
    Color(0xFFDCFCE7), // Green-100
    Color(0xFFDBEAFE), // Blue-100
    Color(0xFFFEF3C7), // Amber-100
    Color(0xFFF3E8FF), // Purple-100
    Color(0xFFCCFBF1), // Teal-100
  ];

  // ============================================
  // GLASSMORPHISM COLORS
  // ============================================
  static const Color glassLight = Color(0x80FFFFFF);
  static const Color glassDark = Color(0x401E293B);
  static const Color glassBorderLight = Color(0x40FFFFFF);
  static const Color glassBorderDark = Color(0x40334155);

  // ============================================
  // SHIMMER COLORS
  // ============================================
  static const Color shimmerBaseLight = Color(0xFFE2E8F0);
  static const Color shimmerHighlightLight = Color(0xFFF8FAFC);
  static const Color shimmerBaseDark = Color(0xFF334155);
  static const Color shimmerHighlightDark = Color(0xFF475569);

  // ============================================
  // CHART COLORS (muted, harmonious)
  // ============================================
  static const List<Color> chartColors = [
    Color(0xFF6366F1), // Indigo (primary)
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
    Color(0xFF22C55E), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xFF64748B), // Slate
    Color(0xFFEF4444), // Red
  ];
}
