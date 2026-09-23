import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/course_tag_option.dart';
import 'package:stitch_aiei_lms/domain/repositories/admin_course_tags_repository.dart';

class SupabaseAdminCourseTagsRepositoryImpl implements AdminCourseTagsRepository {
  SupabaseAdminCourseTagsRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CourseTagOption>> getTags() async {
    final rows = await _client.from('tags').select('id, label').order('label');
    return [for (final row in rows as List) CourseTagOption.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<CourseTagOption> createTag(String label) async {
    final row = await _client.from('tags').insert({'label': label}).select('id, label').single();
    return CourseTagOption.fromMap(row);
  }

  @override
  Future<CourseTagOption> updateTag(String id, String label) async {
    final row = await _client.from('tags').update({'label': label}).eq('id', id).select('id, label').single();
    return CourseTagOption.fromMap(row);
  }

  @override
  Future<void> deleteTags(List<String> ids) async {
    await _client.from('tags').delete().inFilter('id', ids);
  }
}
