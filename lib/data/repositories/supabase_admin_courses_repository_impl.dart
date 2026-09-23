import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/admin_course.dart';
import 'package:stitch_aiei_lms/domain/repositories/admin_courses_repository.dart';

class SupabaseAdminCoursesRepositoryImpl implements AdminCoursesRepository {
  SupabaseAdminCoursesRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const _select = '*, course_tags(tag_id), course_badges(badge_id)';

  @override
  Future<List<AdminCourse>> getCourses() async {
    final rows = await _client.from('courses').select(_select).order('course_code');
    return [for (final row in rows as List) AdminCourse.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<AdminCourse> getCourseById(String id) async {
    final row = await _client.from('courses').select(_select).eq('id', id).single();
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
    required List<String> tagIds,
    List<String> badgeIds = const [],
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
    final id = row['id'] as String;
    await _syncTags(id, tagIds);
    await _syncBadges(id, badgeIds);
    return getCourseById(id);
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
    required List<String> tagIds,
    List<String> badgeIds = const [],
  }) async {
    await _client
        .from('courses')
        .update({
          'course_code': courseCode,
          'course_title': courseTitle,
          'course_description': courseDescription,
          'category': category,
          'image_url': imageUrl,
          'credits': credits,
        })
        .eq('id', id);
    await _syncTags(id, tagIds);
    await _syncBadges(id, badgeIds);
    return getCourseById(id);
  }

  /// Replaces this course's `course_tags` rows with exactly [tagIds] —
  /// delete-then-insert is simplest and this list is always small.
  Future<void> _syncTags(String courseId, List<String> tagIds) async {
    await _client.from('course_tags').delete().eq('course_id', courseId);
    if (tagIds.isEmpty) return;
    await _client.from('course_tags').insert([
      for (final tagId in tagIds) {'course_id': courseId, 'tag_id': tagId},
    ]);
  }

  Future<void> _syncBadges(String courseId, List<String> badgeIds) async {
    await _client.from('course_badges').delete().eq('course_id', courseId);
    if (badgeIds.isEmpty) return;
    await _client.from('course_badges').insert([
      for (final badgeId in badgeIds) {'course_id': courseId, 'badge_id': badgeId},
    ]);
  }

  @override
  Future<void> deleteCourses(List<String> ids) async {
    await _client.from('courses').delete().inFilter('id', ids);
  }

  @override
  Future<String> uploadCourseBanner({required String fileName, required Uint8List bytes}) async {
    final path = 'banners/${DateTime.now().millisecondsSinceEpoch}-${_sanitizeStorageKey(fileName)}';
    await _client.storage.from('course-content').uploadBinary(path, bytes);
    return _client.storage.from('course-content').getPublicUrl(path);
  }

  /// Supabase Storage rejects object keys containing characters outside
  /// `[a-zA-Z0-9._-]` (spaces, parentheses, unicode, etc. all trigger a 400
  /// "Invalid key") — replace anything else so real-world filenames don't
  /// fail to upload.
  String _sanitizeStorageKey(String fileName) => fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
}
