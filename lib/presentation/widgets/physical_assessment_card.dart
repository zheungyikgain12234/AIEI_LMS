import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/core/utils/date_format.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_submission_grading_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/content_block.dart';

/// View of a physical (paper-based) exam or assignment block: its name, due
/// date/time and description. When [studentId] is given (the student's view)
/// it also shows a one-time attendance checkbox that's available only until
/// the due date; once ticked it becomes a large green "recorded" box, and
/// after the due date with no tick it says attendance is closed. Without a
/// [studentId] (the lecturer's syllabus row) it is read-only.
///
/// Attendance is stored as `submission.attended` on the student's
/// `content_block_submissions` row — the same row the lecturer's imported
/// marks land on, so the two never overwrite each other.
class PhysicalAssessmentCard extends StatefulWidget {
  final ContentBlock block;
  final String? studentId;

  const PhysicalAssessmentCard({super.key, required this.block, this.studentId});

  @override
  State<PhysicalAssessmentCard> createState() => _PhysicalAssessmentCardState();
}

class _PhysicalAssessmentCardState extends State<PhysicalAssessmentCard> {
  final _repository = SupabaseSubmissionGradingRepositoryImpl(Supabase.instance.client);
  static const _green = Color(0xFF2E7D32);

  bool _isLoading = false;
  bool _attended = false;
  bool _saving = false;
  String? _error;

  bool get _closed {
    final due = widget.block.dueDate;
    return due != null && !DateTime.now().isBefore(due);
  }

  @override
  void initState() {
    super.initState();
    if (widget.studentId != null) {
      _isLoading = true;
      _load();
    }
  }

  Future<void> _load() async {
    final submission = await _repository.getSubmission(widget.block.id, widget.studentId!);
    if (!mounted) return;
    setState(() {
      _attended = submission?.submission['attended'] == true;
      _isLoading = false;
    });
  }

  Future<void> _tick() async {
    if (_saving || _attended) return;
    // Re-check at tap time — the screen may have been open past the due date.
    if (_closed) {
      setState(() {});
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repository.recordAttendance(contentBlockId: widget.block.id, studentId: widget.studentId!);
      if (!mounted) return;
      setState(() {
        _attended = true;
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not record attendance: $e';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.block;
    final isExam = b.type == ContentBlockType.physicalExam;
    final due = b.dueDate;
    final fallback = isExam ? 'Physical Exam' : 'Physical Assignment';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(b.title?.isNotEmpty == true ? b.title! : fallback, style: FacultyTypography.bodySm(color: FacultyColors.onSurface)),
        Text(
          due == null ? 'Paper-based' : 'Paper-based • Due ${formatDueDate(due)}',
          style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant),
        ),
        if (b.description?.isNotEmpty == true) ...[
          const SizedBox(height: 2),
          Text(b.description!, style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant)),
        ],
        if (widget.studentId != null) ...[
          const SizedBox(height: 10),
          if (_isLoading) const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) else _status(isExam),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(_error!, style: FacultyTypography.labelXs(color: FacultyColors.error)),
          ],
        ],
      ],
    );
  }

  Widget _status(bool isExam) {
    if (_attended) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            const Icon(Icons.check_rounded, size: 72, color: Colors.white),
            const SizedBox(height: 4),
            Text('Attendance recorded', style: FacultyTypography.titleSm(color: Colors.white)),
          ],
        ),
      );
    }
    if (_closed) {
      return Row(
        children: [
          const Icon(Icons.event_busy_outlined, size: 16, color: FacultyColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(child: Text('Attendance is closed.', style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant))),
        ],
      );
    }
    return InkWell(
      onTap: _saving ? null : _tick,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(border: Border.all(color: FacultyColors.primary), borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(value: false, onChanged: _saving ? null : (_) => _tick()),
            Text(isExam ? 'I am attending this exam' : 'I am attending this assignment', style: FacultyTypography.bodyMd(color: FacultyColors.onSurface)),
          ],
        ),
      ),
    );
  }
}
