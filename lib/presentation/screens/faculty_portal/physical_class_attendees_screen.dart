import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/core/utils/date_format.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_students_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_submission_grading_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/content_block_submission.dart';
import 'package:stitch_aiei_lms/domain/models/roster_student.dart';
import 'package:stitch_aiei_lms/domain/repositories/submission_grading_repository.dart' show AttendanceStatus;
import 'widgets/faculty_mobile_top_bar.dart';

// ---------------------------------------------------------------------------
// PhysicalClassAttendeesScreen — one physical session's attendance.
//  - Physical class: a student list where the lecturer picks, per student,
//    Present / Late / Valid absent / Invalid absent (saved as soon as picked).
//  - Physical exam/assignment (requireAttendedFlag): the class roster split
//    into attendees and absentees, as before.
// ---------------------------------------------------------------------------
class PhysicalClassAttendeesScreen extends StatefulWidget {
  final String contentBlockId;
  final String sectionId;
  final String title;
  final DateTime? scheduledAt;
  final DateTime? endsAt;
  /// Physical exam/assignment: the due date attendance closes at (shown instead
  /// of a class window).
  final DateTime? dueDate;
  /// Physical exam/assignment rows also carry imported marks, so only a row
  /// with `submission.attended` set counts as an attendee. Physical classes
  /// keep the original rule: any row means the student ticked.
  final bool requireAttendedFlag;

  const PhysicalClassAttendeesScreen({
    super.key,
    required this.contentBlockId,
    required this.sectionId,
    required this.title,
    this.scheduledAt,
    this.endsAt,
    this.dueDate,
    this.requireAttendedFlag = false,
  });

  @override
  State<PhysicalClassAttendeesScreen> createState() => _PhysicalClassAttendeesScreenState();
}

