import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'widgets/faculty_scaffold.dart';
import 'widgets/faculty_sidebar.dart';
import 'my_assigned_courses_screen.dart';
import 'grade_assignment_screen.dart';

// ---------------------------------------------------------------------------
// StudentDirectoryScreen – Stitch "Student Roster & Progress (Python for
// Enterprise)" faithful Flutter conversion.
// ---------------------------------------------------------------------------
class StudentDirectoryScreen extends StatefulWidget {
  const StudentDirectoryScreen({super.key});

  @override
  State<StudentDirectoryScreen> createState() => _StudentDirectoryScreenState();
}

class _StudentDirectoryScreenState extends State<StudentDirectoryScreen> {
  static const _students = [
    _Student('Maya Patel', 'Business Intelligence Analyst • BI Group', 'EMP-74102', 92, 'Ahead', FacultyColors.tertiary,
        '2/2', '98% Graded', FacultyColors.tertiaryFixed, '98.0%', '18m ago', 'Top Performer', FacultyColors.secondaryContainer, hasSubmission: false),
    _Student('Alex Chen', 'Product Analyst • Operations Core', 'EMP-88219', 75, 'On Schedule', FacultyColors.primary,
        '1/2', 'Pending Review', FacultyColors.surfaceContainerHigh, '94.0%', '2 hours ago', 'On Track', FacultyColors.surfaceContainer, hasSubmission: true),
    _Student('Marcus Vance', 'Financial Systems Lead • Treasury Tech', 'EMP-91024', 45, 'Stalled', FacultyColors.error,
        '0/2', 'Assignment 2 Late', FacultyColors.errorContainer, '68.0%', '6 days ago', 'Needs Review', FacultyColors.errorContainer,
        flagged: true, hasSubmission: false),
    _Student('Elena Rostova', 'Compliance Engineer • Global Risk', 'EMP-60211', 80, 'On Pace', FacultyColors.tertiary,
        '2/2', '89% Avg', FacultyColors.surfaceContainer, '88.5%', 'Yesterday', 'On Track', FacultyColors.surfaceContainer, hasSubmission: false),
    _Student('David Kim', 'Data Ops Associate • Analytics Platform', 'EMP-43890', 70, 'On Pace', FacultyColors.primary,
        '1/2', '92% Graded', FacultyColors.surfaceContainer, '91.0%', '4 hours ago', 'On Track', FacultyColors.surfaceContainer, hasSubmission: false),
    _Student('Sophia Loren', 'Logistics Analyst • Supply Chain Intelligence', 'EMP-55198', 60, 'Behind', FacultyColors.secondary,
        '1/2', 'Draft Saved', FacultyColors.surfaceContainerHigh, '84.0%', '3 days ago', 'Behind Schedule', FacultyColors.surfaceContainer, hasSubmission: false),
  ];

