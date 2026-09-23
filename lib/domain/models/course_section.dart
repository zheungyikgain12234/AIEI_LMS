import 'package:stitch_aiei_lms/core/session/app_session.dart';

class CourseSection {
  final String id;
  final String courseId;
  final String courseCode;
  final String courseTitle;
  final String sectionCode;
  final String roleLabel;
  final String term;
  final String scheduleText;
  final String? dayOfWeek;
  final String? startTime;
  final String? endTime;
  final String? location;
  final String? lecturerId;
  final String? lecturerName;
  final int capacity;
  final String deliveryMode;
  final String? cohortId;
  final String? cohort;
  final String? cohortCode;
  final int? cohortYear;
  final int enrolledCount;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;

  const CourseSection({
    required this.id,
    required this.courseId,
    required this.courseCode,
    required this.courseTitle,
    required this.sectionCode,
    required this.roleLabel,
    required this.term,
    required this.scheduleText,
    this.dayOfWeek,
    this.startTime,
    this.endTime,
    this.location,
    this.lecturerId,
    this.lecturerName,
    required this.capacity,
    required this.deliveryMode,
    this.cohortId,
    this.cohort,
    this.cohortCode,
    this.cohortYear,
    required this.enrolledCount,
    required this.status,
    this.startDate,
    this.endDate,
  });

  /// `enrolled_count` is not stored on the `course_sections` row — it's
  /// always computed by counting `student_courses` rows for this section,
  /// so callers must pass it in rather than reading it off [map].
  factory CourseSection.fromMap(Map<String, dynamic> map, {required int enrolledCount}) {
    final course = map['courses'] as Map<String, dynamic>?;
    final lecturer = map['lecturers'] as Map<String, dynamic>?;
    final cohort = map['cohorts'] as Map<String, dynamic>?;
    return CourseSection(
      id: map['id'] as String,
      courseId: map['course_id'] as String,
      courseCode: displayCode(course?['course_code'] as String? ?? ''),
      courseTitle: course?['course_title'] as String? ?? '',
      sectionCode: displayCode(map['section_code'] as String),
      roleLabel: map['role_label'] as String,
      term: map['term'] as String,
      scheduleText: map['schedule_text'] as String,
      dayOfWeek: map['day_of_week'] as String?,
      startTime: map['start_time'] as String?,
      endTime: map['end_time'] as String?,
      location: map['location'] as String?,
      lecturerId: map['lecturer_id'] as String?,
      lecturerName: lecturer?['name'] as String?,
      capacity: map['capacity'] as int,
      deliveryMode: map['delivery_mode'] as String? ?? 'physical',
      cohortId: map['cohort_id'] as String?,
      cohort: cohort?['name'] as String?,
      cohortCode: cohort?['code'] == null ? null : displayCode(cohort!['code'] as String),
      cohortYear: cohort?['year'] as int?,
      enrolledCount: enrolledCount,
      status: map['status'] as String,
      startDate: map['start_date'] == null ? null : DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] == null ? null : DateTime.parse(map['end_date'] as String),
    );
  }
}
