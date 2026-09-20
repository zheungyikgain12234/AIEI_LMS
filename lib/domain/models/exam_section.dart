/// A section of an exam (`exam_sections` table) — the exam-editor
/// equivalent of a syllabus module, holding any number of [ExamQuestion]s.
class ExamSection {
  final String id;
  final String contentBlockId;
  final String name;
  final int sorting;

  const ExamSection({
    required this.id,
    required this.contentBlockId,
    required this.name,
    required this.sorting,
  });

  factory ExamSection.fromMap(Map<String, dynamic> map) {
    return ExamSection(
      id: map['id'] as String,
      contentBlockId: map['content_block_id'] as String,
      name: map['section_name'] as String,
      sorting: map['section_sorting'] as int? ?? 0,
    );
  }
}
