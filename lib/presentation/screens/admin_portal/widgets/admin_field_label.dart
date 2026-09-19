import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';

/// A form field label, with a red asterisk appended when [required] is true
/// (every compulsory admin-form field must show one).
class AdminFieldLabel extends StatelessWidget {
  final String label;
  final bool required;

  const AdminFieldLabel(this.label, {super.key, this.required = true});

  @override
  Widget build(BuildContext context) {
    final style = AdminTypography.labelMd(color: AdminColors.onSurfaceVariant);
    if (!required) return Text(label, style: style);
    return Text.rich(
      TextSpan(text: label, style: style, children: [
        TextSpan(text: ' *', style: style.copyWith(color: AdminColors.error)),
      ]),
    );
  }
}
