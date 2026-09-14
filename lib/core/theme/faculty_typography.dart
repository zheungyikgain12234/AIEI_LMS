import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'faculty_colors.dart';

/// Typography styles for the Faculty Portal (Inter, per the Stitch spec).
class FacultyTypography {
  FacultyTypography._();

  static TextStyle displayLg({Color color = FacultyColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 32,
        height: 40 / 32,
        letterSpacing: -0.02 * 32,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle headlineLg({Color color = FacultyColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 24,
        height: 32 / 24,
        letterSpacing: -0.015 * 24,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle headlineMd({Color color = FacultyColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 20,
        height: 28 / 20,
        letterSpacing: -0.01 * 20,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle titleSm({Color color = FacultyColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        letterSpacing: -0.005 * 16,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle bodyLg({Color color = FacultyColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodyMd({Color color = FacultyColors.onSurfaceVariant}) =>
      GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodySm({Color color = FacultyColors.onSurfaceVariant}) =>
      GoogleFonts.inter(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle labelMd({Color color = FacultyColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 0.025 * 12,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle labelXs({Color color = FacultyColors.onSurfaceVariant}) =>
      GoogleFonts.inter(
        fontSize: 11,
        height: 14 / 11,
        letterSpacing: 0.03 * 11,
        fontWeight: FontWeight.w500,
        color: color,
      );
}
