/// One real, ungraded assignment/quiz for the signed-in student, still
/// awaiting submission, with a due date — the "Critical Action" box on the
/// Enrolled Courses page shows the two of these with the nearest due dates
/// (soonest/overdue first), sourced from `content_blocks`/
/// `content_block_submissions`, not fabricated demo copy.
class CriticalActionItem {
  final String contentBlockId;
  final String sectionId;
  final String courseTitle;
  final String title;

  /// 'exam' or 'assignment' (`content_blocks.block_type`).
  final String type;
  final DateTime dueDate;

  const CriticalActionItem({
    required this.contentBlockId,
    required this.sectionId,
    required this.courseTitle,
    required this.title,
    required this.type,
    required this.dueDate,
  });

  bool get isOverdue => dueDate.isBefore(DateTime.now());
}
