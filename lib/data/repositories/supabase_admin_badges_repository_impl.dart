import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/badge_award.dart';
import 'package:stitch_aiei_lms/domain/repositories/admin_badges_repository.dart';

const _selectWithJoins = '*, students(name), courses(course_code, course_title), certifications(title)';

class SupabaseAdminBadgesRepositoryImpl implements AdminBadgesRepository {
  SupabaseAdminBadgesRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<BadgeAward>> getBadgeAwards() async {
    final rows = await _client.from('badge_awards').select(_selectWithJoins).order('issue_year', ascending: false);
    return [for (final row in rows as List) BadgeAward.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<List<(String, String)>> getBadgeCatalog() async {
    final rows = await _client.from('certifications').select('id, title').order('title');
    return [for (final row in rows as List) (row['id'] as String, row['title'] as String)];
  }

  @override
  Future<BadgeAward> createBadgeAward({
    required String studentId,
    required String courseId,
    required String badgeId,
    required int issueYear,
    required bool isRevoked,
  }) async {
    final row = await _client
        .from('badge_awards')
        .insert({
          'student_id': studentId,
          'course_id': courseId,
          'badge_id': badgeId,
          'issue_year': issueYear,
          'is_revoked': isRevoked,
        })
        .select(_selectWithJoins)
        .single();
    return BadgeAward.fromMap(row);
  }

  @override
  Future<BadgeAward> updateBadgeAward(
    String id, {
    required String studentId,
    required String courseId,
    required String badgeId,
    required int issueYear,
    required bool isRevoked,
  }) async {
    final row = await _client
        .from('badge_awards')
        .update({
          'student_id': studentId,
          'course_id': courseId,
          'badge_id': badgeId,
          'issue_year': issueYear,
          'is_revoked': isRevoked,
        })
        .eq('id', id)
        .select(_selectWithJoins)
        .single();
    return BadgeAward.fromMap(row);
  }

  @override
  Future<void> deleteBadgeAwards(List<String> ids) async {
    await _client.from('badge_awards').delete().inFilter('id', ids);
  }
}
