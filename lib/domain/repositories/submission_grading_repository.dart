import 'package:stitch_aiei_lms/domain/models/content_block_submission.dart';

/// Backs both sides of exam/assignment submissions for one content block
/// (`content_block_submissions` table): the student's "View Exam"/"View
/// Assignment" submit flow, and the lecturer's "Mark Assignment"/"Mark
/// Exam" screens.
abstract class SubmissionGradingRepository {
  /// Every submission recorded for [contentBlockId], keyed by student id —
  /// a student with no submission yet just has no entry. Powers the
  /// roster's status column on the "Mark Assignment"/"Mark Exam" list.
  Future<Map<String, ContentBlockSubmission>> getRosterSubmissions(String contentBlockId);

  Future<ContentBlockSubmission?> getSubmission(String contentBlockId, String studentId);

  /// Records a student's answer/writeup — upserts by (contentBlockId,
  /// studentId), setting status to `submitted` and `submitted_at` to now.
  /// Leaves any existing marks/feedback/grading fields untouched (a
  /// resubmission doesn't erase a prior grade; the lecturer re-grades it).
  Future<void> submitAnswer({
    required String contentBlockId,
    required String studentId,
    required Map<String, dynamic> submission,
  });

  /// Records a lecturer's marks for one student's submission — upserts by
  /// (contentBlockId, studentId), setting status to `graded`. Also
  /// recomputes this student's real `student_courses.progress_percentage`
  /// for the course this content block belongs to (graded / total exam+
  /// assignment blocks in that class), and — once that reaches 100% —
  /// auto-grants every badge configured on the course (`course_badges`)
  /// that this student doesn't already hold, by inserting into
  /// `badge_awards`.
  Future<void> saveGrade({
    required String contentBlockId,
    required String studentId,
    required Map<String, double> marks,
    String? feedback,
    required double totalScore,
    required String gradedByLecturerId,
  });
}
