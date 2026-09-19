import 'package:stitch_aiei_lms/core/session/app_session.dart';

/// A per-course badge award (Manage Badges admin screen) — distinct from the
/// broader `student_certifications` ledger, which has no course reference.
class BadgeAward {
  final String id;
  final String studentId;
  final String studentName;
  final String courseId;
  final String courseCode;
  final String courseTitle;
  final String badgeId;
  final String badgeCode;
  final String badgeTitle;
  final int issueYear;
  final bool isRevoked;

  const BadgeAward({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseCode,
    required this.courseTitle,
    required this.badgeId,
    required this.badgeCode,
    required this.badgeTitle,
    required this.issueYear,
    required this.isRevoked,
  });

  factory BadgeAward.fromMap(Map<String, dynamic> map) {
    final student = map['students'] as Map<String, dynamic>?;
    final course = map['courses'] as Map<String, dynamic>?;
    final badge = map['certifications'] as Map<String, dynamic>?;
    return BadgeAward(
      id: map['id'] as String,
      studentId: (map['student_id'] as num).toString(),
      studentName: student?['name'] as String? ?? '',
      courseId: map['course_id'] as String,
      courseCode: displayCode(course?['course_code'] as String? ?? ''),
      courseTitle: course?['course_title'] as String? ?? '',
      badgeId: map['badge_id'] as String,
      badgeCode: displayCode(badge?['code'] as String? ?? ''),
      badgeTitle: badge?['title'] as String? ?? '',
      issueYear: map['issue_year'] as int,
      isRevoked: map['is_revoked'] as bool,
    );
  }
}
