import 'package:flutter/material.dart';

/// Design tokens for the Faculty Portal (Stitch "SkillBridge" design system).
/// Primary blue is shared with AppColors and AdminColors (one blue across
/// every portal).
class FacultyColors {
  FacultyColors._();

  static const Color primary = Color(0xFF00288E);
  static const Color primaryContainer = Color(0xFF1E40AF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFA8B8FF);
  static const Color onPrimaryFixedVariant = Color(0xFF173BAB);

  static const Color secondary = Color(0xFF565E74);
  static const Color secondaryContainer = Color(0xFFDAE2FD);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF5C647A);
  static const Color onSecondaryFixed = Color(0xFF131B2E);
  static const Color onSecondaryFixedVariant = Color(0xFF3F465C);

  static const Color tertiary = Color(0xFF006243);
  static const Color tertiaryContainer = Color(0xFF007D57);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFBDFFDC);
  static const Color tertiaryFixed = Color(0xFF85F8C4);
  static const Color onTertiaryFixedVariant = Color(0xFF005137);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const Color background = Color(0xFFF8F9FF);
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceBright = Color(0xFFF8F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color surfaceContainerHighest = Color(0xFFD3E4FE);

  static const Color onSurface = Color(0xFF0F172A);
  static const Color onSurfaceVariant = Color(0xFF334155);
  static const Color outline = Color(0xFF64748B);
  /// Placeholder / hint text: fainter than entered values (about 4.4:1 on the field fill), shown italic and light.
  static const Color hint = Color(0xFF66768C);
  static const Color outlineVariant = Color(0xFFC3C6D7);
}
