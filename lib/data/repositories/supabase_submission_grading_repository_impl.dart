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
    await _syncProgressAndBadges(contentBlockId: contentBlockId, studentId: studentId);
  }

  /// Recomputes [studentId]'s real progress for the course [contentBlockId]
  /// belongs to — graded submissions ÷ every exam/assignment block in that
  /// same class (`course_sections`) — and writes it to
  /// `student_courses.progress_percentage`. Once that hits 100%, every
  /// badge configured on the course (`course_badges`) that this student
  /// doesn't already hold is auto-granted via `badge_awards`.
  Future<void> _syncProgressAndBadges({required String contentBlockId, required String studentId}) async {
    final blockRow = await _client.from('content_blocks').select('session_id').eq('id', contentBlockId).maybeSingle();
    final sessionId = blockRow?['session_id'] as String?;
    if (sessionId == null) return;
    final sessionRow = await _client.from('sessions').select('module_id').eq('id', sessionId).maybeSingle();
    final moduleId = sessionRow?['module_id'] as String?;
    if (moduleId == null) return;
    final moduleRow = await _client.from('course_modules').select('section_id').eq('id', moduleId).maybeSingle();
    final sectionId = moduleRow?['section_id'] as String?;
    if (sectionId == null) return;
    final sectionRow = await _client.from('course_sections').select('course_id').eq('id', sectionId).maybeSingle();
    final courseId = sectionRow?['course_id'] as String?;
    if (courseId == null) return;

    // Every exam/assignment block across this section's own modules — the
    // denominator for real progress (same definition the Course Dashboard
    // and My Assigned Courses use on the lecturer side).
    final moduleRows = await _client.from('course_modules').select('id').eq('section_id', sectionId);
    final moduleIds = [for (final m in moduleRows as List) m['id'] as String];
    final sessionRows = moduleIds.isEmpty
        ? const <dynamic>[]
        : await _client.from('sessions').select('id').inFilter('module_id', moduleIds);
    final sessionIds = [for (final s in sessionRows) s['id'] as String];
    final blockRows = sessionIds.isEmpty
        ? const <dynamic>[]
        : await _client
            .from('content_blocks')
            .select('id')
            .inFilter('session_id', sessionIds)
            .inFilter('block_type', ['exam', 'assignment']);
    final blockIds = [for (final b in blockRows) b['id'] as String];
    if (blockIds.isEmpty) return;

    final gradedRows = await _client
        .from('content_block_submissions')
        .select('id')
        .eq('student_id', studentId)
        .eq('status', 'graded')
        .inFilter('content_block_id', blockIds);
    final gradedCount = (gradedRows as List).length;
    final progress = ((gradedCount / blockIds.length) * 100).round();

    await _client
        .from('student_courses')
        .update({'progress_percentage': progress})
        .eq('student_id', studentId)
        .eq('course_id', courseId);

    if (progress < 100) return;

    final courseBadgeRows = await _client.from('course_badges').select('badge_id').eq('course_id', courseId);
    final badgeIds = [for (final row in courseBadgeRows as List) row['badge_id'] as String];
    if (badgeIds.isEmpty) return;

    final existingAwardRows = await _client
        .from('badge_awards')
        .select('badge_id')
        .eq('student_id', studentId)
        .eq('course_id', courseId);
    final alreadyAwarded = {for (final row in existingAwardRows as List) row['badge_id'] as String};
    final toAward = badgeIds.where((id) => !alreadyAwarded.contains(id)).toList();
    if (toAward.isEmpty) return;

    await _client.from('badge_awards').insert([
      for (final badgeId in toAward) {'student_id': studentId, 'course_id': courseId, 'badge_id': badgeId},
    ]);
  }
}
