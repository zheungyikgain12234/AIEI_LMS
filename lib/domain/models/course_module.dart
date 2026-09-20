/// A module list is scoped to a specific class (a `course_sections` row —
/// its own lecturer/term/schedule), not to the course in the abstract: two
/// different classes of the same course can have different content.
class CourseModule {
  final String id;
  final String sectionId;
  final String name;
  final String description;
  final int sorting;
  final bool isPublished;
  final DateTime? unlockAt;

  const CourseModule({
    required this.id,
    required this.sectionId,
    required this.name,
    required this.description,
    required this.sorting,
    this.isPublished = true,
    this.unlockAt,
  });

  factory CourseModule.fromMap(Map<String, dynamic> map) {
    return CourseModule(
      id: map['id'] as String,
      sectionId: map['section_id'] as String,
      name: map['module_name'] as String,
      description: map['module_description'] as String? ?? '',
      sorting: map['module_sorting'] as int? ?? 0,
      isPublished: map['is_published'] as bool? ?? true,
      unlockAt: map['unlock_at'] != null ? DateTime.parse(map['unlock_at'] as String) : null,
    );
  }
}
