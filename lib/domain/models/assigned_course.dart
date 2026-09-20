import 'package:stitch_aiei_lms/core/session/app_session.dart';

class AssignedCourse {
  final String sectionId;
  final String courseId;
  final String courseCode;
  final String title;
  final String description;
  final String roleLabel;
  final String sectionCode;
  final String scheduleText;
  final int capacity;
  final int enrolledCount;
  final String? cohort;

  const AssignedCourse({
    required this.sectionId,
    required this.courseId,
    required this.courseCode,
    required this.title,
    required this.description,
    required this.roleLabel,
    required this.sectionCode,
    required this.scheduleText,
    required this.capacity,
    required this.enrolledCount,
    this.cohort,
  });

  /// `enrolled_count` is not stored on the `course_sections` row — it's
  /// always computed by counting `student_courses` rows for this section,
  /// so callers must pass it in rather than reading it off [map].
  factory AssignedCourse.fromMap(Map<String, dynamic> map, {required int enrolledCount}) {
    final course = map['courses'] as Map<String, dynamic>;
    return AssignedCourse(
      sectionId: map['id'] as String,
      courseId: course['id'] as String,
      courseCode: displayCode(course['course_code'] as String),
      title: course['course_title'] as String,
      description: course['course_description'] as String,
      roleLabel: map['role_label'] as String,
      sectionCode: displayCode(map['section_code'] as String),
      scheduleText: map['schedule_text'] as String,
      capacity: map['capacity'] as int,
      enrolledCount: enrolledCount,
      cohort: (map['cohorts'] as Map<String, dynamic>?)?['name'] as String?,
    );
  }
}
