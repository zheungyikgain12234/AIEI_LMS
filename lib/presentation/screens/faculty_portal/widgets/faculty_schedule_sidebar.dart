import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/core/utils/date_format.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_faculty_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/assigned_course.dart';

/// Right-hand reference panel on every Faculty Portal screen: all of this
/// lecturer's own active classes with where (location / online), which day,
/// what time and the date range they run — so the lecturer can check their
/// timetable without leaving the page they're on.
class FacultyScheduleSidebar extends StatefulWidget {
  const FacultyScheduleSidebar({super.key});

  static const double width = 300;

  @override
  State<FacultyScheduleSidebar> createState() => _FacultyScheduleSidebarState();
}

class _FacultyScheduleSidebarState extends State<FacultyScheduleSidebar> {
  final _repository = SupabaseFacultyRepositoryImpl(Supabase.instance.client);
  bool _isLoading = true;
  String? _error;
  List<AssignedCourse> _classes = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await _repository.getAssignedCourses(DemoIdentity.lecturerId);
      if (!mounted) return;
      setState(() {
        _classes = all.where((c) => c.isActive).toList();
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

  /// `scheduleText` is "Thu 14:00–17:00 • Room 204" (or "… • Online").
  (String dayTime, String where) _split(AssignedCourse c) {
    final parts = c.scheduleText.split(' • ');
    final dayTime = parts.first.trim().isEmpty ? 'TBD' : parts.first.trim();
    final where = parts.length > 1 ? parts.sublist(1).join(' • ').trim() : '—';
    return (dayTime, where.isEmpty ? '—' : where);
  }

  String _dateRange(AssignedCourse c) {
    if (c.startDate != null && c.endDate != null) return '${formatDate(c.startDate!)} to ${formatDate(c.endDate!)}';
    if (c.startDate != null) return 'From ${formatDate(c.startDate!)}';
    if (c.endDate != null) return 'Until ${formatDate(c.endDate!)}';
    return 'Dates TBD';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: FacultyScheduleSidebar.width,
      decoration: const BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(-1, 0))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MY ACTIVE CLASSES', style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text('Where and when you teach', style: FacultyTypography.bodySm()),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Padding(padding: const EdgeInsets.all(20), child: Text(_error!, style: FacultyTypography.bodySm(color: FacultyColors.error)))
                    : _classes.isEmpty
                        ? Padding(padding: const EdgeInsets.all(20), child: Text('No active classes right now.', style: FacultyTypography.bodySm()))
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _classes.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => _classCard(_classes[i]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _classCard(AssignedCourse c) {
    final (dayTime, where) = _split(c);
    final online = where.toLowerCase() == 'online';
    Widget line(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 14, color: FacultyColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(child: Text(text, style: FacultyTypography.bodySm(color: FacultyColors.onSurface))),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.title, style: FacultyTypography.titleSm()),
          Text('${c.courseCode} • ${c.sectionCode}${c.cohort == null ? '' : ' • ${c.cohort}'}', style: FacultyTypography.labelXs()),
          const SizedBox(height: 4),
          line(online ? Icons.videocam_outlined : Icons.place_outlined, where),
          line(Icons.schedule, dayTime),
          line(Icons.date_range_outlined, _dateRange(c)),
        ],
      ),
    );
  }
}
