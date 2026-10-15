import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';

/// TRIAL: higher-contrast colours and field styling, used by Badge management
/// only (Manage Badges screen + Add/Edit Badge popup) so it can be reviewed
/// before being rolled out. Nothing here changes the shared admin theme.
///
/// Contrast against white / the field fill (WCAG): text 17:1, secondary text
/// 10:1, placeholder 7.6:1, field and checkbox borders 4.8:1 (>= 3:1 needed
/// for UI components), dividers visible but quiet.
class BadgeContrast {
  BadgeContrast._();

  /// Primary text: titles, values, entered text.
  static const text = Color(0xFF0F172A);

  /// Secondary text: subtitles, codes, descriptions.
  static const textSecondary = Color(0xFF334155);

  /// Placeholder: italic, light weight and a fainter grey-blue than entered
  /// text (about 4.4:1 on the field fill).
  static const placeholder = Color(0xFF66768C);

  /// Field fill, light enough that text on it keeps its contrast.
  static const fieldFill = Color(0xFFF1F5F9);

  /// Visible edge for fields, checkboxes and cards.
  static const border = Color(0xFF64748B);

  /// Row dividers and card outlines.
  static const divider = Color(0xFFCBD5E1);

  /// Row highlight when its checkbox is ticked.
  static const selectedRow = Color(0xFFEEF2FF);

  static TextStyle placeholderStyle({double size = 14}) =>
      AdminTypography.bodyMd(color: placeholder).copyWith(fontStyle: FontStyle.italic, fontWeight: FontWeight.w300, fontSize: size);

  /// Filled field with a clear 1px edge and a 2px blue focus ring.
  static InputDecoration fieldDecoration({String? hint, Widget? prefixIcon, EdgeInsetsGeometry? contentPadding}) {
    OutlineInputBorder edge(Color c, double w) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c, width: w));
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: fieldFill,
      hintText: hint,
      hintStyle: placeholderStyle(),
      prefixIcon: prefixIcon,
      border: edge(border, 1),
      enabledBorder: edge(border, 1),
      focusedBorder: edge(AdminColors.primaryContainer, 2),
      errorBorder: edge(AdminColors.error, 1.5),
      focusedErrorBorder: edge(AdminColors.error, 2),
      contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  /// Field label above a field: larger and darker than the shared one.
  static Widget label(String text, {bool required = true}) {
    final style = AdminTypography.bodySm(color: BadgeContrast.text).copyWith(fontWeight: FontWeight.w700);
    return Text.rich(TextSpan(text: text, style: style, children: [
      if (required) TextSpan(text: ' *', style: style.copyWith(color: AdminColors.error)),
    ]));
  }
}
