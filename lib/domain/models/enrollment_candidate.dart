class EnrollmentCandidate {
  final String id;
  final String studentName;
  final String? studentEmployeeId;
  final String studentEmail;
  final String department;
  final String cohort;
  final String targetCourseId;
  final String prerequisiteStatus;
  final String prerequisiteDetail;
  final String standingDetail;
  final String sponsorship;
  final String? queueTag;
  final bool needsReview;
  final DateTime requestedAt;

  const EnrollmentCandidate({
    required this.id,
    required this.studentName,
    this.studentEmployeeId,
    required this.studentEmail,
    required this.department,
    required this.cohort,
    required this.targetCourseId,
    required this.prerequisiteStatus,
    required this.prerequisiteDetail,
    required this.standingDetail,
    required this.sponsorship,
    this.queueTag,
    required this.needsReview,
    required this.requestedAt,
  });

  String get initials {
    final parts = studentName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  factory EnrollmentCandidate.fromMap(Map<String, dynamic> map) {
    return EnrollmentCandidate(
      id: map['id'] as String,
      studentName: map['student_name'] as String,
      studentEmployeeId: map['student_employee_id'] as String?,
      studentEmail: map['student_email'] as String,
      department: map['department'] as String? ?? '',
      cohort: map['cohort'] as String? ?? '',
      targetCourseId: map['target_course_id'] as String,
      prerequisiteStatus: map['prerequisite_status'] as String,
      prerequisiteDetail: map['prerequisite_detail'] as String? ?? '',
      standingDetail: map['standing_detail'] as String? ?? 'Academic Good Standing',
      sponsorship: map['sponsorship'] as String? ?? 'Self-Enrolled',
      queueTag: map['queue_tag'] as String?,
      needsReview: map['needs_review'] as bool? ?? false,
      requestedAt: DateTime.parse(map['requested_at'] as String),
    );
  }
}
