import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/badge_award_request.dart';

/// Badges are only granted once a student is above the course passing mark
/// and an admin approves it. [syncEligibility] raises the pending requests
/// (called from the lecturer's course dashboard, which knows each student's
/// final score); [decide] is the admin's approval, and the only thing that
/// writes a `badge_awards` row.
class SupabaseBadgeApprovalsRepositoryImpl {
  SupabaseBadgeApprovalsRepositoryImpl(this._client);

  final SupabaseClient _client;

  /// Newest first, with student, course and badge names filled in.
  Future<List<BadgeAwardRequest>> listRequests() async {
    final rows = await _client
        .from('badge_award_requests')
        .select('*, students(name), courses(course_code, course_title), certifications(code, title)')
        .order('created_at', ascending: false);
    return [for (final row in rows as List) BadgeAwardRequest.fromMap(row as Map<String, dynamic>)];
  }

  Future<int> pendingCount() async {
    final rows = await _client.from('badge_award_requests').select('id').eq('status', BadgeAwardRequestStatus.pending);
    return (rows as List).length;
  }

  /// Puts forward every student in [finalScores] (student id -> final score %)
  /// who is above [passingMark] for each badge configured on [courseId], unless
  /// they already hold it or an admin has already decided it. A pending request
  /// for a student who is no longer above the mark is withdrawn.
  Future<void> syncEligibility({
    required String courseId,
    required Map<String, double> finalScores,
    required double passingMark,
  }) async {
    final badgeRows = await _client.from('course_badges').select('badge_id').eq('course_id', courseId);
    final badgeIds = [for (final row in badgeRows as List) row['badge_id'] as String];
    if (badgeIds.isEmpty) return;

    final awardRows = await _client.from('badge_awards').select('student_id, badge_id').eq('course_id', courseId);
    final awarded = {for (final row in awardRows as List) '${row['student_id']}|${row['badge_id']}'};
    final requestRows = await _client.from('badge_award_requests').select('id, student_id, badge_id, status').eq('course_id', courseId);
    final requested = <String, Map<String, dynamic>>{
      for (final row in requestRows as List) '${row['student_id']}|${row['badge_id']}': row as Map<String, dynamic>,
    };

    final toInsert = <Map<String, dynamic>>[];
    final toWithdraw = <String>[];
    for (final entry in finalScores.entries) {
      for (final badgeId in badgeIds) {
        final key = '${entry.key}|$badgeId';
        if (awarded.contains(key)) continue;
        final existing = requested[key];
        if (entry.value > passingMark) {
          if (existing == null) {
            toInsert.add({'student_id': entry.key, 'course_id': courseId, 'badge_id': badgeId, 'final_score': entry.value});
          } else if (existing['status'] == BadgeAwardRequestStatus.pending) {
            await _client.from('badge_award_requests').update({'final_score': entry.value}).eq('id', existing['id'] as String);
          }
        } else if (existing != null && existing['status'] == BadgeAwardRequestStatus.pending) {
          toWithdraw.add(existing['id'] as String);
        }
      }
    }
    // Two syncs can overlap (the dashboard reloads often); a request that another
    // sync just created is simply skipped instead of failing on the unique key.
    if (toInsert.isNotEmpty) {
      await _client.from('badge_award_requests').upsert(toInsert, onConflict: 'student_id,course_id,badge_id', ignoreDuplicates: true);
    }
    if (toWithdraw.isNotEmpty) await _client.from('badge_award_requests').delete().inFilter('id', toWithdraw);
  }

  /// Removes a decided request. Deleting a rejected one lets the student be put
  /// forward again the next time the lecturer's course dashboard syncs, if their
  /// score is still above the passing mark.
  Future<void> deleteRequest(String id) async {
    await _client.from('badge_award_requests').delete().eq('id', id);
  }

  /// Approving grants the badge (once); rejecting needs a reason from the
  /// caller. [note] is the remarks (approve) or the reject reason.
  Future<void> decide(BadgeAwardRequest request, {required bool approved, String? note}) async {
    if (approved) {
      final existing = await _client
          .from('badge_awards')
          .select('id')
          .eq('student_id', request.studentId)
          .eq('course_id', request.courseId)
          .eq('badge_id', request.badgeId);
      if ((existing as List).isEmpty) {
        await _client.from('badge_awards').insert({
          'student_id': request.studentId,
          'course_id': request.courseId,
          'badge_id': request.badgeId,
        });
      }
    }
    await _client.from('badge_award_requests').update({
      'status': approved ? BadgeAwardRequestStatus.approved : BadgeAwardRequestStatus.rejected,
      'admin_note': (note == null || note.trim().isEmpty) ? null : note.trim(),
      'decided_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', request.id);
  }
}
