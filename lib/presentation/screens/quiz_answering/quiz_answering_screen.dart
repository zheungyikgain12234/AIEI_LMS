import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/core/utils/date_format.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_exam_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturer_syllabus_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_submission_grading_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/content_block.dart';
import 'package:stitch_aiei_lms/domain/models/content_block_submission.dart';
import 'package:stitch_aiei_lms/domain/models/exam_question.dart';
import 'package:stitch_aiei_lms/presentation/screens/faculty_portal/widgets/downloadable_file.dart';

// ---------------------------------------------------------------------------
// QuizAnsweringScreen — a student's "View Exam" / exam-answering page,
// reached by tapping an exam on CourseContentScreen. Renders every question
// (single/multi-choice, true/false, text, file upload) as an answerable
// form with a question palette for quick navigation, matching the original
// Stitch exam-taking layout; once the lecturer has graded it, shows the
// read-only result instead (auto-graded score per MCQ/true-false question,
// the lecturer's marks for text/file-upload questions, and feedback).
// ---------------------------------------------------------------------------
class QuizAnsweringScreen extends StatefulWidget {
  final String contentBlockId;
  final String sectionId;
  final String studentId;

  const QuizAnsweringScreen({
    super.key,
    required this.contentBlockId,
    required this.sectionId,
    required this.studentId,
  });

  @override
  State<QuizAnsweringScreen> createState() => _QuizAnsweringScreenState();
}

class _QuizAnsweringScreenState extends State<QuizAnsweringScreen> {
  final _syllabusRepository = SupabaseLecturerSyllabusRepositoryImpl(Supabase.instance.client);
  final _examRepository = SupabaseExamRepositoryImpl(Supabase.instance.client);
  final _gradingRepository = SupabaseSubmissionGradingRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  bool _submitting = false;
  ContentBlock? _block;
  List<ExamQuestion> _questions = const [];
  ContentBlockSubmission? _submission;

  final Map<String, Set<String>> _selectedOptions = {};
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, List<Map<String, dynamic>>> _fileAnswers = {};
  final Set<String> _uploadingQuestionIds = {};
  final Set<String> _flagged = {};
  final Map<String, GlobalKey> _questionKeys = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final block = await _syllabusRepository.getContentBlock(widget.contentBlockId);
    final sections = await _examRepository.getSections(widget.contentBlockId);
    final questions = <ExamQuestion>[
      for (final section in sections) ...await _examRepository.getQuestions(section.id),
    ];
    final submission = await _gradingRepository.getSubmission(widget.contentBlockId, widget.studentId);
    if (!mounted) return;

    final rawAnswers = (submission?.submission['answers'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final answersByQuestion = {for (final a in rawAnswers) a['questionId'] as String: a};

    for (final q in questions) {
      _questionKeys[q.id] = GlobalKey();
      final a = answersByQuestion[q.id];
      if (q.type.hasOptions) {
        _selectedOptions[q.id] = {for (final id in (a?['selectedOptionIds'] as List?) ?? const []) id as String};
      } else if (q.type == ExamQuestionType.text) {
        _textControllers[q.id] = TextEditingController(text: a?['textAnswer'] as String? ?? '')..addListener(() => setState(() {}));
      } else if (q.type == ExamQuestionType.fileUpload) {
        _fileAnswers[q.id] = (a?['fileUrls'] as List?)?.cast<Map<String, dynamic>>().toList() ?? [];
      }
    }

    setState(() {
      _block = block;
      _questions = questions;
      _submission = submission;
      _isLoading = false;
    });
  }

  bool _isAnswered(ExamQuestion q) {
    if (q.type.hasOptions) return (_selectedOptions[q.id] ?? const {}).isNotEmpty;
    if (q.type == ExamQuestionType.text) return (_textControllers[q.id]?.text.trim() ?? '').isNotEmpty;
    return (_fileAnswers[q.id] ?? const []).isNotEmpty;
  }

  int get _answeredCount => _questions.where(_isAnswered).length;
  double get _progress => _questions.isEmpty ? 0 : _answeredCount / _questions.length;
  bool get _canSubmit => _questions.isNotEmpty && _questions.every(_isAnswered);
  double get _totalMarks => _questions.fold<double>(0, (sum, q) => sum + q.marks);

  void _toggleFlag(String questionId) => setState(() {
        _flagged.contains(questionId) ? _flagged.remove(questionId) : _flagged.add(questionId);
      });

  void _scrollToQuestion(String questionId) {
    final key = _questionKeys[questionId];
    final ctx = key?.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.1);
  }

