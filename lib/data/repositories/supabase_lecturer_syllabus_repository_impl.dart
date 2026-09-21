import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/content_block.dart';
import 'package:stitch_aiei_lms/domain/models/course_module.dart';
import 'package:stitch_aiei_lms/domain/models/course_session.dart';
import 'package:stitch_aiei_lms/domain/models/syllabus_template.dart';
import 'package:stitch_aiei_lms/domain/repositories/lecturer_syllabus_repository.dart';

class SupabaseLecturerSyllabusRepositoryImpl implements LecturerSyllabusRepository {
  SupabaseLecturerSyllabusRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CourseModule>> getModules(String sectionId) async {
    final rows = await _client.from('course_modules').select().eq('section_id', sectionId).order('module_sorting', ascending: true);
    return [for (final row in rows as List) CourseModule.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<CourseModule> createModule({required String sectionId, required String name, required String description}) async {
    final existing = await _client.from('course_modules').select('id').eq('section_id', sectionId);
    final row = await _client
        .from('course_modules')
        .insert({
          'section_id': sectionId,
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
  Future<void> reorderModules(String sectionId, List<String> orderedIds) async {
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
  Future<ContentBlock> updateContentBlock(String id, {required Map<String, dynamic> content}) async {
    final row = await _client.from('content_blocks').update({'block_content': content}).eq('id', id).select().single();
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

  @override
  Future<List<SyllabusTemplate>> getTemplates() async {
    final rows = await _client.from('syllabus_templates').select().order('created_at', ascending: false);
    return [for (final row in rows as List) SyllabusTemplate.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<void> saveAsTemplate({required String sectionId, required String name}) async {
    final template = await _client.from('syllabus_templates').insert({'name': name}).select().single();
    final templateId = template['id'] as String;

    final modules = await getModules(sectionId);
    for (final module in modules) {
      final newModule = await _client
          .from('template_modules')
          .insert({
            'template_id': templateId,
            'module_name': module.name,
            'module_description': module.description,
            'module_sorting': module.sorting,
            'is_published': module.isPublished,
            'unlock_at': module.unlockAt?.toIso8601String(),
          })
          .select()
          .single();
      final newModuleId = newModule['id'] as String;

      final sessions = await getSessions(module.id);
      for (final session in sessions) {
        final newSession = await _client
            .from('template_sessions')
            .insert({
              'template_module_id': newModuleId,
              'session_name': session.name,
              'session_description': session.description,
              'session_sorting': session.sorting,
              'is_published': session.isPublished,
            })
            .select()
            .single();
        final newSessionId = newSession['id'] as String;

        final blocks = await getContentBlocks(session.id);
        for (final block in blocks) {
          await _client.from('template_content_blocks').insert({
            'template_session_id': newSessionId,
            'block_type': block.type.name,
            'block_content': block.content,
            'block_sorting': block.sorting,
          });
        }
      }
    }
  }

  @override
  Future<void> copyFromTemplate({required String sectionId, required String templateId}) async {
    final existingModules = await _client.from('course_modules').select('id').eq('section_id', sectionId);
    var moduleSorting = (existingModules as List).length;

    final templateModules =
        await _client.from('template_modules').select().eq('template_id', templateId).order('module_sorting', ascending: true);
    for (final tm in templateModules as List) {
      final tmMap = tm as Map<String, dynamic>;
      final newModule = await _client
          .from('course_modules')
          .insert({
            'section_id': sectionId,
            'module_name': tmMap['module_name'],
            'module_description': tmMap['module_description'],
            'module_sorting': moduleSorting++,
            'is_published': tmMap['is_published'],
            'unlock_at': tmMap['unlock_at'],
          })
          .select()
          .single();
      final newModuleId = newModule['id'] as String;

      final templateSessions = await _client
          .from('template_sessions')
          .select()
          .eq('template_module_id', tmMap['id'])
          .order('session_sorting', ascending: true);
      for (final ts in templateSessions as List) {
        final tsMap = ts as Map<String, dynamic>;
        final newSession = await _client
            .from('sessions')
            .insert({
              'module_id': newModuleId,
              'session_name': tsMap['session_name'],
              'session_description': tsMap['session_description'],
              'session_sorting': tsMap['session_sorting'],
              'is_published': tsMap['is_published'],
            })
            .select()
            .single();
        final newSessionId = newSession['id'] as String;

        final templateBlocks = await _client
            .from('template_content_blocks')
            .select()
            .eq('template_session_id', tsMap['id'])
            .order('block_sorting', ascending: true);
        for (final tb in templateBlocks as List) {
          final tbMap = tb as Map<String, dynamic>;
          await _client.from('content_blocks').insert({
            'session_id': newSessionId,
            'block_type': tbMap['block_type'],
            'block_content': tbMap['block_content'],
            'block_sorting': tbMap['block_sorting'],
          });
        }
      }
    }
  }
}
