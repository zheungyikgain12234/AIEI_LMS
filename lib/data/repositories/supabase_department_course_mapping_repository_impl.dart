import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/repositories/department_course_mapping_repository.dart';

class SupabaseDepartmentCourseMappingRepositoryImpl implements DepartmentCourseMappingRepository {
  SupabaseDepartmentCourseMappingRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Set<String>> getCourseIdsForDepartment(String departmentId) async {
    final rows = await _client.from('department_courses').select('course_id').eq('department_id', departmentId);
    return {for (final row in rows as List) row['course_id'] as String};
  }

  @override
  Future<void> setCourseForDepartment(String departmentId, String courseId, bool allowed) async {
    if (allowed) {
      await _client.from('department_courses').upsert(
        {'department_id': departmentId, 'course_id': courseId},
        onConflict: 'department_id,course_id',
      );
    } else {
      await _client.from('department_courses').delete().eq('department_id', departmentId).eq('course_id', courseId);
    }
  }
}
