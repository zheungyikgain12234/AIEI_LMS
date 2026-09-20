/// A single session within a syllabus module (`sessions` table) — the
/// lecturer-authored timeline unit reached via "Syllabus" on My Assigned
/// Courses. Distinct from `module_materials`/`ModuleMaterial`, which is the
/// existing graded lesson/quiz/assignment system students progress through.
class CourseSession {
  final String id;
  final String moduleId;
  final String name;
  final String description;
  final int sorting;
  final bool isPublished;

  const CourseSession({
    required this.id,
    required this.moduleId,
    required this.name,
    required this.description,
    required this.sorting,
    this.isPublished = true,
  });

  factory CourseSession.fromMap(Map<String, dynamic> map) {
    return CourseSession(
      id: map['id'] as String,
      moduleId: map['module_id'] as String,
      name: map['session_name'] as String,
      description: map['session_description'] as String? ?? '',
      sorting: map['session_sorting'] as int? ?? 0,
      isPublished: map['is_published'] as bool? ?? true,
    );
  }
}
