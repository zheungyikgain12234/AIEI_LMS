import 'package:stitch_aiei_lms/core/utils/refresh_on_return.dart';
import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/presentation/widgets/skeleton.dart';
import 'package:stitch_aiei_lms/core/theme/ui_contrast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
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
// lecturer teaches, grouped by Semester then by Class as collapsible sections
// (same layout as Grading & Submissions), each class's sessions sorted by
// date with the latest on top. Tapping a session opens its attendee/absentee
// list.
// ---------------------------------------------------------------------------
class PhysicalClassAttendanceScreen extends StatefulWidget {
  const PhysicalClassAttendanceScreen({super.key});

  @override
  State<PhysicalClassAttendanceScreen> createState() => _PhysicalClassAttendanceScreenState();
}

class _SemesterGroup {
  final String semester;
  final List<_ClassGroup> classes;
  _SemesterGroup(this.semester, this.classes);
}

class _ClassGroup {
  final String label;
  final List<PhysicalClassItem> items;
  _ClassGroup(this.label, this.items);
}

class _PhysicalClassAttendanceScreenState extends State<PhysicalClassAttendanceScreen> with RefreshOnReturn<PhysicalClassAttendanceScreen> {
  @override
  void onReturnedTo() => _load();

  final _facultyRepository = SupabaseFacultyRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  List<_SemesterGroup> _groups = const [];

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
    final classesBySemester = <String, Map<String, List<PhysicalClassItem>>>{};
    for (final item in items) {
      final course = courseBySection[item.sectionId];
      final semester = course?.semester ?? 'No Semester';
      final classLabel = course == null ? item.sectionId : '${course.courseCode} • ${course.sectionCode} — ${course.title}';
      classesBySemester.putIfAbsent(semester, () => {}).putIfAbsent(classLabel, () => []).add(item);
    }

    // Latest on top; sessions without a date sink to the bottom.
    int latestFirst(PhysicalClassItem a, PhysicalClassItem b) {
      final da = a.scheduledAt ?? a.dueDate;
      final db = b.scheduledAt ?? b.dueDate;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    }

    setState(() {
      _groups = [
        for (final semesterEntry in classesBySemester.entries)
          _SemesterGroup(semesterEntry.key, [
            for (final classEntry in semesterEntry.value.entries) _ClassGroup(classEntry.key, [...classEntry.value]..sort(latestFirst)),
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

  /// Only physical assignments keep the old attendee/absentee split; classes and exams share the marking flow.
  bool _isAssessment(PhysicalClassItem item) => item.blockType == 'physicalAssignment';

  void _openItem(PhysicalClassItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhysicalClassAttendeesScreen(
          contentBlockId: item.contentBlockId,
          sectionId: item.sectionId,
          title: item.title,
          scheduledAt: item.scheduledAt,
          endsAt: item.endsAt,
          dueDate: item.dueDate,
          requireAttendedFlag: _isAssessment(item),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show the page frame straight away; only the content area is a placeholder.
      return MediaQuery.of(context).size.width <= 900 ? const SkeletonScaffold() : FacultyScaffold(selected: FacultyNavDestination.physicalClassAttendance, onDestinationSelected: _handleNav, body: const SkeletonPage());
    }
    if (MediaQuery.of(context).size.width <= 900) {
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
                _buildHeader(),
                const SizedBox(height: 16),
                _buildBody(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: FacultyMobileBottomNav(
          selected: FacultyNavDestination.physicalClassAttendance,
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
          _buildHeader(),
          const SizedBox(height: 24),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Physical Class Attendance', style: FacultyTypography.headlineLg()),
        const SizedBox(height: 6),
        Text(
          'Every physical class session, exam and assignment across your semesters and classes, latest first. Select one to see who attended.',
          style: FacultyTypography.bodyMd(),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_groups.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Text('No physical classes, exams or assignments have been created yet.', style: FacultyTypography.bodyMd()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final group in _groups) ...[_semesterTile(group), const SizedBox(height: 12)]],
    );
  }

  Widget _semesterTile(_SemesterGroup group) {
    return Container(
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Material(
          type: MaterialType.transparency,
          child: ExpansionTile(
          initiallyExpanded: true,
          title: Row(
            children: [
              const Icon(Icons.groups_outlined, size: 18, color: FacultyColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(group.semester, style: FacultyTypography.titleSm())),
            ],
          ),
          children: [for (final classGroup in group.classes) _classTile(classGroup)],
          ),
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
          child: Material(
            type: MaterialType.transparency,
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
      ),
    );
  }

  Widget _itemRow(PhysicalClassItem item) {
    return InkWell(
      onTap: () => _openItem(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: UiContrast.divider))),
        child: Row(
          children: [
            Icon(item.blockType == 'physicalExam' ? Icons.edit_note : (_isAssessment(item) ? Icons.draw_outlined : Icons.meeting_room_outlined), size: 18, color: FacultyColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(item.title, style: FacultyTypography.bodyMd(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600)),
            ),
            const Icon(Icons.chevron_right, color: FacultyColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
