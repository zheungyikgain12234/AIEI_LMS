import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_submission_grading_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/content_block.dart';
import 'package:stitch_aiei_lms/domain/repositories/submission_grading_repository.dart' show AttendanceStatus;

/// Student-facing view of a `physicalClass` content block: the class's name
/// and description, plus — read-only — the attendance the lecturer has marked
/// for this student (students can no longer tick their own attendance).
class PhysicalClassAttendanceCard extends StatefulWidget {
  final ContentBlock block;
  final String studentId;

  const PhysicalClassAttendanceCard({super.key, required this.block, required this.studentId});

  @override
  State<PhysicalClassAttendanceCard> createState() => _PhysicalClassAttendanceCardState();
}

class _PhysicalClassAttendanceCardState extends State<PhysicalClassAttendanceCard> {
  final _repository = SupabaseSubmissionGradingRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  String? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final submission = await _repository.getSubmission(widget.block.id, widget.studentId);
    if (!mounted) return;
    final marked = submission?.submission['attendance'];
    setState(() {
      // Older rows only have `attended: true`, which counts as Present.
      _status = marked is String ? marked : (submission?.submission['attended'] == true ? AttendanceStatus.present : null);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.block;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          b.title?.isNotEmpty == true ? b.title! : 'Physical Class',
          style: FacultyTypography.bodyMd(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600),
        ),
        if (b.description?.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Text(b.description!, style: FacultyTypography.bodySm(color: FacultyColors.onSurface)),
        ],
        const SizedBox(height: 8),
        if (_isLoading)
          const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
        else
          _statusRow(),
      ],
    );
  }

  Widget _statusRow() {
    final status = _status;
    final (icon, color, text) = switch (status) {
      AttendanceStatus.present => (Icons.check_circle_outline, const Color(0xFF2E7D32), 'Your attendance: Present'),
      AttendanceStatus.late => (Icons.schedule, const Color(0xFFB26A00), 'Your attendance: Late'),
      AttendanceStatus.validAbsent => (Icons.event_busy_outlined, FacultyColors.onSurfaceVariant, 'Your attendance: Valid absent'),
      AttendanceStatus.invalidAbsent => (Icons.cancel_outlined, FacultyColors.error, 'Your attendance: Invalid absent'),
      _ => (Icons.hourglass_empty, FacultyColors.onSurfaceVariant, 'Attendance not marked yet — your lecturer records it.'),
    };
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: FacultyTypography.bodySm(color: color))),
      ],
    );
  }
}