class _PhysicalClassAttendeesScreenState extends State<PhysicalClassAttendeesScreen> {
  final _rosterRepository = SupabaseAdminStudentsRepositoryImpl(Supabase.instance.client);
  final _gradingRepository = SupabaseSubmissionGradingRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  List<RosterStudent> _roster = const [];
  Map<String, ContentBlockSubmission> _submissions = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final roster = await _rosterRepository.getSectionRoster(widget.sectionId);
    final submissions = await _gradingRepository.getRosterSubmissions(widget.contentBlockId);
    if (!mounted) return;
    setState(() {
      _roster = roster;
      _submissions = submissions;
      _isLoading = false;
    });
  }

  /// A physical class student's marked status (or null when not marked yet).
  /// Older rows only have `attended: true`, which counts as Present.
  String? _statusOf(RosterStudent s) {
    final sub = _submissions[s.studentId];
    if (sub == null) return null;
    final marked = sub.submission['attendance'];
    if (marked is String) return marked;
    return sub.submission['attended'] == true ? AttendanceStatus.present : null;
  }

  Future<void> _mark(RosterStudent s, String status) async {
    final previous = _submissions[s.studentId];
    setState(() {
      final base = previous?.submission ?? const <String, dynamic>{};
      _submissions = {
        ..._submissions,
        s.studentId: ContentBlockSubmission(
          id: previous?.id ?? '',
          contentBlockId: widget.contentBlockId,
          studentId: s.studentId,
          status: previous?.status ?? 'submitted',
          submission: {...base, 'attendance': status},
          marks: previous?.marks ?? const {},
          submittedAt: DateTime.now(),
        ),
      };
    });
    try {
      await _gradingRepository.setAttendanceStatus(contentBlockId: widget.contentBlockId, studentId: s.studentId, status: status);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        final restored = {..._submissions};
        if (previous == null) {
          restored.remove(s.studentId);
        } else {
          restored[s.studentId] = previous;
        }
        _submissions = restored;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save attendance: $e'), backgroundColor: FacultyColors.error),
      );
    }
  }

  static const double _radioColumnWidth = 96;

  Widget _buildMarkingView() {
    final students = [..._roster]..sort(_byName);
    final marked = students.where((s) => _statusOf(s) != null).length;
    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: FacultyMobileTopBar(title: widget.title),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.title, style: FacultyTypography.headlineMd()),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (widget.scheduledAt != null) formatDateRange(widget.scheduledAt!, widget.endsAt),
                      '$marked of ${students.length} marked',
                    ].join(' • '),
                    style: FacultyTypography.bodySm(),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: FacultyColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: students.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('No students are enrolled in this class.', style: FacultyTypography.bodySm()),
                          )
                        : LayoutBuilder(builder: (context, constraints) {
                            // Narrow screens scroll the table sideways instead of squashing the radios.
                            final width = constraints.maxWidth < 640 ? 640.0 : constraints.maxWidth;
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: width,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [_markingHeader(), for (final s in students) _markingRow(s)],
                                ),
                              ),
                            );
                          }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _markingHeader() {
    final style = FacultyTypography.labelMd(color: FacultyColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w700);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: FacultyColors.surfaceContainerLow,
      child: Row(
        children: [
          Expanded(child: Text('Student', style: style)),
          for (final status in AttendanceStatus.all)
            SizedBox(width: _radioColumnWidth, child: Center(child: Text(AttendanceStatus.label(status), style: style))),
        ],
      ),
    );
  }

  Widget _markingRow(RosterStudent s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: FacultyColors.surfaceContainer))),
      child: RadioGroup<String>(
        groupValue: _statusOf(s),
        onChanged: (v) {
          if (v != null) _mark(s, v);
        },
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: FacultyTypography.bodyMd(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600)),
                    Text(s.studentCode, style: FacultyTypography.labelXs()),
                  ],
                ),
              ),
            ),
            for (final status in AttendanceStatus.all)
              SizedBox(width: _radioColumnWidth, child: Center(child: Radio<String>(value: status))),
          ],
        ),
      ),
    );
  }

  bool _attended(RosterStudent s) {
    final sub = _submissions[s.studentId];
    if (sub == null) return false;
    return !widget.requireAttendedFlag || sub.submission['attended'] == true;
  }

  int _byName(RosterStudent a, RosterStudent b) => a.name.toLowerCase().compareTo(b.name.toLowerCase());

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!widget.requireAttendedFlag) return _buildMarkingView();
    final attendees = _roster.where(_attended).toList()..sort(_byName);
    final absentees = _roster.where((s) => !_attended(s)).toList()..sort(_byName);

    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: FacultyMobileTopBar(title: widget.title),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.title, style: FacultyTypography.headlineMd()),
                  const SizedBox(height: 4),
                  Text(
                    [if (widget.scheduledAt != null) formatDateRange(widget.scheduledAt!, widget.endsAt) else if (widget.dueDate != null) 'Due ${formatDueDate(widget.dueDate!)}', '${attendees.length} of ${_roster.length} attended'].join(' • '),
                    style: FacultyTypography.bodySm(),
                  ),
                  const SizedBox(height: 16),
                  _section('Attendees', attendees, present: true),
                  const SizedBox(height: 16),
                  _section('Absentees', absentees, present: false),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String label, List<RosterStudent> students, {required bool present}) {
    final accent = present ? const Color(0xFF2E7D32) : FacultyColors.error;
    return Container(
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(present ? Icons.check_circle_outline : Icons.cancel_outlined, size: 18, color: accent),
                const SizedBox(width: 8),
                Expanded(child: Text(label, style: FacultyTypography.titleSm())),
                Text('${students.length}', style: FacultyTypography.labelMd(color: accent).copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          if (students.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(present ? 'Nobody has ticked attendance yet.' : 'Everyone attended.', style: FacultyTypography.bodySm()),
            )
          else
            for (final s in students) _studentRow(s, present),
        ],
      ),
    );
  }

  Widget _studentRow(RosterStudent s, bool present) {
    final at = present ? _submissions[s.studentId]?.submittedAt : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: FacultyColors.surfaceContainer))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name, style: FacultyTypography.bodyMd(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600)),
                Text(s.studentCode, style: FacultyTypography.labelXs()),
              ],
            ),
          ),
          if (present && at != null) Text('Ticked ${formatDueDate(at.toLocal())}', style: FacultyTypography.labelXs()),
        ],
      ),
    );
  }
}
