import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';

/// System-wide colours and field styling for text/placeholder/border contrast
/// (trialled on Badge management, now used by every portal).
///
/// Contrast against white / the field fill (WCAG): text 17:1, secondary text
/// 10:1, placeholder ~4.4:1 (italic, light), field and checkbox borders 4.8:1
/// (>= 3:1 needed for UI components), dividers visible but quiet.
class UiContrast {
  UiContrast._();

  /// Primary text: titles, values, entered text.
  static const text = Color(0xFF0F172A);

  /// Secondary text: subtitles, codes, descriptions.
  static const textSecondary = Color(0xFF334155);

  /// Placeholder: italic, light weight and a fainter grey-blue than entered text.
  static const placeholder = Color(0xFF66768C);

  /// Field fill, light enough that text on it keeps its contrast.
  static const fieldFill = Color(0xFFF1F5F9);

  /// Visible edge for fields, checkboxes and cards.
  static const border = Color(0xFF64748B);

  /// Row dividers and card outlines.
  static const divider = Color(0xFFCBD5E1);

  /// Row highlight when its checkbox is ticked.
  static const selectedRow = Color(0xFFEEF2FF);

  static TextStyle placeholderStyle({double size = 18}) =>
      AdminTypography.bodyMd(color: placeholder).copyWith(fontStyle: FontStyle.italic, fontWeight: FontWeight.w300, fontSize: size);

  static OutlineInputBorder _edge(Color c, double w) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c, width: w));

  /// The app-wide input theme: filled, clear 1px edge, 2px blue focus ring.
  static InputDecorationTheme get inputTheme => InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: fieldFill,
        hintStyle: placeholderStyle(),
        border: _edge(border, 1),
        enabledBorder: _edge(border, 1),
        focusedBorder: _edge(AdminColors.primaryContainer, 2),
        errorBorder: _edge(AdminColors.error, 1.5),
        focusedErrorBorder: _edge(AdminColors.error, 2),
        disabledBorder: _edge(divider, 1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      );

  /// Checkbox with a thick, visible outline when unticked.
  static CheckboxThemeData get checkboxTheme => CheckboxThemeData(
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: WidgetStateBorderSide.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const BorderSide(color: AdminColors.primaryContainer, width: 2)
              : const BorderSide(color: border, width: 2),
        ),
      );

  /// Same field styling for screens that build their own decoration.
  static InputDecoration fieldDecoration({String? hint, Widget? prefixIcon, EdgeInsetsGeometry? contentPadding}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  /// Field label above a field: larger and darker than before.
  static Widget label(String text, {bool required = true}) {
    final style = AdminTypography.bodySm(color: UiContrast.text).copyWith(fontWeight: FontWeight.w700);
    return Text.rich(TextSpan(text: text, style: style, children: [
      if (required) TextSpan(text: ' *', style: style.copyWith(color: AdminColors.error)),
    ]));
  }
}
