import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography styles matching the Stitch design specification.
class AppTypography {
  AppTypography._();

  // Plus Jakarta Sans Headlines
  static TextStyle headlineXl({Color color = AppColors.primary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 36,
        height: 44 / 36,
        letterSpacing: -0.02 * 36,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle headlineLg({Color color = AppColors.primary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 28,
        height: 36 / 28,
        letterSpacing: -0.02 * 28,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle headlineMd({Color color = AppColors.primary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 20,
        height: 28 / 20,
        letterSpacing: -0.01 * 20,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle headlineSm({Color color = AppColors.primary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // Inter Body Styles
  static TextStyle bodyLg({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodyMd({Color color = AppColors.onSurfaceVariant}) =>
      GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodySm({Color color = AppColors.onSurfaceVariant}) =>
      GoogleFonts.inter(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
        color: color,
      );

  // Inter Label Styles
  static TextStyle labelLg({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: 0.01 * 14,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle labelMd({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 0.02 * 12,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle labelSm({Color color = AppColors.onSurfaceVariant}) =>
      GoogleFonts.inter(
        fontSize: 11,
        height: 14 / 11,
        letterSpacing: 0.04 * 11,
        fontWeight: FontWeight.w700,
        color: color,
      );
}
