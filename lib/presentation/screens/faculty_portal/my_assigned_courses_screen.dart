import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_master_data_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_faculty_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturers_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/assigned_course.dart';
import 'package:stitch_aiei_lms/domain/models/cohort.dart';
import 'package:stitch_aiei_lms/domain/models/lecturer.dart';
import 'widgets/faculty_scaffold.dart';
import 'widgets/faculty_sidebar.dart';
import 'widgets/faculty_mobile_top_bar.dart';
import 'widgets/faculty_mobile_bottom_nav.dart';
import 'course_dashboard_screen.dart';

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

class _MyAssignedCoursesScreenState extends State<MyAssignedCoursesScreen> {
  final _facultyRepository = SupabaseFacultyRepositoryImpl(Supabase.instance.client);
  final _lecturersRepository = SupabaseLecturersRepositoryImpl(Supabase.instance.client);
  final _masterDataRepository = SupabaseAdminMasterDataRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  List<_CourseRow> _rows = const [];
  List<_Stat> _stats = const [];

  // ── Year / Cohort filter ──────────────────────────────────────────────
  List<AssignedCourse> _assignedCourses = const [];
  List<Cohort> _cohorts = const [];
  int? _selectedYear;
  String? _selectedCohort;

  // Real per-course KPIs, keyed by `sectionId` — computed for EVERY assigned
  // course (not just one hardcoded demo course), so the table and overall
  // stats both reflect actual roster/grading data for any course a lecturer
  // teaches. Rebuilt on every `_load()`; looked up (not refetched) on filter
  // change.
  Map<String, int> _moduleCountBySection = const {};
  Map<String, int> _assetCountBySection = const {};
  Map<String, int> _avgProgressBySection = const {};
  Map<String, int> _pendingAssignmentsBySection = const {};
  Map<String, int> _pendingQuizzesBySection = const {};
  Lecturer? _lecturer;

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
    if (_selectedCohort == null) return _assignedCourses;
    return _assignedCourses.where((c) => c.cohort == _selectedCohort).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final assignedCourses = await _facultyRepository.getAssignedCourses(DemoIdentity.lecturerId);
    final lecturers = await _lecturersRepository.getLecturers();
    final cohorts = await _masterDataRepository.getCohorts();
    final sectionIds = [for (final c in assignedCourses) c.sectionId];

    // Real per-course module/asset counts, computed for every assigned
    // course in parallel (not just one hardcoded demo course).
    final moduleCountBySection = <String, int>{};
    final assetCountBySection = <String, int>{};
    await Future.wait([
      for (final c in assignedCourses) _loadCourseModuleCounts(c, moduleCountBySection, assetCountBySection),
    ]);

    // Real pending-grading counts and avg progress, batched across every
    // section in one round trip (see FacultyRepository.getSectionAssessmentStats).
    // This is scoped by section (not course), so a student enrolled in the
    // same course through a different section/cohort is correctly excluded.
    final assessmentStats = await _facultyRepository.getSectionAssessmentStats(sectionIds);
    if (!mounted) return;

    final lecturer = lecturers.where((l) => l.id == DemoIdentity.lecturerId).firstOrNull;

