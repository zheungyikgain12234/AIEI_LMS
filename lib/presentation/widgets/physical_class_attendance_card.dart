import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/core/utils/class_schedule.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_submission_grading_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/content_block.dart';
import 'package:stitch_aiei_lms/domain/repositories/submission_grading_repository.dart' show AttendanceStatus;

/// Student-facing view of a `physicalClass` or `physicalExam` content block:
/// its name, the day and time it takes place (the class's schedule), plus —
/// read-only — the attendance the lecturer has marked for this student
/// (students can't tick their own attendance).
class PhysicalClassAttendanceCard extends StatefulWidget {
  final ContentBlock block;
  final String studentId;

  /// Shown when the block has no title.
  final String fallbackTitle;

  const PhysicalClassAttendanceCard({super.key, required this.block, required this.studentId, this.fallbackTitle = 'Physical Class'});

  @override
  State<PhysicalClassAttendanceCard> createState() => _PhysicalClassAttendanceCardState();
}

class _PhysicalClassAttendanceCardState extends State<PhysicalClassAttendanceCard> {
  final _repository = SupabaseSubmissionGradingRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  String? _status;
  String? _dayTime;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final submission = await _repository.getSubmission(widget.block.id, widget.studentId);
    final dayTime = await _loadDayTime();
    if (!mounted) return;
    final marked = submission?.submission['attendance'];
    setState(() {
      // Older rows only have `attended: true`, which counts as Present.
      _status = marked is String ? marked : (submission?.submission['attended'] == true ? AttendanceStatus.present : null);
      _dayTime = dayTime;
      _isLoading = false;
    });
  }

  /// The block's class (block -> session -> module -> section) day and time.
  Future<String?> _loadDayTime() async {
    try {
      final row = await Supabase.instance.client
          .from('content_blocks')
          .select('sessions(course_modules(course_sections(day_of_week, start_time, end_time)))')
          .eq('id', widget.block.id)
          .maybeSingle();
      final section = ((row?['sessions'] as Map?)?['course_modules'] as Map?)?['course_sections'] as Map?;
      if (section == null) return null;
      return classDayTimeText(
        dayOfWeek: section['day_of_week'] as String?,
        startTime: section['start_time'] as String?,
        endTime: section['end_time'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.block;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          b.title?.isNotEmpty == true ? b.title! : widget.fallbackTitle,
          style: FacultyTypography.bodyMd(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600),
        ),
        if (_dayTime != null) ...[
          const SizedBox(height: 4),
          Text(_dayTime!, style: FacultyTypography.bodySm(color: FacultyColors.onSurface)),
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
