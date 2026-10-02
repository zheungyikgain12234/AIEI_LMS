import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/core/utils/date_format.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_submission_grading_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/content_block.dart';

/// Student-facing view of a `physicalClass` content block: the class's name,
/// description and date/time, plus a one-time attendance checkbox that's only
/// available from the scheduled time until the end of that day. Once ticked
/// (a `content_block_submissions` row) it becomes a large green "recorded"
/// box; after the window with no tick it just says the class is over.
class PhysicalClassAttendanceCard extends StatefulWidget {
  final ContentBlock block;
  final String studentId;

  const PhysicalClassAttendanceCard({super.key, required this.block, required this.studentId});

  @override
  State<PhysicalClassAttendanceCard> createState() => _PhysicalClassAttendanceCardState();
}

class _PhysicalClassAttendanceCardState extends State<PhysicalClassAttendanceCard> {
  final _repository = SupabaseSubmissionGradingRepositoryImpl(Supabase.instance.client);
  static const _green = Color(0xFF2E7D32);

  bool _isLoading = true;
  bool _attended = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final submission = await _repository.getSubmission(widget.block.id, widget.studentId);
    if (!mounted) return;
    setState(() {
      _attended = submission != null;
      _isLoading = false;
    });
  }

  Future<void> _tick() async {
    if (_saving || _attended) return;
    // Re-check at tap time — the screen may have been open past the window.
    if (widget.block.isPhysicalClassOver) {
      setState(() {});
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repository.submitAnswer(
        contentBlockId: widget.block.id,
        studentId: widget.studentId,
        submission: {'attended': true},
      );
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
    final at = b.scheduledAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(b.title?.isNotEmpty == true ? b.title! : 'Physical Class', style: FacultyTypography.bodyMd(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600)),
        if (at != null) ...[
          const SizedBox(height: 2),
          Text(formatDateRange(at, b.endsAt), style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant)),
        ],
        if (b.description?.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Text(b.description!, style: FacultyTypography.bodySm(color: FacultyColors.onSurface)),
        ],
        const SizedBox(height: 10),
        if (_isLoading)
          const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
        else
          _status(),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(_error!, style: FacultyTypography.labelXs(color: FacultyColors.error)),
        ],
      ],
    );
  }

  Widget _status() {
    final at = widget.block.scheduledAt;
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
    if (widget.block.isPhysicalClassOver) {
      return _notice(Icons.event_busy_outlined, 'This class is over.');
    }
    if (at != null && DateTime.now().isBefore(at)) {
      return _notice(Icons.schedule_outlined, 'Attendance opens at ${formatDueDate(at)}.');
    }
    return InkWell(
      onTap: _saving ? null : _tick,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: FacultyColors.primary),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(value: false, onChanged: _saving ? null : (_) => _tick()),
            Text('I am attending this class', style: FacultyTypography.bodyMd(color: FacultyColors.onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _notice(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: FacultyColors.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant))),
      ],
    );
  }
}
