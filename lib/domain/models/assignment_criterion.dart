/// One grading criterion for an `assignment` content block (`assignment_criteria`
/// table) — a flat rubric row of "worth this many marks", set up from "Edit
/// Assignment" and scored per-student on the "Mark Assignment" screen.
class AssignmentCriterion {
  final String id;
  final String contentBlockId;
  final String label;
  final double maxMarks;
  final int sorting;

  const AssignmentCriterion({
    required this.id,
    required this.contentBlockId,
    required this.label,
    required this.maxMarks,
    required this.sorting,
  });

  factory AssignmentCriterion.fromMap(Map<String, dynamic> map) {
    return AssignmentCriterion(
      id: map['id'] as String,
      contentBlockId: map['content_block_id'] as String,
      label: map['criterion_label'] as String? ?? '',
      maxMarks: (map['max_marks'] as num?)?.toDouble() ?? 0,
      sorting: map['criterion_sorting'] as int? ?? 0,
    );
  }
}
