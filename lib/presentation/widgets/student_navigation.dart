import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/presentation/screens/certifications_badges/certifications_badges_screen.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/enrolled_courses_catalogue_screen.dart';
import 'package:stitch_aiei_lms/presentation/screens/my_grades/my_grades_screen.dart';

/// Switches between the student portal's top-level tabs (0 = My Enrolled
/// Courses, 1 = My Badges, 2 = My Grades) shared by the desktop sidebar and
/// the mobile bottom nav. A no-op when [index] is the tab already showing.
void navigateStudentTab(BuildContext context, int index, {required int current}) {
  if (index == current) return;
  final Widget screen = switch (index) {
    0 => const EnrolledCoursesCatalogueScreen(),
    1 => const CertificationsBadgesScreen(),
    _ => const MyGradesScreen(),
  };
  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => screen));
}
