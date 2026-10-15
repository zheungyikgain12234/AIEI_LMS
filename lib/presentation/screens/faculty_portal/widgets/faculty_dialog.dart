import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/presentation/screens/admin_portal/widgets/admin_field_label.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/presentation/screens/admin_portal/widgets/admin_field_error.dart';

/// Popup shell shared by every Lecturer-portal form, matching the admin
/// portal's "Add New Badge" popup: rounded white card, title with a close (X)
/// button, a one-line subtitle, the form, then full-width Cancel / confirm
/// buttons side by side.
///
/// Fields inside pick up the badge popup's look (filled, borderless, rounded)
/// from the theme below, so existing `TextField`s match without changes;
/// prefer [FacultyFormField] for new ones (label above the field).
class FacultyDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final String confirmLabel;

  /// Null disables the confirm button.
  final VoidCallback? onConfirm;
  final String cancelLabel;

  /// Defaults to closing the popup.
  final VoidCallback? onCancel;

  /// False for info-only popups that need just one button.
  final bool showCancel;
  final bool isSaving;

  /// Red confirm button, for delete confirmations.
  final bool destructive;
  final double maxWidth;

  const FacultyDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.confirmLabel = 'Save',
    this.onConfirm,
    this.cancelLabel = 'Cancel',
    this.onCancel,
    this.showCancel = true,
    this.isSaving = false,
    this.destructive = false,
    this.maxWidth = 520,
  });

  @override
  Widget build(BuildContext context) {
    void cancel() => (onCancel ?? () => Navigator.of(context).pop())();
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    final confirmColor = destructive
        ? FacultyColors.error
        : AdminColors.primaryContainer;
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
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: AdminTypography.headlineSm()),
                  ),
                  IconButton(
                    onPressed: isSaving ? null : cancel,
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: AdminTypography.bodyMd()),
              ],
              const SizedBox(height: 20),
              child,
              const SizedBox(height: 24),
              Row(
                children: [
                  if (showCancel) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSaving ? null : cancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: AdminColors.primaryContainer,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: shape,
                        ),
                        child: Text(cancelLabel, textAlign: TextAlign.center),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSaving ? null : onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: shape,
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(confirmLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A form field with its label above it, as in the badge popup. Shows
/// [errorText] in the admin portal's red box beneath the field.
class FacultyFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final String? prefixText;
  final String? suffixText;
  final int maxLines;
  final bool autofocus;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const FacultyFormField({
    super.key,
    required this.controller,
    required this.label,
    this.required = true,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixText,
    this.suffixText,
    this.maxLines = 1,
    this.autofocus = false,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFieldLabel(label, required: required),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          autofocus: autofocus,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: AdminTypography.bodyMd(color: AdminColors.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            helperMaxLines: 3,
            prefixText: prefixText,
            suffixText: suffixText,
          ),
        ),
        AdminFieldError(errorText),
      ],
    );
  }
}

/// Puts a badge-style label above any field (text field, dropdown, ...).
class LabeledField extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;

  const LabeledField({
    super.key,
    required this.label,
    this.required = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFieldLabel(label, required: required),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
