import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import '../controllers/courses_state.dart';

/// Search + sort row for the course grid — category filtering was retired
/// in favor of the real, admin-managed Course Tags row above this bar
/// (see [TagsFilterRow]), which reflects actual data instead of a fixed set
/// of category labels.
class CourseFiltersBar extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final CourseSortOption selectedSort;
  final ValueChanged<CourseSortOption> onSortChanged;
  final List<int> availableYears;
  final int? selectedYear;
  final ValueChanged<int> onYearChanged;
  final List<String> cohortNames;
  final String? selectedCohort;
  final ValueChanged<String> onCohortChanged;
  final bool showYearCohort;

  const CourseFiltersBar({
    this.showYearCohort = true,
    super.key,
    required this.onSearchChanged,
    required this.selectedSort,
    required this.onSortChanged,
    required this.availableYears,
    required this.selectedYear,
    required this.onYearChanged,
    required this.cohortNames,
    required this.selectedCohort,
    required this.onCohortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        if (showYearCohort) ...[_yearDropdown(), _cohortDropdown()],
        // Search Input
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 260),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              onChanged: onSearchChanged,
              style: AppTypography.bodySm(color: AppColors.onSurface),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: AppColors.outline,
                ),
                hintText: 'Filter by title or tag...',
                hintStyle: AppTypography.bodySm(color: AppColors.outline),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ),
              ),
            ),
          ),
        ),

        // Sort Dropdown
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CourseSortOption>(
              value: selectedSort,
              icon: const Icon(
                Icons.expand_more,
                size: 18,
                color: AppColors.outline,
              ),
              borderRadius: BorderRadius.circular(8),
              style: AppTypography.labelMd(color: AppColors.onSurface),
              onChanged: (option) {
                if (option != null) onSortChanged(option);
              },
              items: CourseSortOption.values.map((sort) {
                return DropdownMenuItem<CourseSortOption>(
                  value: sort,
                  child: Text(
                    sort.label,
                    style: AppTypography.labelMd(color: AppColors.onSurface),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _yearDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: availableYears.contains(selectedYear) ? selectedYear : null,
          hint: Text('Year', style: AppTypography.bodySm(color: AppColors.outline)),
          icon: const Icon(Icons.expand_more, size: 18, color: AppColors.outline),
          borderRadius: BorderRadius.circular(8),
          style: AppTypography.labelMd(color: AppColors.onSurface),
          onChanged: (year) {
            if (year != null) onYearChanged(year);
          },
          items: [for (final y in availableYears) DropdownMenuItem(value: y, child: Text('$y'))],
        ),
      ),
    );
  }

  Widget _cohortDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: cohortNames.contains(selectedCohort) ? selectedCohort : null,
          hint: Text('Cohort', style: AppTypography.bodySm(color: AppColors.outline)),
          icon: const Icon(Icons.expand_more, size: 18, color: AppColors.outline),
          borderRadius: BorderRadius.circular(8),
          style: AppTypography.labelMd(color: AppColors.onSurface),
          onChanged: (cohort) {
            if (cohort != null) onCohortChanged(cohort);
          },
          items: [for (final name in cohortNames) DropdownMenuItem(value: name, child: Text(name, overflow: TextOverflow.ellipsis))],
        ),
      ),
    );
  }
}
