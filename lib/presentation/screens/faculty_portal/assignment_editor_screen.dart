import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/core/utils/date_format.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_assignment_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/assignment_criterion.dart';
import 'widgets/downloadable_file.dart';
import 'widgets/faculty_mobile_top_bar.dart';
import 'widgets/required_field_label.dart';

// ---------------------------------------------------------------------------
// AssignmentEditorScreen — reached via "Manage Contents" on an assignment
// content block in the Syllabus editor. Shows the assignment's info
// (description, instructions, due date) set from the "Add Content" form,
// plus the lecturer-defined grading criteria (each worth a number of
// marks) that the "Mark Assignment" screen scores a student against.
// ---------------------------------------------------------------------------
class AssignmentEditorScreen extends StatefulWidget {
  final String contentBlockId;
  final String assignmentTitle;
  final String? description;
  final String? instructions;
  final DateTime? dueDate;
  final List<Map<String, dynamic>> instructionFiles;

  const AssignmentEditorScreen({
    super.key,
    required this.contentBlockId,
    required this.assignmentTitle,
    this.description,
    this.instructions,
    this.dueDate,
    this.instructionFiles = const [],
  });

  @override
  State<AssignmentEditorScreen> createState() => _AssignmentEditorScreenState();
}

class _AssignmentEditorScreenState extends State<AssignmentEditorScreen> {
  final _repository = SupabaseAssignmentRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  List<AssignmentCriterion> _criteria = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final criteria = await _repository.getCriteria(widget.contentBlockId);
    if (!mounted) return;
    setState(() {
      _criteria = criteria;
      _isLoading = false;
    });
  }

  double get _totalMarks => _criteria.fold<double>(0, (sum, c) => sum + c.maxMarks);

  Future<void> _addCriterion() async {
    final result = await showDialog<_CriterionFormResult>(context: context, builder: (_) => const _CriterionDialog());
    if (result == null) return;
    await _repository.createCriterion(contentBlockId: widget.contentBlockId, label: result.label, maxMarks: result.maxMarks);
    await _load();
  }

  Future<void> _editCriterion(AssignmentCriterion c) async {
    final result = await showDialog<_CriterionFormResult>(context: context, builder: (_) => _CriterionDialog(existing: c));
    if (result == null) return;
    await _repository.updateCriterion(c.id, label: result.label, maxMarks: result.maxMarks);
    await _load();
  }

  Future<void> _deleteCriterion(AssignmentCriterion c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete criterion?'),
        content: Text('This deletes "${c.label}" from the grading criteria. This cannot be undone.'),
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
    if (confirmed != true) return;
    await _repository.deleteCriterion(c.id);
    await _load();
  }

  Future<void> _reorderCriteria(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final previous = List<AssignmentCriterion>.from(_criteria);
    setState(() {
      final c = _criteria.removeAt(oldIndex);
      _criteria.insert(newIndex, c);
    });
    try {
      await _repository.reorderCriteria(widget.contentBlockId, [for (final c in _criteria) c.id]);
    } catch (e) {
      if (!mounted) return;
      setState(() => _criteria = previous);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save the new order: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: FacultyMobileTopBar(title: widget.assignmentTitle),
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
                  _infoCard(),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: FacultyColors.secondaryContainer, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.grading_outlined, size: 14, color: FacultyColors.onSecondaryContainer),
                        const SizedBox(width: 6),
                        Text('Total possible marks: ${_formatMarks(_totalMarks)}',
                            style: FacultyTypography.labelXs(color: FacultyColors.onSecondaryContainer)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Define the criteria a submission will be graded against.',
                          style: FacultyTypography.bodySm(),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addCriterion,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Criterion'),
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
                  _buildCriteriaList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatMarks(double marks) => marks.toStringAsFixed(marks.truncateToDouble() == marks ? 0 : 1);

  Widget _infoCard() {
    final hasAnyInfo = (widget.description?.isNotEmpty ?? false) ||
        (widget.instructions?.isNotEmpty ?? false) ||
        widget.dueDate != null ||
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
          if (widget.dueDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: FacultyColors.secondaryContainer, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_outlined, size: 14, color: FacultyColors.onSecondaryContainer),
                  const SizedBox(width: 6),
                  Text('Due ${formatDueDate(widget.dueDate!)}', style: FacultyTypography.labelXs(color: FacultyColors.onSecondaryContainer)),
                ],
              ),
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

  Widget _buildCriteriaList() {
    if (_criteria.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Text('No grading criteria yet. Add one to start building the rubric.', style: FacultyTypography.bodyMd()),
      );
    }
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorder: _reorderCriteria,
      itemCount: _criteria.length,
      itemBuilder: (context, index) {
        final c = _criteria[index];
        return Padding(key: ValueKey(c.id), padding: const EdgeInsets.only(bottom: 8), child: _criterionRow(c, index));
      },
    );
  }

  Widget _criterionRow(AssignmentCriterion c, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_indicator, size: 18, color: FacultyColors.onSurfaceVariant),
          ),
          const SizedBox(width: 8),
          Icon(Icons.checklist_rtl, size: 18, color: FacultyColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(c.label, style: FacultyTypography.bodyMd())),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: FacultyColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(6)),
            child: Text('${_formatMarks(c.maxMarks)} marks', style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant)),
          ),
          IconButton(
            onPressed: () => _editCriterion(c),
            icon: const Icon(Icons.edit_outlined, size: 16, color: FacultyColors.onSurfaceVariant),
            tooltip: 'Edit criterion',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: () => _deleteCriterion(c),
            icon: const Icon(Icons.close, size: 16, color: FacultyColors.onSurfaceVariant),
            tooltip: 'Remove',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CriterionDialog — add/edit a grading criterion: a label and the marks
// it's worth.
// ---------------------------------------------------------------------------
typedef _CriterionFormResult = ({String label, double maxMarks});

class _CriterionDialog extends StatefulWidget {
  final AssignmentCriterion? existing;

  const _CriterionDialog({this.existing});

  @override
  State<_CriterionDialog> createState() => _CriterionDialogState();
}

class _CriterionDialogState extends State<_CriterionDialog> {
  late final _labelController = TextEditingController(text: widget.existing?.label ?? '');
  late final _marksController = TextEditingController(text: (widget.existing?.maxMarks ?? 10).toString());

  @override
  void dispose() {
    _labelController.dispose();
    _marksController.dispose();
    super.dispose();
  }

  double? get _parsedMarks => double.tryParse(_marksController.text.trim());

  bool get _canSave {
    if (_labelController.text.trim().isEmpty) return false;
    final marks = _parsedMarks;
    return marks != null && marks > 0;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Criterion' : 'Edit Criterion'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _labelController,
              autofocus: true,
              decoration: InputDecoration(label: requiredLabel('Criterion (e.g. "Code Correctness")')),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _marksController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(label: requiredLabel('Marks this criterion is worth')),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _canSave
              ? () => Navigator.of(context)
                  .pop<_CriterionFormResult>((label: _labelController.text.trim(), maxMarks: _parsedMarks!))
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
