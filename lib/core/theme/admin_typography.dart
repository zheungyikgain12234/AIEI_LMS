import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_colors.dart';

/// Typography styles for the Admin Portal (Inter, per the Stitch spec).
class AdminTypography {
  AdminTypography._();

  static TextStyle displayLg({Color color = AdminColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 40,
        height: 44 / 36,
        letterSpacing: -0.025 * 36,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle headlineLg({Color color = AdminColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 34,
        height: 38 / 30,
        letterSpacing: -0.02 * 30,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle headlineMd({Color color = AdminColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 28,
        height: 32 / 24,
        letterSpacing: -0.015 * 24,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle headlineSm({Color color = AdminColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 24,
        height: 28 / 20,
        letterSpacing: -0.01 * 20,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle titleMd({Color color = AdminColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 20,
        height: 24 / 16,
        letterSpacing: -0.005 * 16,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle titleSm({Color color = AdminColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 18,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle bodyLg({Color color = AdminColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 20,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodyMd({Color color = AdminColors.onSurfaceVariant}) =>
      GoogleFonts.inter(
        fontSize: 18,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodySm({Color color = AdminColors.onSurfaceVariant}) =>
      GoogleFonts.inter(
        fontSize: 17,
        height: 18 / 13,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle labelMd({Color color = AdminColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 16,
        height: 16 / 12,
        letterSpacing: 0.02 * 12,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle labelSm({Color color = AdminColors.onSurfaceVariant}) =>
      GoogleFonts.inter(
        fontSize: 16,
        height: 14 / 11,
        letterSpacing: 0.04 * 11,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle dataMetric({Color color = AdminColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 32,
        height: 32 / 28,
        letterSpacing: -0.02 * 28,
        fontWeight: FontWeight.w700,
        color: color,
      );
}
