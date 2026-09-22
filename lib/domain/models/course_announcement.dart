class CourseAnnouncement {
  final String id;
  final String sectionId;
  final String lecturerId;
  final String lecturerName;
  final String title;
  final String body;
  final DateTime createdAt;

  const CourseAnnouncement({
    required this.id,
    required this.sectionId,
    required this.lecturerId,
    required this.lecturerName,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory CourseAnnouncement.fromMap(Map<String, dynamic> map) {
    return CourseAnnouncement(
      id: map['id'] as String,
      sectionId: map['section_id'] as String,
      lecturerId: map['lecturer_id'] as String,
      lecturerName: (map['lecturers'] as Map<String, dynamic>?)?['name'] as String? ?? 'Lecturer',
      title: map['title'] as String,
      body: map['body'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