  void _handleNav(FacultyNavDestination dest) {
    switch (dest) {
      case FacultyNavDestination.myCourses:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyAssignedCoursesScreen()));
        break;
      case FacultyNavDestination.studentDirectory:
        break;
      case FacultyNavDestination.gradingAndSubmissions:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GradeAssignmentScreen()));
        break;
    }
  }

  void _rowAction(_Student s, String action) {
    if (action == 'submissions' && s.hasSubmission) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GradeAssignmentScreen()));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No ${action == 'submissions' ? 'submission' : action} data for ${s.name} in this preview.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FacultyScaffold(
      selected: FacultyNavDestination.studentDirectory,
      onDestinationSelected: _handleNav,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 24),
          _buildStatsRow(),
          const SizedBox(height: 24),
          _buildTableCard(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back, size: 18, color: FacultyColors.primary),
                    const SizedBox(width: 4),
                    Text('Back to Course Dashboard', style: FacultyTypography.labelMd(color: FacultyColors.primary)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('COURSE ID:', style: FacultyTypography.labelXs()),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(4)),
                  child: Text('CS-6401-ENT', style: FacultyTypography.labelXs(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700)),
                ),
                Text('/ FALL 2025', style: FacultyTypography.labelXs()),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 16,
          runSpacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: FacultyColors.secondaryContainer, borderRadius: BorderRadius.circular(4)),
                  child: Text('PYTHON FOR ENTERPRISE DATA', style: FacultyTypography.labelXs(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 4),
                Text('Student Directory', style: FacultyTypography.displayLg()),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('42 enrolled students in Fall 2025 Cohort', style: FacultyTypography.bodyMd(color: FacultyColors.onSurfaceVariant)),
                    Text('•', style: FacultyTypography.bodyMd()),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: FacultyColors.tertiary, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('38 on-track', style: FacultyTypography.bodyMd(color: FacultyColors.tertiary).copyWith(fontWeight: FontWeight.w700)),
                    ]),
                    Text('•', style: FacultyTypography.bodyMd()),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: FacultyColors.error, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('4 flagged for review', style: FacultyTypography.bodyMd(color: FacultyColors.error).copyWith(fontWeight: FontWeight.w700)),
                    ]),
                  ],
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Roster export not wired up in this preview.'))),
              icon: const Icon(Icons.file_download_outlined, size: 18, color: FacultyColors.secondary),
              label: const Text('Export'),
              style: OutlinedButton.styleFrom(
                foregroundColor: FacultyColors.onSurface,
                backgroundColor: FacultyColors.surfaceContainerLowest,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 500 ? 2 : 1);
      final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
      final cards = [
        _stat('COHORT CAPACITY', '42', Icons.groups_outlined, FacultyColors.primary, footer: '100% Enrolled', footer2: 'Max Seat: 45', barColor: FacultyColors.primary),
        _stat('AVG. QUIZ PERFORMANCE', '88.4%', Icons.quiz_outlined, FacultyColors.primary, footer: '+3.1% vs Q2', barColor: FacultyColors.tertiary, progress: 0.884),
        _stat('ASSIGNMENT COMPLETION', '81.0%', Icons.task_alt_outlined, FacultyColors.primary, footer: '34 of 42 on pace', footer2: 'Module 3 Due Fri', barColor: FacultyColors.primaryContainer),
        _stat('REQUIRES INTERVENTION', '3 Students', Icons.warning_amber_outlined, FacultyColors.error, footer: 'Overdue submissions', valueColor: FacultyColors.error, iconBg: FacultyColors.errorContainer, barColor: FacultyColors.error),
      ];
      return Wrap(spacing: 16, runSpacing: 16, children: cards.map((c) => SizedBox(width: width, child: c)).toList());
    });
  }

  Widget _stat(String label, String value, IconData icon, Color iconColor, {String? footer, String? footer2, Color? valueColor, Color? iconBg, double? progress, Color? barColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Expanded(child: Text(label, style: FacultyTypography.labelXs().copyWith(fontWeight: FontWeight.w700))),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: iconBg ?? FacultyColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: FacultyTypography.displayLg().copyWith(color: valueColor ?? FacultyColors.onSurface, fontSize: 26)),
          const SizedBox(height: 10),
          if (progress != null)
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: LinearProgressIndicator(value: progress, minHeight: 5, backgroundColor: FacultyColors.surfaceContainer, valueColor: AlwaysStoppedAnimation<Color>(barColor ?? FacultyColors.primary)),
                ),
              ),
              if (footer != null) ...[const SizedBox(width: 6), Text(footer, style: FacultyTypography.labelXs())],
            ])
          else if (footer != null)
            Row(
              children: [
                Expanded(child: Text(footer, style: FacultyTypography.bodySm(color: valueColor ?? FacultyColors.tertiary).copyWith(fontWeight: FontWeight.w600))),
                if (footer2 != null) Text(footer2, style: FacultyTypography.labelXs()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTableCard() {
    return Container(
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: FacultyTypography.bodySm(color: FacultyColors.onSurface),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: FacultyColors.surfaceContainerLow,
                hintText: 'Search by student name, email, employee ID...',
                hintStyle: FacultyTypography.bodySm(color: FacultyColors.outline),
                prefixIcon: const Icon(Icons.search, size: 18, color: FacultyColors.outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1100,
              child: Column(
                children: [
                  _tableHeaderRow(),
                  for (final s in _students) _tableRow(s),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Showing 1 to 6 of 42 students', style: FacultyTypography.bodySm()),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [1, 2, 3, 4].map((p) {
                    final active = p == 1;
                    return Container(
                      margin: const EdgeInsets.only(left: 4),
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? FacultyColors.primary : FacultyColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$p', style: FacultyTypography.labelXs(color: active ? Colors.white : FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeaderRow() {
    TextStyle s() => FacultyTypography.labelXs().copyWith(fontWeight: FontWeight.w700);
    return Container(
      color: FacultyColors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('STUDENT', style: s())),
          Expanded(flex: 2, child: Text('EMPLOYEE ID', style: s())),
          Expanded(flex: 2, child: Text('PROGRESS', style: s())),
          Expanded(flex: 1, child: Text('ASSIGN.', style: s())),
          Expanded(flex: 1, child: Text('QUIZ AVG', style: s(), textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text('STATUS', style: s(), textAlign: TextAlign.center)),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _tableRow(_Student s) {
    return Container(
      decoration: BoxDecoration(
        color: s.flagged ? FacultyColors.errorContainer.withValues(alpha: 0.15) : null,
        border: const Border(bottom: BorderSide(color: FacultyColors.surfaceContainerLow)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(color: FacultyColors.surfaceContainerHigh, shape: BoxShape.circle),
                  child: Icon(Icons.person, color: FacultyColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(child: Text(s.name, style: FacultyTypography.bodyMd(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                        if (s.flagged) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.flag, size: 14, color: FacultyColors.error)),
                      ]),
                      Text(s.role, style: FacultyTypography.labelXs(), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(s.employeeId, style: FacultyTypography.bodySm(color: FacultyColors.secondary))),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${s.progress}%', style: FacultyTypography.labelXs(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
                    Text(s.progressTag, style: FacultyTypography.labelXs(color: s.progressColor).copyWith(fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: LinearProgressIndicator(value: s.progress / 100, minHeight: 5, backgroundColor: FacultyColors.surfaceContainer, valueColor: AlwaysStoppedAnimation<Color>(s.progressColor)),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.assignments, style: FacultyTypography.bodySm(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: s.assignmentsTagBg, borderRadius: BorderRadius.circular(4)),
                  child: Text(s.assignmentsTag, style: FacultyTypography.labelXs(), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(s.quizAvg, textAlign: TextAlign.right, style: FacultyTypography.titleSm(color: s.flagged ? FacultyColors.error : FacultyColors.onSurface)),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: s.statusBg, borderRadius: BorderRadius.circular(4)),
                child: Text(s.status, style: FacultyTypography.labelXs(color: s.statusColor).copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18, color: FacultyColors.secondary),
              onSelected: (action) => _rowAction(s, action),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'submissions', child: Text('View Submissions')),
                PopupMenuItem(value: 'email', child: Text('Email Student')),
                PopupMenuItem(value: 'note', child: Text('Add Private Note')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Student {
  final String name;
  final String role;
  final String employeeId;
  final int progress;
  final String progressTag;
  final Color progressColor;
  final String assignments;
  final String assignmentsTag;
  final Color assignmentsTagBg;
  final String quizAvg;
  final String lastActive;
  final String status;
  final Color statusBg;
  final bool flagged;
  final bool hasSubmission;

  Color get statusColor => status == 'Needs Review' ? FacultyColors.onErrorContainer : (status == 'Top Performer' ? FacultyColors.primary : FacultyColors.tertiary);

  const _Student(
    this.name,
    this.role,
    this.employeeId,
    this.progress,
    this.progressTag,
    this.progressColor,
    this.assignments,
    this.assignmentsTag,
    this.assignmentsTagBg,
    this.quizAvg,
    this.lastActive,
    this.status,
    this.statusBg, {
    this.flagged = false,
    this.hasSubmission = false,
  });
}
