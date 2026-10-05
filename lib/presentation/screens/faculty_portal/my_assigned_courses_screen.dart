import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_master_data_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_faculty_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturers_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_programmes_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/assigned_course.dart';
import 'package:stitch_aiei_lms/domain/models/cohort.dart';
import 'package:stitch_aiei_lms/domain/models/lecturer.dart';
import 'package:stitch_aiei_lms/domain/repositories/faculty_repository.dart' show SyllabusDeadline;
import 'widgets/faculty_scaffold.dart';
import 'widgets/faculty_sidebar.dart';
import 'widgets/faculty_mobile_top_bar.dart';
import 'widgets/faculty_mobile_bottom_nav.dart';
import 'course_dashboard_screen.dart';
import 'grading_queue_screen.dart';
import 'physical_class_attendance_screen.dart';
import 'course_syllabus_screen.dart';

const _kAccentPalette = [
  (FacultyColors.primary, Color(0xFFDBEAFE)),
  (Color(0xFF9333EA), Color(0xFFF3E8FF)),
  (Color(0xFF0284C7), Color(0xFFE0F2FE)),
];

class MyAssignedCoursesScreen extends StatefulWidget {
  const MyAssignedCoursesScreen({super.key});

  @override
  State<MyAssignedCoursesScreen> createState() => _MyAssignedCoursesScreenState();
}

class _MyAssignedCoursesScreenState extends State<MyAssignedCoursesScreen> with WidgetsBindingObserver {
  final _facultyRepository = SupabaseFacultyRepositoryImpl(Supabase.instance.client);
  final _lecturersRepository = SupabaseLecturersRepositoryImpl(Supabase.instance.client);
  final _masterDataRepository = SupabaseAdminMasterDataRepositoryImpl(Supabase.instance.client);
  final _programmesRepository = SupabaseProgrammesRepositoryImpl(Supabase.instance.client);
  Map<String, List<String>> _programmesByCourse = const {};

  bool _isLoading = true;
  List<_CourseRow> _rows = const [];
  List<_Stat> _stats = const [];

  // ── Year / Cohort filter ──────────────────────────────────────────────
  List<AssignedCourse> _assignedCourses = const [];
  List<Cohort> _cohorts = const [];
  int? _selectedYear;
  String? _selectedCohort;

  // ── Search filter (course name/code only) ───────────────────────────────
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Real per-course KPIs, keyed by `sectionId` — computed for EVERY assigned
  // course (not just one hardcoded demo course), so the table and overall
  // stats both reflect actual roster/grading data for any course a lecturer
  // teaches. Rebuilt on every `_load()`; looked up (not refetched) on filter
  // change.
  Map<String, int> _moduleCountBySection = const {};
  Map<String, int> _sessionCountBySection = const {};
  Map<String, int> _avgProgressBySection = const {};
  Map<String, int> _pendingAssignmentsBySection = const {};
  Map<String, int> _pendingQuizzesBySection = const {};
  Lecturer? _lecturer;
  Timer? _actionsTimer;

  /// Classes whose syllabus still needs submitting for approval, soonest
  /// edit-period end first — the Critical Action box (see [_syllabusActionWindowDays]).
  List<({AssignedCourse course, DateTime due})> _syllabusActions = const [];
  static const _syllabusActionWindowDays = 5;

  Map<String, int> get _cohortYearByName => {for (final c in _cohorts) c.name: c.year};

  /// Years the lecturer actually has assigned courses in, sorted ascending.
  List<int> get _availableYears {
    final years = <int>{};
    for (final c in _assignedCourses) {
      final year = _cohortYearByName[c.cohort];
      if (year != null) years.add(year);
    }
    return years.toList()..sort();
  }

  /// Cohort names (within [year]) the lecturer has assigned courses in, in
  /// the same order as the master `cohorts` list (so "first in the list" is
  /// well-defined).
  List<String> _cohortNamesForYear(int year) {
    final assignedNames = _assignedCourses.map((c) => c.cohort).whereType<String>().toSet();
    return [
      for (final c in _cohorts)
        if (c.year == year && assignedNames.contains(c.name)) c.name,
    ];
  }

