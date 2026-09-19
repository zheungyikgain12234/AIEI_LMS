import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/repositories/specialization_course_mapping_repository.dart';

class SupabaseSpecializationCourseMappingRepositoryImpl implements SpecializationCourseMappingRepository {
  SupabaseSpecializationCourseMappingRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Set<String>> getCourseIdsForSpecialization(String specializationId) async {
    final rows = await _client.from('specialization_courses').select('course_id').eq('specialization_id', specializationId);
    return {for (final row in rows as List) row['course_id'] as String};
  }

  @override
  Future<void> setCourseForSpecialization(String specializationId, String courseId, bool allowed) async {
    if (allowed) {
      await _client.from('specialization_courses').upsert(
        {'specialization_id': specializationId, 'course_id': courseId},
        onConflict: 'specialization_id,course_id',
      );
    } else {
      await _client.from('specialization_courses').delete().eq('specialization_id', specializationId).eq('course_id', courseId);
    }
  }
}
