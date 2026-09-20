/// How a single [ExamQuestion] is answered.
enum ExamQuestionType {
  singleChoice('single_choice'),
  multiChoice('multi_choice'),
  boolean('boolean'),
  text('text');

  final String key;
  const ExamQuestionType(this.key);

  static ExamQuestionType fromKey(String key) =>
      ExamQuestionType.values.firstWhere((t) => t.key == key, orElse: () => ExamQuestionType.text);

  /// Whether this type has answer choices ([ExamQuestionOption]s) at all —
  /// `text` questions are free-response and graded manually.
  bool get hasOptions => this != ExamQuestionType.text;

  /// Whether more than one choice can be marked correct.
  bool get allowsMultipleCorrect => this == ExamQuestionType.multiChoice;
}

/// One answer choice for a single/multi-choice or true/false [ExamQuestion].
class ExamQuestionOption {
  final String id;
  final String text;
  final bool isCorrect;
  final int sorting;

  const ExamQuestionOption({required this.id, required this.text, required this.isCorrect, required this.sorting});

  factory ExamQuestionOption.fromMap(Map<String, dynamic> map) {
    return ExamQuestionOption(
      id: map['id'] as String,
      text: map['option_text'] as String? ?? '',
      isCorrect: map['is_correct'] as bool? ?? false,
      sorting: map['option_sorting'] as int? ?? 0,
    );
  }
}

/// One question inside an [ExamSection] (`exam_questions` table).
class ExamQuestion {
  final String id;
  final String sectionId;
  final String text;
  final ExamQuestionType type;
  final int sorting;
  final List<ExamQuestionOption> options;

  const ExamQuestion({
    required this.id,
    required this.sectionId,
    required this.text,
    required this.type,
    required this.sorting,
    this.options = const [],
  });

  factory ExamQuestion.fromMap(Map<String, dynamic> map, {List<ExamQuestionOption> options = const []}) {
    return ExamQuestion(
      id: map['id'] as String,
      sectionId: map['exam_section_id'] as String,
      text: map['question_text'] as String? ?? '',
      type: ExamQuestionType.fromKey(map['question_type'] as String),
      sorting: map['question_sorting'] as int? ?? 0,
      options: options,
    );
  }
}
