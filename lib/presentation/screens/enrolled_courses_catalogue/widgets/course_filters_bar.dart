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

  const CourseFiltersBar({
    super.key,
    required this.onSearchChanged,
    required this.selectedSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
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

        const SizedBox(width: 12),

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
}
