import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_students_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_material_progress_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/material_progress.dart';
import 'package:stitch_aiei_lms/domain/models/roster_student.dart';
import 'widgets/faculty_scaffold.dart';
import 'widgets/faculty_sidebar.dart';
import 'widgets/faculty_mobile_top_bar.dart';
import 'widgets/faculty_mobile_bottom_nav.dart';
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
  final _rosterRepository = SupabaseAdminStudentsRepositoryImpl(Supabase.instance.client);
  final _materialProgressRepository = SupabaseMaterialProgressRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  List<_Student> _students = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final roster = await _rosterRepository.getCourseRoster(DemoIdentity.coursePyId);

    final assignmentProgress = <String, MaterialProgress?>{};
    final quizProgress = <String, MaterialProgress?>{};
    await Future.wait([
      for (final s in roster) ...[
        _materialProgressRepository
            .getProgress(s.studentId, DemoIdentity.materialAssignment02Id)
            .then((p) => assignmentProgress[s.studentId] = p),
        _materialProgressRepository
            .getProgress(s.studentId, DemoIdentity.materialComplianceQuizId)
            .then((p) => quizProgress[s.studentId] = p),
      ],
    ]);

    if (!mounted) return;

    final students = [
      for (final s in roster)
        _studentFromRoster(s, assignmentProgress[s.studentId], quizProgress[s.studentId]),
    ];

    setState(() {
      _students = students;
      _isLoading = false;
    });
  }

  _Student _studentFromRoster(RosterStudent s, MaterialProgress? assignment, MaterialProgress? quiz) {
    final (progressTag, progressColor) = _paceFor(s.riskStatus);
    final (status, statusBg) = _standingFor(s.riskStatus);

    final doneCount = [assignment, quiz].where((p) => p?.status == 'completed').length;
    final hasSubmission = assignment != null && assignment.status == 'completed' && assignment.score == null;

    String assignmentsTag;
    Color assignmentsTagBg;
    if (hasSubmission) {
      assignmentsTag = 'Pending Review';
      assignmentsTagBg = FacultyColors.surfaceContainerHigh;
    } else if (doneCount == 2) {
      assignmentsTag = s.overallScore != null ? '${s.overallScore!.toStringAsFixed(0)}% Graded' : 'Graded';
      assignmentsTagBg = FacultyColors.surfaceContainer;
    } else if (doneCount == 1) {
      assignmentsTag = 'In Progress';
      assignmentsTagBg = FacultyColors.surfaceContainerHigh;
    } else if (s.riskStatus == 'critical') {
      assignmentsTag = 'Assignment Late';
      assignmentsTagBg = FacultyColors.errorContainer;
    } else {
      assignmentsTag = 'Not Started';
      assignmentsTagBg = FacultyColors.surfaceContainer;
    }

    return _Student(
      studentId: s.studentId,
      name: s.name,
      role: s.title ?? 'Enrolled Student',
      studentCode: s.studentCode,
      progress: s.progressPercentage,
      progressTag: progressTag,
      progressColor: progressColor,
      assignments: '$doneCount/2',
      assignmentsTag: assignmentsTag,
      assignmentsTagBg: assignmentsTagBg,
      quizAvg: s.overallScore != null ? '${s.overallScore!.toStringAsFixed(1)}%' : '—',
      lastActive: _formatLastActive(s.lastActivityAt),
      status: status,
      statusBg: statusBg,
      flagged: s.riskStatus == 'critical',
      hasSubmission: hasSubmission,
    );
  }

  (String, Color) _paceFor(String riskStatus) {
    switch (riskStatus) {
      case 'critical':
        return ('Stalled', FacultyColors.error);
      case 'at_risk':
        return ('Behind', FacultyColors.secondary);
      default:
        return ('On Pace', FacultyColors.tertiary);
    }
  }

  (String, Color) _standingFor(String riskStatus) {
    switch (riskStatus) {
      case 'critical':
        return ('Needs Review', FacultyColors.errorContainer);
      case 'at_risk':
        return ('Behind Schedule', FacultyColors.surfaceContainer);
      default:
        return ('On Track', FacultyColors.surfaceContainer);
    }
  }

  String _formatLastActive(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (MediaQuery.of(context).size.width < 700) {
      return _buildMobileScaffold(context);
    }
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

  int get _onTrackCount => _students.where((s) => s.status == 'On Track').length;
  int get _flaggedCount => _students.where((s) => s.flagged).length;

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
                    Text('${_students.length} enrolled students in Fall 2025 Cohort', style: FacultyTypography.bodyMd(color: FacultyColors.onSurfaceVariant)),
                    Text('•', style: FacultyTypography.bodyMd()),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: FacultyColors.tertiary, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('$_onTrackCount on-track', style: FacultyTypography.bodyMd(color: FacultyColors.tertiary).copyWith(fontWeight: FontWeight.w700)),
                    ]),
                    Text('•', style: FacultyTypography.bodyMd()),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: FacultyColors.error, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('$_flaggedCount flagged for review', style: FacultyTypography.bodyMd(color: FacultyColors.error).copyWith(fontWeight: FontWeight.w700)),
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
    final total = _students.length;
    final avgProgress = total == 0 ? 0 : (_students.fold<int>(0, (sum, s) => sum + s.progress) / total).round();
    final scored = _students.where((s) => s.quizAvg != '—').toList();
    final avgQuiz = scored.isEmpty
        ? null
        : scored.fold<double>(0, (sum, s) => sum + double.parse(s.quizAvg.replaceAll('%', ''))) / scored.length;
    final assignmentDone = _students.fold<int>(0, (sum, s) => sum + int.parse(s.assignments.split('/').first));
    final assignmentCompletionPct = total == 0 ? 0.0 : assignmentDone / (total * 2);
    final onPace = _students.where((s) => s.status != 'Needs Review').length;
    final needsIntervention = _flaggedCount;

    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 500 ? 2 : 1);
      final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
      final cards = [
        _stat('COHORT CAPACITY', '$total', Icons.groups_outlined, FacultyColors.primary, footer: '$avgProgress% Avg Progress', barColor: FacultyColors.primary),
        _stat('AVG. QUIZ PERFORMANCE', avgQuiz != null ? '${avgQuiz.toStringAsFixed(1)}%' : '—', Icons.quiz_outlined, FacultyColors.primary,
            footer: '${scored.length} of $total scored', barColor: FacultyColors.tertiary, progress: avgQuiz != null ? avgQuiz / 100 : null),
        _stat('ASSIGNMENT COMPLETION', '${(assignmentCompletionPct * 100).toStringAsFixed(0)}%', Icons.task_alt_outlined, FacultyColors.primary,
            footer: '$onPace of $total on pace', barColor: FacultyColors.primaryContainer),
        _stat('REQUIRES INTERVENTION', '$needsIntervention Students', Icons.warning_amber_outlined, FacultyColors.error,
            footer: 'Flagged for review', valueColor: FacultyColors.error, iconBg: FacultyColors.errorContainer, barColor: FacultyColors.error),
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
                Text('Showing 1 to ${_students.length} of ${_students.length} students', style: FacultyTypography.bodySm()),
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
          Expanded(flex: 2, child: Text(s.studentCode, style: FacultyTypography.bodySm(color: FacultyColors.secondary))),
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

  // -------------------------------------------------------------------------
  // Mobile (<700px) layout
  // -------------------------------------------------------------------------

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: const FacultyMobileTopBar.root(),
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _mobileBackRow(context),
              const SizedBox(height: 12),
              _mobileHeaderRow(context),
              const SizedBox(height: 16),
              _mobileTelemetryGrid(),
              const SizedBox(height: 16),
              _mobileSearchField(),
              const SizedBox(height: 10),
              _mobileFilterChipsRow(),
              const SizedBox(height: 8),
              _mobileSortRow(),
              const SizedBox(height: 16),
              for (final s in _students) ...[
                _mobileStudentCard(s),
                const SizedBox(height: 12),
              ],
              _mobilePaginationBar(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: FacultyMobileBottomNav(
        selected: FacultyNavDestination.studentDirectory,
        pendingCount: 14,
        onDestinationSelected: _handleNav,
      ),
    );
  }

  Widget _mobileBackRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, size: 18, color: FacultyColors.secondary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Back to Course Dashboard',
                      style: FacultyTypography.labelMd(color: FacultyColors.secondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(4)),
          child: Text(
            'CS-6401-ENT',
            style: FacultyTypography.labelXs(color: FacultyColors.secondary).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _mobileHeaderRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student Directory & Roster',
                style: FacultyTypography.headlineMd(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: FacultyColors.tertiary, shape: BoxShape.circle)),
                  Text('${_students.length} enrolled', style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant)),
                  Text('•', style: FacultyTypography.bodySm(color: FacultyColors.outlineVariant)),
                  Text('$_onTrackCount on-track', style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant)),
                  Text('•', style: FacultyTypography.bodySm(color: FacultyColors.outlineVariant)),
                  Text('$_flaggedCount flagged', style: FacultyTypography.bodySm(color: FacultyColors.error).copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Roster export not wired up in this preview.')),
          ),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: FacultyColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.file_download_outlined, size: 18, color: FacultyColors.secondary),
                const SizedBox(width: 4),
                Text('Export', style: FacultyTypography.labelMd(color: FacultyColors.onSurface)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _mobileTelemetryGrid() {
    final total = _students.length;
    final avgProgress = total == 0 ? 0 : (_students.fold<int>(0, (sum, s) => sum + s.progress) / total).round();
    final scored = _students.where((s) => s.quizAvg != '—').toList();
    final avgQuiz = scored.isEmpty
        ? null
        : scored.fold<double>(0, (sum, s) => sum + double.parse(s.quizAvg.replaceAll('%', ''))) / scored.length;
    final assignmentDone = _students.fold<int>(0, (sum, s) => sum + int.parse(s.assignments.split('/').first));
    final assignmentCompletionPct = total == 0 ? 0.0 : assignmentDone / (total * 2) * 100;
    final onPace = _students.where((s) => s.status != 'Needs Review').length;

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _mobileTelemetryCard(
                  label: 'Cohort Fill',
                  icon: Icons.groups_outlined,
                  iconColor: FacultyColors.secondary,
                  value: '$total',
                  footer: '$avgProgress% Avg Progress',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _mobileTelemetryCard(
                  label: 'Avg Quiz Score',
                  icon: Icons.verified_outlined,
                  iconColor: FacultyColors.onTertiaryContainer,
                  value: avgQuiz != null ? '${avgQuiz.toStringAsFixed(1)}%' : '—',
                  footer: '${scored.length} of $total scored',
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
                child: _mobileTelemetryCard(
                  label: 'Assignments',
                  icon: Icons.task_outlined,
                  iconColor: FacultyColors.secondaryContainer,
                  value: '${assignmentCompletionPct.toStringAsFixed(0)}%',
                  footer: '$onPace of $total on pace',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _mobileTelemetryCard(
                  label: 'Requires Action',
                  icon: Icons.notification_important_outlined,
                  iconColor: FacultyColors.error,
                  value: '$_flaggedCount',
                  valueSuffix: ' alerts',
                  footer: 'Flagged for review',
                  labelColor: FacultyColors.error,
                  valueColor: FacultyColors.error,
                  footerColor: FacultyColors.error,
                  background: FacultyColors.errorContainer.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mobileTelemetryCard({
    required String label,
    required IconData icon,
    required Color iconColor,
    required String value,
    String? valueSuffix,
    double? progress,
    Color? progressColor,
    IconData? trendIcon,
    String? trendText,
    Color? trendColor,
    String? footer,
    Color? labelColor,
    Color? valueColor,
    Color? footerColor,
    Color? background,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background ?? FacultyColors.surfaceContainerLowest,
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
                  label,
                  style: FacultyTypography.labelXs(color: labelColor ?? FacultyColors.onSurfaceVariant)
                      .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 18, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: FacultyTypography.headlineMd(color: valueColor ?? FacultyColors.primary).copyWith(fontWeight: FontWeight.w700),
              children: [
                TextSpan(text: value),
                if (valueSuffix != null)
                  TextSpan(text: valueSuffix, style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant)),
              ],
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(9999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: FacultyColors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor ?? FacultyColors.primary),
              ),
            ),
          ],
          if (trendIcon != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(trendIcon, size: 14, color: trendColor ?? FacultyColors.onTertiaryContainer),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    trendText ?? '',
                    style: FacultyTypography.labelXs(color: trendColor ?? FacultyColors.onTertiaryContainer).copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: 4),
            Text(
              footer,
              style: FacultyTypography.labelXs(color: footerColor ?? FacultyColors.onSurfaceVariant).copyWith(
                fontWeight: footerColor != null ? FontWeight.w700 : FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _mobileSearchField() {
    return TextField(
      style: FacultyTypography.bodySm(color: FacultyColors.onSurface),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: FacultyColors.surfaceContainerLowest,
        hintText: 'Search student name or ID...',
        hintStyle: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant),
        prefixIcon: const Icon(Icons.search, size: 20, color: FacultyColors.onSurfaceVariant),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }

  Widget _mobileFilterChipsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _mobileFilterChip('All', '${_students.length}', selected: true),
          const SizedBox(width: 8),
          _mobileFilterChip('On Track', '$_onTrackCount'),
          const SizedBox(width: 8),
          _mobileFilterChip('Review', '$_flaggedCount', dotColor: FacultyColors.error),
        ],
      ),
    );
  }

  Widget _mobileFilterChip(String label, String count, {bool selected = false, Color? dotColor}) {
    final bg = selected ? FacultyColors.secondary : FacultyColors.surfaceContainerLowest;
    final fg = selected ? FacultyColors.onSecondary : FacultyColors.onSurfaceVariant;
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
          if (dotColor != null) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(label, style: FacultyTypography.labelMd(color: fg)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: selected ? FacultyColors.surfaceContainerLowest.withValues(alpha: 0.25) : FacultyColors.surfaceContainer,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              count,
              style: FacultyTypography.labelXs(color: fg).copyWith(fontWeight: FontWeight.w700, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileSortRow() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: FacultyColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sort: Grade', style: FacultyTypography.labelXs(color: FacultyColors.onSurface)),
            const SizedBox(width: 2),
            const Icon(Icons.expand_more, size: 16, color: FacultyColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _mobileStudentCard(_Student s) {
    final bool isTop = s.status == 'Top Performer';
    final bool isBehind = s.status == 'Behind Schedule';
    final String badgeLabel = isTop ? 'On Track' : (isBehind ? 'Behind Pace' : s.status);
    final Color badgeColor = s.flagged ? FacultyColors.error : (isBehind ? FacultyColors.onSurfaceVariant : FacultyColors.onTertiaryContainer);
    final Color badgeBg = s.flagged ? FacultyColors.errorContainer : (isBehind ? FacultyColors.surfaceContainer : FacultyColors.surfaceContainerLow);
    final Color ringColor = s.flagged ? FacultyColors.error : (isBehind ? FacultyColors.outline : FacultyColors.onTertiaryContainer);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: FacultyColors.surfaceContainerHigh,
                      shape: BoxShape.circle,
                      border: Border.all(color: ringColor, width: 2),
                    ),
                    child: const Icon(Icons.person, color: FacultyColors.primary, size: 20),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: ringColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: FacultyColors.surfaceContainerLowest, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            s.name,
                            style: FacultyTypography.titleSm(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isTop) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: FacultyColors.tertiaryFixed, borderRadius: BorderRadius.circular(9999)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, size: 11, color: FacultyColors.primary),
                                const SizedBox(width: 2),
                                Text('Top', style: FacultyTypography.labelXs(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700, fontSize: 10)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${s.studentCode} • ${s.role}',
                      style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  badgeLabel,
                  style: FacultyTypography.labelXs(color: badgeColor).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant),
                          children: [
                            const TextSpan(text: 'Course Pace: '),
                            TextSpan(
                              text: '${s.progress}% ${s.progressTag}',
                              style: FacultyTypography.bodySm(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant),
                          children: [
                            const TextSpan(text: 'Quiz Avg: '),
                            TextSpan(
                              text: s.quizAvg,
                              style: FacultyTypography.bodySm(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: LinearProgressIndicator(
                    value: s.progress / 100,
                    minHeight: 5,
                    backgroundColor: FacultyColors.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(s.progressColor),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Assignments: ${s.assignments} (${s.assignmentsTag})',
                        style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule, size: 13, color: FacultyColors.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text(s.lastActive, style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (s.flagged) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: FacultyColors.errorContainer.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(10)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_outlined, size: 16, color: FacultyColors.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${s.assignmentsTag}: No recorded activity for ${s.lastActive}.',
                      style: FacultyTypography.labelXs(color: FacultyColors.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          _mobileCardFooter(s, isTop: isTop, isBehind: isBehind),
        ],
      ),
    );
  }

  Widget _mobileCardFooter(_Student s, {required bool isTop, required bool isBehind}) {
    if (s.flagged) {
      return Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => _rowAction(s, 'submissions'),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
              child: Text('View Submissions', style: FacultyTypography.labelMd(color: FacultyColors.secondary), overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _rowAction(s, 'email'),
            style: ElevatedButton.styleFrom(
              backgroundColor: FacultyColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Intervene'),
          ),
        ],
      );
    }
    if (s.hasSubmission) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _rowAction(s, 'submissions'),
          style: ElevatedButton.styleFrom(
            backgroundColor: FacultyColors.secondary,
            foregroundColor: FacultyColors.onSecondary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Grade Assignment'),
        ),
      );
    }
    final String leftLabel = isTop ? 'View Detailed Telemetry' : (isBehind ? 'Extend Milestone' : 'Performance Log');
    final String rightLabel = isTop ? 'Notes' : (isBehind ? 'Nudge' : 'Feedback');
    final String rightAction = isTop ? 'note' : (isBehind ? 'nudge' : 'email');
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => _rowAction(s, isTop ? 'telemetry' : 'submissions'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(leftLabel, style: FacultyTypography.labelMd(color: FacultyColors.secondary), overflow: TextOverflow.ellipsis),
                ),
                if (isTop) const Padding(padding: EdgeInsets.only(left: 2), child: Icon(Icons.chevron_right, size: 16, color: FacultyColors.secondary)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _rowAction(s, rightAction),
          style: ElevatedButton.styleFrom(
            backgroundColor: FacultyColors.surfaceContainerLow,
            foregroundColor: FacultyColors.secondary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(rightLabel),
        ),
      ],
    );
  }

  Widget _mobilePaginationBar() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          Text(
            'Showing ${_students.length} of ${_students.length} students',
            style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pageBtn(icon: Icons.chevron_left, enabled: false),
              _pageBtn(label: '1', active: true),
              _pageBtn(label: '2'),
              _pageBtn(label: '3'),
              _pageBtn(icon: Icons.chevron_right),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pageBtn({String? label, IconData? icon, bool active = false, bool enabled = true}) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? FacultyColors.secondary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: icon != null
          ? Icon(icon, size: 18, color: enabled ? FacultyColors.onSurface : FacultyColors.outline)
          : Text(
              label ?? '',
              style: FacultyTypography.labelXs(color: active ? FacultyColors.onSecondary : FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w700),
            ),
    );
  }
}

class _Student {
  final String studentId;
  final String name;
  final String role;
  final String studentCode;
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

  const _Student({
    required this.studentId,
    required this.name,
    required this.role,
    required this.studentCode,
    required this.progress,
    required this.progressTag,
    required this.progressColor,
    required this.assignments,
    required this.assignmentsTag,
    required this.assignmentsTagBg,
    required this.quizAvg,
    required this.lastActive,
    required this.status,
    required this.statusBg,
    this.flagged = false,
    this.hasSubmission = false,
  });
}
