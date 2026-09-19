import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/admin_course.dart';
import 'package:stitch_aiei_lms/domain/repositories/admin_courses_repository.dart';

class SupabaseAdminCoursesRepositoryImpl implements AdminCoursesRepository {
  SupabaseAdminCoursesRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AdminCourse>> getCourses() async {
    final rows = await _client.from('courses').select().order('course_code');
    return [for (final row in rows as List) AdminCourse.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<AdminCourse> getCourseById(String id) async {
    final row = await _client.from('courses').select().eq('id', id).single();
    return AdminCourse.fromMap(row);
  }

  @override
  Future<AdminCourse> createCourse({
    required String courseCode,
    required String courseTitle,
    required String courseDescription,
    required String category,
    String? imageUrl,
    required int credits,
  }) async {
    final row = await _client
        .from('courses')
        .insert({
          'course_code': courseCode,
          'course_title': courseTitle,
          'course_description': courseDescription,
          'category': category,
          'image_url': imageUrl,
          'credits': credits,
        })
        .select()
        .single();
    return AdminCourse.fromMap(row);
  }

  @override
  Future<AdminCourse> updateCourse(
    String id, {
    required String courseCode,
    required String courseTitle,
    required String courseDescription,
    required String category,
    String? imageUrl,
    required int credits,
  }) async {
    final row = await _client
        .from('courses')
        .update({
          'course_code': courseCode,
          'course_title': courseTitle,
          'course_description': courseDescription,
          'category': category,
          'image_url': imageUrl,
          'credits': credits,
        })
        .eq('id', id)
        .select()
        .single();
    return AdminCourse.fromMap(row);
  }

  @override
  Future<void> deleteCourses(List<String> ids) async {
    await _client.from('courses').delete().inFilter('id', ids);
  }
}
