import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';

/// "Enroll into: [Year] [Cohort]" picker for the Compulsory for You section.
/// Deliberately styled apart from the filter controls — it doesn't filter the
/// list, it only chooses which cohort's class "Enroll Now" puts the student in.
class EnrollTargetPicker extends StatelessWidget {
  final List<int> years;
  final int? selectedYear;
  final ValueChanged<int> onYearChanged;
  final List<String> cohortNames;
  final String? selectedCohort;
  final ValueChanged<String> onCohortChanged;

  const EnrollTargetPicker({
    super.key,
    required this.years,
    required this.selectedYear,
    required this.onYearChanged,
    required this.cohortNames,
    required this.selectedCohort,
    required this.onCohortChanged,
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
              items: [for (final y in years) DropdownMenuItem(value: y, child: Text('$y'))],
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: cohortNames.contains(selectedCohort) ? selectedCohort : null,
              hint: Text('Cohort', style: AppTypography.bodySm(color: AppColors.outline)),
              icon: const Icon(Icons.expand_more, size: 18, color: AppColors.outline),
              style: AppTypography.labelMd(color: AppColors.onSurface),
              onChanged: (c) {
                if (c != null) onCohortChanged(c);
              },
              items: [for (final n in cohortNames) DropdownMenuItem(value: n, child: Text(n, overflow: TextOverflow.ellipsis))],
            ),
          ),
        ],
      ),
    );
  }
}