  List<AssignedCourse> get _filteredAssignedCourses {
    var courses = _assignedCourses;
    if (_selectedCohort != null) {
      courses = courses.where((c) => c.cohort == _selectedCohort).toList();
    }
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      courses = courses
          .where((c) => c.title.toLowerCase().contains(query) || c.courseCode.toLowerCase().contains(query))
          .toList();
    }
    return courses;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    // Admin changes (edit period, approval) are made elsewhere, so poll for the
    // Critical Action box instead of requiring a page reload.
    _actionsTimer = Timer.periodic(const Duration(seconds: 15), (_) => _refreshSyllabusActions());
  }

  @override
  void dispose() {
    _actionsTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _rows = _buildRows();
      _stats = _computeStats();
    });
  }

  Future<void> _load() async {
    final assignedCourses = await _facultyRepository.getAssignedCourses(DemoIdentity.lecturerId);
    final lecturers = await _lecturersRepository.getLecturers();
    final cohorts = await _masterDataRepository.getCohorts();
    final programmesByCourse = await _programmesRepository.getProgrammeNamesByCourse();
    final sectionIds = [for (final c in assignedCourses) c.sectionId];

    // Real per-course module/session counts, computed for every assigned
    // course in parallel (not just one hardcoded demo course).
    final moduleCountBySection = <String, int>{};
    final sessionCountBySection = <String, int>{};
    await Future.wait([
      for (final c in assignedCourses) _loadCourseModuleCounts(c, moduleCountBySection, sessionCountBySection),
    ]);

    // Real pending-grading counts and avg progress, batched across every
    // section in one round trip (see FacultyRepository.getSectionAssessmentStats).
    // This is scoped by section (not course), so a student enrolled in the
    // same course through a different section/cohort is correctly excluded.
    final assessmentStats = await _facultyRepository.getSectionAssessmentStats(sectionIds);
    final deadlines = await _facultyRepository.getSyllabusDeadlines(sectionIds);
    if (!mounted) return;

    final lecturer = lecturers.where((l) => l.id == DemoIdentity.lecturerId).firstOrNull;

    setState(() {
      _assignedCourses = assignedCourses;
      _cohorts = cohorts;
      _programmesByCourse = programmesByCourse;
      _moduleCountBySection = moduleCountBySection;
      _sessionCountBySection = sessionCountBySection;
      _avgProgressBySection = {for (final e in assessmentStats.entries) e.key: e.value.avgProgress};
      _pendingAssignmentsBySection = {for (final e in assessmentStats.entries) e.key: e.value.pendingAssignments};
      _pendingQuizzesBySection = {for (final e in assessmentStats.entries) e.key: e.value.pendingQuizzes};
      _lecturer = lecturer;
      _syllabusActions = _syllabusActionsFrom(assignedCourses, deadlines);

      // Default to the current calendar year if the lecturer has courses
      // there, else fall back to the most recent year they do have.
      final years = _availableYears;
      final currentYear = DateTime.now().year;
      _selectedYear = years.contains(currentYear) ? currentYear : (years.isEmpty ? null : years.last);
      final cohortNames = _selectedYear == null ? const <String>[] : _cohortNamesForYear(_selectedYear!);
      _selectedCohort = cohortNames.isEmpty ? null : cohortNames.first;

      _rows = _buildRows();
      _stats = _computeStats();
      _isLoading = false;
    });
  }

  /// Draft syllabi whose edit period ends within [_syllabusActionWindowDays]
  /// days (or already has), soonest first.
  List<({AssignedCourse course, DateTime due})> _syllabusActionsFrom(List<AssignedCourse> courses, List<SyllabusDeadline> deadlines) {
    final courseBySection = {for (final c in courses) c.sectionId: c};
    final items = <({AssignedCourse course, DateTime due})>[
      for (final d in deadlines)
        if (courseBySection[d.sectionId] != null && _daysLeft(d.editEndAt) <= _syllabusActionWindowDays)
          (course: courseBySection[d.sectionId]!, due: d.editEndAt),
    ];
    items.sort((a, b) => a.due.compareTo(b.due));
    return items;
  }

  /// Re-reads just the syllabus deadlines (cheap) so the Critical Action box
  /// appears/disappears when an admin changes a class's edit period or a
  /// syllabus is submitted/approved.
  Future<void> _refreshSyllabusActions() async {
    if (!mounted || _isLoading || _assignedCourses.isEmpty) return;
    try {
      final deadlines = await _facultyRepository.getSyllabusDeadlines([for (final c in _assignedCourses) c.sectionId]);
      if (!mounted) return;
      setState(() => _syllabusActions = _syllabusActionsFrom(_assignedCourses, deadlines));
    } catch (_) {
      // A failed background refresh just keeps what's already shown.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshSyllabusActions();
  }

  int _daysLeft(DateTime due) {
    final now = DateTime.now();
    return DateTime(due.year, due.month, due.day).difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  String _dueText(DateTime due) {
    final diff = _daysLeft(due);
    if (diff < 0) return 'Overdue by ${-diff} Day${-diff == 1 ? '' : 's'}';
    if (diff == 0) return 'Due Today';
    return 'Due in $diff Day${diff == 1 ? '' : 's'}';
  }

  /// "Critical Action" box (same look as the student portal's) listing every
  /// class whose syllabus still has to be submitted for approval before its
  /// edit period closes. Hidden when there is nothing to do.
  Widget _buildCriticalActions() {
    if (_syllabusActions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFF4D4F), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('CRITICAL ACTION', style: FacultyTypography.labelXs(color: FacultyColors.errorContainer).copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _syllabusActions.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _syllabusActionRow(_syllabusActions[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _syllabusActionRow(({AssignedCourse course, DateTime due}) item) {
    final c = item.course;
    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CourseSyllabusScreen(sectionId: c.sectionId, courseTitle: c.title)),
        );
        if (mounted) _load();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.fact_check_outlined, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submit syllabus for approval',
                    style: FacultyTypography.bodyMd(color: Colors.white).copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${c.courseCode} • ${c.sectionCode} — ${c.title}',
                    style: FacultyTypography.bodySm(color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: FacultyColors.error, borderRadius: BorderRadius.circular(4)),
              child: Text(_dueText(item.due), style: FacultyTypography.labelXs(color: Colors.white).copyWith(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  /// Fetches this one course's module/session counts from its own section.
  Future<void> _loadCourseModuleCounts(
    AssignedCourse c,
    Map<String, int> moduleCountBySection,
    Map<String, int> sessionCountBySection,
  ) async {
    final modules = await _facultyRepository.getCourseModules(c.sectionId);
    final sessionCount = await _facultyRepository.getSessionCount(c.sectionId);
    moduleCountBySection[c.sectionId] = modules.length;
    sessionCountBySection[c.sectionId] = sessionCount;
  }

  List<_CourseRow> _buildRows() {
    final courses = _filteredAssignedCourses;
    return [
      for (var i = 0; i < courses.length; i++) _rowFromCourse(courses[i], i),
    ];
  }

  /// Recomputed against [_filteredAssignedCourses] so the cards react to the
  /// Year/Cohort selection above the course list, not just the full roster.
  List<_Stat> _computeStats() {
    final courses = _filteredAssignedCourses;
    final activeCourses = courses.where((c) => c.isActive).toList();
    final enrolledInActive = activeCourses.fold<int>(0, (sum, c) => sum + c.enrolledCount);

    final pendingAssignments =
        courses.fold<int>(0, (sum, c) => sum + (_pendingAssignmentsBySection[c.sectionId] ?? 0));
    final pendingQuizzes = courses.fold<int>(0, (sum, c) => sum + (_pendingQuizzesBySection[c.sectionId] ?? 0));
    final totalPending = pendingAssignments + pendingQuizzes;

    // `credits_max` is a per-cohort cap, not a global one, so when a cohort
    // is selected the credits used are summed just for that cohort's
    // assigned courses rather than read off the lecturer's global
    // `credits_used` (which is deduped across every cohort they teach in).
    final creditsUsed = _selectedCohort == null
        ? _lecturer?.creditsUsed
        : courses.fold<int>(0, (sum, c) => sum + c.credits);
    final creditsFootnote = _selectedCohort == null ? null : 'in $_selectedCohort';

    return [
      _Stat('Active Courses', '${activeCourses.length} / ${courses.length} Courses', '$enrolledInActive Enrolled Learners (Active)',
          Icons.school_outlined, FacultyColors.primary, FacultyColors.surfaceContainer),
      _Stat('Pending Reviews', '$totalPending Items', '$pendingAssignments assignments • $pendingQuizzes quizzes',
          Icons.history_toggle_off, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
      _Stat(
          'Teaching Capacity',
          _lecturer != null && creditsUsed != null ? '$creditsUsed / ${_lecturer!.creditsMax} Cr' : '— / — Cr',
          creditsFootnote,
          Icons.speed,
          const Color(0xFF4F46E5),
          const Color(0xFFE0E7FF)),
    ];
  }

  void _onYearChanged(int year) {
    setState(() {
      _selectedYear = year;
      final cohortNames = _cohortNamesForYear(year);
      _selectedCohort = cohortNames.isEmpty ? null : cohortNames.first;
      _rows = _buildRows();
      _stats = _computeStats();
    });
  }

  void _onCohortChanged(String cohort) {
    setState(() {
      _selectedCohort = cohort;
      _rows = _buildRows();
      _stats = _computeStats();
    });
  }

  _CourseRow _rowFromCourse(AssignedCourse c, int index) {
    final segments = c.courseCode.split('-');
    var initials = segments.first;
    if (initials.length > 3) initials = initials.substring(0, 3);
    final (accent, accentBg) = _kAccentPalette[index % _kAccentPalette.length];
    final moduleCount = _moduleCountBySection[c.sectionId];
    final sessionCount = _sessionCountBySection[c.sectionId];
    final avgProgress = _avgProgressBySection[c.sectionId] ?? 0;
    final pendingCount = (_pendingAssignmentsBySection[c.sectionId] ?? 0) + (_pendingQuizzesBySection[c.sectionId] ?? 0);
    return _CourseRow(
      courseId: c.courseId,
      programmes: _programmesByCourse[c.courseId] ?? const [],
      sectionId: c.sectionId,
      initials: initials,
      accent: accent,
      accentBg: accentBg,
      code: c.courseCode,
      title: '[${c.sectionCode}] ${c.title}',
      description: c.description,
      schedule: c.scheduleText,
      dateRange: _formatDateRange(c.startDate, c.endDate),
      enrolled: '${c.enrolledCount} / ${c.capacity} Enrolled Students',
      modules: moduleCount == null ? '— Modules • — Sessions' : '$moduleCount Modules • $sessionCount Sessions',
      isActive: c.isActive,
      avgProgress: avgProgress,
      pendingCount: '$pendingCount items',
      pendingLabel: 'Review Items',
    );
  }

  static String _formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return 'Schedule TBD';
    if (start != null && end != null) return '${_formatDate(start)} – ${_formatDate(end)}';
    if (start != null) return 'From ${_formatDate(start)}';
    return 'Until ${_formatDate(end!)}';
  }

  void _handleNav(FacultyNavDestination dest) {
    if (dest == FacultyNavDestination.myCourses) return;
    switch (dest) {
      case FacultyNavDestination.myCourses:
        break;
      case FacultyNavDestination.gradingAndSubmissions:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GradingQueueScreen()));
        break;
      case FacultyNavDestination.physicalClassAttendance:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PhysicalClassAttendanceScreen()));
        break;
    }
  }

  void _openDashboard(_CourseRow c) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CourseDashboardScreen(sectionId: c.sectionId, courseId: c.courseId)),
    );
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
      selected: FacultyNavDestination.myCourses,
      onDestinationSelected: _handleNav,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildCriticalActions(),
          const SizedBox(height: 8),
          _buildStatsRow(),
          const SizedBox(height: 24),
          _buildToolbar(),
          Container(
            decoration: BoxDecoration(
              color: FacultyColors.surfaceContainerLowest,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
            ),
            child: Column(
              children: [
                for (var i = 0; i < _rows.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: FacultyColors.surfaceContainer),
                  _buildCourseRow(_rows[i]),
                ],
              ],
            ),
          ),
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
              Text('My Assigned Courses', style: FacultyTypography.headlineLg()),
              const SizedBox(height: 6),
              Text(
                'Manage current curriculum materials, monitor cohort progress, and review pending evaluations across your assigned sections.',
                style: FacultyTypography.bodyMd(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 500 ? 2 : 1);
      final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: _stats.map((s) => SizedBox(width: width, child: _statCard(s))).toList(),
      );
    });
  }

  Widget _statCard(_Stat s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.label, style: FacultyTypography.labelXs()),
                const SizedBox(height: 4),
                Text(s.value, style: FacultyTypography.headlineLg().copyWith(color: s.valueColor ?? FacultyColors.onSurface)),
                if (s.footnote != null) ...[
                  const SizedBox(height: 6),
                  Text(s.footnote!, style: FacultyTypography.labelXs(color: s.footnoteColor ?? FacultyColors.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: s.iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(s.icon, color: s.iconColor, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
        border: const Border(bottom: BorderSide(color: FacultyColors.surfaceContainer)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: FacultyTypography.bodySm(color: FacultyColors.onSurface),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: FacultyColors.surfaceContainerLow,
                hintText: 'Filter by course name or code...',
                hintStyle: FacultyTypography.bodySm(color: FacultyColors.outline),
                prefixIcon: const Icon(Icons.search, size: 16, color: FacultyColors.outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Row(mainAxisSize: MainAxisSize.min, children: [
            _yearDropdown(),
            const SizedBox(width: 8),
            _cohortDropdown(),
          ]),
          Text('Showing ${_rows.length} assigned course${_rows.length == 1 ? '' : 's'}', style: FacultyTypography.labelXs()),
        ],
      ),
    );
  }

  Widget _yearDropdown({ValueChanged<int>? onChanged}) {
    final years = _availableYears;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: years.contains(_selectedYear) ? _selectedYear : null,
          hint: Text('Year', style: FacultyTypography.bodySm(color: FacultyColors.outline)),
          isDense: true,
          icon: const Icon(Icons.expand_more, size: 16, color: FacultyColors.outline),
          style: FacultyTypography.bodySm(color: FacultyColors.onSurface),
          items: [for (final y in years) DropdownMenuItem(value: y, child: Text('$y'))],
          onChanged: (y) {
            if (y == null) return;
            _onYearChanged(y);
            onChanged?.call(y);
          },
        ),
      ),
    );
  }

  Widget _cohortDropdown({ValueChanged<String>? onChanged}) {
    final cohortNames = _selectedYear == null ? const <String>[] : _cohortNamesForYear(_selectedYear!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: cohortNames.contains(_selectedCohort) ? _selectedCohort : null,
          hint: Text('Cohort', style: FacultyTypography.bodySm(color: FacultyColors.outline)),
          isDense: true,
          icon: const Icon(Icons.expand_more, size: 16, color: FacultyColors.outline),
          style: FacultyTypography.bodySm(color: FacultyColors.onSurface),
          items: [for (final name in cohortNames) DropdownMenuItem(value: name, child: Text(name, overflow: TextOverflow.ellipsis))],
          onChanged: (c) {
            if (c == null) return;
            _onCohortChanged(c);
            onChanged?.call(c);
          },
        ),
      ),
    );
  }

  Widget _buildCourseRow(_CourseRow c) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final left = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.accentBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.accent.withValues(alpha: 0.3)),
              ),
              alignment: Alignment.center,
              child: Text(c.initials, style: FacultyTypography.labelMd(color: c.accent)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _pill(c.code, c.accentBg, c.accent),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: c.isActive ? const Color(0xFF10B981) : FacultyColors.outline, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Text(c.isActive ? 'Active' : 'Inactive',
                            style: FacultyTypography.labelXs(color: c.isActive ? const Color(0xFF059669) : FacultyColors.outline)),
                      ]),
                    ],
                  ),
                  if (c.programmes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _programmePills(c),
                  ],
                  const SizedBox(height: 6),
                  Text(c.title, style: FacultyTypography.titleSm()),
                  const SizedBox(height: 2),
                  Text(c.description, style: FacultyTypography.labelXs(), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      _iconLabel(Icons.calendar_today_outlined, c.schedule),
                      _iconLabel(Icons.event_outlined, c.dateRange),
                      _iconLabel(Icons.person_outline, c.enrolled),
                      _iconLabel(Icons.folder_open_outlined, c.modules),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );

        final middle = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _metric('Average Student Progress', '${c.avgProgress}%', progress: c.avgProgress / 100, barColor: c.accent),
            const SizedBox(width: 24),
            _metric('Pending Grading', c.pendingCount, footnote: c.pendingLabel, valueColor: const Color(0xFFD97706)),
          ],
        );

        final actions = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () => _openDashboard(c),
              icon: const Icon(Icons.speed, size: 16),
              label: const Text('Open Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FacultyColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 5, child: left),
              const SizedBox(width: 24),
              middle,
              const SizedBox(width: 24),
              SizedBox(width: 160, child: actions),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [left, const SizedBox(height: 16), middle, const SizedBox(height: 16), actions],
        );
      }),
    );
  }

  Widget _metric(String label, String value, {double? progress, Color? barColor, String? footnote, Color? valueColor, Color? footnoteColor}) {
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          Text(label, style: FacultyTypography.labelXs(), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(value, style: FacultyTypography.titleSm(color: valueColor ?? FacultyColors.onSurface)),
          if (progress != null) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: 72,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: FacultyColors.surfaceContainer,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor ?? FacultyColors.primary),
                ),
              ),
            ),
          ],
          if (footnote != null) ...[
            const SizedBox(height: 2),
            Text(footnote, style: FacultyTypography.labelXs(color: footnoteColor ?? FacultyColors.outline)),
          ],
        ],
      ),
    );
  }

  /// One pill per programme the course is mapped to.
  Widget _programmePills(_CourseRow c) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final name in c.programmes)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(9999)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.workspace_premium_outlined, size: 12, color: FacultyColors.secondary),
              const SizedBox(width: 4),
              Flexible(child: Text(name, style: FacultyTypography.labelXs(color: FacultyColors.secondary).copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            ]),
          ),
      ],
    );
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: FacultyTypography.labelXs(color: fg).copyWith(fontWeight: FontWeight.w700)),
    );
  }

  Widget _iconLabel(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: FacultyColors.outline),
        const SizedBox(width: 5),
        Flexible(child: Text(text, style: FacultyTypography.labelXs(), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Mobile (< 700px) layout — the same content as desktop (header, critical
  // actions, stats, filter toolbar and course list). The desktop widgets are
  // already responsive (stats go one-per-row; each course row stacks), so
  // they are reused as-is.
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
              _buildHeader(),
              const SizedBox(height: 16),
              _buildCriticalActions(),
              const SizedBox(height: 8),
              _buildStatsRow(),
              const SizedBox(height: 16),
              _buildToolbar(),
              Container(
                decoration: BoxDecoration(
                  color: FacultyColors.surfaceContainerLowest,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < _rows.length; i++) ...[
                      if (i > 0) const Divider(height: 1, color: FacultyColors.surfaceContainer),
                      _buildCourseRow(_rows[i]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: FacultyMobileBottomNav(
        selected: FacultyNavDestination.myCourses,
        onDestinationSelected: _handleNav,
      ),
    );
  }
}

class _Stat {
  final String label;
  final String value;
  final String? footnote;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color? valueColor;
  final Color? footnoteColor;

  const _Stat(this.label, this.value, this.footnote, this.icon, this.iconColor, this.iconBg, {this.valueColor, this.footnoteColor});
}

class _CourseRow {
  final String courseId;
  final List<String> programmes;
  final String sectionId;
  final String initials;
  final Color accent;
  final Color accentBg;
  final String code;
  final String title;
  final String description;
  final String schedule;
  final String dateRange;
  final String enrolled;
  final String modules;
  final bool isActive;
  final int avgProgress;
  final String pendingCount;
  final String pendingLabel;

  const _CourseRow({
    required this.courseId,
    required this.programmes,
    required this.sectionId,
    required this.initials,
    required this.accent,
    required this.accentBg,
    required this.code,
    required this.title,
    required this.description,
    required this.schedule,
    required this.dateRange,
    required this.enrolled,
    required this.modules,
    required this.isActive,
    required this.avgProgress,
    required this.pendingCount,
    required this.pendingLabel,
  });
}
