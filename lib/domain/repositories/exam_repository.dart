import 'package:stitch_aiei_lms/domain/models/exam_question.dart';
import 'package:stitch_aiei_lms/domain/models/exam_section.dart';

/// Backs the "Manage Contents" (exam) screen reached from an `exam` content block on the
/// Syllabus screen — a section → question (→ answer choices) authoring tree,
/// scoped to that one exam block.
abstract class ExamRepository {
  Future<List<ExamSection>> getSections(String contentBlockId);

  Future<ExamSection> createSection({required String contentBlockId, required String name});

  Future<ExamSection> renameSection(String id, {required String name});

  Future<void> deleteSection(String id);

  /// Persists a new section order after a drag-to-reorder — [orderedIds] is
  /// every section of the exam, in its new top-to-bottom order.
  Future<void> reorderSections(String contentBlockId, List<String> orderedIds);

  /// Questions of a section, each with its answer choices already resolved
  /// (empty for a `text` question, which has none).
  Future<List<ExamQuestion>> getQuestions(String sectionId);

  /// Creates a question and its answer choices (if [type] has any) in one
  /// call — [options] is ignored for [ExamQuestionType.text]. [marks] is how
  /// much this question is worth toward the exam's total.
  Future<ExamQuestion> createQuestion({
    required String sectionId,
    required String text,
    required ExamQuestionType type,
    required double marks,
    List<({String text, bool isCorrect})> options,
  });

  /// Replaces a question's text/type/marks/choices wholesale — simpler and
  /// safer than diffing individual option edits, since a type change (e.g.
  /// single-choice → boolean) invalidates the old choice set anyway.
  Future<ExamQuestion> updateQuestion(
    String id, {
    required String text,
    required ExamQuestionType type,
    required double marks,
    List<({String text, bool isCorrect})> options,
  });

  Future<void> deleteQuestion(String id);

  /// Persists a new question order after a drag-to-reorder — [orderedIds]
  /// is every question of the section, in its new top-to-bottom order.
  Future<void> reorderQuestions(String sectionId, List<String> orderedIds);

  /// Sum of every question's [ExamQuestion.marks] across every section of
  /// this exam — the denominator shown next to a lecturer's per-question
  /// marks and on the "Mark Exam" grading screen.
  Future<double> getTotalMarks(String contentBlockId);
}
