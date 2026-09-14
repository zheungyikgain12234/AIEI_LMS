import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/domain/models/enrolled_course.dart';
import 'course_card.dart';

class CourseGrid extends StatelessWidget {
  final List<EnrolledCourse> courses;
  final ValueChanged<EnrolledCourse>? onCourseAction;

  const CourseGrid({
    super.key,
    required this.courses,
    this.onCourseAction,
  });

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 56,
              color: AppColors.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No courses found',
              style: AppTypography.headlineSm(color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search query or selected filter category.',
              style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount;

        if (width >= 1080) {
          crossAxisCount = 3;
        } else if (width >= 650) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        const double gap = 24;
        final double itemWidth =
            (width - (crossAxisCount - 1) * gap) / crossAxisCount;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: courses.map((course) {
            return SizedBox(
              width: itemWidth,
              child: CourseCard(
                course: course,
                onAction: () => onCourseAction?.call(course),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
