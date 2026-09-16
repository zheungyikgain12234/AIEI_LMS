class CourseModule {
  final String id;
  final String courseId;
  final String name;
  final String description;
  final int sorting;
  final bool isPublished;
  final DateTime? unlockAt;

  const CourseModule({
    required this.id,
    required this.courseId,
    required this.name,
    required this.description,
    required this.sorting,
    this.isPublished = true,
    this.unlockAt,
  });

  factory CourseModule.fromMap(Map<String, dynamic> map) {
    return CourseModule(
      id: map['id'] as String,
      courseId: map['course_id'] as String,
      name: map['module_name'] as String,
      description: map['module_description'] as String? ?? '',
      sorting: map['module_sorting'] as int? ?? 0,
      isPublished: map['is_published'] as bool? ?? true,
      unlockAt: map['unlock_at'] != null ? DateTime.parse(map['unlock_at'] as String) : null,
    );
  }
}
