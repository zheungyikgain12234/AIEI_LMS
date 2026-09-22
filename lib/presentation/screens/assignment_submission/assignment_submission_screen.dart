import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/core/utils/date_format.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_assignment_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturer_syllabus_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_submission_grading_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/assignment_criterion.dart';
import 'package:stitch_aiei_lms/domain/models/content_block.dart';
import 'package:stitch_aiei_lms/domain/models/content_block_submission.dart';
import 'package:stitch_aiei_lms/presentation/screens/faculty_portal/widgets/downloadable_file.dart';
import 'package:stitch_aiei_lms/presentation/screens/faculty_portal/widgets/faculty_mobile_top_bar.dart';

// ---------------------------------------------------------------------------
// AssignmentSubmissionScreen — a student's "View Assignment" page, reached
// by tapping an assignment on CourseContentScreen. Shows the assignment's
// info (description/instructions/due date/attached files) and lecturer-
// defined grading criteria, a writeup + file-upload submission form, and —
// once graded — the lecturer's per-criterion marks/feedback.
// ---------------------------------------------------------------------------
class AssignmentSubmissionScreen extends StatefulWidget {
  final String contentBlockId;
  final String sectionId;
  final String studentId;

  const AssignmentSubmissionScreen({
    super.key,
    required this.contentBlockId,
    required this.sectionId,
    required this.studentId,
  });

  @override
  State<AssignmentSubmissionScreen> createState() => _AssignmentSubmissionScreenState();
}

class _AssignmentSubmissionScreenState extends State<AssignmentSubmissionScreen> {
  final _syllabusRepository = SupabaseLecturerSyllabusRepositoryImpl(Supabase.instance.client);
  final _assignmentRepository = SupabaseAssignmentRepositoryImpl(Supabase.instance.client);
  final _gradingRepository = SupabaseSubmissionGradingRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  bool _submitting = false;
  ContentBlock? _block;
  List<AssignmentCriterion> _criteria = const [];
  ContentBlockSubmission? _submission;
  late final _writeupController = TextEditingController();
  List<Map<String, dynamic>> _files = [];
  bool _uploadingFile = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _writeupController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final block = await _syllabusRepository.getContentBlock(widget.contentBlockId);
    final criteria = await _assignmentRepository.getCriteria(widget.contentBlockId);
    final submission = await _gradingRepository.getSubmission(widget.contentBlockId, widget.studentId);
    if (!mounted) return;
    setState(() {
      _block = block;
      _criteria = criteria;
      _submission = submission;
      _writeupController.text = submission?.submission['writeup'] as String? ?? '';
      _files = (submission?.submission['files'] as List?)?.cast<Map<String, dynamic>>().toList() ?? [];
      _isLoading = false;
    });
  }

  double get _totalMarks => _criteria.fold<double>(0, (sum, c) => sum + c.maxMarks);

  bool get _canSubmit => _writeupController.text.trim().isNotEmpty || _files.isNotEmpty;

  Future<void> _pickAndUploadFile() async {
    final block = _block;
    if (block == null) return;
    final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) return;
    setState(() => _uploadingFile = true);
    try {
      final url = await _syllabusRepository.uploadContentFile(sessionId: block.sessionId, fileName: file.name, bytes: bytes);
      if (!mounted) return;
      setState(() {
        _files = [
          ..._files,
          {'name': file.name, 'url': url},
        ];
        _uploadingFile = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingFile = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  void _removeFile(int index) => setState(() => _files = [..._files]..removeAt(index));

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    await _gradingRepository.submitAnswer(
      contentBlockId: widget.contentBlockId,
      studentId: widget.studentId,
      submission: {
        if (_writeupController.text.trim().isNotEmpty) 'writeup': _writeupController.text.trim(),
        if (_files.isNotEmpty) 'files': _files,
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assignment submitted.')));
    Navigator.of(context).pop();
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
        appBar: const FacultyMobileTopBar(title: 'Assignment'),
        body: Center(child: Text('This assignment is no longer available.', style: FacultyTypography.bodyMd())),
      );
    }
    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: FacultyMobileTopBar(title: block.title?.isNotEmpty == true ? block.title! : 'Assignment'),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_submission?.isGraded ?? false) _gradeBanner(_submission!),
                  if (_submission?.isGraded ?? false) const SizedBox(height: 16),
                  _infoCard(block),
                  const SizedBox(height: 16),
                  if (_criteria.isNotEmpty) ...[
                    _criteriaCard(),
                    const SizedBox(height: 16),
                  ],
                  Text('Your Submission', style: FacultyTypography.headlineMd()),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _writeupController,
                    decoration: const InputDecoration(hintText: 'Write your submission here (optional if attaching files)...'),
                    maxLines: 6,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < _files.length; i++) _fileRow(i),
                  OutlinedButton.icon(
                    onPressed: _uploadingFile ? null : _pickAndUploadFile,
                    icon: _uploadingFile
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.upload_file, size: 16),
                    label: const Text('Attach a file'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: !_canSubmit || _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_outlined, size: 18),
                    label: Text(_submission == null ? 'Submit Assignment' : 'Resubmit Assignment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FacultyColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _gradeBanner(ContentBlockSubmission submission) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: FacultyColors.secondaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grading_outlined, color: FacultyColors.onSecondaryContainer),
              const SizedBox(width: 8),
              Text(
                'Graded: ${_formatMarks(submission.totalScore ?? 0)} / ${_formatMarks(_totalMarks)}',
                style: FacultyTypography.headlineMd(color: FacultyColors.onSecondaryContainer),
              ),
            ],
          ),
          if (submission.feedback?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(submission.feedback!, style: FacultyTypography.bodySm(color: FacultyColors.onSecondaryContainer)),
          ],
        ],
      ),
    );
  }

  Widget _infoCard(ContentBlock block) {
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
              if (block.dueDate != null) _chip(Icons.event_outlined, 'Due ${formatDueDate(block.dueDate!)}'),
              if (block.weightage != null) _chip(Icons.percent, '${_formatMarks(block.weightage!)}% of final grade'),
            ],
          ),
          if (block.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Text('Description', style: FacultyTypography.labelMd(color: FacultyColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(block.description!, style: FacultyTypography.bodySm(color: FacultyColors.onSurface)),
          ],
          if (block.instructions?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Text('Instructions', style: FacultyTypography.labelMd(color: FacultyColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(block.instructions!, style: FacultyTypography.bodySm(color: FacultyColors.onSurface)),
          ],
          if (block.instructionFiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Attached Files', style: FacultyTypography.labelMd(color: FacultyColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            for (final f in block.instructionFiles)
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

  Widget _chip(IconData icon, String label) {
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

  Widget _criteriaCard() {
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
          Text('Grading Criteria', style: FacultyTypography.headlineMd()),
          const SizedBox(height: 4),
          Text('Total: ${_formatMarks(_totalMarks)} marks', style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant)),
          const SizedBox(height: 10),
          for (final c in _criteria)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Expanded(child: Text(c.label, style: FacultyTypography.bodySm(color: FacultyColors.onSurface))),
                  Text('${_formatMarks(c.maxMarks)} marks', style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _fileRow(int index) {
    final f = _files[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.attach_file, size: 16, color: FacultyColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(child: Text('${f['name']}', style: FacultyTypography.bodySm(color: FacultyColors.onSurface))),
          IconButton(
            onPressed: () => _removeFile(index),
            icon: const Icon(Icons.close, size: 16, color: FacultyColors.onSurfaceVariant),
            visualDensity: VisualDensity.compact,
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}
