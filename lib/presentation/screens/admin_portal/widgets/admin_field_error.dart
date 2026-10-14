import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';

/// A small red box shown directly beneath the form field that failed
/// validation. Renders nothing when [message] is null, so it can sit
/// unconditionally under a field.
class AdminFieldError extends StatelessWidget {
  final String? message;

  const AdminFieldError(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: AdminColors.errorContainer, borderRadius: BorderRadius.circular(8)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, size: 16, color: AdminColors.onErrorContainer),
            const SizedBox(width: 6),
            Expanded(child: Text(message!, style: AdminTypography.bodySm(color: AdminColors.onErrorContainer))),
          ],
        ),
      ),
    );
  }
}
