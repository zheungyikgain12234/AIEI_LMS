import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_students_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_faculty_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturers_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_material_progress_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/assigned_course.dart';
import 'widgets/faculty_scaffold.dart';
import 'widgets/faculty_sidebar.dart';
import 'widgets/faculty_mobile_top_bar.dart';
import 'widgets/faculty_mobile_bottom_nav.dart';
import 'course_dashboard_screen.dart';
import 'student_directory_screen.dart';

/// The course dashboard/roster preview in this app is only wired up for
/// PY-402's seeded data, so only that course's "Open Dashboard"/"Roster"
/// actions are enabled — mirrors the old hardcoded `dashboardAvailable`.
const _kDashboardCourseId = '44444444-4444-4444-4444-444444444401';

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
  final _adminStudentsRepository = SupabaseAdminStudentsRepositoryImpl(Supabase.instance.client);
  final _progressRepository = SupabaseMaterialProgressRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  List<_CourseRow> _rows = const [];
  List<_Stat> _stats = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final assignedCourses = await _facultyRepository.getAssignedCourses(DemoIdentity.lecturerId);
    final lecturers = await _lecturersRepository.getLecturers();

    // Only PY-402 (_kDashboardCourseId) has a full seeded roster + graded
    // submissions in this demo, so that's the only course we can compute
    // real grading/progress KPIs for — see DemoIdentity for the material ids.
    final roster = await _adminStudentsRepository.getCourseRoster(_kDashboardCourseId);
    final modules = await _facultyRepository.getCourseModules(_kDashboardCourseId);
    final materials = await _facultyRepository.getCourseMaterials(_kDashboardCourseId);
    final assignmentSubs =
        await _progressRepository.getSubmissionsForMaterial(DemoIdentity.materialAssignment02Id);
    final quizSubs =
        await _progressRepository.getSubmissionsForMaterial(DemoIdentity.materialComplianceQuizId);
    if (!mounted) return;

    final lecturer = lecturers.where((l) => l.id == DemoIdentity.lecturerId).firstOrNull;

    final pendingAssignments = assignmentSubs.where((m) => m.status == 'completed' && m.score == null).length;
    final pendingQuizzes = quizSubs.where((m) => m.status == 'completed' && m.score == null).length;
    final totalPending = pendingAssignments + pendingQuizzes;

    final scores = roster.map((s) => s.overallScore).whereType<double>().toList();
    final avgCohortScore = scores.isEmpty ? null : scores.reduce((a, b) => a + b) / scores.length;
    final assetCount = materials.fold<int>(0, (sum, m) => sum + m.attachedFiles.length);
    final avgRosterProgress = roster.isEmpty
        ? null
        : roster.fold<int>(0, (sum, s) => sum + s.progressPercentage) ~/ roster.length;

    final rows = [
      for (var i = 0; i < assignedCourses.length; i++)
        _rowFromCourse(
          assignedCourses[i],
          i,
          moduleCount: assignedCourses[i].courseId == _kDashboardCourseId ? modules.length : null,
          assetCount: assignedCourses[i].courseId == _kDashboardCourseId ? assetCount : null,
          avgProgress: assignedCourses[i].courseId == _kDashboardCourseId ? avgRosterProgress : null,
          pendingCount: assignedCourses[i].courseId == _kDashboardCourseId ? totalPending : null,
          classAvgScore: assignedCourses[i].courseId == _kDashboardCourseId ? avgCohortScore : null,
        ),
    ];

    final totalEnrolled = assignedCourses.fold<int>(0, (sum, c) => sum + c.enrolledCount);

    setState(() {
      _rows = rows;
      _stats = [
        _Stat('Active Courses', '${assignedCourses.length} Courses', '$totalEnrolled Enrolled Learners', Icons.school_outlined,
            FacultyColors.primary, FacultyColors.surfaceContainer),
        _Stat('Pending Reviews', '$totalPending Items', '$pendingAssignments assignments • $pendingQuizzes quizzes',
            Icons.history_toggle_off, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
        _Stat(
            'Average Cohort Score',
            avgCohortScore == null ? '—' : '${avgCohortScore.toStringAsFixed(1)}%',
            null,
            Icons.show_chart,
            const Color(0xFF059669),
            const Color(0xFFD1FAE5)),
        _Stat('Teaching Capacity', lecturer != null ? '${lecturer.creditsUsed} / ${lecturer.creditsMax} Cr' : '— / — Cr', null,
            Icons.speed, const Color(0xFF4F46E5), const Color(0xFFE0E7FF)),
      ];
      _isLoading = false;
    });
  }

  _CourseRow _rowFromCourse(
    AssignedCourse c,
    int index, {
    int? moduleCount,
    int? assetCount,
    int? avgProgress,
    int? pendingCount,
    double? classAvgScore,
  }) {
    final segments = c.courseCode.split('-');
    var initials = segments.first;
    if (initials.length > 3) initials = initials.substring(0, 3);
    final (accent, accentBg) = _kAccentPalette[index % _kAccentPalette.length];
    return _CourseRow(
      initials: initials,
      accent: accent,
      accentBg: accentBg,
      code: c.courseCode,
      roleLabel: c.roleLabel,
      section: '${c.sectionCode} • ${c.capacity} Cap.',
      title: c.title,
      description: c.description,
      schedule: c.scheduleText,
      enrolled: '${c.enrolledCount} / ${c.capacity} Enrolled Students',
      modules: moduleCount == null ? '— Modules • — Assets' : '$moduleCount Modules • $assetCount Assets',
      avgProgress: avgProgress ?? 0,
      pendingCount: pendingCount == null ? '— items' : '$pendingCount items',
      pendingLabel: 'Review Items',
      classAvg: classAvgScore == null ? '—' : '${classAvgScore.toStringAsFixed(1)}%',
      classAvgTag: classAvgScore == null ? 'On Track' : (classAvgScore >= 80 ? 'On Track' : 'Needs Attention'),
      dashboardAvailable: c.courseId == _kDashboardCourseId,
    );
  }

  void _handleNav(FacultyNavDestination dest) {
    if (dest == FacultyNavDestination.myCourses) return;
    if (dest == FacultyNavDestination.studentDirectory) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentDirectoryScreen()));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('The full submissions queue isn\'t in this preview — open a course dashboard to grade a submission.')),
    );
  }

  void _unavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Detailed dashboard data isn\'t available for this course in the preview.')),
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
          const SizedBox(height: 32),
          _buildTipCard(),
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
              Text(
                'ACADEMIC TERM: FALL 2025 • DIVISION OF COMPUTING & AI',
                style: FacultyTypography.labelXs(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
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
          Text('Showing 3 assigned courses', style: FacultyTypography.labelXs()),
        ],
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
                      _pill(c.roleLabel, const Color(0xFFD1FAE5), const Color(0xFF047857)),
                      Text(c.section, style: FacultyTypography.labelXs()),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text('Active Cohort', style: FacultyTypography.labelXs(color: const Color(0xFF059669))),
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
            _metric('Avg Progress', '${c.avgProgress}%', progress: c.avgProgress / 100, barColor: c.accent),
            const SizedBox(width: 24),
            _metric('Pending Grading', c.pendingCount, footnote: c.pendingLabel, valueColor: const Color(0xFFD97706)),
            const SizedBox(width: 24),
            _metric('Class Avg', c.classAvg, footnote: c.classAvgTag, footnoteColor: const Color(0xFF059669)),
          ],
        );

        final actions = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () => c.dashboardAvailable
                  ? Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CourseDashboardScreen()))
                  : _unavailable(),
              icon: const Icon(Icons.speed, size: 16),
              label: const Text('Open Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.dashboardAvailable ? FacultyColors.primary : FacultyColors.onSurface,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => c.dashboardAvailable
                        ? Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentDirectoryScreen()))
                        : _unavailable(),
                    icon: const Icon(Icons.group_outlined, size: 14),
                    label: const Text('Roster'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FacultyColors.onSurfaceVariant,
                      backgroundColor: FacultyColors.surfaceContainerLow,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: FacultyTypography.labelXs(),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _unavailable,
                    icon: const Icon(Icons.menu_book_outlined, size: 14),
                    label: const Text('Syllabus'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FacultyColors.onSurfaceVariant,
                      backgroundColor: FacultyColors.surfaceContainerLow,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: FacultyTypography.labelXs(),
                    ),
                  ),
                ),
              ],
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

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: FacultyColors.primary, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.info_outline, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Term Teaching Compliance & Syllabus Deadlines',
                    style: FacultyTypography.labelXs(color: const Color(0xFF1E3A8A)).copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'All midterm assignment grades for PY-402 and DATA-501 must be finalized before the institutional audit lock on Friday, Nov 21. For schedule changes or section capacity overrides, contact your Chief Academic Administrator (Marcus Vance).',
                  style: FacultyTypography.labelXs(color: const Color(0xFF1E40AF)),
                ),
              ],
            ),
          ),
        ],
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
              Text('My Courses', style: FacultyTypography.headlineLg(color: FacultyColors.primary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: FacultyColors.secondaryContainer, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: FacultyColors.secondary, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(
                          'FALL 2025 TERM',
                          style: FacultyTypography.labelXs(color: FacultyColors.onSecondaryContainer).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school, size: 14, color: FacultyColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('Computing & AI', style: FacultyTypography.labelXs()),
                      ],
                    ),
                  ),
                ],
              ),
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
              _buildMobileComplianceNotice(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: FacultyMobileBottomNav(
        selected: FacultyNavDestination.myCourses,
        pendingCount: 22,
        onDestinationSelected: _handleNav,
      ),
    );
  }

  Widget _buildMobileKpiGrid() {
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
                  value: '3',
                  valueColor: FacultyColors.primary,
                  footnote: '112 Enrolled Learners',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _mobileKpiCard(
                  label: 'Pending Reviews',
                  icon: Icons.pending_actions,
                  iconBg: FacultyColors.errorContainer,
                  iconColor: FacultyColors.onErrorContainer,
                  value: '22',
                  valueColor: FacultyColors.error,
                  valueTag: 'urgent',
                  valueTagColor: FacultyColors.onErrorContainer,
                  footnote: '14 asgns • 8 quizzes',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _mobileKpiCard(
                  label: 'Avg Cohort Score',
                  icon: Icons.trending_up,
                  iconBg: FacultyColors.tertiaryFixed,
                  iconColor: FacultyColors.onTertiaryFixedVariant,
                  value: '86.4%',
                  valueColor: FacultyColors.primary,
                  valueTag: '+2.8%',
                  valueTagColor: FacultyColors.onTertiaryContainer,
                  footnote: 'vs. last academic term',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _mobileKpiCard(
                  label: 'Workload',
                  icon: Icons.pie_chart,
                  iconBg: FacultyColors.surfaceContainer,
                  iconColor: FacultyColors.primary,
                  value: '12',
                  valueSuffix: '/ 15 Cr',
                  valueColor: FacultyColors.primary,
                  footnote: 'Capacity: 80% assigned',
                ),
              ),
            ],
          ),
        ),
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
        _mobileFilterChip(label: 'Active Cohorts', bg: FacultyColors.secondary, fg: Colors.white, trailingBadge: '3'),
        _mobileFilterChip(label: 'Fall 2025', icon: Icons.calendar_month, bg: FacultyColors.surfaceContainerLowest, fg: FacultyColors.onSurfaceVariant),
        _mobileFilterChip(label: 'Role: All', icon: Icons.tune, bg: FacultyColors.surfaceContainerLowest, fg: FacultyColors.onSurfaceVariant),
      ],
    );
  }

  Widget _mobileFilterChip({required String label, required Color bg, required Color fg, IconData? icon, String? trailingBadge}) {
    return Container(
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
                          decoration: BoxDecoration(color: FacultyColors.tertiaryFixed, borderRadius: BorderRadius.circular(9999)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 5, height: 5, decoration: const BoxDecoration(color: FacultyColors.onTertiaryFixedVariant, shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Active Cohort',
                                  style: FacultyTypography.labelXs(color: FacultyColors.onTertiaryFixedVariant).copyWith(fontWeight: FontWeight.w700),
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
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            c.roleLabel,
                            style: FacultyTypography.labelXs(color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          c.enrolled,
                          style: FacultyTypography.labelXs(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
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
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _mobileMetricTile(
                    icon: Icons.assignment_late,
                    iconBg: FacultyColors.errorContainer,
                    iconColor: FacultyColors.onErrorContainer,
                    value: '$pendingNumber to Grade',
                    valueColor: FacultyColors.error,
                    footnote: c.pendingLabel,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _mobileMetricTile(
                    icon: Icons.grade,
                    iconBg: FacultyColors.tertiaryFixed,
                    iconColor: FacultyColors.onTertiaryFixedVariant,
                    value: c.classAvg,
                    valueColor: FacultyColors.primary,
                    footnote: 'Class Avg Grade',
                  ),
                ),
              ],
            ),
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
            onPressed: () => c.dashboardAvailable
                ? Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CourseDashboardScreen()))
                : _unavailable(),
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
        const SizedBox(width: 8),
        _mobileIconButton(
          icon: Icons.group,
          tooltip: 'Course Roster',
          onTap: () => c.dashboardAvailable
              ? Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentDirectoryScreen()))
              : _unavailable(),
        ),
        const SizedBox(width: 8),
        _mobileIconButton(icon: Icons.description, tooltip: 'Course Syllabus', onTap: _unavailable),
      ],
    );
  }

  Widget _mobileIconButton({required IconData icon, required String tooltip, required VoidCallback onTap}) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: FacultyColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 20, color: FacultyColors.secondary),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileComplianceNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.verified_user, size: 20, color: FacultyColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Teaching Compliance Notice',
                        style: FacultyTypography.labelMd(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: FacultyColors.secondary, shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: FacultyTypography.bodySm(),
                    children: [
                      const TextSpan(text: 'Midterm assignment grades finalized before audit lock on '),
                      TextSpan(
                        text: 'Nov 21, 23:59 UTC',
                        style: FacultyTypography.bodySm(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: '. Course syllabi and telemetry synchronize bi-hourly with Registrar systems.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
  final String initials;
  final Color accent;
  final Color accentBg;
  final String code;
  final String roleLabel;
  final String section;
  final String title;
  final String description;
  final String schedule;
  final String enrolled;
  final String modules;
  final int avgProgress;
  final String pendingCount;
  final String pendingLabel;
  final String classAvg;
  final String classAvgTag;
  final bool dashboardAvailable;

  const _CourseRow({
    required this.initials,
    required this.accent,
    required this.accentBg,
    required this.code,
    required this.roleLabel,
    required this.section,
    required this.title,
    required this.description,
    required this.schedule,
    required this.enrolled,
    required this.modules,
    required this.avgProgress,
    required this.pendingCount,
    required this.pendingLabel,
    required this.classAvg,
    required this.classAvgTag,
    required this.dashboardAvailable,
  });
}
