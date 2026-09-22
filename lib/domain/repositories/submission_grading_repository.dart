import 'package:stitch_aiei_lms/domain/models/content_block_submission.dart';

/// Backs the "Mark Assignment"/"Mark Exam" screens — a student's submission
/// and grading result for one exam/assignment content block
/// (`content_block_submissions` table).
abstract class SubmissionGradingRepository {
  /// Every submission recorded for [contentBlockId], keyed by student id —
  /// a student with no submission yet just has no entry. Powers the
  /// roster's status column on the "Mark Assignment"/"Mark Exam" list.
  Future<Map<String, ContentBlockSubmission>> getRosterSubmissions(String contentBlockId);

  Future<ContentBlockSubmission?> getSubmission(String contentBlockId, String studentId);

  /// Records a lecturer's marks for one student's submission — upserts by
  /// (contentBlockId, studentId), setting status to `graded`.
  Future<void> saveGrade({
    required String contentBlockId,
    required String studentId,
    required Map<String, double> marks,
    String? feedback,
    required double totalScore,
    required String gradedByLecturerId,
  });
}
