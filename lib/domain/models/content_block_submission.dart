/// A student's submission + grading result for one exam/assignment content
/// block (`content_block_submissions` table) — backs the "Mark
/// Assignment"/"Mark Exam" screens. `submission` and `marks` are free-form
/// jsonb whose shape depends on the content block's type:
/// - assignment `submission`: `{"writeup": "...", "files": [{"name","sizeLabel"}]}`
/// - assignment `marks`: `{"<criterionId>": marksAwarded}`
/// - exam `submission`: `{"answers": [{"questionId","selectedOptionIds":[...],"textAnswer"}]}`
/// - exam `marks`: `{"<questionId>": marksAwarded}`
class ContentBlockSubmission {
  final String id;
  final String contentBlockId;
  final String studentId;
  final String status;
  final Map<String, dynamic> submission;
  final Map<String, double> marks;
  final double? totalScore;
  final String? feedback;
  final DateTime? submittedAt;
  final String? gradedBy;
  final DateTime? gradedAt;

  const ContentBlockSubmission({
    required this.id,
    required this.contentBlockId,
    required this.studentId,
    required this.status,
    required this.submission,
    required this.marks,
    this.totalScore,
    this.feedback,
    this.submittedAt,
    this.gradedBy,
    this.gradedAt,
  });

  bool get isGraded => status == 'graded';

  factory ContentBlockSubmission.fromMap(Map<String, dynamic> map) {
    final rawMarks = Map<String, dynamic>.from(map['marks'] as Map? ?? {});
    return ContentBlockSubmission(
      id: map['id'] as String,
      contentBlockId: map['content_block_id'] as String,
      studentId: (map['student_id'] as num).toString(),
      status: map['status'] as String? ?? 'not_started',
      submission: Map<String, dynamic>.from(map['submission'] as Map? ?? {}),
      marks: {for (final entry in rawMarks.entries) entry.key: (entry.value as num).toDouble()},
      totalScore: (map['total_score'] as num?)?.toDouble(),
      feedback: map['feedback'] as String?,
      submittedAt: map['submitted_at'] == null ? null : DateTime.tryParse(map['submitted_at'] as String),
      gradedBy: map['graded_by'] as String?,
      gradedAt: map['graded_at'] == null ? null : DateTime.tryParse(map['graded_at'] as String),
    );
  }
}
