import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/utils/date_format.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_exam_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/exam_question.dart';
import 'package:stitch_aiei_lms/domain/models/exam_section.dart';
import 'widgets/downloadable_file.dart';
import 'widgets/faculty_mobile_top_bar.dart';
import 'widgets/required_field_label.dart';

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

  const ExamEditorScreen({
    super.key,
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

  bool _isLoading = true;
  List<ExamSection> _sections = [];
  final Map<String, List<ExamQuestion>> _questionsBySection = {};
  final Set<String> _expandedSections = {};
  final Set<String> _loadingSections = {};
  double _totalMarks = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final sections = await _repository.getSections(widget.contentBlockId);
    final totalMarks = await _repository.getTotalMarks(widget.contentBlockId);
    if (!mounted) return;
    setState(() {
      _sections = sections;
      _totalMarks = totalMarks;
      _isLoading = false;
    });
  }

  Future<void> _refreshTotalMarks() async {
    final totalMarks = await _repository.getTotalMarks(widget.contentBlockId);
    if (!mounted) return;
    setState(() => _totalMarks = totalMarks);
  }

  Future<void> _toggleSection(String sectionId) async {
    if (_expandedSections.contains(sectionId)) {
      setState(() => _expandedSections.remove(sectionId));
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
    await _repository.createSection(contentBlockId: widget.contentBlockId, name: name.trim());
    await _load();
  }

  Future<void> _editSection(ExamSection s) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _SectionNameDialog(dialogTitle: 'Rename Section', existingName: s.name),
    );
    if (name == null || name.trim().isEmpty) return;
    await _repository.renameSection(s.id, name: name.trim());
    await _load();
  }

  Future<void> _deleteSection(ExamSection s) async {
    final confirmed = await _confirmDelete(
      title: 'Delete section?',
      message: 'This deletes "${s.name}" and every question inside it. This cannot be undone.',
    );
    if (confirmed != true) return;
    await _repository.deleteSection(s.id);
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
    await _repository.createQuestion(
        sectionId: sectionId, text: result.text, type: result.type, marks: result.marks, options: result.options);
    await _refreshQuestionsFor(sectionId);
    await _refreshTotalMarks();
  }

  Future<void> _editQuestion(String sectionId, ExamQuestion q) async {
    final result = await showDialog<_QuestionFormResult>(context: context, builder: (_) => _QuestionDialog(existing: q));
    if (result == null) return;
    await _repository.updateQuestion(q.id, text: result.text, type: result.type, marks: result.marks, options: result.options);
    await _refreshQuestionsFor(sectionId);
    await _refreshTotalMarks();
  }

  Future<void> _deleteQuestion(String sectionId, ExamQuestion q) async {
    final confirmed = await _confirmDelete(title: 'Delete question?', message: 'This cannot be undone.');
    if (confirmed != true) return;
    await _repository.deleteQuestion(q.id);
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
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: FacultyColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save the new order: $e')));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
                      ElevatedButton.icon(
                        onPressed: _addSection,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Section'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FacultyColors.primary,
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
                    child: const Icon(Icons.drag_indicator, color: FacultyColors.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  Icon(expanded ? Icons.expand_more : Icons.chevron_right, color: FacultyColors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.name, style: FacultyTypography.titleSm())),
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
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _addQuestion(s.id),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Question'),
                        style: TextButton.styleFrom(foregroundColor: FacultyColors.primary, textStyle: FacultyTypography.labelMd()),
                      ),
                    ),
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.dialogTitle),
      content: SizedBox(
        width: 380,
        child: TextField(
          controller: _nameController,
          autofocus: true,
          decoration: InputDecoration(label: requiredLabel('Section name')),
          onChanged: (_) => setState(() {}),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _nameController.text.trim().isEmpty ? null : () => Navigator.of(context).pop(_nameController.text.trim()),
          child: const Text('Save'),
        ),
      ],
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

  bool get _canSave {
    if (_textController.text.trim().isEmpty) return false;
    final marks = _parsedMarks;
    if (marks == null || marks <= 0) return false;
    if (!_type.hasOptions) return true;
    final filled = _choices.where((c) => c._controller.text.trim().isNotEmpty).toList();
    return filled.length >= 2 && filled.any((c) => c.isCorrect);
  }

  void _save() {
    final options = <({String text, bool isCorrect})>[
      for (final c in _choices)
        if (c._controller.text.trim().isNotEmpty) (text: c._controller.text.trim(), isCorrect: c.isCorrect),
    ];
    Navigator.of(context)
        .pop<_QuestionFormResult>((text: _textController.text.trim(), type: _type, marks: _parsedMarks ?? 1, options: options));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Question' : 'Edit Question'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _textController,
                decoration: InputDecoration(label: requiredLabel('Question')),
                maxLines: 3,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _marksController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(label: requiredLabel('Marks this question is worth')),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<ExamQuestionType>(
                initialValue: _type,
                decoration: InputDecoration(label: requiredLabel('Question style')),
                items: const [
                  DropdownMenuItem(value: ExamQuestionType.singleChoice, child: Text('Single-select MCQ')),
                  DropdownMenuItem(value: ExamQuestionType.multiChoice, child: Text('Multi-select MCQ')),
                  DropdownMenuItem(value: ExamQuestionType.boolean, child: Text('True / False')),
                  DropdownMenuItem(value: ExamQuestionType.text, child: Text('Text input')),
                  DropdownMenuItem(value: ExamQuestionType.fileUpload, child: Text('File upload')),
                ],
                onChanged: _onTypeChanged,
              ),
              if (_type.hasOptions) ...[
                const SizedBox(height: 14),
                Text(
                  _type.allowsMultipleCorrect ? 'Choices — check every correct answer' : 'Choices — select the correct answer',
                  style: FacultyTypography.labelMd(color: FacultyColors.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                ..._choices.asMap().entries.map((entry) => _choiceRow(entry.key, entry.value)),
                if (_type != ExamQuestionType.boolean) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addChoice,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add choice'),
                      style: TextButton.styleFrom(foregroundColor: FacultyColors.primary),
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
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _canSave ? _save : null, child: const Text('Save')),
      ],
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
              decoration: InputDecoration(labelText: 'Choice ${index + 1}'),
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
