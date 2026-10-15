import 'package:flutter/material.dart';

/// Design tokens extracted precisely from the Stitch design system.
class AppColors {
  AppColors._();

  // Primary Palette (shared royal blue — identical in the admin and faculty portals)
  static const Color primary = Color(0xFF00288E);
  static const Color primaryContainer = Color(0xFF1E40AF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFFDDE1FF);
  static const Color primaryFixedDim = Color(0xFFB8C4FF);

  // Secondary Palette (Vibrant Royal Blue)
  static const Color secondary = Color(0xFF0051D5);
  static const Color secondaryContainer = Color(0xFF316BF3);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFFFEFCFF);
  static const Color secondaryFixed = Color(0xFFDBE1FF);
  static const Color secondaryFixedDim = Color(0xFFB4C5FF);

  // Surface & Canvas Palette
  static const Color background = Color(0xFFF8F9FF);
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceBright = Color(0xFFF8F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color surfaceContainerHighest = Color(0xFFD3E4FE);

  // Typography & Content Colors
  static const Color onSurface = Color(0xFF0F172A);
  static const Color onSurfaceVariant = Color(0xFF334155);
  static const Color outline = Color(0xFF64748B);
  /// Placeholder / hint text: fainter than entered values (about 4.4:1 on the field fill), shown italic and light.
  static const Color hint = Color(0xFF66768C);
  static const Color outlineVariant = Color(0xFFC5C6CD);

  // Tertiary Palette (Success / Complete Emerald)
  static const Color tertiary = Color(0xFF00190E);
  static const Color tertiaryContainer = Color(0xFF00301E);
  static const Color onTertiaryContainer = Color(0xFF00A472);
  static const Color tertiaryFixed = Color(0xFF6FFBBE);

  // Error / Urgent Action Palette
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);
}
