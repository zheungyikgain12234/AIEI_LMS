class MaterialProgress {
  final String materialId;
  final String status;
  final int? score;
  final int attempts;
  final Map<String, dynamic> submissionContent;
  final String? feedback;
  final String? gradedBy;

  const MaterialProgress({
    required this.materialId,
    required this.status,
    this.score,
    required this.attempts,
    required this.submissionContent,
    this.feedback,
    this.gradedBy,
  });

  factory MaterialProgress.fromMap(Map<String, dynamic> map) {
    return MaterialProgress(
      materialId: map['material_id'] as String,
      status: map['status'] as String,
      score: map['score'] as int?,
      attempts: map['attempts'] as int? ?? 0,
      submissionContent: Map<String, dynamic>.from(map['submission_content'] as Map? ?? {}),
      feedback: map['feedback'] as String?,
      gradedBy: map['graded_by'] as String?,
    );
  }
}
