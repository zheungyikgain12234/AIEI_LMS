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

  /// Course Tags (`course_tags` → `tags`) — at least one is required.
  final List<String> tagIds;

  /// Badges (`course_badges` → `certifications`) the student unlocks on
  /// completing this course — optional.
  final List<String> badgeIds;

  const AdminCourse({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.courseDescription,
    required this.category,
    this.imageUrl,
    required this.credits,
    this.tagIds = const [],
    this.badgeIds = const [],
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
      tagIds: [
        for (final entry in (map['course_tags'] as List? ?? []))
          if (entry['tag_id'] != null) entry['tag_id'] as String,
      ],
      badgeIds: [
        for (final entry in (map['course_badges'] as List? ?? []))
          if (entry['badge_id'] != null) entry['badge_id'] as String,
      ],
    );
  }
}
