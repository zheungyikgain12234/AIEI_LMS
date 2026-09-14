import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/domain/models/enrolled_course.dart';
import '../controllers/courses_state.dart';

class CourseFiltersBar extends StatelessWidget {
  final CourseCategory selectedCategory;
  final ValueChanged<CourseCategory> onSelectCategory;
  final ValueChanged<String> onSearchChanged;
  final CourseSortOption selectedSort;
  final ValueChanged<CourseSortOption> onSortChanged;
  final int Function(CourseCategory) countForCategory;

  const CourseFiltersBar({
    super.key,
    required this.selectedCategory,
    required this.onSelectCategory,
    required this.onSearchChanged,
    required this.selectedSort,
    required this.onSortChanged,
    required this.countForCategory,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        final filterPills = Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: CourseCategory.values.map((category) {
            final isSelected = category == selectedCategory;
            final count = countForCategory(category);

            return _FilterPill(
              label: category.label,
              count: count,
              isSelected: isSelected,
              onTap: () => onSelectCategory(category),
            );
          }).toList(),
        );

        final searchAndSort = Row(
          mainAxisSize: MainAxisSize.min,
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

        if (isWide) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: filterPills),
              const SizedBox(width: 16),
              searchAndSort,
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              filterPills,
              const SizedBox(height: 16),
              searchAndSort,
            ],
          );
        }
      },
    );
  }
}

class _FilterPill extends StatefulWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FilterPill> createState() => _FilterPillState();
}

class _FilterPillState extends State<_FilterPill> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    final Color bgColor;
    final Color textColor;
    final Color badgeBg;
    final Color badgeText;

    if (isSelected) {
      bgColor = AppColors.secondary;
      textColor = AppColors.onSecondary;
      badgeBg = Colors.white.withValues(alpha: 0.2);
      badgeText = AppColors.onSecondary;
    } else if (_isHovered) {
      bgColor = AppColors.surfaceContainerLow;
      textColor = AppColors.onSurface;
      badgeBg = AppColors.surfaceContainer;
      badgeText = AppColors.onSurfaceVariant;
    } else {
      bgColor = AppColors.surfaceContainerLowest;
      textColor = AppColors.onSurfaceVariant;
      badgeBg = AppColors.surfaceContainer;
      badgeText = AppColors.onSurfaceVariant;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: AppTypography.labelMd(color: textColor),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  '${widget.count}',
                  style: AppTypography.labelSm(color: badgeText).copyWith(
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
