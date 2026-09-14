import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'widgets/faculty_scaffold.dart';
import 'widgets/faculty_sidebar.dart';
import 'course_dashboard_screen.dart';
import 'student_directory_screen.dart';
import 'package:stitch_aiei_lms/presentation/screens/admin_portal/manage_lecturers_screen.dart';

class MyAssignedCoursesScreen extends StatefulWidget {
  const MyAssignedCoursesScreen({super.key});

  @override
  State<MyAssignedCoursesScreen> createState() => _MyAssignedCoursesScreenState();
}

class _MyAssignedCoursesScreenState extends State<MyAssignedCoursesScreen> {
  static const _rows = [
    _CourseRow(
      initials: 'PY',
      accent: FacultyColors.primary,
      accentBg: Color(0xFFDBEAFE),
      code: 'PY-402',
      roleLabel: 'Primary Instructor',
      section: 'Sec A01 • 4 Credit Units',
      title: 'Python for Enterprise Data Analysis & Automation',
      description: 'ETL pipelines, pandas data structures, automated business workflows, and production API connectors.',
      schedule: 'Mon / Wed 18:00–20:30 UTC',
      enrolled: '42 / 50 Enrolled Students',
      modules: '4 Modules • 28 Assets',
      avgProgress: 72,
      pendingCount: '14 items',
      pendingLabel: 'Assignment 02',
      classAvg: '88.4%',
      classAvgTag: 'On Track',
      dashboardAvailable: true,
    ),
    _CourseRow(
      initials: 'ETL',
      accent: Color(0xFF9333EA),
      accentBg: Color(0xFFF3E8FF),
      code: 'DATA-501',
      roleLabel: 'Primary Instructor',
      section: 'Sec B02 • 4 Credit Units',
      title: 'Automated ETL & Enterprise Data Pipelines',
      description: 'Airflow orchestration, real-time Kafka event streams, schema validation, and SQL warehouse data transformations.',
      schedule: 'Tue / Thu 13:00–14:45 UTC',
      enrolled: '38 / 45 Enrolled Students',
      modules: '6 Modules • 34 Assets',
      avgProgress: 84,
      pendingCount: '6 items',
      pendingLabel: 'Pipeline Lab 03',
      classAvg: '89.1%',
      classAvgTag: 'Top Tier',
      dashboardAvailable: false,
    ),
    _CourseRow(
      initials: 'AI',
      accent: Color(0xFF0284C7),
      accentBg: Color(0xFFE0F2FE),
      code: 'AI-301',
      roleLabel: 'Co-Lecturer',
      section: 'Sec C01 • 4 Credit Units',
      title: 'Applied Machine Learning in Enterprise',
      description: 'Supervised models, gradient boosted trees, scikit-learn optimization, and enterprise model governance.',
      schedule: 'Lab Fridays 14:00–17:00 UTC',
      enrolled: '29 / 35 Enrolled Students',
      modules: '5 Modules • 22 Assets',
      avgProgress: 65,
      pendingCount: '2 items',
      pendingLabel: 'Midterm Lab',
      classAvg: '82.7%',
      classAvgTag: 'Expected Band',
      dashboardAvailable: false,
    ),
  ];

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
    return FacultyScaffold(
      selected: FacultyNavDestination.myCourses,
      onDestinationSelected: _handleNav,
      onOpenAdminPortal: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ManageLecturersScreen()),
        );
      },
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
    final stats = [
      _Stat('Active Courses', '3 Courses', '112 Enrolled Learners', Icons.school_outlined, FacultyColors.primary, FacultyColors.surfaceContainer),
      _Stat('Pending Reviews', '22 Items', '14 assignments • 8 quizzes', Icons.history_toggle_off, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
      _Stat('Average Cohort Score', '86.4%', '+2.8% vs last term', Icons.show_chart, const Color(0xFF059669), const Color(0xFFD1FAE5)),
      _Stat('Teaching Capacity', '12 / 15 Cr', null, Icons.speed, const Color(0xFF4F46E5), const Color(0xFFE0E7FF)),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 500 ? 2 : 1);
      final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: stats.map((s) => SizedBox(width: width, child: _statCard(s))).toList(),
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
