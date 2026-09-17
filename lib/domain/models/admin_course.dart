/// A course as managed from the Admin Portal's Manage Courses screen — the
/// full row shape (unlike the leaner catalogue-facing [Course] model), used
/// so lecturer/section assignment can be built against these later.
class AdminCourse {
  final String id;
  final String courseCode;
  final String courseTitle;
  final String courseDescription;
  final String category;
  final String? imageUrl;
  final String scheduleText;
  final int capacity;
  final int credits;

  const AdminCourse({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.courseDescription,
    required this.category,
    this.imageUrl,
    required this.scheduleText,
    required this.capacity,
    required this.credits,
  });

  factory AdminCourse.fromMap(Map<String, dynamic> map) {
    return AdminCourse(
      id: map['id'] as String,
      courseCode: map['course_code'] as String,
      courseTitle: map['course_title'] as String,
      courseDescription: map['course_description'] as String,
      category: map['category'] as String,
      imageUrl: map['image_url'] as String?,
      scheduleText: map['schedule_text'] as String,
      capacity: map['capacity'] as int,
      credits: map['credits'] as int,
    );
  }
}
