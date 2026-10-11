class EnrollmentCandidate {
  final String id;
  final String studentName;
  final String? studentEmployeeId;
  final String studentEmail;
  final String department;
  final String cohort;
  final String? role;
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
    this.role,
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

  /// An eligible candidate is simply a registered student not yet enrolled
  /// in the target course; the review fields have no backing data and keep
  /// their neutral defaults.
  factory EnrollmentCandidate.fromStudent(Map<String, dynamic> map, {required String courseId}) {
    return EnrollmentCandidate(
      id: '${map['id']}',
      studentName: map['name'] as String,
      studentEmployeeId: map['student_code'] as String?,
      studentEmail: map['email'] as String,
      department: (map['department'] ?? map['program_track']) as String? ?? '',
      cohort: map['cohort'] as String? ?? '',
      role: map['role'] as String?,
      targetCourseId: courseId,
      prerequisiteStatus: 'met',
      prerequisiteDetail: '',
      standingDetail: 'Academic Good Standing',
      sponsorship: 'Self-Enrolled',
      queueTag: null,
      needsReview: false,
      requestedAt: DateTime.now(),
    );
  }
}
