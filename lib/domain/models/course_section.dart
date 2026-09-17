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
  final int enrolledCount;
  final String status;

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
    required this.enrolledCount,
    required this.status,
  });

  factory CourseSection.fromMap(Map<String, dynamic> map) {
    final course = map['courses'] as Map<String, dynamic>?;
    final lecturer = map['lecturers'] as Map<String, dynamic>?;
    return CourseSection(
      id: map['id'] as String,
      courseId: map['course_id'] as String,
      courseCode: course?['course_code'] as String? ?? '',
      courseTitle: course?['course_title'] as String? ?? '',
      sectionCode: map['section_code'] as String,
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
      enrolledCount: map['enrolled_count'] as int,
      status: map['status'] as String,
    );
  }
}
