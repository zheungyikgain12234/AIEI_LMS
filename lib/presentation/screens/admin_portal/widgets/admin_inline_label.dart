import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';

/// A label with a dropdown or field beside it. When the space is narrow (a
/// phone) the label sits above the field instead, so the field keeps the full
/// width rather than being squeezed next to the label.
class AdminInlineLabel extends StatelessWidget {
  final String label;
  final Widget field;

  const AdminInlineLabel({super.key, required this.label, required this.field});

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: AdminTypography.labelMd(color: AdminColors.onSurfaceVariant),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [text, const SizedBox(height: 6), field],
          );
        }
        return Row(
          children: [
            text,
            const SizedBox(width: 12),
            Expanded(child: field),
          ],
        );
      },
    );
  }
}
