import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/content_block.dart';
import 'package:stitch_aiei_lms/domain/models/course_module.dart';
import 'package:stitch_aiei_lms/domain/models/course_session.dart';
import 'package:stitch_aiei_lms/domain/repositories/lecturer_syllabus_repository.dart';

class SupabaseLecturerSyllabusRepositoryImpl implements LecturerSyllabusRepository {
  SupabaseLecturerSyllabusRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CourseModule>> getModules(String courseId) async {
    final rows = await _client.from('course_modules').select().eq('course_id', courseId).order('module_sorting', ascending: true);
    return [for (final row in rows as List) CourseModule.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<CourseModule> createModule({required String courseId, required String name, required String description}) async {
    final existing = await _client.from('course_modules').select('id').eq('course_id', courseId);
    final row = await _client
        .from('course_modules')
        .insert({
          'course_id': courseId,
          'module_name': name,
          'module_description': description,
          'module_sorting': (existing as List).length,
        })
        .select()
        .single();
    return CourseModule.fromMap(row);
  }

  @override
  Future<CourseModule> updateModule(String id, {required String name, required String description, required bool isPublished}) async {
    final row = await _client
        .from('course_modules')
        .update({'module_name': name, 'module_description': description, 'is_published': isPublished})
        .eq('id', id)
        .select()
        .single();
    return CourseModule.fromMap(row);
  }

  @override
  Future<void> deleteModule(String id) async {
    await _client.from('course_modules').delete().eq('id', id);
  }

  @override
  Future<void> reorderModules(String courseId, List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      final updated = await _client.from('course_modules').update({'module_sorting': i}).eq('id', orderedIds[i]).select('id');
      if ((updated as List).isEmpty) {
        throw StateError('No module matched id ${orderedIds[i]} — it may have been deleted elsewhere.');
      }
    }
  }

  @override
  Future<List<CourseSession>> getSessions(String moduleId) async {
    final rows = await _client.from('sessions').select().eq('module_id', moduleId).order('session_sorting', ascending: true);
    return [for (final row in rows as List) CourseSession.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<CourseSession> createSession({required String moduleId, required String name, required String description}) async {
    final existing = await _client.from('sessions').select('id').eq('module_id', moduleId);
    final row = await _client
        .from('sessions')
        .insert({
          'module_id': moduleId,
          'session_name': name,
          'session_description': description,
          'session_sorting': (existing as List).length,
        })
        .select()
        .single();
    return CourseSession.fromMap(row);
  }

  @override
  Future<CourseSession> updateSession(String id, {required String name, required String description, required bool isPublished}) async {
    final row = await _client
        .from('sessions')
        .update({'session_name': name, 'session_description': description, 'is_published': isPublished})
        .eq('id', id)
        .select()
        .single();
    return CourseSession.fromMap(row);
  }

  @override
  Future<void> deleteSession(String id) async {
    await _client.from('sessions').delete().eq('id', id);
  }

  @override
  Future<void> reorderSessions(String moduleId, List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      final updated = await _client.from('sessions').update({'session_sorting': i}).eq('id', orderedIds[i]).select('id');
      if ((updated as List).isEmpty) {
        throw StateError('No session matched id ${orderedIds[i]} — it may have been deleted elsewhere.');
      }
    }
  }

  @override
  Future<List<ContentBlock>> getContentBlocks(String sessionId) async {
    final rows = await _client.from('content_blocks').select().eq('session_id', sessionId).order('block_sorting', ascending: true);
    return [for (final row in rows as List) ContentBlock.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<ContentBlock> addContentBlock({
    required String sessionId,
    required ContentBlockType type,
    required Map<String, dynamic> content,
  }) async {
    final existing = await _client.from('content_blocks').select('id').eq('session_id', sessionId);
    final row = await _client
        .from('content_blocks')
        .insert({
          'session_id': sessionId,
          'block_type': type.name,
          'block_content': content,
          'block_sorting': (existing as List).length,
        })
        .select()
        .single();
    return ContentBlock.fromMap(row);
  }

  @override
  Future<void> deleteContentBlock(String id) async {
    await _client.from('content_blocks').delete().eq('id', id);
  }

  @override
  Future<void> reorderContentBlocks(String sessionId, List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      final updated = await _client.from('content_blocks').update({'block_sorting': i}).eq('id', orderedIds[i]).select('id');
      if ((updated as List).isEmpty) {
        throw StateError('No content block matched id ${orderedIds[i]} — it may have been deleted elsewhere.');
      }
    }
  }

  @override
  Future<String> uploadContentFile({required String sessionId, required String fileName, required Uint8List bytes}) async {
    final path = '$sessionId/${DateTime.now().millisecondsSinceEpoch}-${_sanitizeStorageKey(fileName)}';
    await _client.storage.from('course-content').uploadBinary(path, bytes);
    return _client.storage.from('course-content').getPublicUrl(path);
  }

  /// Supabase Storage rejects object keys containing characters outside
  /// `[a-zA-Z0-9._-]` (spaces, parentheses, unicode, etc. all trigger a 400
  /// "Invalid key") — replace anything else so real-world filenames like
  /// "Lecture Notes (Week 1).pdf" don't fail to upload.
  String _sanitizeStorageKey(String fileName) => fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
}
