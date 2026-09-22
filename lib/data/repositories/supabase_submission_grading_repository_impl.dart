import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/content_block_submission.dart';
import 'package:stitch_aiei_lms/domain/repositories/submission_grading_repository.dart';

class SupabaseSubmissionGradingRepositoryImpl implements SubmissionGradingRepository {
  SupabaseSubmissionGradingRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, ContentBlockSubmission>> getRosterSubmissions(String contentBlockId) async {
    final rows = await _client.from('content_block_submissions').select().eq('content_block_id', contentBlockId);
    final submissions = [for (final row in rows as List) ContentBlockSubmission.fromMap(row as Map<String, dynamic>)];
    return {for (final s in submissions) s.studentId: s};
  }

  @override
  Future<ContentBlockSubmission?> getSubmission(String contentBlockId, String studentId) async {
    final row = await _client
        .from('content_block_submissions')
        .select()
        .eq('content_block_id', contentBlockId)
        .eq('student_id', studentId)
        .maybeSingle();
    return row == null ? null : ContentBlockSubmission.fromMap(row);
  }

  @override
  Future<void> submitAnswer({
    required String contentBlockId,
    required String studentId,
    required Map<String, dynamic> submission,
  }) async {
    await _client.from('content_block_submissions').upsert(
      {
        'content_block_id': contentBlockId,
        'student_id': studentId,
        'status': 'submitted',
        'submission': submission,
        'submitted_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'content_block_id,student_id',
    );
  }

  @override
  Future<void> saveGrade({
    required String contentBlockId,
    required String studentId,
    required Map<String, double> marks,
    String? feedback,
    required double totalScore,
    required String gradedByLecturerId,
  }) async {
    await _client.from('content_block_submissions').upsert(
      {
        'content_block_id': contentBlockId,
        'student_id': studentId,
        'status': 'graded',
        'marks': marks,
        'total_score': totalScore,
        'feedback': feedback,
        'graded_by': gradedByLecturerId,
        'graded_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'content_block_id,student_id',
    );
  }
}
