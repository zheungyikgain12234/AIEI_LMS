import 'package:stitch_aiei_lms/core/utils/dropdown_sort.dart';
import 'package:stitch_aiei_lms/presentation/screens/admin_portal/widgets/admin_field_error.dart';
import 'package:stitch_aiei_lms/core/utils/input_formatters.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/presentation/widgets/skeleton.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/utils/date_format.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_students_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_app_settings_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_exam_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_submission_grading_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/exam_question.dart';
import 'package:stitch_aiei_lms/domain/models/exam_section.dart';
import 'package:stitch_aiei_lms/domain/repositories/app_settings_repository.dart';
import 'widgets/downloadable_file.dart';
import 'widgets/faculty_mobile_top_bar.dart';
import 'widgets/faculty_dialog.dart';

// ---------------------------------------------------------------------------
// ExamEditorScreen — reached via "Manage Contents" on an exam content block in the
// Syllabus editor. Mirrors that screen's shape: sections (like modules),
// each holding any number of questions, each optionally holding its answer
// choices (single/multi-choice and true/false; free-text has none).
// ---------------------------------------------------------------------------
class ExamEditorScreen extends StatefulWidget {
  final String contentBlockId;
  final String examTitle;
  final String? description;
  final String? instructions;
  final DateTime? dueDate;
  final String? mode;
  final List<Map<String, dynamic>> instructionFiles;

  /// View-only: nothing can be added, edited, deleted or reordered (admins
  /// reviewing a syllabus they aren't allowed to edit).
  final bool readOnly;

  /// A saved template's snapshot of this exam (see the repository's block-tree
  /// snapshot). When given, the screen shows it read-only instead of loading
  /// a real content block from the database.
  final Map<String, dynamic>? previewTree;

  /// Called whenever this screen changes the syllabus itself (sections,
  /// questions, criteria, ordering). Not called by actions that leave the
  /// syllabus untouched, such as allowing a student to re-attempt.
  final VoidCallback? onEdited;

  const ExamEditorScreen({
    super.key,
    this.onEdited,
    this.readOnly = false,
    this.previewTree,
    required this.contentBlockId,
    required this.examTitle,
    this.description,
    this.instructions,
    this.dueDate,
    this.mode,
    this.instructionFiles = const [],
  });

  @override
  State<ExamEditorScreen> createState() => _ExamEditorScreenState();
}