    setState(() {
      _assignedCourses = assignedCourses;
      _cohorts = cohorts;
      _moduleCountBySection = moduleCountBySection;
      _assetCountBySection = assetCountBySection;
      _avgProgressBySection = {for (final e in assessmentStats.entries) e.key: e.value.avgProgress};
      _pendingAssignmentsBySection = {for (final e in assessmentStats.entries) e.key: e.value.pendingAssignments};
      _pendingQuizzesBySection = {for (final e in assessmentStats.entries) e.key: e.value.pendingQuizzes};
      _lecturer = lecturer;

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

  /// Fetches this one course's module/asset counts from its own section.
  Future<void> _loadCourseModuleCounts(
    AssignedCourse c,
    Map<String, int> moduleCountBySection,
    Map<String, int> assetCountBySection,
  ) async {
    final modules = await _facultyRepository.getCourseModules(c.sectionId);
    final materials = await _facultyRepository.getCourseMaterials(c.sectionId);
    moduleCountBySection[c.sectionId] = modules.length;
    assetCountBySection[c.sectionId] = materials.fold<int>(0, (sum, m) => sum + m.attachedFiles.length);
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
    final assetCount = _assetCountBySection[c.sectionId];
    final avgProgress = _avgProgressBySection[c.sectionId] ?? 0;
    final pendingCount = (_pendingAssignmentsBySection[c.sectionId] ?? 0) + (_pendingQuizzesBySection[c.sectionId] ?? 0);
    return _CourseRow(
      courseId: c.courseId,
      sectionId: c.sectionId,
      initials: initials,
      accent: accent,
      accentBg: accentBg,
      code: c.courseCode,
      section: '${c.sectionCode} • ${c.capacity} Cap.',
      title: c.title,
      description: c.description,
      schedule: c.scheduleText,
      enrolled: '${c.enrolledCount} / ${c.capacity} Enrolled Students',
      modules: moduleCount == null ? '— Modules • — Assets' : '$moduleCount Modules • $assetCount Assets',
      isActive: c.isActive,
      avgProgress: avgProgress,
      pendingCount: '$pendingCount items',
      pendingLabel: 'Review Items',
    );
  }

  void _handleNav(FacultyNavDestination dest) {
    if (dest == FacultyNavDestination.myCourses) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('The full submissions queue isn\'t in this preview — open a course dashboard to grade a submission.')),
    );
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
          const SizedBox(height: 32),
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
              style: FacultyTypography.bodySm(color: FacultyColors.onSurface),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: FacultyColors.surfaceContainerLow,
                hintText: 'Filter by course name, code, or schedule...',
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
                      Text(c.section, style: FacultyTypography.labelXs()),
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
        Text(text, style: FacultyTypography.labelXs()),
      ],
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
              Text('My Courses', style: FacultyTypography.headlineLg(color: FacultyColors.primary)),
              const SizedBox(height: 10),
              Text(
                'Manage active curriculum, track progress, and review pending evaluations.',
                style: FacultyTypography.bodyMd(),
              ),
              const SizedBox(height: 20),
              _buildMobileKpiGrid(),
              const SizedBox(height: 20),
              _buildMobileSearchBar(),
              const SizedBox(height: 10),
              _buildMobileFilterRow(),
              const SizedBox(height: 20),
              for (final c in _rows) ...[
                _buildMobileCourseCard(c),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: FacultyMobileBottomNav(
        selected: FacultyNavDestination.myCourses,
        pendingCount: _assignedCourses.fold<int>(
            0, (sum, c) => sum + (_pendingAssignmentsBySection[c.sectionId] ?? 0) + (_pendingQuizzesBySection[c.sectionId] ?? 0)),
        onDestinationSelected: _handleNav,
      ),
    );
  }

  Widget _buildMobileKpiGrid() {
    final courses = _filteredAssignedCourses;
    final activeCourses = courses.where((c) => c.isActive).toList();
    final enrolledInActive = activeCourses.fold<int>(0, (sum, c) => sum + c.enrolledCount);
    final pendingAssignments = courses.fold<int>(0, (sum, c) => sum + (_pendingAssignmentsBySection[c.sectionId] ?? 0));
    final pendingQuizzes = courses.fold<int>(0, (sum, c) => sum + (_pendingQuizzesBySection[c.sectionId] ?? 0));
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _mobileKpiCard(
                  label: 'Active Courses',
                  icon: Icons.menu_book,
                  iconBg: FacultyColors.surfaceContainer,
                  iconColor: FacultyColors.secondary,
                  value: '${activeCourses.length}',
                  valueSuffix: '/ ${courses.length}',
                  valueColor: FacultyColors.primary,
                  footnote: '$enrolledInActive Enrolled Learners (Active)',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _mobileKpiCard(
                  label: 'Pending Reviews',
                  icon: Icons.pending_actions,
                  iconBg: FacultyColors.errorContainer,
                  iconColor: FacultyColors.onErrorContainer,
                  value: '${pendingAssignments + pendingQuizzes}',
                  valueColor: FacultyColors.error,
                  footnote: '$pendingAssignments asgns • $pendingQuizzes quizzes',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Builder(builder: (context) {
          // `credits_max` is a per-cohort cap, so with a cohort selected the
          // credits used are summed just for that cohort's courses rather
          // than read off the lecturer's global (cross-cohort) credits_used.
          final creditsUsed = _selectedCohort == null
              ? _lecturer?.creditsUsed
              : courses.fold<int>(0, (sum, c) => sum + c.credits);
          final creditsMax = _lecturer?.creditsMax;
          return _mobileKpiCard(
            label: 'Teaching Capacity',
            icon: Icons.pie_chart,
            iconBg: FacultyColors.surfaceContainer,
            iconColor: FacultyColors.primary,
            value: creditsUsed != null ? '$creditsUsed' : '—',
            valueSuffix: creditsMax != null ? '/ $creditsMax Cr' : '/ — Cr',
            valueColor: FacultyColors.primary,
            footnote: creditsUsed != null && creditsMax != null && creditsMax > 0
                ? '${(creditsUsed / creditsMax * 100).round()}% assigned'
                    '${_selectedCohort == null ? '' : ' in $_selectedCohort'}'
                : '—',
          );
        }),
      ],
    );
  }

  Widget _mobileKpiCard({
    required String label,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    Color? valueColor,
    String? valueSuffix,
    String? valueTag,
    Color? valueTagColor,
    required String footnote,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: FacultyTypography.labelXs(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 5,
            children: [
              Text(
                value,
                style: FacultyTypography.headlineLg(color: valueColor ?? FacultyColors.primary).copyWith(fontWeight: FontWeight.w700, height: 1),
              ),
              if (valueSuffix != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(valueSuffix, style: FacultyTypography.labelMd(color: FacultyColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w400)),
                ),
              if (valueTag != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(valueTag, style: FacultyTypography.labelXs(color: valueTagColor ?? FacultyColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            footnote,
            style: FacultyTypography.bodySm(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: TextField(
        style: FacultyTypography.bodySm(color: FacultyColors.onSurface),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.transparent,
          hintText: 'Search assigned courses or codes...',
          hintStyle: FacultyTypography.bodySm(color: FacultyColors.outline),
          prefixIcon: const Icon(Icons.search, size: 20, color: FacultyColors.outline),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildMobileFilterRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _mobileFilterChip(
          label: _selectedYear == null ? 'Year' : '$_selectedYear',
          icon: Icons.calendar_month,
          bg: FacultyColors.surfaceContainerLowest,
          fg: FacultyColors.onSurfaceVariant,
          onTap: _openMobileYearCohortPicker,
        ),
        _mobileFilterChip(
          label: _selectedCohort ?? 'Cohort',
          icon: Icons.groups_outlined,
          bg: FacultyColors.surfaceContainerLowest,
          fg: FacultyColors.onSurfaceVariant,
          onTap: _openMobileYearCohortPicker,
        ),
      ],
    );
  }

  void _openMobileYearCohortPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: FacultyColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter by Year & Cohort', style: FacultyTypography.titleSm()),
              const SizedBox(height: 16),
              Text('Year', style: FacultyTypography.labelXs()),
              const SizedBox(height: 6),
              _yearDropdown(onChanged: (y) => setModalState(() {})),
              const SizedBox(height: 16),
              Text('Cohort', style: FacultyTypography.labelXs()),
              const SizedBox(height: 6),
              _cohortDropdown(onChanged: (c) => setModalState(() {})),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileFilterChip({required String label, required Color bg, required Color fg, IconData? icon, String? trailingBadge, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: FacultyColors.outline),
              const SizedBox(width: 6),
            ],
            Text(label, style: FacultyTypography.labelMd(color: fg)),
            if (trailingBadge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                child: Text(
                  trailingBadge,
                  style: FacultyTypography.labelXs(color: fg).copyWith(fontWeight: FontWeight.w700, fontSize: 10),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCourseCard(_CourseRow c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _mobileCourseMediaHeader(c),
          const SizedBox(height: 12),
          Text(c.title, style: FacultyTypography.titleSm(), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(c.description, style: FacultyTypography.bodySm(), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: c.accent),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  c.schedule,
                  style: FacultyTypography.bodySm(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text('•', style: FacultyTypography.bodySm()),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  c.modules,
                  style: FacultyTypography.bodySm(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _mobileCourseMetricsBox(c),
          const SizedBox(height: 12),
          _mobileCourseActions(c),
        ],
      ),
    );
  }

  Widget _mobileCourseMediaHeader(_CourseRow c) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 128,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.accent, c.accent.withValues(alpha: 0.65)],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    FacultyColors.primary.withValues(alpha: 0.9),
                    FacultyColors.primary.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: FacultyColors.primaryContainer, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            c.code,
                            style: FacultyTypography.labelXs(color: Colors.white).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: c.isActive ? FacultyColors.tertiaryFixed : Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: c.isActive ? FacultyColors.onTertiaryFixedVariant : Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  c.isActive ? 'Active' : 'Inactive',
                                  style: FacultyTypography.labelXs(color: c.isActive ? FacultyColors.onTertiaryFixedVariant : Colors.white)
                                      .copyWith(fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    c.enrolled,
                    style: FacultyTypography.labelXs(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileCourseMetricsBox(_CourseRow c) {
    final pendingNumber = c.pendingCount.split(' ').first;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'SYLLABUS PACING',
                  style: FacultyTypography.labelXs(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${c.avgProgress}% Completed',
                style: FacultyTypography.labelMd(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: c.avgProgress / 100,
              minHeight: 8,
              backgroundColor: FacultyColors.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(FacultyColors.secondaryContainer),
            ),
          ),
          const SizedBox(height: 10),
          _mobileMetricTile(
            icon: Icons.assignment_late,
            iconBg: FacultyColors.errorContainer,
            iconColor: FacultyColors.onErrorContainer,
            value: '$pendingNumber to Grade',
            valueColor: FacultyColors.error,
            footnote: c.pendingLabel,
          ),
        ],
      ),
    );
  }

  Widget _mobileMetricTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    Color? valueColor,
    required String footnote,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 3)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: FacultyTypography.labelXs(color: valueColor ?? FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  footnote,
                  style: FacultyTypography.labelXs().copyWith(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileCourseActions(_CourseRow c) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _openDashboard(c),
            style: ElevatedButton.styleFrom(
              backgroundColor: FacultyColors.secondary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    'Open Dashboard',
                    style: FacultyTypography.labelMd(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
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
  final String sectionId;
  final String initials;
  final Color accent;
  final Color accentBg;
  final String code;
  final String section;
  final String title;
  final String description;
  final String schedule;
  final String enrolled;
  final String modules;
  final bool isActive;
  final int avgProgress;
  final String pendingCount;
  final String pendingLabel;

  const _CourseRow({
    required this.courseId,
    required this.sectionId,
    required this.initials,
    required this.accent,
    required this.accentBg,
    required this.code,
    required this.section,
    required this.title,
    required this.description,
    required this.schedule,
    required this.enrolled,
    required this.modules,
    required this.isActive,
    required this.avgProgress,
    required this.pendingCount,
    required this.pendingLabel,
  });
}
