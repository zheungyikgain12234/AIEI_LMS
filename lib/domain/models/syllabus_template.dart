/// A saved, reusable module → session → content-block tree ("Save as
/// Template" / "Copy from Template" on the Syllabus screen), independent of
/// any one class so it can be copied into any class's syllabus.
class SyllabusTemplate {
  final String id;
  final String name;
  final DateTime createdAt;

  const SyllabusTemplate({required this.id, required this.name, required this.createdAt});

  factory SyllabusTemplate.fromMap(Map<String, dynamic> map) {
    return SyllabusTemplate(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
