import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_faculty_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/repositories/faculty_repository.dart' show PendingGradingItem;
import 'mark_assignment_screen.dart';
import 'mark_exam_screen.dart';
import 'my_assigned_courses_screen.dart';
import 'widgets/faculty_scaffold.dart';
import 'widgets/faculty_sidebar.dart';
import 'widgets/faculty_mobile_top_bar.dart';
import 'widgets/faculty_mobile_bottom_nav.dart';

// ---------------------------------------------------------------------------
// GradingQueueScreen — the real "Grading and Submissions" destination.
// Lists every exam/assignment content block, across every class this
// lecturer teaches, that has at least one submission awaiting grading
// (`content_block_submissions.status = 'submitted'`), grouped by Cohort
// then by Class as collapsible sections. Tapping an item opens the same
// Mark Exam / Mark Assignment roster reached from the Syllabus editor.
// ---------------------------------------------------------------------------
class GradingQueueScreen extends StatefulWidget {
  const GradingQueueScreen({super.key});

  @override
  State<GradingQueueScreen> createState() => _GradingQueueScreenState();
}

class _CohortGroup {
  final String cohort;
  final List<_ClassGroup> classes;
  _CohortGroup(this.cohort, this.classes);

  int get totalPending => classes.fold(0, (sum, c) => sum + c.totalPending);
}

class _ClassGroup {
  final String label;
  final List<PendingGradingItem> items;
  _ClassGroup(this.label, this.items);

  int get totalPending => items.fold(0, (sum, i) => sum + i.pendingCount);
}

class _GradingQueueScreenState extends State<GradingQueueScreen> {
  final _facultyRepository = SupabaseFacultyRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  List<_CohortGroup> _groups = const [];
  int _totalPending = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final assignedCourses = await _facultyRepository.getAssignedCourses(DemoIdentity.lecturerId);
    final sectionIds = [for (final c in assignedCourses) c.sectionId];
    final items = await _facultyRepository.getPendingGradingItems(sectionIds);
    if (!mounted) return;

    final courseBySection = {for (final c in assignedCourses) c.sectionId: c};

    // Cohort -> class label -> items, built in the lecturer's assigned-course
    // order so cohorts/classes appear in a stable, predictable order.
    final classesByCohort = <String, Map<String, List<PendingGradingItem>>>{};
    for (final item in items) {
      final course = courseBySection[item.sectionId];
      final cohort = course?.cohort ?? 'No Cohort';
      final classLabel = course == null ? item.sectionId : '${course.courseCode} • ${course.sectionCode} — ${course.title}';
      classesByCohort.putIfAbsent(cohort, () => {}).putIfAbsent(classLabel, () => []).add(item);
    }

    final groups = [
      for (final cohortEntry in classesByCohort.entries)
        _CohortGroup(cohortEntry.key, [
          for (final classEntry in cohortEntry.value.entries) _ClassGroup(classEntry.key, classEntry.value),
        ]),
    ];

    setState(() {
      _groups = groups;
      _totalPending = items.fold(0, (sum, i) => sum + i.pendingCount);
      _isLoading = false;
    });
  }

  void _openItem(PendingGradingItem item, String classLabel) {
    if (item.blockType == 'exam') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MarkExamScreen(contentBlockId: item.contentBlockId, sectionId: item.sectionId, title: item.title),
        ),
      ).then((_) => _load());
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MarkAssignmentScreen(contentBlockId: item.contentBlockId, sectionId: item.sectionId, title: item.title),
        ),
      ).then((_) => _load());
    }
  }

  void _handleNav(FacultyNavDestination dest) {
    switch (dest) {
      case FacultyNavDestination.myCourses:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyAssignedCoursesScreen()));
        break;
      case FacultyNavDestination.gradingAndSubmissions:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (MediaQuery.of(context).size.width < 700) {
      return _buildMobileScaffold(context);
    }
    return FacultyScaffold(
      selected: FacultyNavDestination.gradingAndSubmissions,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Grading and Submissions', style: FacultyTypography.headlineLg()),
              const SizedBox(height: 6),
              Text(
                'Every quiz and assignment with at least one submission awaiting grading, grouped by cohort and class.',
                style: FacultyTypography.bodyMd(),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: FacultyColors.errorContainer, borderRadius: BorderRadius.circular(10)),
          child: Text(
            '$_totalPending pending',
            style: FacultyTypography.labelMd(color: FacultyColors.error).copyWith(fontWeight: FontWeight.w700),
          ),
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
        child: Text('Nothing to grade — every submission is up to date.', style: FacultyTypography.bodyMd()),
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
              _countPill(group.totalPending),
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
                _countPill(group.totalPending),
              ],
            ),
            children: [for (final item in group.items) _itemRow(item, group.label)],
          ),
        ),
      ),
    );
  }

  Widget _itemRow(PendingGradingItem item, String classLabel) {
    final isExam = item.blockType == 'exam';
    return InkWell(
      onTap: () => _openItem(item, classLabel),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: FacultyColors.surfaceContainer))),
        child: Row(
          children: [
            Icon(isExam ? Icons.quiz_outlined : Icons.assignment_outlined, size: 18, color: isExam ? FacultyColors.primary : FacultyColors.secondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: FacultyTypography.bodyMd(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600)),
                  Text(isExam ? 'Quiz' : 'Assignment', style: FacultyTypography.labelXs()),
                ],
              ),
            ),
            _countPill(item.pendingCount, label: item.pendingCount == 1 ? 'student' : 'students'),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: FacultyColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _countPill(int count, {String label = 'pending'}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: FacultyColors.errorContainer, borderRadius: BorderRadius.circular(9999)),
      child: Text(
        '$count $label',
        style: FacultyTypography.labelXs(color: FacultyColors.error).copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Mobile (< 700px) layout
  // ---------------------------------------------------------------------

  Widget _buildMobileScaffold(BuildContext context) {
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
              Text('Grading and Submissions', style: FacultyTypography.headlineLg(color: FacultyColors.primary)),
              const SizedBox(height: 8),
              Text(
                'Quizzes and assignments awaiting grading, by cohort and class.',
                style: FacultyTypography.bodyMd(),
              ),
              const SizedBox(height: 16),
              _buildBody(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: FacultyMobileBottomNav(
        selected: FacultyNavDestination.gradingAndSubmissions,
        pendingCount: _totalPending,
        onDestinationSelected: _handleNav,
      ),
    );
  }
}
