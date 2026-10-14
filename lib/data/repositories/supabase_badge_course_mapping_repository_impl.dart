import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/repositories/badge_course_mapping_repository.dart';

class SupabaseBadgeCourseMappingRepositoryImpl implements BadgeCourseMappingRepository {
  SupabaseBadgeCourseMappingRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Set<String>> getCourseIdsForBadge(String badgeId) async {
    final rows = await _client.from('course_badges').select('course_id').eq('badge_id', badgeId);
    return {for (final row in rows as List) row['course_id'] as String};
  }

  @override
  Future<Set<String>> getBadgeIdsForCourse(String courseId) async {
    final rows = await _client.from('course_badges').select('badge_id').eq('course_id', courseId);
    return {for (final row in rows as List) row['badge_id'] as String};
  }

  @override
  Future<void> setCourseForBadge(String badgeId, String courseId, bool allowed) async {
    if (allowed) {
      await _client.from('course_badges').upsert(
        {'course_id': courseId, 'badge_id': badgeId},
        onConflict: 'course_id,badge_id',
      );
    } else {
      await _client.from('course_badges').delete().eq('course_id', courseId).eq('badge_id', badgeId);
    }
  }
}
