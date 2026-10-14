import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/content_block.dart';
import 'package:stitch_aiei_lms/domain/models/course_section.dart' show SyllabusStatus;
import 'package:stitch_aiei_lms/domain/models/course_module.dart';
import 'package:stitch_aiei_lms/domain/models/course_session.dart';
import 'package:stitch_aiei_lms/domain/models/syllabus_template.dart';
import 'package:stitch_aiei_lms/domain/repositories/lecturer_syllabus_repository.dart';

class SupabaseLecturerSyllabusRepositoryImpl implements LecturerSyllabusRepository {
  SupabaseLecturerSyllabusRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<void> setSyllabusStatus(String sectionId, String status) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _client.from('course_sections').update({
      'syllabus_status': status,
      if (status == SyllabusStatus.submitted) 'syllabus_submitted_at': now,
      if (status == SyllabusStatus.approved) 'syllabus_approved_at': now,
    }).eq('id', sectionId);
  }

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
  Future<ContentBlock?> getContentBlock(String id) async {
    final row = await _client.from('content_blocks').select().eq('id', id).maybeSingle();
    return row == null ? null : ContentBlock.fromMap(row);
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
            // Exam questions / assignment rubric live in their own tables, so
            // they're snapshotted into the template too.
            'block_tree': await _snapshotBlockTree(block.id, block.type.name),
          });
        }
      }
    }
  }

  @override
  Future<List<String>> getTemplateModuleNames(String templateId) async {
    final rows = await _client
        .from('template_modules')
        .select('module_name')
        .eq('template_id', templateId)
        .order('module_sorting', ascending: true);
    return [for (final row in rows as List) row['module_name'] as String];
  }

  @override
  Future<void> copyFromTemplate({required String sectionId, required String templateId}) async {
    final existingModules = await _client.from('course_modules').select('id, module_name').eq('section_id', sectionId).order('module_sorting', ascending: true);
    final existing = existingModules as List;

    final templateModules =
        await _client.from('template_modules').select().eq('template_id', templateId).order('module_sorting', ascending: true);
    final templateList = templateModules as List;

    // The template's module list must be exactly the class's (same names,
    // same order); otherwise nothing is touched.
    final matches = existing.length == templateList.length &&
        [for (var i = 0; i < existing.length; i++) i].every(
          (i) => _sameModuleName(existing[i]['module_name'] as String, templateList[i]['module_name'] as String),
        );
    if (!matches) {
      throw StateError('This template\'s modules are not exactly the same as this class\'s modules.');
    }

    // Overwrite: clear every existing session (content blocks cascade), then
    // copy the template's sessions into the class's own modules.
    final moduleIds = [for (final m in existing) (m as Map<String, dynamic>)['id'] as String];
    if (moduleIds.isNotEmpty) {
      await _client.from('sessions').delete().inFilter('module_id', moduleIds);
    }
    for (var i = 0; i < existing.length; i++) {
      await _copyTemplateSessions(
        templateModuleId: (templateList[i] as Map<String, dynamic>)['id'] as String,
        newModuleId: moduleIds[i],
        startSorting: 0,
      );
    }
  }



  @override
  Future<List<CourseModule>> getTemplateModules(String templateId) async {
    final rows = await _client.from('template_modules').select().eq('template_id', templateId).order('module_sorting', ascending: true);
    return [for (final row in rows as List) CourseModule.fromMap({...row as Map<String, dynamic>, 'section_id': templateId})];
  }

  @override
  Future<List<CourseSession>> getTemplateSessions(String templateModuleId) async {
    final rows = await _client.from('template_sessions').select().eq('template_module_id', templateModuleId).order('session_sorting', ascending: true);
    return [for (final row in rows as List) CourseSession.fromMap({...row as Map<String, dynamic>, 'module_id': templateModuleId})];
  }

  /// The exam / assignment snapshot stored with a template content block, or
  /// null when it has none (older templates, other block types).
  Future<Map<String, dynamic>?> getTemplateBlockTree(String templateBlockId) async {
    final row = await _client.from('template_content_blocks').select('block_tree').eq('id', templateBlockId).maybeSingle();
    final tree = row?['block_tree'];
    return tree is Map ? Map<String, dynamic>.from(tree) : null;
  }

  @override
  Future<List<ContentBlock>> getTemplateContentBlocks(String templateSessionId) async {
    final rows = await _client.from('template_content_blocks').select().eq('template_session_id', templateSessionId).order('block_sorting', ascending: true);
    return [for (final row in rows as List) ContentBlock.fromMap({...row as Map<String, dynamic>, 'session_id': templateSessionId})];
  }

  bool _sameModuleName(String a, String b) => a.trim().toLowerCase() == b.trim().toLowerCase();

  /// Copies every session (and its content blocks) of one template module
  /// into [newModuleId], numbering them from [startSorting].
  Future<void> _copyTemplateSessions({required String templateModuleId, required String newModuleId, required int startSorting}) async {
    final templateSessions = await _client
        .from('template_sessions')
        .select()
        .eq('template_module_id', templateModuleId)
        .order('session_sorting', ascending: true);
    for (final ts in templateSessions as List) {
      final tsMap = ts as Map<String, dynamic>;
      final newSession = await _client
          .from('sessions')
          .insert({
            'module_id': newModuleId,
            'session_name': tsMap['session_name'],
            'session_description': tsMap['session_description'],
            'session_sorting': startSorting + (tsMap['session_sorting'] as int),
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
        final newBlock = await _client
            .from('content_blocks')
            .insert({
              'session_id': newSessionId,
              'block_type': tbMap['block_type'],
              'block_content': tbMap['block_content'],
              'block_sorting': tbMap['block_sorting'],
            })
            .select('id')
            .single();
        await _restoreBlockTree(newBlock['id'] as String, tbMap['block_type'] as String, tbMap['block_tree']);
      }
    }
  }

  /// Reads an exam's sections → questions → options, or an assignment's
  /// rubric criteria, as plain JSON (no ids), so a template holds its own
  /// independent copy. Returns null for block types with no such tree.
  Future<Map<String, dynamic>?> _snapshotBlockTree(String blockId, String blockType) async {
    if (blockType == 'exam') {
      final sections = await _client.from('exam_sections').select().eq('content_block_id', blockId).order('section_sorting');
      final out = <Map<String, dynamic>>[];
      for (final s in sections as List) {
        final questions = await _client.from('exam_questions').select().eq('exam_section_id', s['id']).order('question_sorting');
        final qOut = <Map<String, dynamic>>[];
        for (final q in questions as List) {
          final options = await _client.from('exam_question_options').select().eq('question_id', q['id']).order('option_sorting');
          qOut.add({
            'text': q['question_text'],
            'type': q['question_type'],
            'marks': q['marks'],
            'sorting': q['question_sorting'],
            'options': [
              for (final o in options as List) {'text': o['option_text'], 'correct': o['is_correct'], 'sorting': o['option_sorting']},
            ],
          });
        }
        out.add({'name': s['section_name'], 'sorting': s['section_sorting'], 'questions': qOut});
      }
      return {'sections': out};
    }
    if (blockType == 'assignment') {
      final criteria = await _client.from('assignment_criteria').select().eq('content_block_id', blockId).order('criterion_sorting');
      return {
        'criteria': [
          for (final c in criteria as List) {'label': c['criterion_label'], 'maxMarks': c['max_marks'], 'sorting': c['criterion_sorting']},
        ],
      };
    }
    return null;
  }

  /// Inserts brand-new exam sections/questions/options (or rubric criteria)
  /// for [blockId] from a [_snapshotBlockTree] snapshot. Every row gets a
  /// fresh id, so later edits to the copy never touch the original.
  Future<void> _restoreBlockTree(String blockId, String blockType, Object? tree) async {
    if (tree is! Map) return;
    if (blockType == 'exam') {
      for (final s in (tree['sections'] as List? ?? const [])) {
        final section = await _client
            .from('exam_sections')
            .insert({'content_block_id': blockId, 'section_name': s['name'], 'section_sorting': s['sorting']})
            .select('id')
            .single();
        for (final q in (s['questions'] as List? ?? const [])) {
          final question = await _client
              .from('exam_questions')
              .insert({
                'exam_section_id': section['id'],
                'question_text': q['text'],
                'question_type': q['type'],
                'marks': q['marks'],
                'question_sorting': q['sorting'],
              })
              .select('id')
              .single();
          final options = [
            for (final o in (q['options'] as List? ?? const []))
              {'question_id': question['id'], 'option_text': o['text'], 'is_correct': o['correct'], 'option_sorting': o['sorting']},
          ];
          if (options.isNotEmpty) await _client.from('exam_question_options').insert(options);
        }
      }
    } else if (blockType == 'assignment') {
      final criteria = [
        for (final c in (tree['criteria'] as List? ?? const []))
          {'content_block_id': blockId, 'criterion_label': c['label'], 'max_marks': c['maxMarks'], 'criterion_sorting': c['sorting']},
      ];
      if (criteria.isNotEmpty) await _client.from('assignment_criteria').insert(criteria);
    }
  }

  @override
  Future<double> getTotalWeightage(String sectionId, {String? excludeContentBlockId}) async {
    final moduleRows = await _client.from('course_modules').select('id').eq('section_id', sectionId);
    final moduleIds = [for (final row in moduleRows as List) row['id'] as String];
    if (moduleIds.isEmpty) return 0;

    final sessionRows = await _client.from('sessions').select('id').inFilter('module_id', moduleIds);
    final sessionIds = [for (final row in sessionRows as List) row['id'] as String];
    if (sessionIds.isEmpty) return 0;

    final blockRows = await _client
        .from('content_blocks')
        .select('id, block_content')
        .inFilter('session_id', sessionIds)
        .inFilter('block_type', ['exam', 'assignment', 'physicalExam', 'physicalAssignment']);

    var total = 0.0;
    for (final row in blockRows as List) {
      final map = row as Map<String, dynamic>;
      if (excludeContentBlockId != null && map['id'] == excludeContentBlockId) continue;
      final content = Map<String, dynamic>.from(map['block_content'] as Map? ?? {});
      total += (content['weightage'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }
}
