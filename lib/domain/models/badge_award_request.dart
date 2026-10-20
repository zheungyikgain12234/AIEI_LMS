import 'package:stitch_aiei_lms/core/session/app_session.dart';

class BadgeAwardRequestStatus {
  BadgeAwardRequestStatus._();

  static const pending = 'pending';
  static const approved = 'approved';
  static const rejected = 'rejected';
}

/// A student who went above the course passing mark and is waiting for an
/// admin to approve the course's badge for them.
class BadgeAwardRequest {
  final String id;
  final String studentId;
  final String studentName;
  final String courseId;
  final String courseCode;
  final String courseTitle;
  final String badgeId;
  final String badgeCode;
  final String badgeTitle;

  /// The student's final score (%) when the request was raised.
  final double finalScore;
  final String status;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? decidedAt;

  const BadgeAwardRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseCode,
    required this.courseTitle,
    required this.badgeId,
    required this.badgeCode,
    required this.badgeTitle,
    required this.finalScore,
    required this.status,
    required this.createdAt,
    this.adminNote,
    this.decidedAt,
  });

  bool get isPending => status == BadgeAwardRequestStatus.pending;
  bool get isApproved => status == BadgeAwardRequestStatus.approved;

  factory BadgeAwardRequest.fromMap(Map<String, dynamic> map) {
    final student = map['students'] as Map<String, dynamic>?;
    final course = map['courses'] as Map<String, dynamic>?;
    final badge = map['certifications'] as Map<String, dynamic>?;
    return BadgeAwardRequest(
      id: map['id'] as String,
      studentId: (map['student_id'] as num).toString(),
      studentName: student?['name'] as String? ?? '',
      courseId: map['course_id'] as String,
      courseCode: displayCode(course?['course_code'] as String? ?? ''),
      courseTitle: course?['course_title'] as String? ?? '',
      badgeId: map['badge_id'] as String,
      badgeCode: displayCode(badge?['code'] as String? ?? ''),
      badgeTitle: badge?['title'] as String? ?? '',
      finalScore: (map['final_score'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String,
      adminNote: map['admin_note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      decidedAt: map['decided_at'] == null ? null : DateTime.parse(map['decided_at'] as String).toLocal(),
    );
  }
}
