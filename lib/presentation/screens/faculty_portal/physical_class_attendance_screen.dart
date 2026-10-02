import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/core/utils/date_format.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_faculty_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/repositories/faculty_repository.dart' show PhysicalClassItem;
import 'grading_queue_screen.dart';
import 'my_assigned_courses_screen.dart';
import 'physical_class_attendees_screen.dart';
import 'widgets/faculty_mobile_bottom_nav.dart';
import 'widgets/faculty_mobile_top_bar.dart';
import 'widgets/faculty_scaffold.dart';
import 'widgets/faculty_sidebar.dart';

// ---------------------------------------------------------------------------
// PhysicalClassAttendanceScreen — the "Physical Class Attendance" sidebar
// destination. Lists every physical class session across every class this
// lecturer teaches, grouped by Cohort then by Class as collapsible sections
// (same layout as Grading & Submissions), each class's sessions sorted by
// date with the latest on top. Tapping a session opens its attendee/absentee
// list.
// ---------------------------------------------------------------------------
class PhysicalClassAttendanceScreen extends StatefulWidget {
  const PhysicalClassAttendanceScreen({super.key});

  @override
  State<PhysicalClassAttendanceScreen> createState() => _PhysicalClassAttendanceScreenState();
}

class _CohortGroup {
  final String cohort;
  final List<_ClassGroup> classes;
  _CohortGroup(this.cohort, this.classes);
}

class _ClassGroup {
  final String label;
  final List<PhysicalClassItem> items;
  _ClassGroup(this.label, this.items);
}

class _PhysicalClassAttendanceScreenState extends State<PhysicalClassAttendanceScreen> {
  final _facultyRepository = SupabaseFacultyRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  List<_CohortGroup> _groups = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final assignedCourses = await _facultyRepository.getAssignedCourses(DemoIdentity.lecturerId);
    final items = await _facultyRepository.getPhysicalClassItems([for (final c in assignedCourses) c.sectionId]);
    if (!mounted) return;

    final courseBySection = {for (final c in assignedCourses) c.sectionId: c};
    final classesByCohort = <String, Map<String, List<PhysicalClassItem>>>{};
    for (final item in items) {
      final course = courseBySection[item.sectionId];
      final cohort = course?.cohort ?? 'No Cohort';
      final classLabel = course == null ? item.sectionId : '${course.courseCode} • ${course.sectionCode} — ${course.title}';
      classesByCohort.putIfAbsent(cohort, () => {}).putIfAbsent(classLabel, () => []).add(item);
    }

    // Latest on top; sessions without a date sink to the bottom.
    int latestFirst(PhysicalClassItem a, PhysicalClassItem b) {
      if (a.scheduledAt == null && b.scheduledAt == null) return 0;
      if (a.scheduledAt == null) return 1;
      if (b.scheduledAt == null) return -1;
      return b.scheduledAt!.compareTo(a.scheduledAt!);
    }

    setState(() {
      _groups = [
        for (final cohortEntry in classesByCohort.entries)
          _CohortGroup(cohortEntry.key, [
            for (final classEntry in cohortEntry.value.entries) _ClassGroup(classEntry.key, [...classEntry.value]..sort(latestFirst)),
          ]),
      ];
      _isLoading = false;
    });
  }

  void _handleNav(FacultyNavDestination dest) {
    switch (dest) {
      case FacultyNavDestination.myCourses:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyAssignedCoursesScreen()));
      case FacultyNavDestination.gradingAndSubmissions:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GradingQueueScreen()));
      case FacultyNavDestination.physicalClassAttendance:
        break;
    }
  }

  void _openItem(PhysicalClassItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhysicalClassAttendeesScreen(
          contentBlockId: item.contentBlockId,
          sectionId: item.sectionId,
          title: item.title,
          scheduledAt: item.scheduledAt,
          endsAt: item.endsAt,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (MediaQuery.of(context).size.width < 700) {
      return Scaffold(
        backgroundColor: FacultyColors.background,
        appBar: const FacultyMobileTopBar.root(),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Physical Class Attendance', style: FacultyTypography.headlineLg(color: FacultyColors.primary)),
                const SizedBox(height: 8),
                Text('Physical class sessions by cohort and class, latest first.', style: FacultyTypography.bodyMd()),
                const SizedBox(height: 16),
                _buildBody(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: FacultyMobileBottomNav(
          selected: FacultyNavDestination.physicalClassAttendance,
          pendingCount: 0,
          onDestinationSelected: _handleNav,
        ),
      );
    }
    return FacultyScaffold(
      selected: FacultyNavDestination.physicalClassAttendance,
      onDestinationSelected: _handleNav,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Physical Class Attendance', style: FacultyTypography.headlineLg()),
          const SizedBox(height: 6),
          Text(
            'Every physical class session across your cohorts and classes, latest first. Select one to see who attended.',
            style: FacultyTypography.bodyMd(),
          ),
          const SizedBox(height: 24),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_groups.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Text('No physical classes have been created yet.', style: FacultyTypography.bodyMd()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final group in _groups) ...[_cohortTile(group), const SizedBox(height: 12)]],
    );
  }

  Widget _cohortTile(_CohortGroup group) {
    return Container(
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Row(
            children: [
              const Icon(Icons.groups_outlined, size: 18, color: FacultyColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(group.cohort, style: FacultyTypography.titleSm())),
            ],
          ),
          children: [for (final classGroup in group.classes) _classTile(classGroup)],
        ),
      ),
    );
  }

  Widget _classTile(_ClassGroup group) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
      child: Container(
        decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Row(
              children: [
                const Icon(Icons.school_outlined, size: 16, color: FacultyColors.secondary),
                const SizedBox(width: 8),
                Expanded(child: Text(group.label, style: FacultyTypography.bodyMd(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600))),
              ],
            ),
            children: [for (final item in group.items) _itemRow(item)],
          ),
        ),
      ),
    );
  }

  Widget _itemRow(PhysicalClassItem item) {
    return InkWell(
      onTap: () => _openItem(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: FacultyColors.surfaceContainer))),
        child: Row(
          children: [
            const Icon(Icons.meeting_room_outlined, size: 18, color: FacultyColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: FacultyTypography.bodyMd(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600)),
                  Text(item.scheduledAt == null ? 'No date set' : formatDateRange(item.scheduledAt!, item.endsAt), style: FacultyTypography.labelXs()),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: FacultyColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