  Future<void> _pickAndUploadFor(ExamQuestion q) async {
    final block = _block;
    if (block == null) return;
    final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) return;
    setState(() => _uploadingQuestionIds.add(q.id));
    try {
      final url = await _syllabusRepository.uploadContentFile(sessionId: block.sessionId, fileName: file.name, bytes: bytes);
      if (!mounted) return;
      setState(() {
        _fileAnswers[q.id] = [
          ...(_fileAnswers[q.id] ?? const []),
          {'name': file.name, 'url': url},
        ];
        _uploadingQuestionIds.remove(q.id);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingQuestionIds.remove(q.id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  void _removeFileFor(ExamQuestion q, int index) {
    setState(() => _fileAnswers[q.id] = [...(_fileAnswers[q.id] ?? const [])]..removeAt(index));
  }

  void _openSubmitModal() {
    showDialog(
      context: context,
      builder: (ctx) => _SubmitDialog(
        answeredCount: _answeredCount,
        totalQuestions: _questions.length,
        flaggedCount: _flagged.length,
        onConfirm: () async {
          Navigator.of(ctx).pop();
          await _submit();
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    final answers = [
      for (final q in _questions)
        if (q.type.hasOptions)
          {'questionId': q.id, 'selectedOptionIds': (_selectedOptions[q.id] ?? const {}).toList()}
        else if (q.type == ExamQuestionType.text)
          {'questionId': q.id, 'textAnswer': _textControllers[q.id]?.text.trim() ?? ''}
        else
          {'questionId': q.id, 'fileUrls': _fileAnswers[q.id] ?? const []},
    ];
    await _gradingRepository.submitAnswer(
      contentBlockId: widget.contentBlockId,
      studentId: widget.studentId,
      submission: {'answers': answers},
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Your exam answers have been submitted for evaluation.'),
      backgroundColor: AppColors.secondary,
    ));
    final navigator = Navigator.of(context);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) navigator.pop();
    });
  }

  String _formatMarks(double marks) => marks.toStringAsFixed(marks.truncateToDouble() == marks ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final block = _block;
    if (block == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.surfaceContainerLowest, elevation: 0, title: const Text('Exam')),
        body: Center(child: Text('This exam is no longer available.', style: AppTypography.bodyMd())),
      );
    }
    if (MediaQuery.of(context).size.width < 700) {
      return _buildMobileScaffold(context, block);
    }
    final graded = _submission?.isGraded ?? false;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopUtilityBar(),
                    const SizedBox(height: 16),
                    _buildBanner(block),
                    const SizedBox(height: 16),
                    if (graded) ...[_gradeBanner(_submission!), const SizedBox(height: 16)],
                    LayoutBuilder(builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 900;
                      final left = _buildQuestionsColumn(graded);
                      final palette = _buildPaletteCard(graded);
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 8, child: left),
                            const SizedBox(width: 16),
                            SizedBox(width: 340, child: palette),
                          ],
                        );
                      }
                      return Column(children: [left, const SizedBox(height: 16), palette]);
                    }),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Mobile layout ─────────────────────────────────────────────────────────
  Widget _buildMobileScaffold(BuildContext context, ContentBlock block) {
    final graded = _submission?.isGraded ?? false;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back, color: AppColors.onSurface)),
        title: Text(block.title?.isNotEmpty == true ? block.title! : 'Exam', style: AppTypography.headlineSm(color: AppColors.onSurface)),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMobileMetaCard(block),
              if (graded) ...[const SizedBox(height: 12), _gradeBanner(_submission!)],
              const SizedBox(height: 12),
              if (_questions.isNotEmpty) _buildMobileQuestionStrip(),
              const SizedBox(height: 12),
              _buildQuestionsColumn(graded),
              const SizedBox(height: 12),
              if (!graded) _submitButton(fullWidth: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileMetaCard(ContentBlock block) {
    final percent = (_progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: AppColors.secondaryContainer.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.verified_user, color: AppColors.secondary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  block.description?.isNotEmpty == true ? block.description! : (block.title ?? 'Exam'),
                  style: AppTypography.labelLg(color: AppColors.primary).copyWith(fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final w = (constraints.maxWidth - 16) / 3;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(width: w, child: _mobileStat('Questions', '${_questions.length}')),
                SizedBox(width: w, child: _mobileStat('Marks', _formatMarks(_totalMarks))),
                SizedBox(width: w, child: _mobileStat('Weight', block.weightage != null ? '${_formatMarks(block.weightage!)}%' : '—')),
              ],
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text('$_answeredCount of ${_questions.length} answered • $percent% done',
                    style: AppTypography.labelSm(color: AppColors.primary).copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainer,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(label, style: AppTypography.labelSm(), textAlign: TextAlign.center),
          Text(value, style: AppTypography.labelMd(color: AppColors.primary).copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildMobileQuestionStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Question Palette', style: AppTypography.labelMd(color: AppColors.primary).copyWith(fontWeight: FontWeight.w700))),
              Text('$_answeredCount answered', style: AppTypography.labelSm()),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _questions.length,
              separatorBuilder: (context, i) => const SizedBox(width: 8),
              itemBuilder: (context, i) => SizedBox(width: 40, child: _paletteTile(_questions[i], i + 1)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top utility bar ──────────────────────────────────────────────────────
  Widget _buildTopUtilityBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back, size: 18, color: AppColors.secondary),
                    const SizedBox(width: 6),
                    Text('Back to Course', style: AppTypography.labelMd()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner ────────────────────────────────────────────────────────────────
  Widget _buildBanner(ContentBlock block) {
    final percent = (_progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 20,
            runSpacing: 16,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: AppColors.secondaryContainer.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.verified_user, color: AppColors.secondary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Text(block.title?.isNotEmpty == true ? block.title! : 'Exam', style: AppTypography.headlineMd(color: AppColors.primary)),
                  ),
                ],
              ),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  _statPill('Total Questions', '${_questions.length}', AppColors.secondaryContainer),
                  _statPill('Total Marks', _formatMarks(_totalMarks), AppColors.onTertiaryContainer),
                  if (block.weightage != null) _statPill('Exam Weight', '${_formatMarks(block.weightage!)}% Final Grade', AppColors.secondary),
                  if (block.dueDate != null) _statPill('Due', formatDueDate(block.dueDate!), AppColors.error),
                ],
              ),
            ],
          ),
          if (block.instructions?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Text(block.instructions!, style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)),
          ],
          if (block.instructionFiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                for (final f in block.instructionFiles)
                  DownloadableFile(
                    url: f['url'] as String? ?? '',
                    label: f['name'] as String? ?? f['url'] as String? ?? 'Attachment',
                    style: AppTypography.bodySm(color: AppColors.secondary),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text('Progress: $_answeredCount of ${_questions.length} answered • $percent% Completed',
                    style: AppTypography.labelSm(color: AppColors.primary).copyWith(fontWeight: FontWeight.w700)),
              ),
              Text('${_questions.length - _answeredCount} Questions Remaining', style: AppTypography.labelSm()),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainer,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, String value, Color dotColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTypography.labelSm()),
            Text(value, style: AppTypography.labelLg(color: AppColors.primary).copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  Widget _gradeBanner(ContentBlockSubmission submission) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.secondaryContainer.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grading_outlined, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text('Graded: ${_formatMarks(submission.totalScore ?? 0)} / ${_formatMarks(_totalMarks)}',
                  style: AppTypography.headlineMd(color: AppColors.primary)),
            ],
          ),
          if (submission.feedback?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(submission.feedback!, style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }

  // ── Questions column ─────────────────────────────────────────────────────
  Widget _buildQuestionsColumn(bool graded) {
    if (_questions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Text('No questions have been published for this exam yet.', style: AppTypography.bodyMd()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _questions.length; i++) ...[
          KeyedSubtree(key: _questionKeys[_questions[i].id], child: _questionCard(_questions[i], i + 1, readOnly: graded)),
          const SizedBox(height: 16),
        ],
        if (!graded) _submitButton(fullWidth: false),
      ],
    );
  }

  Widget _submitButton({required bool fullWidth}) {
    final button = ElevatedButton.icon(
      onPressed: !_canSubmit || _submitting ? null : _openSubmitModal,
      icon: _submitting
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
          : const Icon(Icons.send, size: 18),
      label: Text(_submission == null ? 'Submit Exam' : 'Resubmit Exam'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    if (!fullWidth) return Align(alignment: Alignment.centerRight, child: button);
    return SizedBox(width: double.infinity, child: button);
  }

  Widget _questionHeader({required int number, required ExamQuestion q, required bool readOnly}) {
    final isFlagged = _flagged.contains(q.id);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
          child: Text(number.toString().padLeft(2, '0'), style: AppTypography.headlineSm(color: AppColors.primary)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_kickerFor(q.type), style: AppTypography.labelSm()),
              Text(q.text, style: AppTypography.labelMd(color: AppColors.primary).copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
          child: Text('${_formatMarks(q.marks)} marks', style: AppTypography.labelSm(color: AppColors.onSurfaceVariant)),
        ),
        if (!readOnly) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _toggleFlag(q.id),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.flag, size: 16, color: isFlagged ? AppColors.error : AppColors.outline),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _kickerFor(ExamQuestionType type) {
    switch (type) {
      case ExamQuestionType.singleChoice:
        return 'SINGLE CHOICE';
      case ExamQuestionType.multiChoice:
        return 'MULTIPLE CHOICE • SELECT ALL THAT APPLY';
      case ExamQuestionType.boolean:
        return 'TRUE / FALSE';
      case ExamQuestionType.text:
        return 'FREE RESPONSE';
      case ExamQuestionType.fileUpload:
        return 'FILE UPLOAD';
    }
  }

  Widget _questionCard(ExamQuestion q, int number, {required bool readOnly}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _questionHeader(number: number, q: q, readOnly: readOnly),
          const SizedBox(height: 16),
          if (q.type.hasOptions)
            ..._optionsFor(q, readOnly: readOnly)
          else
            _manualAnswerFor(q, readOnly: readOnly),
          if (readOnly) ...[const SizedBox(height: 10), _markBadge(q)],
        ],
      ),
    );
  }

  List<Widget> _optionsFor(ExamQuestion q, {required bool readOnly}) {
    final selected = _selectedOptions[q.id] ?? const {};
    return [
      for (final o in q.options) ...[
        _optionTile(q, o, selected: selected.contains(o.id), readOnly: readOnly),
        const SizedBox(height: 10),
      ],
    ];
  }

  Widget _optionTile(ExamQuestion q, ExamQuestionOption o, {required bool selected, required bool readOnly}) {
    final showCorrect = readOnly && o.isCorrect;
    return GestureDetector(
      onTap: readOnly
          ? null
          : () => setState(() {
                final current = Set<String>.from(_selectedOptions[q.id] ?? const {});
                if (q.type.allowsMultipleCorrect) {
                  current.contains(o.id) ? current.remove(o.id) : current.add(o.id);
                } else {
                  current
                    ..clear()
                    ..add(o.id);
                }
                _selectedOptions[q.id] = current;
              }),
      child: MouseRegion(
        cursor: readOnly ? MouseCursor.defer : SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.secondaryContainer.withValues(alpha: 0.1) : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.secondary : AppColors.outlineVariant.withValues(alpha: 0.3),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                q.type.allowsMultipleCorrect
                    ? (selected ? Icons.check_box : Icons.check_box_outline_blank)
                    : (selected ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                size: 20,
                color: selected ? AppColors.secondary : AppColors.outline,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(o.text, style: AppTypography.bodyMd())),
              if (showCorrect) const Icon(Icons.check_circle, size: 16, color: AppColors.onTertiaryContainer),
            ],
          ),
        ),
      ),
    );
  }

  Widget _manualAnswerFor(ExamQuestion q, {required bool readOnly}) {
    if (q.type == ExamQuestionType.text) {
      final wordCount = (_textControllers[q.id]?.text.trim() ?? '').isEmpty
          ? 0
          : _textControllers[q.id]!.text.trim().split(RegExp(r'\s+')).length;
      if (readOnly) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
          child: Text(
            _textControllers[q.id]?.text.isNotEmpty == true ? _textControllers[q.id]!.text : 'No answer submitted.',
            style: AppTypography.bodyMd(color: AppColors.onSurface),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _textControllers[q.id],
                maxLines: 6,
                style: AppTypography.bodyMd(color: AppColors.onSurface),
                decoration: InputDecoration(border: InputBorder.none, hintText: 'Type your answer...', hintStyle: AppTypography.bodyMd(color: AppColors.outline)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('$wordCount word${wordCount == 1 ? '' : 's'}', style: AppTypography.labelSm()),
        ],
      );
    }

    // file upload
    final files = _fileAnswers[q.id] ?? const [];
    final uploading = _uploadingQuestionIds.contains(q.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < files.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: readOnly
                ? DownloadableFile(url: files[i]['url'] as String? ?? '', label: files[i]['name'] as String? ?? 'Attachment', style: AppTypography.bodyMd(color: AppColors.onSurface))
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, size: 16, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Expanded(child: Text('${files[i]['name']}', style: AppTypography.bodyMd(color: AppColors.onSurface))),
                        IconButton(
                          onPressed: () => _removeFileFor(q, i),
                          icon: const Icon(Icons.close, size: 16, color: AppColors.onSurfaceVariant),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Remove',
                        ),
                      ],
                    ),
                  ),
          ),
        if (!readOnly)
          OutlinedButton.icon(
            onPressed: uploading ? null : () => _pickAndUploadFor(q),
            icon: uploading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.upload_file, size: 16),
            label: const Text('Attach a file'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.secondary),
          )
        else if (files.isEmpty)
          Text('No file submitted.', style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _markBadge(ExamQuestion q) {
    final marks = _submission?.marks[q.id] ?? 0;
    final full = marks >= q.marks;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: full ? AppColors.secondaryContainer.withValues(alpha: 0.15) : AppColors.errorContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${_formatMarks(marks)} / ${_formatMarks(q.marks)} marks',
        style: AppTypography.labelSm(color: full ? AppColors.secondary : AppColors.onErrorContainer).copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  // ── Palette sidebar ───────────────────────────────────────────────────────
  Widget _buildPaletteCard(bool graded) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Question Palette', style: AppTypography.headlineSm(color: AppColors.primary)),
                    Text('${_questions.length} Questions Total', style: AppTypography.bodySm()),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.secondaryContainer.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text('$_answeredCount Answered', style: AppTypography.labelSm(color: AppColors.secondary).copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_questions.isNotEmpty)
            GridView.count(
              crossAxisCount: 5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [for (var i = 0; i < _questions.length; i++) _paletteTile(_questions[i], i + 1)],
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _legendDot(AppColors.onTertiaryContainer, Icons.check, 'Answered ($_answeredCount)'),
              _legendDot(AppColors.error, null, 'Flagged (${_flagged.length})'),
              _legendDot(AppColors.surfaceContainerLow, null, 'Unanswered'),
            ],
          ),
          if (!graded) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: !_canSubmit || _submitting ? null : _openSubmitModal,
                icon: const Icon(Icons.verified, size: 18),
                label: const Text('Finish & Submit Exam'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _paletteTile(ExamQuestion q, int number) {
    final isAnswered = _isAnswered(q);
    final isFlagged = _flagged.contains(q.id);

    Color bg = AppColors.surfaceContainerLow;
    Color fg = AppColors.onSurfaceVariant;
    if (isAnswered) {
      bg = AppColors.surface;
      fg = AppColors.primary;
    }

    return GestureDetector(
      onTap: () => _scrollToQuestion(q.id),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Stack(
          children: [
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(number.toString().padLeft(2, '0'), style: AppTypography.labelLg(color: fg).copyWith(fontWeight: FontWeight.w700)),
                  if (isAnswered) const Icon(Icons.check, size: 12, color: AppColors.onTertiaryContainer),
                ],
              ),
            ),
            if (isFlagged)
              Positioned(
                top: 4,
                right: 4,
                child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, IconData? icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: icon != null ? Icon(icon, size: 9, color: AppColors.onTertiaryContainer) : null,
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.labelSm()),
      ],
    );
  }
}

// ── Submission confirmation dialog ─────────────────────────────────────────
class _SubmitDialog extends StatelessWidget {
  final int answeredCount;
  final int totalQuestions;
  final int flaggedCount;
  final VoidCallback onConfirm;

  const _SubmitDialog({
    required this.answeredCount,
    required this.totalQuestions,
    required this.flaggedCount,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final percent = totalQuestions == 0 ? 0 : ((answeredCount / totalQuestions) * 100).round();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: AppColors.secondaryContainer.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.assignment_turned_in, color: AppColors.secondary, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ready to Submit Exam?', style: AppTypography.headlineMd(color: AppColors.primary)),
                      Text('Review your answer distribution before finalizing.', style: AppTypography.bodySm()),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryRow('Completed Questions:', '$answeredCount of $totalQuestions ($percent%)', AppColors.primary),
                  const SizedBox(height: 6),
                  _summaryRow('Flagged for Review:', '$flaggedCount Questions', AppColors.error),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Return to Exam')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryContainer,
                    foregroundColor: AppColors.onSecondaryContainer,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Yes, Confirm Submission'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMd()),
        Text(value, style: AppTypography.labelMd(color: valueColor).copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
