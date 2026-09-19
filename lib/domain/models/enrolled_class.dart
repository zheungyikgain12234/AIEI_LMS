import 'package:stitch_aiei_lms/core/session/app_session.dart';

/// A class a student is currently enrolled in (Manage Enrolled Courses
/// screen) — a `student_courses` row joined with its course and, when the
/// enrollment was made via a specific section, that section's code.
class EnrolledClass {
  final String courseId;
  final String courseCode;
  final String courseTitle;
  final String? sectionId;
  final String? sectionCode;

  const EnrolledClass({
    required this.courseId,
    required this.courseCode,
    required this.courseTitle,
    this.sectionId,
    this.sectionCode,
  });

  /// Prefers the section code (e.g. `OSHE-101-01`) when the enrollment is
  /// tied to a specific class; falls back to the course code otherwise.
  String get displayName => sectionCode ?? courseCode;

  factory EnrolledClass.fromMap(Map<String, dynamic> map) {
    final course = map['courses'] as Map<String, dynamic>?;
    final section = map['course_sections'] as Map<String, dynamic>?;
    return EnrolledClass(
      courseId: map['course_id'] as String,
      courseCode: displayCode(course?['course_code'] as String? ?? ''),
      courseTitle: course?['course_title'] as String? ?? '',
      sectionId: map['section_id'] as String?,
      sectionCode: section?['section_code'] == null ? null : displayCode(section!['section_code'] as String),
    );
  }
}
