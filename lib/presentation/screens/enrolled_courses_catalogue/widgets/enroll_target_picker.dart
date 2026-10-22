import 'package:stitch_aiei_lms/core/utils/dropdown_sort.dart';
import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';

/// "Enroll into: [Year] [Semester]" picker for the Compulsory for You section.
/// Deliberately styled apart from the filter controls — it doesn't filter the
/// list, it only chooses which semester's class "Enroll Now" puts the student in.
class EnrollTargetPicker extends StatelessWidget {
  final List<int> years;
  final int? selectedYear;
  final ValueChanged<int> onYearChanged;
  final List<String> semesterNames;
  final String? selectedSemester;
  final ValueChanged<String> onSemesterChanged;

  const EnrollTargetPicker({
    super.key,
    required this.years,
    required this.selectedYear,
    required this.onYearChanged,
    required this.semesterNames,
    required this.selectedSemester,
    required this.onSemesterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.how_to_reg_outlined, size: 16, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 6),
            Text('Enroll into:', style: AppTypography.labelMd(color: AppColors.onSurfaceVariant)),
          ]),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: years.contains(selectedYear) ? selectedYear : null,
              hint: Text('Year', style: AppTypography.bodySm(color: AppColors.outline)),
              icon: const Icon(Icons.expand_more, size: 18, color: AppColors.outline),
              style: AppTypography.labelMd(color: AppColors.onSurface),
              onChanged: (y) {
                if (y != null) onYearChanged(y);
              },
              items: sortDropdownItems([for (final y in years) DropdownMenuItem(value: y, child: Text('$y'))]),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: semesterNames.contains(selectedSemester) ? selectedSemester : null,
              hint: Text('Semester', style: AppTypography.bodySm(color: AppColors.outline)),
              icon: const Icon(Icons.expand_more, size: 18, color: AppColors.outline),
              style: AppTypography.labelMd(color: AppColors.onSurface),
              onChanged: (c) {
                if (c != null) onSemesterChanged(c);
              },
              items: sortDropdownItems([for (final n in semesterNames) DropdownMenuItem(value: n, child: Text(n, overflow: TextOverflow.ellipsis))]),
            ),
          ),
        ],
      ),
    );
  }
}
