import 'package:stitch_aiei_lms/core/utils/dropdown_sort.dart';
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
  final List<String> semesterNames;
  final String? selectedSemester;
  final ValueChanged<String> onSemesterChanged;
  final bool showYearSemester;

  /// Programmes to filter by; the dropdown is hidden when there are none.
  final List<String> programmeNames;
  final String? selectedProgramme;
  final ValueChanged<String?>? onProgrammeChanged;
  /// How the controls align when they wrap — end beside the tags row on
  /// desktop, start when stacked under it on a phone.
  final WrapAlignment alignment;

  const CourseFiltersBar({
    this.showYearSemester = true,
    this.programmeNames = const [],
    this.selectedProgramme,
    this.onProgrammeChanged,
    this.alignment = WrapAlignment.end,
    super.key,
    required this.onSearchChanged,
    required this.selectedSort,
    required this.onSortChanged,
    required this.availableYears,
    required this.selectedYear,
    required this.onYearChanged,
    required this.semesterNames,
    required this.selectedSemester,
    required this.onSemesterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        if (programmeNames.isNotEmpty) _programmeDropdown(),
        if (showYearSemester) ...[_yearDropdown(), _semesterDropdown()],
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
                border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false,
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
              items: sortDropdownItems(CourseSortOption.values.map((sort) {
                return DropdownMenuItem<CourseSortOption>(
                  value: sort,
                  child: Text(
                    sort.label,
                    style: AppTypography.labelMd(color: AppColors.onSurface),
                  ),
                );
              }).toList()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _programmeDropdown() {
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
          // '' stands for "all programmes".
          value: programmeNames.contains(selectedProgramme) ? selectedProgramme : '',
          icon: const Icon(Icons.expand_more, size: 18, color: AppColors.outline),
          borderRadius: BorderRadius.circular(8),
          style: AppTypography.labelMd(color: AppColors.onSurface),
          onChanged: (value) => onProgrammeChanged?.call(value == null || value.isEmpty ? null : value),
          items: sortDropdownItems([
            DropdownMenuItem(value: '', child: Text('All programmes', style: AppTypography.labelMd(color: AppColors.onSurface))),
            for (final name in programmeNames) DropdownMenuItem(value: name, child: Text(name, overflow: TextOverflow.ellipsis)),
          ]),
        ),
      ),
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
          items: sortDropdownItems([for (final y in availableYears) DropdownMenuItem(value: y, child: Text('$y'))]),
        ),
      ),
    );
  }

  Widget _semesterDropdown() {
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
          value: semesterNames.contains(selectedSemester) ? selectedSemester : null,
          hint: Text('Semester', style: AppTypography.bodySm(color: AppColors.outline)),
          icon: const Icon(Icons.expand_more, size: 18, color: AppColors.outline),
          borderRadius: BorderRadius.circular(8),
          style: AppTypography.labelMd(color: AppColors.onSurface),
          onChanged: (semester) {
            if (semester != null) onSemesterChanged(semester);
          },
          items: sortDropdownItems([for (final name in semesterNames) DropdownMenuItem(value: name, child: Text(name, overflow: TextOverflow.ellipsis))]),
        ),
      ),
    );
  }
}
