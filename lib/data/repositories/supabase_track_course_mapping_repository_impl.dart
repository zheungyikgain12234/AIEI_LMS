import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/repositories/track_course_mapping_repository.dart';

class SupabaseTrackCourseMappingRepositoryImpl implements TrackCourseMappingRepository {
  SupabaseTrackCourseMappingRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Set<String>> getCourseIdsForTrack(String trackId) async {
    final rows = await _client.from('track_courses').select('course_id').eq('track_id', trackId);
    return {for (final row in rows as List) row['course_id'] as String};
  }

  @override
  Future<void> setCourseForTrack(String trackId, String courseId, bool allowed) async {
    if (allowed) {
      await _client.from('track_courses').upsert(
        {'track_id': trackId, 'course_id': courseId},
        onConflict: 'track_id,course_id',
      );
    } else {
      await _client.from('track_courses').delete().eq('track_id', trackId).eq('course_id', courseId);
    }
  }
}
