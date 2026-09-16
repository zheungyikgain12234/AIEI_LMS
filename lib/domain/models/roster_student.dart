/// A student's enrollment row in one course — powers both the Admin
/// "Course Enrollment" roster and the Faculty "Student Directory" /
/// "Course Dashboard" rosters (same underlying `student_courses` join).
class RosterStudent {
  final String studentId;
  final String name;
  final String? title;
  final String employeeId;
  final String email;
  final int progressPercentage;
  final String? grade;
  final double? overallScore;
  final int attendancePercentage;
  final String riskStatus;
  final String sponsorship;
  final DateTime lastActivityAt;
  final bool isOnlineNow;
  final DateTime enrolledAt;

  const RosterStudent({
    required this.studentId,
    required this.name,
    this.title,
    required this.employeeId,
    required this.email,
    required this.progressPercentage,
    this.grade,
    this.overallScore,
    required this.attendancePercentage,
    required this.riskStatus,
    required this.sponsorship,
    required this.lastActivityAt,
    required this.isOnlineNow,
    required this.enrolledAt,
  });

  factory RosterStudent.fromMap(Map<String, dynamic> map) {
    final student = map['students'] as Map<String, dynamic>;
    return RosterStudent(
      studentId: student['id'] as String,
      name: student['name'] as String,
      title: student['title'] as String?,
      employeeId: student['student_id'] as String,
      email: student['email'] as String,
      progressPercentage: map['progress_percentage'] as int,
      grade: map['grade'] as String?,
      overallScore: (map['overall_score'] as num?)?.toDouble(),
      attendancePercentage: map['attendance_percentage'] as int,
      riskStatus: map['risk_status'] as String,
      sponsorship: map['sponsorship'] as String? ?? 'Self-Enrolled',
      lastActivityAt: DateTime.parse(map['last_activity_at'] as String),
      isOnlineNow: map['is_online_now'] as bool? ?? false,
      enrolledAt: DateTime.parse(map['enrolled_at'] as String),
    );
  }
}
