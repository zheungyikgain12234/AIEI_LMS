import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_assignment_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_submission_grading_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/assignment_criterion.dart';
import 'package:stitch_aiei_lms/domain/models/content_block_submission.dart';
import 'widgets/faculty_mobile_top_bar.dart';

// ---------------------------------------------------------------------------
// AssignmentGradingScreen — one student's assignment submission, opened from
// the roster on MarkAssignmentScreen. Shows the writeup/files read-only,
// a marks input per lecturer-defined criterion, overall feedback, a live
// running total, and Save Marks.
// ---------------------------------------------------------------------------
class AssignmentGradingScreen extends StatefulWidget {
  final String contentBlockId;
  final String studentId;
  final String studentName;

  const AssignmentGradingScreen({super.key, required this.contentBlockId, required this.studentId, required this.studentName});

  @override
  State<AssignmentGradingScreen> createState() => _AssignmentGradingScreenState();
}

class _AssignmentGradingScreenState extends State<AssignmentGradingScreen> {
  final _assignmentRepository = SupabaseAssignmentRepositoryImpl(Supabase.instance.client);
  final _gradingRepository = SupabaseSubmissionGradingRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  bool _saving = false;
  List<AssignmentCriterion> _criteria = const [];
  ContentBlockSubmission? _submission;
  final Map<String, TextEditingController> _marksControllers = {};
  late final _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _marksControllers.values) {
      c.dispose();
    }
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final criteria = await _assignmentRepository.getCriteria(widget.contentBlockId);
    final submission = await _gradingRepository.getSubmission(widget.contentBlockId, widget.studentId);
    if (!mounted) return;
    setState(() {
      _criteria = criteria;
      _submission = submission;
      for (final c in criteria) {
        final existingMark = submission?.marks[c.id];
        _marksControllers[c.id] = TextEditingController(text: existingMark?.toString() ?? '');
      }
      _feedbackController.text = submission?.feedback ?? '';
      _isLoading = false;
    });
  }

  double? _parsedMarksFor(AssignmentCriterion c) => double.tryParse(_marksControllers[c.id]?.text.trim() ?? '');

  double get _total {
    var total = 0.0;
    for (final c in _criteria) {
      total += (_parsedMarksFor(c) ?? 0).clamp(0, c.maxMarks);
    }
    return total;
  }

  double get _maxTotal => _criteria.fold<double>(0, (sum, c) => sum + c.maxMarks);

  bool get _canSave {
    if (_criteria.isEmpty) return false;
    for (final c in _criteria) {
      final marks = _parsedMarksFor(c);
      if (marks == null || marks < 0 || marks > c.maxMarks) return false;
    }
    return true;
  }

  Future<void> _saveMarks() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final marks = {for (final c in _criteria) c.id: _parsedMarksFor(c)!};
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
    Navigator.of(context).pop();
  }

  String _formatMarks(double marks) => marks.toStringAsFixed(marks.truncateToDouble() == marks ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final submission = _submission;
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
                  if (submission == null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: FacultyColors.errorContainer, borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        '${widget.studentName} hasn\'t submitted this assignment yet — marks can still be recorded, but there\'s no writeup to review.',
                        style: FacultyTypography.bodySm(color: FacultyColors.onErrorContainer),
                      ),
                    )
                  else
                    _submissionCard(submission),
                  const SizedBox(height: 20),
                  Text('Grading Criteria', style: FacultyTypography.headlineMd()),
                  const SizedBox(height: 12),
                  if (_criteria.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12)),
                      child: Text('No grading criteria have been set up for this assignment yet.', style: FacultyTypography.bodySm()),
                    )
                  else
                    for (final c in _criteria) _criterionRow(c),
                  const SizedBox(height: 16),
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

  Widget _submissionCard(ContentBlockSubmission submission) {
    final writeup = submission.submission['writeup'] as String?;
    final files = (submission.submission['files'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
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
          Text('Submission', style: FacultyTypography.headlineMd()),
          if (submission.submittedAt != null) ...[
            const SizedBox(height: 4),
            Text('Submitted ${submission.submittedAt}', style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant)),
          ],
          if (writeup != null && writeup.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(writeup, style: FacultyTypography.bodySm(color: FacultyColors.onSurface)),
          ],
          if (files.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final f in files) _fileRow(f),
          ],
        ],
      ),
    );
  }

  Widget _fileRow(Map<String, dynamic> f) {
    final url = f['url'] as String?;
    final name = f['name'] as String? ?? 'Attachment';
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: () => _openFile(url, name),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const Icon(Icons.download_outlined, size: 16, color: FacultyColors.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    name,
                    style: FacultyTypography.bodySm(color: FacultyColors.primary)
                        .copyWith(decoration: TextDecoration.underline),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (f['sizeLabel'] != null) ...[
                  const SizedBox(width: 6),
                  Text('(${f['sizeLabel']})', style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openFile(String? url, String name) async {
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No file preview available for "$name" in this preview.')));
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _criterionRow(AssignmentCriterion c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: FacultyColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(c.label, style: FacultyTypography.bodyMd(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              child: TextField(
                controller: _marksControllers[c.id],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                decoration: InputDecoration(isDense: true, suffixText: '/ ${_formatMarks(c.maxMarks)}'),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalAndSaveBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Total: ${_formatMarks(_total)} / ${_formatMarks(_maxTotal)}',
              style: FacultyTypography.headlineMd(color: FacultyColors.primary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: !_canSave || _saving ? null : _saveMarks,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save Marks'),
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
    );
  }
}
