import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';

/// A record's code, shown as plain text above an Edit form. Codes are set
/// once at creation and can never be changed, so they are not an input.
class AdminFixedCode extends StatelessWidget {
  final String label;
  final String value;

  const AdminFixedCode({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$label: ', style: AdminTypography.labelMd(color: AdminColors.onSurfaceVariant)),
            TextSpan(text: value, style: AdminTypography.titleSm(color: AdminColors.onSurface)),
          ],
        ),
      ),
    );
  }
}
