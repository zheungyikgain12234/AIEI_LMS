import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/repositories/role_course_mapping_repository.dart';

class SupabaseRoleCourseMappingRepositoryImpl implements RoleCourseMappingRepository {
  SupabaseRoleCourseMappingRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Set<String>> getCourseIdsForRole(String roleId) async {
    final rows = await _client.from('role_courses').select('course_id').eq('role_id', roleId);
    return {for (final row in rows as List) row['course_id'] as String};
  }

  @override
  Future<void> setCourseForRole(String roleId, String courseId, bool allowed) async {
    if (allowed) {
      await _client.from('role_courses').upsert(
        {'role_id': roleId, 'course_id': courseId},
        onConflict: 'role_id,course_id',
      );
    } else {
      await _client.from('role_courses').delete().eq('role_id', roleId).eq('course_id', courseId);
    }
  }
}
