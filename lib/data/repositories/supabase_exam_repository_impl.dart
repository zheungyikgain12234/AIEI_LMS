import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/exam_question.dart';
import 'package:stitch_aiei_lms/domain/models/exam_section.dart';
import 'package:stitch_aiei_lms/domain/repositories/exam_repository.dart';

class SupabaseExamRepositoryImpl implements ExamRepository {
  SupabaseExamRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ExamSection>> getSections(String contentBlockId) async {
    final rows = await _client
        .from('exam_sections')
        .select()
        .eq('content_block_id', contentBlockId)
        .order('section_sorting', ascending: true);
    return [for (final row in rows as List) ExamSection.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<ExamSection> createSection({required String contentBlockId, required String name}) async {
    final existing = await _client.from('exam_sections').select('id').eq('content_block_id', contentBlockId);
    final row = await _client
        .from('exam_sections')
        .insert({
          'content_block_id': contentBlockId,
          'section_name': name,
          'section_sorting': (existing as List).length,
        })
        .select()
        .single();
    return ExamSection.fromMap(row);
  }

  @override
  Future<ExamSection> renameSection(String id, {required String name}) async {
    final row = await _client.from('exam_sections').update({'section_name': name}).eq('id', id).select().single();
    return ExamSection.fromMap(row);
  }

  @override
  Future<void> deleteSection(String id) async {
    await _client.from('exam_sections').delete().eq('id', id);
  }

  @override
  Future<void> reorderSections(String contentBlockId, List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      final updated = await _client.from('exam_sections').update({'section_sorting': i}).eq('id', orderedIds[i]).select('id');
      if ((updated as List).isEmpty) {
        throw StateError('No section matched id ${orderedIds[i]} — it may have been deleted elsewhere.');
      }
    }
  }

  @override
  Future<List<ExamQuestion>> getQuestions(String sectionId) async {
    final rows = await _client
        .from('exam_questions')
        .select()
        .eq('exam_section_id', sectionId)
        .order('question_sorting', ascending: true);
    final questionIds = [for (final row in rows as List) row['id'] as String];
    if (questionIds.isEmpty) return [];

    final optionRows = await _client
        .from('exam_question_options')
        .select()
        .inFilter('question_id', questionIds)
        .order('option_sorting', ascending: true);
    final optionsByQuestion = <String, List<ExamQuestionOption>>{};
    for (final row in optionRows as List) {
      final map = row as Map<String, dynamic>;
      optionsByQuestion.putIfAbsent(map['question_id'] as String, () => []).add(ExamQuestionOption.fromMap(map));
    }

    return [
      for (final row in rows) ExamQuestion.fromMap(row, options: optionsByQuestion[row['id']] ?? const []),
    ];
  }

  @override
  Future<ExamQuestion> createQuestion({
    required String sectionId,
    required String text,
    required ExamQuestionType type,
    List<({String text, bool isCorrect})> options = const [],
  }) async {
    final existing = await _client.from('exam_questions').select('id').eq('exam_section_id', sectionId);
    final row = await _client
        .from('exam_questions')
        .insert({
          'exam_section_id': sectionId,
          'question_text': text,
          'question_type': type.key,
          'question_sorting': (existing as List).length,
        })
        .select()
        .single();
    final questionId = row['id'] as String;
    final savedOptions = await _writeOptions(questionId, type, options);
    return ExamQuestion.fromMap(row, options: savedOptions);
  }

  @override
  Future<ExamQuestion> updateQuestion(
    String id, {
    required String text,
    required ExamQuestionType type,
    List<({String text, bool isCorrect})> options = const [],
  }) async {
    final row = await _client
        .from('exam_questions')
        .update({'question_text': text, 'question_type': type.key})
        .eq('id', id)
        .select()
        .single();
    await _client.from('exam_question_options').delete().eq('question_id', id);
    final savedOptions = await _writeOptions(id, type, options);
    return ExamQuestion.fromMap(row, options: savedOptions);
  }

  Future<List<ExamQuestionOption>> _writeOptions(
    String questionId,
    ExamQuestionType type,
    List<({String text, bool isCorrect})> options,
  ) async {
    if (!type.hasOptions || options.isEmpty) return [];
    final rows = await _client
        .from('exam_question_options')
        .insert([
          for (var i = 0; i < options.length; i++)
            {
              'question_id': questionId,
              'option_text': options[i].text,
              'is_correct': options[i].isCorrect,
              'option_sorting': i,
            },
        ])
        .select();
    return [for (final row in rows as List) ExamQuestionOption.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<void> deleteQuestion(String id) async {
    await _client.from('exam_questions').delete().eq('id', id);
  }

  @override
  Future<void> reorderQuestions(String sectionId, List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      final updated =
          await _client.from('exam_questions').update({'question_sorting': i}).eq('id', orderedIds[i]).select('id');
      if ((updated as List).isEmpty) {
        throw StateError('No question matched id ${orderedIds[i]} — it may have been deleted elsewhere.');
      }
    }
  }
}
