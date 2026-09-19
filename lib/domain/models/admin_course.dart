import 'package:stitch_aiei_lms/core/session/app_session.dart';

/// A course as managed from the Admin Portal's Manage Courses screen — the
/// full row shape (unlike the leaner catalogue-facing [Course] model), used
/// so lecturer/section assignment can be built against these later.
///
/// Schedule and capacity are class-level concerns (see [CourseSection]),
/// not course-level, so they don't live here.
class AdminCourse {
  final String id;
  final String courseCode;
  final String courseTitle;
  final String courseDescription;
  final String category;
  final String? imageUrl;
  final int credits;

  const AdminCourse({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.courseDescription,
    required this.category,
    this.imageUrl,
    required this.credits,
  });

  factory AdminCourse.fromMap(Map<String, dynamic> map) {
    return AdminCourse(
      id: map['id'] as String,
      courseCode: displayCode(map['course_code'] as String),
      courseTitle: map['course_title'] as String,
      courseDescription: map['course_description'] as String,
      category: map['category'] as String,
      imageUrl: map['image_url'] as String?,
      credits: map['credits'] as int,
    );
  }
}
