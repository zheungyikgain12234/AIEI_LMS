import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/core/utils/date_format.dart';
import 'package:stitch_aiei_lms/domain/models/course_section.dart';
import 'package:stitch_aiei_lms/presentation/widgets/class_calendar.dart';
import 'package:stitch_aiei_lms/presentation/widgets/skeleton.dart';

/// "My active classes" panel at the bottom of the student portal's sidebar —
/// the student's counterpart of the lecturer portal's: each class they are
/// enrolled in right now with where, which day, what time and the date range it
/// runs, followed by a blue calendar with every class day highlighted in green.
class StudentScheduleSidebar extends StatefulWidget {
  const StudentScheduleSidebar({super.key});

  @override
  State<StudentScheduleSidebar> createState() => _StudentScheduleSidebarState();
}

class _StudentScheduleSidebarState extends State<StudentScheduleSidebar> {
  final _client = Supabase.instance.client;
  bool _isLoading = true;
  String? _error;

  /// Every class the student is enrolled in (the calendar can be paged to any
  /// month); [_active] is the subset running today.
  List<CourseSection> _classes = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await _client
          .from('student_courses')
          .select('section_id, course_sections(*, courses(course_code, course_title), cohorts(name, code, year))')
          .eq('student_id', DemoIdentity.studentId);
      final sections = <String, CourseSection>{};
      for (final row in rows as List) {
        final section = row['course_sections'] as Map<String, dynamic>?;
        if (section == null) continue;
        sections[section['id'] as String] = CourseSection.fromMap(section, enrolledCount: 0);
      }
      if (!mounted) return;
      setState(() {
        _classes = sections.values.toList()..sort((a, b) => a.courseTitle.toLowerCase().compareTo(b.courseTitle.toLowerCase()));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your classes.';
        _isLoading = false;
      });
    }
  }

  List<CourseSection> get _active {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      for (final c in _classes)
        if ((c.startDate == null || !today.isBefore(c.startDate!)) && (c.endDate == null || !today.isAfter(c.endDate!))) c,
    ];
  }

  String _dateRange(CourseSection c) {
    if (c.startDate != null && c.endDate != null) return '${formatDate(c.startDate!)} to ${formatDate(c.endDate!)}';
    if (c.startDate != null) return 'From ${formatDate(c.startDate!)}';
    if (c.endDate != null) return 'Until ${formatDate(c.endDate!)}';
    return 'Dates TBD';
  }

  @override
  Widget build(BuildContext context) {
    // A slightly deeper blue than the menu above so the section reads as its own
    // area; the class cards inside are white, so their dark text stays crisp.
    final active = _active;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFDFE7FA),
        border: Border(top: BorderSide(color: AdminColors.navBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MY ACTIVE CLASSES', style: AppTypography.labelSm(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Where and when you study', style: AppTypography.bodySm()),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Column(children: [Skeleton(height: 92, radius: 10), SizedBox(height: 10), Skeleton(height: 92, radius: 10)]),
                  )
                : _error != null
                    ? Padding(padding: const EdgeInsets.fromLTRB(20, 12, 16, 12), child: Text(_error!, style: AppTypography.bodySm(color: AppColors.error)))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                        children: [
                          if (active.isEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                              child: Text('No active classes right now.', style: AppTypography.bodySm()),
                            )
                          else
                            for (final c in active) ...[_classCard(c), const SizedBox(height: 10)],
                          ClassCalendar(
                            classes: [
                              for (final c in _classes)
                                CalendarClass(
                                  title: c.courseTitle,
                                  weekday: CalendarClass.weekdayFromName(c.dayOfWeek),
                                  startTime: c.startTime,
                                  endTime: c.endTime,
                                  where: c.deliveryMode == 'online' ? 'Online' : (c.location ?? '').trim(),
                                  startDate: c.startDate,
                                  endDate: c.endDate,
                                ),
                            ],
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _classCard(CourseSection c) {
    final online = c.deliveryMode == 'online';
    final where = online ? 'Online' : ((c.location ?? '').trim().isEmpty ? '—' : c.location!.trim());
    final dayTime = c.scheduleText.split(' • ').first.trim().isEmpty ? 'TBD' : c.scheduleText.split(' • ').first.trim();
    Widget line(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(child: Text(text, style: AppTypography.bodySm(color: AppColors.onSurface))),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AdminColors.navBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.courseTitle, style: AppTypography.labelLg()),
          Text('${c.courseCode} • ${c.sectionCode}${c.cohort == null ? '' : ' • ${c.cohort}'}', style: AppTypography.labelSm()),
          const SizedBox(height: 4),
          line(online ? Icons.videocam_outlined : Icons.place_outlined, where),
          line(Icons.schedule, dayTime),
          line(Icons.date_range_outlined, _dateRange(c)),
        ],
      ),
    );
  }
}
