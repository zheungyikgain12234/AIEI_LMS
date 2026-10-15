import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/presentation/widgets/skeleton.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/core/utils/date_format.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_faculty_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/assigned_course.dart';

/// "My active classes" panel at the bottom of the left Faculty Portal sidebar:
/// all of this lecturer's own active classes with where (location / online),
/// which day, what time and the date range they run — so the lecturer can
/// check their timetable without leaving the page they're on. Fills whatever
/// height the nav items above it leave free and scrolls within it.
class FacultyScheduleSidebar extends StatefulWidget {
  const FacultyScheduleSidebar({super.key});

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
    // A slightly deeper blue than the menu above so the section reads as its own
    // area; the class cards inside are white, so their dark text stays crisp.
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFDFE7FA),
        border: Border(top: BorderSide(color: AdminColors.navBorder)),
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 14, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MY ACTIVE CLASSES', style: FacultyTypography.labelXs(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('Where and when you teach', style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant)),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(children: [Skeleton(height: 92, radius: 10), SizedBox(height: 10), Skeleton(height: 92, radius: 10)]),
                )
              : _error != null
                  ? Padding(padding: const EdgeInsets.fromLTRB(30, 12, 20, 12), child: Text(_error!, style: FacultyTypography.bodySm(color: FacultyColors.error)))
                  : _classes.isEmpty
                      ? Padding(padding: const EdgeInsets.fromLTRB(30, 12, 20, 12), child: Text('No active classes right now.', style: FacultyTypography.bodySm()))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AdminColors.navBorder)),
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
