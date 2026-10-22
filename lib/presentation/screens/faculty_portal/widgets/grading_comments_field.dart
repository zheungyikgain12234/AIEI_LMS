import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/presentation/screens/admin_portal/widgets/admin_field_label.dart';

/// Optional comments box shown under all questions/criteria on the marking
/// screens. Capped at [maxLength] characters, with a faint "used/max" counter
/// in the bottom-right corner of the text area.
class GradingCommentsField extends StatelessWidget {
  static const int maxLength = 3500;

  final TextEditingController controller;

  const GradingCommentsField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminFieldLabel('Comments', required: false),
        const SizedBox(height: 6),
        Stack(
          children: [
            TextField(
              controller: controller,
              minLines: 5,
              maxLines: 10,
              inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
              style: FacultyTypography.bodyMd(color: FacultyColors.onSurface),
              decoration: const InputDecoration(
                hintText: 'Optional comments for the student, shown after marking...',
                // Extra bottom room so typed text never runs under the counter.
                contentPadding: EdgeInsets.fromLTRB(12, 14, 12, 30),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 8,
              child: IgnorePointer(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) => Text(
                    '${value.text.length}/$maxLength',
                    style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant).copyWith(fontSize: 16, color: const Color(0xFF8A94A6)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
