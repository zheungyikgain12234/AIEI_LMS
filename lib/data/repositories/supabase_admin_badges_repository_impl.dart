import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/session/app_session.dart';
import 'package:stitch_aiei_lms/domain/models/badge_award.dart';
import 'package:stitch_aiei_lms/domain/repositories/admin_badges_repository.dart';

const _selectWithJoins = '*, students(name), courses(course_code, course_title), certifications(code, title)';

class SupabaseAdminBadgesRepositoryImpl implements AdminBadgesRepository {
  SupabaseAdminBadgesRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<BadgeAward>> getBadgeAwards() async {
    final rows = await _client.from('badge_awards').select(_selectWithJoins).order('issue_date', ascending: false);
    return [for (final row in rows as List) BadgeAward.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<List<(String, String, String)>> getBadgeCatalog() async {
    final rows = await _client.from('certifications').select('id, code, title').order('title');
    return [for (final row in rows as List) (row['id'] as String, displayCode(row['code'] as String), row['title'] as String)];
  }

  @override
  Future<BadgeAward> createBadgeAward({
    required String studentId,
    required String courseId,
    required String badgeId,
    required DateTime issueDate,
    required bool isRevoked,
  }) async {
    final row = await _client
        .from('badge_awards')
        .insert({
          'student_id': studentId,
          'course_id': courseId,
          'badge_id': badgeId,
          'issue_date': issueDate.toIso8601String().substring(0, 10),
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
    required DateTime issueDate,
    required bool isRevoked,
  }) async {
    final row = await _client
        .from('badge_awards')
        .update({
          'student_id': studentId,
          'course_id': courseId,
          'badge_id': badgeId,
          'issue_date': issueDate.toIso8601String().substring(0, 10),
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

  @override
  Future<List<(String, int)>> getMonthlyIssueCounts() async {
    final now = DateTime.now();
    final earliest = DateTime(now.year, now.month - 5, 1);
    final rows = await _client
        .from('badge_awards')
        .select('issue_date')
        .eq('is_revoked', false)
        .gte('issue_date', earliest.toIso8601String().substring(0, 10));
    final counts = <String, int>{};
    for (var i = 0; i < 6; i++) {
      final month = DateTime(earliest.year, earliest.month + i, 1);
      counts[_monthKey(month)] = 0;
    }
    for (final row in rows as List) {
      final date = DateTime.parse(row['issue_date'] as String);
      final key = _monthKey(DateTime(date.year, date.month, 1));
      if (counts.containsKey(key)) counts[key] = counts[key]! + 1;
    }
    return [
      for (var i = 0; i < 6; i++)
        (
          _monthLabel(DateTime(earliest.year, earliest.month + i, 1)),
          counts[_monthKey(DateTime(earliest.year, earliest.month + i, 1))]!,
        ),
    ];
  }

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _monthKey(DateTime month) => '${month.year}-${month.month}';
  String _monthLabel(DateTime month) => _monthNames[month.month - 1];
}
