import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';

/// The one popup-form style for the Admin Portal (modelled on "Add New
/// Badge"): rounded white card, title with a close button, the form body, then
/// a full-width Cancel / Save button pair. [onSubmit] is never greyed out by
/// the caller — validate inside it and show errors beside the fields.
class AdminFormDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onSubmit;
  final Widget submitChild;
  final VoidCallback? onCancel;
  final bool showCancel;
  final double maxWidth;

  const AdminFormDialog({
    super.key,
    required this.title,
    required this.child,
    required this.onSubmit,
    this.submitChild = const Text('Save'),
    this.onCancel,
    this.showCancel = true,
    this.maxWidth = 520,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminColors.surfaceContainerLowest,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(child: Text(title, style: AdminTypography.headlineSm())),
                IconButton(
                  onPressed: onCancel ?? () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ]),
              const SizedBox(height: 8),
              child,
              const SizedBox(height: 24),
              Row(children: [
                if (showCancel) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel ?? () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: AdminColors.primaryContainer,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel', textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.primaryContainer,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: submitChild,
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

/// The filled, borderless text-field look used inside every admin popup form.
InputDecoration adminFormDecoration({String? hint, Widget? prefixIcon}) => InputDecoration(
      isDense: true,
      hintText: hint,
      prefixIcon: prefixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
