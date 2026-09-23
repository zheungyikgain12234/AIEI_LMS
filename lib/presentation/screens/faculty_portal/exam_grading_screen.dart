import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_exam_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_submission_grading_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/content_block_submission.dart';
import 'package:stitch_aiei_lms/domain/models/exam_question.dart';
import 'widgets/downloadable_file.dart';
import 'widgets/faculty_mobile_top_bar.dart';

/// One roster entry in the grading queue an [ExamGradingScreen] was opened
/// from — lets "Save and Mark the Next Student" step forward through the
/// same sorted/paginated order the lecturer was looking at on
/// [MarkExamScreen] without returning to that screen first.
typedef GradingQueueEntry = ({String studentId, String studentName});

// ---------------------------------------------------------------------------
// ExamGradingScreen — one student's exam answers, opened from the roster on
// MarkExamScreen. Single/multi-choice and true/false questions are
// auto-marked against the correct option(s) and shown read-only; text and
// file-upload questions get a manual marks input. Ends in a live running
// total and two save actions: "Save Marks and Exit" (back to the roster)
// and "Save and Mark the Next Student" (straight to the next student in
// [orderedStudents]).
// ---------------------------------------------------------------------------
class ExamGradingScreen extends StatefulWidget {
  final String contentBlockId;
  final String studentId;
  final String studentName;
  final List<GradingQueueEntry>? orderedStudents;
  final int? currentIndex;

  const ExamGradingScreen({
    super.key,
    required this.contentBlockId,
    required this.studentId,
    required this.studentName,
    this.orderedStudents,
    this.currentIndex,
  });

  @override
  State<ExamGradingScreen> createState() => _ExamGradingScreenState();
}

class _StudentAnswer {
  final Set<String> selectedOptionIds;
  final String? textAnswer;
  final List<Map<String, dynamic>> fileUrls;
  const _StudentAnswer({this.selectedOptionIds = const {}, this.textAnswer, this.fileUrls = const []});
}

