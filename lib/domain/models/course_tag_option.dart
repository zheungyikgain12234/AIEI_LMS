/// One row of the Course Tags master data (`tags` table) — admin-managed,
/// a single unique label. Courses attach any number of these via
/// `course_tags`; `color_hex`/`icon_name` are left at their schema defaults
/// since the admin form only exposes the label.
class CourseTagOption {
  final String id;
  final String label;

  const CourseTagOption({required this.id, required this.label});

  factory CourseTagOption.fromMap(Map<String, dynamic> map) {
    return CourseTagOption(id: map['id'] as String, label: map['label'] as String);
  }
}
