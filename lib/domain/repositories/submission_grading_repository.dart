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

  /// Records that [studentId] is attending a physical exam/assignment (sets
  /// `submission.attended` to true). Unlike [submitAnswer] this never changes
  /// the row's status, so marks already imported for the student stay graded.
  Future<void> recordAttendance({required String contentBlockId, required String studentId});

  /// Sets [studentId]'s attendance for a physical class session, marked by the
  /// lecturer: one of [AttendanceStatus]. Stored as `submission.attendance`.
  Future<void> setAttendanceStatus({required String contentBlockId, required String studentId, required String status});

  /// Records a lecturer's marks for one student's submission — upserts by
  /// (contentBlockId, studentId), setting status to `graded`. Also
  /// recomputes this student's real `student_courses.progress_percentage`
  /// for the course this content block belongs to (graded / total exam+
  /// assignment blocks in that class). Badges are not granted here; they go
  /// through the admin's Badge Approvals.
  Future<void> saveGrade({
    required String contentBlockId,
    required String studentId,
    required Map<String, double> marks,
    String? feedback,
    required double totalScore,
    required String gradedByLecturerId,
  });

  /// Deletes [studentId]'s submission row for [contentBlockId] entirely, so
  /// the exam-answering screen sees no submission and lets them attempt it
  /// again — used by the exam editor's admin-gated "reset a student's
  /// attempt" control. Does not touch `student_courses.progress_percentage`
  /// or any badges already awarded from a prior grade on this block.
  Future<void> resetAttempt({required String contentBlockId, required String studentId});
}

/// The four attendance outcomes a lecturer can mark for a physical class.
class AttendanceStatus {
  AttendanceStatus._();

  static const present = 'present';
  static const late = 'late';
  static const validAbsent = 'valid_absent';
  static const invalidAbsent = 'invalid_absent';

  static const all = [present, late, validAbsent, invalidAbsent];

  static String label(String status) => switch (status) {
        present => 'Present',
        late => 'Late',
        validAbsent => 'Valid absent',
        invalidAbsent => 'Invalid absent',
        _ => status,
      };
}