class _ExamGradingScreenState extends State<ExamGradingScreen> {
  final _examRepository = SupabaseExamRepositoryImpl(Supabase.instance.client);
  final _gradingRepository = SupabaseSubmissionGradingRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  bool _saving = false;
  List<ExamQuestion> _questions = const [];
  ContentBlockSubmission? _submission;
  final Map<String, _StudentAnswer> _answersByQuestion = {};
  final Map<String, TextEditingController> _textMarksControllers = {};
  late final _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _textMarksControllers.values) {
      c.dispose();
    }
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final sections = await _examRepository.getSections(widget.contentBlockId);
    final questions = <ExamQuestion>[
      for (final section in sections) ...await _examRepository.getQuestions(section.id),
    ];
    final submission = await _gradingRepository.getSubmission(widget.contentBlockId, widget.studentId);
    if (!mounted) return;

    final rawAnswers = (submission?.submission['answers'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final answersByQuestion = <String, _StudentAnswer>{
      for (final a in rawAnswers)
        a['questionId'] as String: _StudentAnswer(
          selectedOptionIds: {for (final id in (a['selectedOptionIds'] as List?) ?? const []) id as String},
          textAnswer: a['textAnswer'] as String?,
          fileUrls: (a['fileUrls'] as List?)?.cast<Map<String, dynamic>>() ?? const [],
        ),
    };

    setState(() {
      _questions = questions;
      _submission = submission;
      _answersByQuestion
        ..clear()
        ..addAll(answersByQuestion);
      for (final q in questions.where((q) => q.type.isManuallyGraded)) {
        final existingMark = submission?.marks[q.id];
        _textMarksControllers[q.id] = TextEditingController(text: existingMark?.toString() ?? '');
      }
      _feedbackController.text = submission?.feedback ?? '';
      _isLoading = false;
    });
  }

  /// Auto-graded score for a single/multi-choice or true/false question —
  /// full marks if the student's selected option(s) exactly match the
  /// correct one(s), otherwise 0. Not partial-credited.
  double _autoScoreFor(ExamQuestion q) {
    final answer = _answersByQuestion[q.id];
    if (answer == null) return 0;
    final correctIds = {for (final o in q.options.where((o) => o.isCorrect)) o.id};
    return answer.selectedOptionIds.length == correctIds.length && answer.selectedOptionIds.containsAll(correctIds)
        ? q.marks
        : 0;
  }

  double? _parsedTextMarksFor(ExamQuestion q) => double.tryParse(_textMarksControllers[q.id]?.text.trim() ?? '');

  double get _total {
    var total = 0.0;
    for (final q in _questions) {
      if (q.type.isManuallyGraded) {
        total += (_parsedTextMarksFor(q) ?? 0).clamp(0, q.marks);
      } else {
        total += _autoScoreFor(q);
      }
    }
    return total;
  }

  double get _maxTotal => _questions.fold<double>(0, (sum, q) => sum + q.marks);

  bool get _canSave {
    if (_questions.isEmpty) return false;
    for (final q in _questions.where((q) => q.type.isManuallyGraded)) {
      final marks = _parsedTextMarksFor(q);
      if (marks == null || marks < 0 || marks > q.marks) return false;
    }
    return true;
  }

  bool get _hasNextStudent {
    final ordered = widget.orderedStudents;
    final index = widget.currentIndex;
    if (ordered == null || index == null) return false;
    return index + 1 < ordered.length;
  }

  /// There's nothing to save for a student who hasn't submitted, so the
  /// "Next" action must still work in that case — it just navigates without
  /// calling [_saveMarks], rather than being disabled outright by [_canSave]
  /// (which is only meaningful once a submission exists to grade).
  bool get _canAdvance => _submission == null || _canSave;

  void _onNextPressed() {
    if (_submission == null) {
      _goToNextStudent();
    } else {
      _saveMarks(andExit: false);
    }
  }

  void _goToNextStudent() {
    final ordered = widget.orderedStudents!;
    final nextIndex = widget.currentIndex! + 1;
    final next = ordered[nextIndex];
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ExamGradingScreen(
          contentBlockId: widget.contentBlockId,
          studentId: next.studentId,
          studentName: next.studentName,
          orderedStudents: ordered,
          currentIndex: nextIndex,
        ),
      ),
    );
  }

  Future<void> _saveMarks({required bool andExit}) async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final marks = {
      for (final q in _questions)
        q.id: q.type.isManuallyGraded ? _parsedTextMarksFor(q)! : _autoScoreFor(q),
    };
    await _gradingRepository.saveGrade(
      contentBlockId: widget.contentBlockId,
      studentId: widget.studentId,
      marks: marks,
      feedback: _feedbackController.text.trim().isEmpty ? null : _feedbackController.text.trim(),
      totalScore: _total,
      gradedByLecturerId: DemoIdentity.lecturerId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marks saved.')));
    if (andExit || !_hasNextStudent) {
      Navigator.of(context).pop();
      return;
    }
    _goToNextStudent();
  }

  String _formatMarks(double marks) => marks.toStringAsFixed(marks.truncateToDouble() == marks ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: FacultyMobileTopBar(title: widget.studentName),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_submission == null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: FacultyColors.errorContainer, borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        '${widget.studentName} hasn\'t submitted this exam yet — marks can still be recorded, but there are no answers to review.',
                        style: FacultyTypography.bodySm(color: FacultyColors.onErrorContainer),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (_questions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12)),
                      child: Text('No questions have been set up for this exam yet.', style: FacultyTypography.bodySm()),
                    )
                  else
                    for (var i = 0; i < _questions.length; i++) _questionCard(_questions[i], i + 1),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _feedbackController,
                    decoration: const InputDecoration(labelText: 'Overall feedback (optional)'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  _totalAndSaveBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _questionCard(ExamQuestion q, int number) {
    final answer = _answersByQuestion[q.id];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FacultyColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text('Q$number. ${q.text}', style: FacultyTypography.bodyMd(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: FacultyColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(6)),
                  child: Text('${_formatMarks(q.marks)} marks', style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (q.type.isManuallyGraded) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
                child: q.type == ExamQuestionType.fileUpload
                    ? (answer?.fileUrls.isNotEmpty == true
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final f in answer!.fileUrls)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: DownloadableFile(
                                    url: f['url'] as String? ?? '',
                                    label: f['name'] as String? ?? f['url'] as String? ?? 'Attachment',
                                    style: FacultyTypography.bodySm(color: FacultyColors.onSurface),
                                  ),
                                ),
                            ],
                          )
                        : Text('No file submitted.', style: FacultyTypography.bodySm(color: FacultyColors.onSurface)))
                    : Text(
                        answer?.textAnswer?.isNotEmpty == true ? answer!.textAnswer! : 'No answer submitted.',
                        style: FacultyTypography.bodySm(color: FacultyColors.onSurface),
                      ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('Marks:', style: FacultyTypography.labelMd(color: FacultyColors.onSurfaceVariant)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _textMarksControllers[q.id],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(isDense: true, suffixText: '/ ${_formatMarks(q.marks)}'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ] else ...[
              for (final o in q.options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        answer?.selectedOptionIds.contains(o.id) == true ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        size: 16,
                        color: answer?.selectedOptionIds.contains(o.id) == true ? FacultyColors.primary : FacultyColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(o.text, style: FacultyTypography.bodySm(color: FacultyColors.onSurface))),
                      if (o.isCorrect) const Icon(Icons.check_circle, size: 14, color: FacultyColors.tertiary),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _autoScoreFor(q) == q.marks ? FacultyColors.secondaryContainer : FacultyColors.errorContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Auto-graded: ${_formatMarks(_autoScoreFor(q))} / ${_formatMarks(q.marks)}',
                  style: FacultyTypography.labelXs(
                    color: _autoScoreFor(q) == q.marks ? FacultyColors.onSecondaryContainer : FacultyColors.onErrorContainer,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _totalAndSaveBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Total: ${_formatMarks(_total)} / ${_formatMarks(_maxTotal)}',
            style: FacultyTypography.headlineMd(color: FacultyColors.primary),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: !_canSave || _saving ? null : () => _saveMarks(andExit: true),
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.logout, size: 18),
                label: const Text('Save Marks and Exit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FacultyColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: !_canAdvance || _saving || !_hasNextStudent ? null : _onNextPressed,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.navigate_next, size: 18),
                label: Text(_submission == null ? 'Next' : 'Save and Mark the Next Student'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FacultyColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