class _ExamEditorScreenState extends State<ExamEditorScreen> {
  final _repository = SupabaseExamRepositoryImpl(Supabase.instance.client);
  final _studentsRepository = SupabaseAdminStudentsRepositoryImpl(Supabase.instance.client);
  final _gradingRepository = SupabaseSubmissionGradingRepositoryImpl(Supabase.instance.client);
  final _settingsRepository = SupabaseAppSettingsRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  List<ExamSection> _sections = [];
  final Map<String, List<ExamQuestion>> _questionsBySection = {};
  final Set<String> _expandedSections = {};
  final Set<String> _loadingSections = {};
  double _totalMarks = 0;
  bool _allowExamReset = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    if (widget.previewTree != null) {
      _loadPreview();
      return;
    }
    final sections = await _repository.getSections(widget.contentBlockId);
    final totalMarks = await _repository.getTotalMarks(widget.contentBlockId);
    final settings = await _settingsRepository.getSettings();
    if (!mounted) return;
    setState(() {
      _sections = sections;
      _totalMarks = totalMarks;
      _allowExamReset = settings[AppSettingKeys.allowLecturerExamReset] ?? false;
      _isLoading = false;
    });
  }

  Future<void> _resetAttempt(String code) async {
    final student = await _studentsRepository.getStudentByCode(code);
    if (!mounted) return;
    if (student == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No student found with code "$code".')));
      return;
    }
    await _gradingRepository.resetAttempt(contentBlockId: widget.contentBlockId, studentId: student.id);
    if (!mounted) return;
    showSuccessSnackBar(context, '${student.name}\'s attempt was reset — they can attempt this exam again.');
  }

  Future<void> _refreshTotalMarks() async {
    final totalMarks = await _repository.getTotalMarks(widget.contentBlockId);
    if (!mounted) return;
    setState(() => _totalMarks = totalMarks);
  }

  /// Builds the section / question lists from the template snapshot (no database ids).
  void _loadPreview() {
    final raw = (widget.previewTree!['sections'] as List?) ?? const [];
    final sections = <ExamSection>[];
    var total = 0.0;
    for (var i = 0; i < raw.length; i++) {
      final s = raw[i] as Map;
      final sectionId = 'preview-s$i';
      sections.add(ExamSection(id: sectionId, contentBlockId: widget.contentBlockId, name: (s['name'] as String?) ?? '', sorting: i));
      final questions = <ExamQuestion>[];
      final rawQuestions = (s['questions'] as List?) ?? const [];
      for (var j = 0; j < rawQuestions.length; j++) {
        final q = rawQuestions[j] as Map;
        final marks = (q['marks'] as num?)?.toDouble() ?? 1;
        total += marks;
        final rawOptions = (q['options'] as List?) ?? const [];
        questions.add(ExamQuestion(
          id: 'preview-s$i-q$j',
          sectionId: sectionId,
          text: (q['text'] as String?) ?? '',
          type: ExamQuestionType.fromKey((q['type'] as String?) ?? 'text'),
          marks: marks,
          sorting: j,
          options: [
            for (var k = 0; k < rawOptions.length; k++)
              ExamQuestionOption(
                id: 'preview-s$i-q$j-o$k',
                text: ((rawOptions[k] as Map)['text'] as String?) ?? '',
                isCorrect: (rawOptions[k] as Map)['correct'] == true,
                sorting: k,
              ),
          ],
        ));
      }
      _questionsBySection[sectionId] = questions;
    }
    setState(() {
      _sections = sections;
      _totalMarks = total;
      _isLoading = false;
    });
  }

  Future<void> _toggleSection(String sectionId) async {
    if (_expandedSections.contains(sectionId)) {
      setState(() => _expandedSections.remove(sectionId));
      return;
    }
    if (widget.previewTree != null) {
      setState(() => _expandedSections.add(sectionId));
      return;
    }
    setState(() {
      _expandedSections.add(sectionId);
      _loadingSections.add(sectionId);
    });
    final questions = await _repository.getQuestions(sectionId);
    if (!mounted) return;
    setState(() {
      _questionsBySection[sectionId] = questions;
      _loadingSections.remove(sectionId);
    });
  }

  Future<void> _refreshQuestionsFor(String sectionId) async {
    final questions = await _repository.getQuestions(sectionId);
    if (!mounted) return;
    setState(() => _questionsBySection[sectionId] = questions);
  }

  // ── Section CRUD ─────────────────────────────────────────────────────

  Future<void> _addSection() async {
    final name = await showDialog<String>(context: context, builder: (_) => const _SectionNameDialog(dialogTitle: 'Add Section'));
    if (name == null || name.trim().isEmpty) return;
    widget.onEdited?.call();
    await _repository.createSection(contentBlockId: widget.contentBlockId, name: name.trim());
    if (mounted) showSuccessSnackBar(context, 'Section added.');
    await _load();
  }

  Future<void> _editSection(ExamSection s) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _SectionNameDialog(dialogTitle: 'Rename Section', existingName: s.name),
    );
    if (name == null || name.trim().isEmpty) return;
    widget.onEdited?.call();
    await _repository.renameSection(s.id, name: name.trim());
    if (mounted) showSuccessSnackBar(context, 'Section renamed.');
    await _load();
  }

  Future<void> _deleteSection(ExamSection s) async {
    final confirmed = await _confirmDelete(
      title: 'Delete section?',
      message: 'This deletes "${s.name}" and every question inside it. This cannot be undone.',
    );
    if (confirmed != true) return;
    widget.onEdited?.call();
    await _repository.deleteSection(s.id);
    if (mounted) showSuccessSnackBar(context, 'Section deleted.');
    _expandedSections.remove(s.id);
    _questionsBySection.remove(s.id);
    await _load();
  }

  Future<void> _reorderSections(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final previous = List<ExamSection>.from(_sections);
    setState(() {
      final s = _sections.removeAt(oldIndex);
      _sections.insert(newIndex, s);
    });
    try {
      widget.onEdited?.call();
      await _repository.reorderSections(widget.contentBlockId, [for (final s in _sections) s.id]);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sections = previous);
      _showError(e);
    }
  }

  // ── Question CRUD ────────────────────────────────────────────────────

  Future<void> _addQuestion(String sectionId) async {
    final result = await showDialog<_QuestionFormResult>(context: context, builder: (_) => const _QuestionDialog());
    if (result == null) return;
    widget.onEdited?.call();
    await _repository.createQuestion(
        sectionId: sectionId, text: result.text, type: result.type, marks: result.marks, options: result.options);
    if (mounted) showSuccessSnackBar(context, 'Question added.');
    await _refreshQuestionsFor(sectionId);
    await _refreshTotalMarks();
  }

  Future<void> _editQuestion(String sectionId, ExamQuestion q) async {
    final result = await showDialog<_QuestionFormResult>(context: context, builder: (_) => _QuestionDialog(existing: q));
    if (result == null) return;
    widget.onEdited?.call();
    await _repository.updateQuestion(q.id, text: result.text, type: result.type, marks: result.marks, options: result.options);
    if (mounted) showSuccessSnackBar(context, 'Question updated.');
    await _refreshQuestionsFor(sectionId);
    await _refreshTotalMarks();
  }

  Future<void> _deleteQuestion(String sectionId, ExamQuestion q) async {
    final confirmed = await _confirmDelete(title: 'Delete question?', message: 'This cannot be undone.');
    if (confirmed != true) return;
    widget.onEdited?.call();
    await _repository.deleteQuestion(q.id);
    if (mounted) showSuccessSnackBar(context, 'Question deleted.');
    await _refreshQuestionsFor(sectionId);
    await _refreshTotalMarks();
  }

  Future<void> _reorderQuestions(String sectionId, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final previous = List<ExamQuestion>.from(_questionsBySection[sectionId] ?? const []);
    final questions = List<ExamQuestion>.from(previous);
    final q = questions.removeAt(oldIndex);
    questions.insert(newIndex, q);
    setState(() => _questionsBySection[sectionId] = questions);
    try {
      widget.onEdited?.call();
      await _repository.reorderQuestions(sectionId, [for (final q in questions) q.id]);
    } catch (e) {
      if (!mounted) return;
      setState(() => _questionsBySection[sectionId] = previous);
      _showError(e);
    }
  }

  Future<bool?> _confirmDelete({required String title, required String message}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => FacultyDialog(
        title: title,
        confirmLabel: 'Delete',
        destructive: true,
        onConfirm: () => Navigator.of(ctx).pop(true),
        child: Text(message, style: FacultyTypography.bodyMd()),
      ),
    );
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save the new order: $e')));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SkeletonScaffold();
    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: FacultyMobileTopBar(title: widget.examTitle),
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
                  _examInfoCard(),
                  if (_allowExamReset && !widget.readOnly) ...[
                    const SizedBox(height: 12),
                    _ResetAttemptCard(onReset: _resetAttempt),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: FacultyColors.secondaryContainer, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.grading_outlined, size: 14, color: FacultyColors.onSecondaryContainer),
                        const SizedBox(width: 6),
                        Text('Total marks: ${_totalMarks.toStringAsFixed(_totalMarks.truncateToDouble() == _totalMarks ? 0 : 1)}',
                            style: FacultyTypography.labelXs(color: FacultyColors.onSecondaryContainer)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Build the sections and questions students will answer for this exam.',
                          style: FacultyTypography.bodySm(),
                        ),
                      ),
                      if (!widget.readOnly)
                      ElevatedButton.icon(
                        onPressed: _addSection,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Section', textAlign: TextAlign.center),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.primaryContainer,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _examInfoCard() {
    final hasAnyInfo = (widget.description?.isNotEmpty ?? false) ||
        (widget.instructions?.isNotEmpty ?? false) ||
        widget.dueDate != null ||
        (widget.mode?.isNotEmpty ?? false) ||
        widget.instructionFiles.isNotEmpty;
    if (!hasAnyInfo) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (widget.mode?.isNotEmpty ?? false) _infoChip(Icons.rule_folder_outlined, _modeLabel(widget.mode!)),
              if (widget.dueDate != null) _infoChip(Icons.event_outlined, 'Due ${formatDueDate(widget.dueDate!)}'),
            ],
          ),
          if (widget.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Text('Description', style: FacultyTypography.labelMd(color: FacultyColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(widget.description!, style: FacultyTypography.bodySm(color: FacultyColors.onSurface)),
          ],
          if (widget.instructions?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Text('Instructions', style: FacultyTypography.labelMd(color: FacultyColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(widget.instructions!, style: FacultyTypography.bodySm(color: FacultyColors.onSurface)),
          ],
          if (widget.instructionFiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Attached Files', style: FacultyTypography.labelMd(color: FacultyColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            for (final f in widget.instructionFiles)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: DownloadableFile(
                  url: f['url'] as String? ?? '',
                  label: f['name'] as String? ?? f['url'] as String? ?? 'Attachment',
                  style: FacultyTypography.bodySm(color: FacultyColors.onSurface),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: FacultyColors.secondaryContainer, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: FacultyColors.onSecondaryContainer),
          const SizedBox(width: 6),
          Text(label, style: FacultyTypography.labelXs(color: FacultyColors.onSecondaryContainer)),
        ],
      ),
    );
  }

  String _modeLabel(String mode) {
    switch (mode) {
      case 'open_book':
        return 'Open-book';
      case 'take_home':
        return 'Take-home test';
      case 'normal':
      default:
        return 'Normal';
    }
  }

  Widget _buildSectionList() {
    if (_sections.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Text('No sections yet. Add one to start building the exam.', style: FacultyTypography.bodyMd()),
      );
    }
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorder: _reorderSections,
      itemCount: _sections.length,
      itemBuilder: (context, index) {
        final s = _sections[index];
        return Padding(key: ValueKey(s.id), padding: const EdgeInsets.only(bottom: 12), child: _sectionCard(s, index));
      },
    );
  }

  Widget _sectionCard(ExamSection s, int index) {
    final expanded = _expandedSections.contains(s.id);
    final loading = _loadingSections.contains(s.id);
    final questions = _questionsBySection[s.id] ?? const <ExamQuestion>[];
    return Container(
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleSection(s.id),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    enabled: !widget.readOnly,
                    child: const Icon(Icons.drag_indicator, color: FacultyColors.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  Icon(expanded ? Icons.expand_more : Icons.chevron_right, color: FacultyColors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.name, style: FacultyTypography.titleSm())),
                  if (!widget.readOnly) ...[
                  IconButton(
                    onPressed: () => _editSection(s),
                    icon: const Icon(Icons.edit_outlined, size: 18, color: FacultyColors.onSurfaceVariant),
                    tooltip: 'Rename section',
                  ),
                  IconButton(
                    onPressed: () => _deleteSection(s),
                    icon: const Icon(Icons.delete_outline, size: 18, color: FacultyColors.error),
                    tooltip: 'Delete section',
                  ),
                  ],
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1, color: FacultyColors.surfaceContainer),
                  const SizedBox(height: 12),
                  if (loading)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                  else ...[
                    if (questions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('No questions yet.', style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant)),
                      )
                    else
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        onReorder: (oldIndex, newIndex) => _reorderQuestions(s.id, oldIndex, newIndex),
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          final q = questions[index];
                          return Padding(
                            key: ValueKey(q.id),
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _questionRow(s.id, q, index),
                          );
                        },
                      ),
                    if (!widget.readOnly) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _addQuestion(s.id),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Question', textAlign: TextAlign.center),
                        style: TextButton.styleFrom(foregroundColor: AdminColors.primaryContainer, textStyle: FacultyTypography.labelMd()),
                      ),
                    ),
                    ],
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _questionRow(String sectionId, ExamQuestion q, int index) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderableDragStartListener(
            index: index,
            enabled: !widget.readOnly,
            child: const Icon(Icons.drag_indicator, size: 18, color: FacultyColors.onSurfaceVariant),
          ),
          const SizedBox(width: 8),
          Icon(_iconFor(q.type), size: 18, color: FacultyColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(q.text.isEmpty ? '(empty question)' : q.text, style: FacultyTypography.bodyMd())),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: FacultyColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        '${q.marks.toStringAsFixed(q.marks.truncateToDouble() == q.marks ? 0 : 1)} marks',
                        style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: FacultyColors.secondaryContainer, borderRadius: BorderRadius.circular(6)),
                      child: Text(_labelFor(q.type), style: FacultyTypography.labelXs(color: FacultyColors.onSecondaryContainer)),
                    ),
                  ],
                ),
                if (q.type.hasOptions && q.options.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...q.options.map(
                    (o) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(
                            o.isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 14,
                            color: o.isCorrect ? FacultyColors.primary : FacultyColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(child: Text(o.text, style: FacultyTypography.bodySm(color: FacultyColors.onSurface))),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!widget.readOnly) ...[
          IconButton(
            onPressed: () => _editQuestion(sectionId, q),
            icon: const Icon(Icons.edit_outlined, size: 16, color: FacultyColors.onSurfaceVariant),
            tooltip: 'Edit question',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: () => _deleteQuestion(sectionId, q),
            icon: const Icon(Icons.close, size: 16, color: FacultyColors.onSurfaceVariant),
            tooltip: 'Remove',
            visualDensity: VisualDensity.compact,
          ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(ExamQuestionType type) {
    switch (type) {
      case ExamQuestionType.singleChoice:
        return Icons.radio_button_checked;
      case ExamQuestionType.multiChoice:
        return Icons.checklist;
      case ExamQuestionType.boolean:
        return Icons.rule;
      case ExamQuestionType.text:
        return Icons.short_text;
      case ExamQuestionType.fileUpload:
        return Icons.upload_file_outlined;
    }
  }

  String _labelFor(ExamQuestionType type) {
    switch (type) {
      case ExamQuestionType.singleChoice:
        return 'Single-select MCQ';
      case ExamQuestionType.multiChoice:
        return 'Multi-select MCQ';
      case ExamQuestionType.boolean:
        return 'True / False';
      case ExamQuestionType.text:
        return 'Text input';
      case ExamQuestionType.fileUpload:
        return 'File upload';
    }
  }
}

// ---------------------------------------------------------------------------
// _ResetAttemptCard — admin-gated (AppSettingKeys.allowLecturerExamReset)
// control letting a lecturer clear one student's exam submission by typing
// in their student code, so that student can attempt the exam again.
// ---------------------------------------------------------------------------
class _ResetAttemptCard extends StatefulWidget {
  final Future<void> Function(String code) onReset;

  const _ResetAttemptCard({required this.onReset});

  @override
  State<_ResetAttemptCard> createState() => _ResetAttemptCardState();
}

class _ResetAttemptCardState extends State<_ResetAttemptCard> {
  final _codeController = TextEditingController();
  bool _resetting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _resetting = true);
    try {
      await widget.onReset(code);
      _codeController.clear();
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reset a Student\'s Attempt', style: FacultyTypography.titleSm()),
          const SizedBox(height: 4),
          Text(
            'Clears a student\'s submission for this exam so they can attempt it again.',
            style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  enabled: !_resetting,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(hintText: 'Student code, e.g. EMP-88219', isDense: true),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _resetting ? null : _submit,
                icon: _resetting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.restart_alt, size: 18),
                label: const Text('Reset Attempt', textAlign: TextAlign.center),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FacultyColors.error,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

// ---------------------------------------------------------------------------
// _SectionNameDialog — shared Add/Rename form for exam sections.
// ---------------------------------------------------------------------------
class _SectionNameDialog extends StatefulWidget {
  final String dialogTitle;
  final String? existingName;

  const _SectionNameDialog({required this.dialogTitle, this.existingName});

  @override
  State<_SectionNameDialog> createState() => _SectionNameDialogState();
}

class _SectionNameDialogState extends State<_SectionNameDialog> {
  late final _nameController = TextEditingController(text: widget.existingName ?? '');
  String? _nameError;

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Section name is required.');
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FacultyDialog(
      title: widget.dialogTitle,
      subtitle: 'Sections group related questions in the exam.',
      onConfirm: _submit,
      child: FacultyFormField(
        controller: _nameController,
        label: 'Section name',
        autofocus: true,
        errorText: _nameError,
        onChanged: (_) => setState(() => _nameError = null),
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _QuestionDialog — add/edit a question: text, type dropdown, and (for
// single/multi-choice + true/false) its answer choices with a
// radio/checkbox next to each to mark the expected answer(s).
// ---------------------------------------------------------------------------
typedef _QuestionFormResult = ({String text, ExamQuestionType type, double marks, List<({String text, bool isCorrect})> options});

class _QuestionDialog extends StatefulWidget {
  final ExamQuestion? existing;

  const _QuestionDialog({this.existing});

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _ChoiceDraft {
  final _controller = TextEditingController();
  bool isCorrect;
  _ChoiceDraft({String text = '', this.isCorrect = false}) {
    _controller.text = text;
  }
}

class _QuestionDialogState extends State<_QuestionDialog> {
  late final _textController = TextEditingController(text: widget.existing?.text ?? '');
  late final _marksController = TextEditingController(text: (widget.existing?.marks ?? 1).toString());
  late ExamQuestionType _type = widget.existing?.type ?? ExamQuestionType.singleChoice;
  late List<_ChoiceDraft> _choices = _initialChoices();

  List<_ChoiceDraft> _initialChoices() {
    final existing = widget.existing;
    if (existing != null && existing.type.hasOptions && existing.options.isNotEmpty) {
      return [for (final o in existing.options) _ChoiceDraft(text: o.text, isCorrect: o.isCorrect)];
    }
    if ((widget.existing?.type ?? ExamQuestionType.singleChoice) == ExamQuestionType.boolean) {
      return [_ChoiceDraft(text: 'True', isCorrect: true), _ChoiceDraft(text: 'False')];
    }
    return [_ChoiceDraft(), _ChoiceDraft()];
  }

  @override
  void dispose() {
    _textController.dispose();
    _marksController.dispose();
    for (final c in _choices) {
      c._controller.dispose();
    }
    super.dispose();
  }

  void _onTypeChanged(ExamQuestionType? t) {
    if (t == null) return;
    setState(() {
      _type = t;
      if (t == ExamQuestionType.boolean) {
        for (final c in _choices) {
          c._controller.dispose();
        }
        _choices = [_ChoiceDraft(text: 'True', isCorrect: true), _ChoiceDraft(text: 'False')];
      }
    });
  }

  void _addChoice() => setState(() => _choices.add(_ChoiceDraft()));

  void _removeChoice(int index) => setState(() {
        _choices[index]._controller.dispose();
        _choices.removeAt(index);
      });

  void _selectCorrect(int index) => setState(() {
        if (_type.allowsMultipleCorrect) {
          _choices[index].isCorrect = !_choices[index].isCorrect;
        } else {
          for (var i = 0; i < _choices.length; i++) {
            _choices[i].isCorrect = i == index;
          }
        }
      });

  double? get _parsedMarks => double.tryParse(_marksController.text.trim());

  bool _submitted = false;
  Map<String, String> _errors = {};

  Map<String, String> _validate() {
    final errors = <String, String>{};
    if (_textController.text.trim().isEmpty) errors['text'] = 'Question is required.';
    final marks = _parsedMarks;
    if (marks == null || marks <= 0) {
      errors['marks'] = 'Marks must be greater than 0.';
    } else if (marks > maxMarksLimit) {
      errors['marks'] = 'Marks cannot exceed ${maxMarksLimit.toInt()}.';
    }
    if (_type.hasOptions) {
      final filled = _choices.where((c) => c._controller.text.trim().isNotEmpty).toList();
      if (filled.length < 2) {
        errors['choices'] = 'Enter at least two choices.';
      } else if (!filled.any((c) => c.isCorrect)) {
        errors['choices'] = 'Mark at least one correct answer.';
      }
    }
    return errors;
  }

  void _save() {
    final errors = _validate();
    setState(() {
      _submitted = true;
      _errors = errors;
    });
    if (errors.isNotEmpty) return;
    final options = <({String text, bool isCorrect})>[
      for (final c in _choices)
        if (c._controller.text.trim().isNotEmpty) (text: c._controller.text.trim(), isCorrect: c.isCorrect),
    ];
    Navigator.of(context)
        .pop<_QuestionFormResult>((text: _textController.text.trim(), type: _type, marks: _parsedMarks ?? 1, options: options));
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) _errors = _validate();
    return FacultyDialog(
      title: widget.existing == null ? 'Add Question' : 'Edit Question',
      subtitle: 'Write the question, set its marks and choose how students answer.',
      maxWidth: 560,
      confirmLabel: widget.existing == null ? 'Add Question' : 'Save Changes',
      onConfirm: _save,
      child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabeledField(label: 'Question', required: true, child: TextField(
                controller: _textController,
                decoration: const InputDecoration(),
                maxLines: 3,
                onChanged: (_) => setState(() {}),
              )),
              AdminFieldError(_errors['text']),
              const SizedBox(height: 14),
              LabeledField(label: 'Marks this question is worth', required: true, child: TextField(
                controller: _marksController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: decimalOnly,
                decoration: const InputDecoration(),
                onChanged: (_) => setState(() {}),
              )),
              AdminFieldError(_errors['marks']),
              const SizedBox(height: 14),
              LabeledField(label: 'Question style', required: true, child: DropdownButtonFormField<ExamQuestionType>(
                initialValue: _type,
                decoration: const InputDecoration(),
                icon: const Icon(Icons.expand_more, size: 18, color: FacultyColors.onSurfaceVariant),
                items: sortDropdownItems(const [
                  DropdownMenuItem(value: ExamQuestionType.singleChoice, child: Text('Single-select MCQ')),
                  DropdownMenuItem(value: ExamQuestionType.multiChoice, child: Text('Multi-select MCQ')),
                  DropdownMenuItem(value: ExamQuestionType.boolean, child: Text('True / False')),
                  DropdownMenuItem(value: ExamQuestionType.text, child: Text('Text input')),
                  DropdownMenuItem(value: ExamQuestionType.fileUpload, child: Text('File upload')),
                ]),
                onChanged: _onTypeChanged,
              )),
              if (_type.hasOptions) ...[
                const SizedBox(height: 14),
                Text(
                  _type.allowsMultipleCorrect ? 'Choices — check every correct answer' : 'Choices — select the correct answer',
                  style: FacultyTypography.labelMd(color: FacultyColors.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                ..._choices.asMap().entries.map((entry) => _choiceRow(entry.key, entry.value)),
                AdminFieldError(_errors['choices']),
                if (_type != ExamQuestionType.boolean) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addChoice,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add choice', textAlign: TextAlign.center),
                      style: TextButton.styleFrom(foregroundColor: AdminColors.primaryContainer),
                    ),
                  ),
                ],
              ],
              if (_type == ExamQuestionType.fileUpload) ...[
                const SizedBox(height: 10),
                Text(
                  'Students will attach one or more files as their answer — graded manually, like a text question.',
                  style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant),
                ),
              ],
            ],
          ),
    );
  }

  Widget _choiceRow(int index, _ChoiceDraft choice) {
    final isBoolean = _type == ExamQuestionType.boolean;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          _type.allowsMultipleCorrect
              ? Checkbox(value: choice.isCorrect, onChanged: (_) => _selectCorrect(index))
              : Radio<int>(value: index, groupValue: _choices.indexWhere((c) => c.isCorrect), onChanged: (_) => _selectCorrect(index)),
          Expanded(
            child: TextField(
              controller: choice._controller,
              enabled: !isBoolean,
              decoration: InputDecoration(hintText: 'Choice ${index + 1}'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (!isBoolean && _choices.length > 2)
            IconButton(
              onPressed: () => _removeChoice(index),
              icon: const Icon(Icons.close, size: 18, color: FacultyColors.onSurfaceVariant),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
