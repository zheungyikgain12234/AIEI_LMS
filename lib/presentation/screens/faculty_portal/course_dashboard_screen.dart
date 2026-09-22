import 'package:flutter/material.dart' hide MaterialType;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_students_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_exam_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_faculty_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_material_progress_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/content_block_submission.dart';
import 'package:stitch_aiei_lms/domain/models/material_progress.dart';
import 'package:stitch_aiei_lms/domain/models/module_material.dart';
import 'package:stitch_aiei_lms/presentation/screens/course_info/course_content_screen.dart';
import 'widgets/faculty_scaffold.dart';
import 'widgets/faculty_sidebar.dart';
import 'widgets/student_roster_panel.dart';
import 'my_assigned_courses_screen.dart';
import 'course_syllabus_screen.dart';
import 'grade_assignment_screen.dart';
import 'grade_quiz_screen.dart';
import 'widgets/faculty_mobile_top_bar.dart';

// ---------------------------------------------------------------------------
// CourseDashboardScreen – Stitch "Course Management (Python for Enterprise)"
// faithful Flutter conversion.
// ---------------------------------------------------------------------------
class CourseDashboardScreen extends StatefulWidget {
  final String sectionId;
  final String courseId;

  const CourseDashboardScreen({super.key, required this.sectionId, required this.courseId});

  @override
  State<CourseDashboardScreen> createState() => _CourseDashboardScreenState();
}

class _CourseDashboardScreenState extends State<CourseDashboardScreen> {
  final _client = Supabase.instance.client;
  final _facultyRepository = SupabaseFacultyRepositoryImpl(Supabase.instance.client);
  final _rosterRepository = SupabaseAdminStudentsRepositoryImpl(Supabase.instance.client);
  final _materialProgressRepository = SupabaseMaterialProgressRepositoryImpl(Supabase.instance.client);
  final _examRepository = SupabaseExamRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  bool _showAnnouncementForm = false;

  String _courseTitle = 'Course';
  String _courseCode = '';
  int? _capacity;
  int _enrolledCount = 0;
  int _avgProgress = 0;
  int _assignmentsToGrade = 0;
  int _quizzesToGrade = 0;
  int _flaggedCount = 0;
  int _moduleCount = 0;
  int _materialCount = 0;
  int _totalAssignmentBlocks = 0;
  List<_DeadlineItem> _deadlines = const [];
  List<RosterRow> _rosterRows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final assignedCourses = await _facultyRepository.getAssignedCourses(DemoIdentity.lecturerId);
    final students = await _rosterRepository.getCourseRoster(widget.courseId);
    final modules = await _facultyRepository.getCourseModules(widget.sectionId);
    final materials = await _facultyRepository.getCourseMaterials(widget.sectionId);

    // The Deadlines & Schedule card below still reads the old
    // module_materials due-date list, and its submitted-count is only
    // wired up for the two demo materials this preview seeds submissions
    // for — see DemoIdentity. That card is unrelated to the KPI/roster
    // numbers below, which are computed for real from every exam/assignment
    // content block in this class's actual syllabus tree.
    final hasAssignmentMaterial = materials.any((m) => m.id == DemoIdentity.materialAssignment02Id);
    final hasQuizMaterial = materials.any((m) => m.id == DemoIdentity.materialComplianceQuizId);
    final assignmentSubs = hasAssignmentMaterial
        ? await _materialProgressRepository.getSubmissionsForMaterial(DemoIdentity.materialAssignment02Id)
        : const <MaterialProgress>[];
    final quizSubs = hasQuizMaterial
        ? await _materialProgressRepository.getSubmissionsForMaterial(DemoIdentity.materialComplianceQuizId)
        : const <MaterialProgress>[];
    final assignmentSubmittedCount = assignmentSubs.where((p) => p.status == 'completed').length;
    final quizSubmittedCount = quizSubs.where((p) => p.status == 'completed').length;

    // ── Real class-wide assessment coverage (course_modules -> sessions ->
    // content_blocks, filtered to exam/assignment) plus every submission
    // against those blocks — this is what backs the KPI row and the
    // Student Directory's progress/assignment/quiz columns below. ────────
    final moduleRows = await _client.from('course_modules').select('id').eq('section_id', widget.sectionId);
    final moduleIds = [for (final row in moduleRows as List) row['id'] as String];
    final sessionRows = moduleIds.isEmpty
        ? const <dynamic>[]
        : await _client.from('sessions').select('id').inFilter('module_id', moduleIds);
    final sessionIds = [for (final row in sessionRows) row['id'] as String];
    final assessmentRows = sessionIds.isEmpty
        ? const <dynamic>[]
        : await _client
            .from('content_blocks')
            .select('id, block_type')
            .inFilter('session_id', sessionIds)
            .inFilter('block_type', ['exam', 'assignment']);
    final assessmentBlocks = [
      for (final row in assessmentRows) (id: row['id'] as String, type: row['block_type'] as String),
    ];
    final typeByBlock = {for (final b in assessmentBlocks) b.id: b.type};
    final totalAssessments = assessmentBlocks.length;
    final totalAssignmentBlocks = assessmentBlocks.where((b) => b.type == 'assignment').length;
    final examBlockIds = [for (final b in assessmentBlocks) if (b.type == 'exam') b.id];

    final examMaxMarks = <String, double>{};
    for (final id in examBlockIds) {
      examMaxMarks[id] = await _examRepository.getTotalMarks(id);
    }

    final blockIds = [for (final b in assessmentBlocks) b.id];
    final submissionRows = blockIds.isEmpty
        ? const <dynamic>[]
        : await _client.from('content_block_submissions').select().inFilter('content_block_id', blockIds);
    final submissionsByStudent = <String, List<ContentBlockSubmission>>{};
    for (final row in submissionRows) {
      final sub = ContentBlockSubmission.fromMap(row as Map<String, dynamic>);
      submissionsByStudent.putIfAbsent(sub.studentId, () => []).add(sub);
    }
    if (!mounted) return;

    final course = assignedCourses.where((c) => c.courseId == widget.courseId).firstOrNull;
    final flaggedCount = students.where((s) => s.riskStatus == 'critical').length;

    var assignmentsToGrade = 0;
    var quizzesToGrade = 0;
    var progressSum = 0;
    final rosterRows = <RosterRow>[];
    for (final s in students) {
      final subs = submissionsByStudent[s.studentId] ?? const <ContentBlockSubmission>[];
      final graded = subs.where((sub) => sub.status == 'graded').toList();
      final pending = subs.where((sub) => sub.status == 'submitted').toList();
      final gradedAssignments = graded.where((sub) => typeByBlock[sub.contentBlockId] == 'assignment').length;
      final gradedExams = graded.where((sub) => typeByBlock[sub.contentBlockId] == 'exam').toList();

      assignmentsToGrade += pending.where((sub) => typeByBlock[sub.contentBlockId] == 'assignment').length;
      quizzesToGrade += pending.where((sub) => typeByBlock[sub.contentBlockId] == 'exam').length;

      final progress = totalAssessments == 0 ? 0 : ((graded.length / totalAssessments) * 100).round();
      progressSum += progress;

      double? quizAvgPercent;
      if (gradedExams.isNotEmpty) {
        final pcts = <double>[
          for (final sub in gradedExams)
            if ((examMaxMarks[sub.contentBlockId] ?? 0) > 0) (sub.totalScore ?? 0) / examMaxMarks[sub.contentBlockId]! * 100,
        ];
        if (pcts.isNotEmpty) quizAvgPercent = pcts.reduce((a, b) => a + b) / pcts.length;
      }

      rosterRows.add(RosterRow.fromRoster(
        s,
        progress: progress,
        totalAssignments: totalAssignmentBlocks,
        gradedAssignments: gradedAssignments,
        quizAvgPercent: quizAvgPercent,
        hasPendingSubmission: pending.isNotEmpty,
      ));
    }
    final avgProgress = students.isEmpty ? 0 : (progressSum / students.length).round();

    final deadlineMaterials = materials.where((m) => m.dueAt != null).toList()
      ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));

    final deadlines = [
      for (final m in deadlineMaterials)
        _DeadlineItem(
          material: m,
          submittedCount: m.id == DemoIdentity.materialAssignment02Id
              ? assignmentSubmittedCount
              : m.id == DemoIdentity.materialComplianceQuizId
                  ? quizSubmittedCount
                  : null,
        ),
    ];

    setState(() {
      _courseTitle = course?.title ?? 'Course';
      _courseCode = course?.courseCode ?? _courseCode;
      _capacity = course?.capacity;
      _enrolledCount = students.length;
      _avgProgress = avgProgress;
      _assignmentsToGrade = assignmentsToGrade;
      _quizzesToGrade = quizzesToGrade;
      _flaggedCount = flaggedCount;
      _moduleCount = modules.length;
      _materialCount = materials.length;
      _totalAssignmentBlocks = totalAssignmentBlocks;
      _deadlines = deadlines;
      _rosterRows = rosterRows;
      _isLoading = false;
    });
  }

  void _handleNav(FacultyNavDestination dest) {
    switch (dest) {
      case FacultyNavDestination.myCourses:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyAssignedCoursesScreen()));
        break;
      case FacultyNavDestination.gradingAndSubmissions:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GradeAssignmentScreen()));
        break;
    }
  }

  void _openSyllabusEditor() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CourseSyllabusScreen(sectionId: widget.sectionId, courseTitle: _courseTitle)),
    );
  }

  void _rosterRowAction(RosterRow s, String action) {
    if (action == 'submissions' && s.hasSubmission) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GradeAssignmentScreen()));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No ${action == 'submissions' ? 'submission' : action} data for ${s.name} in this preview.')),
    );
  }

  void _previewAsStudent() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CourseContentScreen(sectionId: widget.sectionId, courseTitle: _courseTitle)),
    );
  }

  void _notAvailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Not wired up in this preview.')),
    );
  }

  // ---------------------------------------------------------------------
  // Deadline CTA wiring — only the assignment/quiz materials this demo is
  // hard-wired to have a real grading screen; other due materials fall
  // back to a generic "not available" action.
  // ---------------------------------------------------------------------

  IconData _iconForMaterial(ModuleMaterial m) {
    switch (m.type) {
      case MaterialType.assignment:
        return Icons.terminal;
      case MaterialType.quiz:
        return Icons.rule_outlined;
      case MaterialType.video:
        return Icons.play_circle_outline;
      case MaterialType.lesson:
        return Icons.menu_book_outlined;
    }
  }

  (String, IconData?, bool) _ctaForMaterial(ModuleMaterial m) {
    if (m.id == DemoIdentity.materialAssignment02Id) {
      return ('Grade Submissions', Icons.arrow_forward, true);
    }
    if (m.id == DemoIdentity.materialComplianceQuizId) {
      return ('Review Answers', Icons.checklist, false);
    }
    return ('View Details', null, false);
  }

  VoidCallback _onTapForMaterial(ModuleMaterial m) {
    if (m.id == DemoIdentity.materialAssignment02Id) {
      return () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GradeAssignmentScreen()));
    }
    if (m.id == DemoIdentity.materialComplianceQuizId) {
      return () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GradeQuizScreen()));
    }
    return _notAvailable;
  }

  String _formatDue(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return 'Due ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
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
          _buildTopBar(),
          const SizedBox(height: 20),
          _buildKpiRow(),
          const SizedBox(height: 24),
          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1000;
            final left = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDeadlinesCard(),
                const SizedBox(height: 24),
                _buildQuickSettingsCard(),
              ],
            );
            final right = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickAccessHub(),
                const SizedBox(height: 24),
                _buildAnnouncementsCard(),
              ],
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: left),
                  const SizedBox(width: 24),
                  Expanded(flex: 5, child: right),
                ],
              );
            }
            return Column(children: [left, const SizedBox(height: 24), right]);
          }),
          const SizedBox(height: 24),
          _buildStudentRosterCard(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.start,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back, size: 18, color: FacultyColors.secondary),
                    const SizedBox(width: 4),
                    Text('Back to My Courses', style: FacultyTypography.labelMd(color: FacultyColors.secondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(_courseTitle, style: FacultyTypography.displayLg()),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _tag('ACTIVE COHORT', FacultyColors.tertiaryContainer, Colors.white, dot: true),
                _tag('TERM: FALL 2025', FacultyColors.surfaceContainer, FacultyColors.onSurfaceVariant),
                _tag('COURSE ID: $_courseCode', FacultyColors.surfaceContainerHigh, FacultyColors.onSurface),
              ],
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _previewAsStudent,
              icon: const Icon(Icons.visibility_outlined, size: 18, color: FacultyColors.secondary),
              label: const Text('Preview as Student'),
              style: OutlinedButton.styleFrom(
                foregroundColor: FacultyColors.onSurface,
                backgroundColor: FacultyColors.surfaceContainerLowest,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _notAvailable,
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: const Text('Course Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FacultyColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tag(String text, Color bg, Color fg, {bool dot = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            const Icon(Icons.circle, size: 6, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(text, style: FacultyTypography.labelXs(color: fg).copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildKpiRow() {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 500 ? 2 : 1);
      final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
      final cards = [
        _kpiCard('ENROLLED STUDENTS', '$_enrolledCount', Icons.groups_outlined, FacultyColors.primary, FacultyColors.surfaceContainer,
            footer: 'Live roster count'),
        _kpiCard('ASSIGNMENTS TO GRADE', '$_assignmentsToGrade', Icons.assignment_turned_in_outlined, FacultyColors.onSecondaryFixedVariant, FacultyColors.secondaryContainer,
            footer: '$_assignmentsToGrade pending submissions', footerColor: FacultyColors.onSecondaryFixedVariant, pillFooter: true),
        _kpiCard('QUIZZES TO GRADE', '$_quizzesToGrade', Icons.quiz_outlined, FacultyColors.primary, FacultyColors.surfaceContainerHigh,
            footer: '$_quizzesToGrade open-ended manual checks'),
        _kpiCard('AVG. COHORT PROGRESS', '$_avgProgress%', Icons.donut_large, FacultyColors.primary, FacultyColors.surfaceContainer,
            progress: _avgProgress / 100),
      ];
      return Wrap(spacing: 16, runSpacing: 16, children: cards.map((c) => SizedBox(width: width, child: c)).toList());
    });
  }

  Widget _kpiCard(String label, String value, IconData icon, Color iconColor, Color iconBg,
      {String? footer, Color? footerColor, IconData? footerIcon, bool pillFooter = false, double? progress}) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: FacultyTypography.labelXs().copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(value, style: FacultyTypography.displayLg()),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (progress != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(9999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: FacultyColors.surfaceContainerHigh,
                valueColor: const AlwaysStoppedAnimation<Color>(FacultyColors.primary),
              ),
            )
          else if (pillFooter && footer != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: FacultyColors.secondaryContainer, borderRadius: BorderRadius.circular(6)),
              child: Text(footer, style: FacultyTypography.labelXs(color: footerColor ?? FacultyColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w700)),
            )
          else if (footer != null)
            Row(
              children: [
                if (footerIcon != null) ...[
                  Icon(footerIcon, size: 14, color: footerColor),
                  const SizedBox(width: 3),
                ],
                Expanded(
                  child: Text(footer,
                      style: FacultyTypography.labelXs(color: footerColor ?? FacultyColors.onSurfaceVariant).copyWith(
                        fontWeight: footerIcon != null ? FontWeight.w700 : FontWeight.w400,
                      )),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDeadlinesCard() {
    return Container(
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: FacultyColors.surfaceContainerLow,
            child: Row(
              children: [
                const Icon(Icons.event_note_outlined, color: FacultyColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Upcoming Deadlines & Schedule', style: FacultyTypography.headlineMd())),
                Text('${_deadlines.length} items queued', style: FacultyTypography.labelXs()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _deadlines.isEmpty
                ? Text('No upcoming deadlines for this course.', style: FacultyTypography.bodySm())
                : Column(
                    children: [
                      for (var i = 0; i < _deadlines.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        _deadlineRowFor(_deadlines[i]),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _deadlineRowFor(_DeadlineItem item) {
    final m = item.material;
    final overdue = m.dueAt!.isBefore(DateTime.now());
    final (ctaLabel, ctaIcon, ctaPrimary) = _ctaForMaterial(m);
    return _deadlineRow(
      icon: _iconForMaterial(m),
      title: m.name,
      dueText: _formatDue(m.dueAt!),
      dueColor: overdue ? FacultyColors.error : FacultyColors.onSurfaceVariant,
      meta: item.submittedCount != null ? '${item.submittedCount} submitted / $_enrolledCount total' : null,
      ctaLabel: ctaLabel,
      ctaIcon: ctaIcon,
      ctaPrimary: ctaPrimary,
      onTap: _onTapForMaterial(m),
    );
  }

  Widget _deadlineRow({
    required IconData icon,
    required String title,
    required String dueText,
    required Color dueColor,
    String? meta,
    String? badge,
    required String ctaLabel,
    IconData? ctaIcon,
    required bool ctaPrimary,
    bool muted = false,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: muted ? FacultyColors.surfaceContainerLow : FacultyColors.surfaceBright,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: muted ? FacultyColors.surfaceContainerHigh : FacultyColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: muted ? FacultyColors.secondary : FacultyColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(title, style: FacultyTypography.titleSm(), overflow: TextOverflow.ellipsis)),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(4)),
                            child: Text(badge, style: FacultyTypography.labelXs(color: FacultyColors.secondary)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.event, size: 13, color: dueColor),
                          const SizedBox(width: 3),
                          Text(dueText, style: FacultyTypography.bodySm(color: dueColor).copyWith(fontWeight: FontWeight.w500)),
                        ]),
                        if (meta != null) ...[
                          Text('•', style: FacultyTypography.bodySm()),
                          Text(meta, style: FacultyTypography.bodySm(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w500)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (ctaIcon != null)
            ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(ctaIcon, size: 16),
              label: Text(ctaLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: ctaPrimary ? FacultyColors.primary : FacultyColors.surfaceContainerLowest,
                foregroundColor: ctaPrimary ? Colors.white : FacultyColors.onSurface,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: FacultyTypography.labelXs(),
              ),
            )
          else
            OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: FacultyColors.onSurface,
                backgroundColor: FacultyColors.surfaceContainer,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: FacultyTypography.labelXs(),
              ),
              child: Text(ctaLabel),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickSettingsCard() {
    final capacityText = _capacity != null ? '$_enrolledCount / $_capacity' : '$_enrolledCount';
    final seatsRemaining = _capacity != null ? '${(_capacity! - _enrolledCount).clamp(0, _capacity!)} seats remaining' : 'Live roster count';
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
              const Icon(Icons.info_outline, color: FacultyColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Course Quick Settings & Info', style: FacultyTypography.headlineMd())),
              TextButton(
                onPressed: _notAvailable,
                child: Text('Edit Details', style: FacultyTypography.labelMd(color: FacultyColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: FacultyColors.surfaceBright, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SYLLABUS OVERVIEW', style: FacultyTypography.labelXs().copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'Equips modern engineering students with hands-on techniques to architect robust ETL extraction pipelines, operationalize pandas for large datasets, and execute automated reporting workflows directly inside institutional networks.',
                  style: FacultyTypography.bodyMd(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth >= 560 ? 3 : 1;
            final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
            final items = [
              _infoTile('Passing Criteria', '80%', 'Weighted total grade'),
              _infoTile('Enrollment Capacity', capacityText, seatsRemaining),
              _infoTile('Granted Credential', 'Enterprise Python Specialist', 'Accredited', badge: true),
            ];
            return Wrap(spacing: 16, runSpacing: 16, children: items.map((i) => SizedBox(width: width, child: i)).toList());
          }),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, String footnote, {bool badge = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: FacultyTypography.labelXs()),
          const SizedBox(height: 4),
          Text(value, style: badge ? FacultyTypography.titleSm() : FacultyTypography.headlineMd()),
          const SizedBox(height: 4),
          badge
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.verified, size: 13, color: FacultyColors.tertiary),
                  const SizedBox(width: 3),
                  Text(footnote, style: FacultyTypography.labelXs(color: FacultyColors.tertiary)),
                ])
              : Text(footnote, style: FacultyTypography.labelXs()),
        ],
      ),
    );
  }

  Widget _buildQuickAccessHub() {
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
          Text('RESOURCE OVERVIEW', style: FacultyTypography.labelXs().copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('Quick Access Hub', style: FacultyTypography.headlineMd()),
          const SizedBox(height: 16),
          _hubRow(
            icon: Icons.folder_copy_outlined,
            iconBg: FacultyColors.primary,
            iconColor: Colors.white,
            title: 'Curriculum & Materials',
            subtitle: '$_moduleCount core modules • $_materialCount assets uploaded',
            ctaLabel: 'Edit Syllabus',
            onTap: _openSyllabusEditor,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRosterCard() {
    final total = _rosterRows.length;
    final avgProgress = total == 0 ? 0 : (_rosterRows.fold<int>(0, (sum, s) => sum + s.progress) / total).round();
    final scored = _rosterRows.where((s) => s.quizAvg != '—').toList();
    final avgQuiz = scored.isEmpty
        ? null
        : scored.fold<double>(0, (sum, s) => sum + double.parse(s.quizAvg.replaceAll('%', ''))) / scored.length;
    final assignmentDone = _rosterRows.fold<int>(0, (sum, s) => sum + int.parse(s.assignments.split('/').first));
    final assignmentCompletionPct =
        total == 0 || _totalAssignmentBlocks == 0 ? 0.0 : assignmentDone / (total * _totalAssignmentBlocks);
    final onPace = _rosterRows.where((s) => s.status != 'Needs Review').length;

    return Container(
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: FacultyColors.surfaceContainerLow,
            child: Row(
              children: [
                const Icon(Icons.badge_outlined, color: FacultyColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Student Directory', style: FacultyTypography.headlineMd())),
                Text('$total enrolled', style: FacultyTypography.labelXs()),
                if (_flaggedCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: FacultyColors.errorContainer, borderRadius: BorderRadius.circular(4)),
                    child: Text('$_flaggedCount flagged', style: FacultyTypography.labelXs(color: FacultyColors.error).copyWith(fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ),
          if (_rosterRows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('No students enrolled in this class yet.', style: FacultyTypography.bodySm()),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(builder: (context, constraints) {
                final cols = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 500 ? 2 : 1);
                final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
                final cards = [
                  _kpiCard('COHORT CAPACITY', '$total', Icons.groups_outlined, FacultyColors.primary, FacultyColors.surfaceContainer,
                      footer: '$avgProgress% Avg Progress'),
                  _kpiCard('AVG. QUIZ PERFORMANCE', avgQuiz != null ? '${avgQuiz.toStringAsFixed(1)}%' : '—', Icons.quiz_outlined,
                      FacultyColors.primary, FacultyColors.surfaceContainer,
                      progress: avgQuiz != null ? avgQuiz / 100 : null),
                  _kpiCard('ASSIGNMENT COMPLETION', '${(assignmentCompletionPct * 100).toStringAsFixed(0)}%', Icons.task_alt_outlined,
                      FacultyColors.primary, FacultyColors.surfaceContainer,
                      footer: '$onPace of $total on pace'),
                  _kpiCard('REQUIRES INTERVENTION', '$_flaggedCount Students', Icons.warning_amber_outlined, FacultyColors.error,
                      FacultyColors.errorContainer,
                      footer: 'Flagged for review', footerColor: FacultyColors.error),
                ];
                return Wrap(spacing: 16, runSpacing: 16, children: cards.map((c) => SizedBox(width: width, child: c)).toList());
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
            StudentRosterTable(rows: _rosterRows, onAction: _rosterRowAction),
          ],
        ],
      ),
    );
  }

  Widget _hubRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? trailingBadge,
    required String ctaLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: FacultyTypography.titleSm()),
                Row(
                  children: [
                    Text(subtitle, style: FacultyTypography.bodySm()),
                    if (trailingBadge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: FacultyColors.errorContainer, borderRadius: BorderRadius.circular(4)),
                        child: Text(trailingBadge, style: FacultyTypography.labelXs(color: FacultyColors.error).copyWith(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward, size: 14),
            label: Text(ctaLabel),
            style: OutlinedButton.styleFrom(
              foregroundColor: FacultyColors.onSurface,
              backgroundColor: FacultyColors.surfaceContainerLowest,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: FacultyTypography.labelXs(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsCard() {
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
              const Icon(Icons.campaign_outlined, color: FacultyColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Course Announcements', style: FacultyTypography.headlineMd())),
              TextButton.icon(
                onPressed: () => setState(() => _showAnnouncementForm = !_showAnnouncementForm),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Post New'),
                style: TextButton.styleFrom(foregroundColor: FacultyColors.primary, textStyle: FacultyTypography.labelMd()),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _announcement('Office hours moved to Thursday 3 PM', 'Yesterday',
              'Due to the departmental curriculum council meeting, our usual Wednesday slot is moved. Room 402 or via Zoom bridge.'),
          const SizedBox(height: 8),
          _announcement('Starter repo updated for Assignment 02', 'Nov 08',
              'A patch was pushed to address the dataset schema parser warning in Python 3.11. Please run git pull before continuing.'),
          if (_showAnnouncementForm) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Draft Quick Broadcast', style: FacultyTypography.labelMd()),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: FacultyColors.surfaceContainerLowest,
                      hintText: 'Subject line...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    maxLines: 2,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: FacultyColors.surfaceContainerLowest,
                      hintText: 'Announcement content...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _showAnnouncementForm = false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _showAnnouncementForm = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Announcement published.'), backgroundColor: FacultyColors.primary),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: FacultyColors.primary, foregroundColor: Colors.white, elevation: 0),
                        child: const Text('Publish'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _announcement(String title, String time, String body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: FacultyColors.surfaceBright, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: FacultyTypography.bodyMd(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600))),
              Text(time, style: FacultyTypography.labelXs()),
            ],
          ),
          const SizedBox(height: 4),
          Text(body, style: FacultyTypography.bodySm(), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Mobile (<700px) layout — separate Scaffold, does not reuse
  // FacultyScaffold/FacultyHeader/FacultySidebar (desktop-only shell).
  // ---------------------------------------------------------------------

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: const FacultyMobileTopBar(title: 'Course Detail'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _mobileActionBar(),
              const SizedBox(height: 12),
              _mobileCourseIdentityCard(),
              const SizedBox(height: 16),
              _mobileKpiGrid(),
              const SizedBox(height: 20),
              _mobileGradingQueueSection(),
              const SizedBox(height: 20),
              _mobileQuickAccessSection(),
              const SizedBox(height: 20),
              _mobileStudentRosterSection(),
              const SizedBox(height: 20),
              _mobileAnnouncementsCard(),
              const SizedBox(height: 20),
              _mobileGovernanceCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileActionBar() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, size: 18, color: FacultyColors.secondary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Back to My Courses',
                      style: FacultyTypography.labelMd(color: FacultyColors.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _mobileIconSquareButton(icon: Icons.settings, onTap: _notAvailable),
        const SizedBox(width: 8),
        _mobilePreviewButton(),
      ],
    );
  }

  Widget _mobileIconSquareButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: FacultyColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4)],
        ),
        child: Icon(icon, size: 20, color: FacultyColors.onSurfaceVariant),
      ),
    );
  }

  Widget _mobilePreviewButton() {
    return InkWell(
      onTap: _previewAsStudent,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: FacultyColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility_outlined, size: 18, color: FacultyColors.secondary),
            const SizedBox(width: 4),
            Text('Preview', style: FacultyTypography.labelMd(color: FacultyColors.secondary)),
          ],
        ),
      ),
    );
  }

  Widget _mobileCourseIdentityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _tag('ACTIVE COHORT', FacultyColors.tertiaryContainer, Colors.white, dot: true),
              _tag('TERM: FALL 2025', FacultyColors.surfaceContainerLow, FacultyColors.onSurfaceVariant),
              _tag(_courseCode, FacultyColors.surfaceContainerLow, FacultyColors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _courseTitle,
            style: FacultyTypography.headlineLg(color: FacultyColors.primary),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.school, size: 16, color: FacultyColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Lead Instructor: Dr. Sarah Lin • Faculty of Applied Computing',
                  style: FacultyTypography.bodySm(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileKpiGrid() {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _mobileStatCard(
                  icon: Icons.group,
                  iconBg: FacultyColors.surfaceContainer,
                  iconColor: FacultyColors.secondary,
                  cornerBadge: _mobileBadgePill('Live', FacultyColors.surfaceContainerLow, FacultyColors.tertiary),
                  value: '$_enrolledCount',
                  label: 'Enrolled Students',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _mobileStatCard(
                  icon: Icons.assignment_turned_in,
                  iconBg: FacultyColors.errorContainer.withValues(alpha: 0.4),
                  iconColor: FacultyColors.error,
                  cornerBadge: _mobileBadgePill(
                    _assignmentsToGrade > 0 ? 'Action req.' : 'Clear',
                    FacultyColors.errorContainer,
                    FacultyColors.onErrorContainer,
                    bold: true,
                  ),
                  value: '$_assignmentsToGrade',
                  label: 'Assignments to Grade',
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
                child: _mobileStatCard(
                  icon: Icons.quiz,
                  iconBg: FacultyColors.surfaceContainer,
                  iconColor: FacultyColors.secondary,
                  cornerBadge: _mobileBadgePill('$_quizzesToGrade checks', FacultyColors.surfaceContainer, FacultyColors.secondary),
                  value: '$_quizzesToGrade',
                  label: 'Quizzes to Grade',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _mobileStatCard(
                  icon: Icons.trending_up,
                  iconBg: FacultyColors.surfaceContainer,
                  iconColor: FacultyColors.secondary,
                  cornerBadge: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      value: _avgProgress / 100,
                      strokeWidth: 3,
                      backgroundColor: FacultyColors.surfaceContainerHigh,
                      valueColor: const AlwaysStoppedAnimation<Color>(FacultyColors.secondary),
                    ),
                  ),
                  value: '$_avgProgress%',
                  label: 'Cohort Progress',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mobileBadgePill(String text, Color bg, Color fg, {bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        text,
        style: FacultyTypography.labelXs(color: fg).copyWith(fontWeight: bold ? FontWeight.w700 : FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _mobileStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Widget cornerBadge,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              Flexible(child: cornerBadge),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: FacultyTypography.headlineLg(color: FacultyColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: FacultyTypography.labelXs().copyWith(fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _mobileGradingQueueSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.pending_actions, size: 20, color: FacultyColors.secondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Grading Queue & Deadlines', style: FacultyTypography.headlineMd(color: FacultyColors.primary), overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 6),
            _mobileBadgePill('${_deadlines.length} Active', FacultyColors.surfaceContainerLow, FacultyColors.onSurfaceVariant, bold: true),
          ],
        ),
        const SizedBox(height: 10),
        if (_deadlines.isEmpty)
          Text('No upcoming deadlines for this course.', style: FacultyTypography.bodySm())
        else
          for (var i = 0; i < _deadlines.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _mobileDeadlineCardFor(_deadlines[i]),
          ],
      ],
    );
  }

  Widget _mobileDeadlineCardFor(_DeadlineItem item) {
    final m = item.material;
    final (ctaLabel, ctaIcon, ctaPrimary) = _ctaForMaterial(m);
    if (item.submittedCount != null) {
      final ratio = _enrolledCount == 0 ? 0.0 : item.submittedCount! / _enrolledCount;
      return _mobileQueueCard(
        badgeText: m.type == MaterialType.assignment ? 'High Priority' : 'Evaluation',
        badgeBg: m.type == MaterialType.assignment
            ? FacultyColors.errorContainer.withValues(alpha: 0.4)
            : FacultyColors.surfaceContainer,
        badgeFg: m.type == MaterialType.assignment ? FacultyColors.error : FacultyColors.secondary,
        title: m.name,
        subtitle: '${_formatDue(m.dueAt!)} • ${item.submittedCount} / $_enrolledCount Students Submitted',
        progressLabel: 'Submission Status',
        progressValueText: '${(ratio * 100).toStringAsFixed(0)}% turned in',
        progressValue: ratio,
        buttonLabel: '$ctaLabel${m.type == MaterialType.assignment ? ' ($_assignmentsToGrade)' : ' ($_quizzesToGrade)'}',
        buttonIcon: ctaIcon ?? Icons.arrow_forward,
        buttonBg: ctaPrimary ? FacultyColors.secondary : FacultyColors.surfaceContainer,
        buttonFg: ctaPrimary ? Colors.white : FacultyColors.secondary,
        onTap: _onTapForMaterial(m),
      );
    }
    return _mobileUpcomingCardFor(item);
  }

  Widget _mobileQueueCard({
    required String badgeText,
    required Color badgeBg,
    required Color badgeFg,
    required String title,
    required String subtitle,
    required String progressLabel,
    required String progressValueText,
    required double progressValue,
    required String buttonLabel,
    required IconData buttonIcon,
    required Color buttonBg,
    required Color buttonFg,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(4)),
              child: Text(
                badgeText.toUpperCase(),
                style: FacultyTypography.labelXs(color: badgeFg).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(title, style: FacultyTypography.titleSm(color: FacultyColors.primary), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(subtitle, style: FacultyTypography.bodySm(), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(progressLabel, style: FacultyTypography.labelXs(), overflow: TextOverflow.ellipsis)),
                    Text(
                      progressValueText,
                      style: FacultyTypography.labelXs(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 8,
                    backgroundColor: FacultyColors.surfaceContainerHighest,
                    valueColor: const AlwaysStoppedAnimation<Color>(FacultyColors.secondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(buttonIcon, size: 18),
              label: Text(buttonLabel, overflow: TextOverflow.ellipsis),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonBg,
                foregroundColor: buttonFg,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: FacultyTypography.labelMd(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileUpcomingCardFor(_DeadlineItem item) {
    final m = item.material;
    return Container(
      padding: const EdgeInsets.all(16),
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
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _mobileBadgePill('Upcoming', FacultyColors.surfaceContainerLow, FacultyColors.onSurfaceVariant, bold: true),
                    Text(_formatDue(m.dueAt!), style: FacultyTypography.bodySm()),
                  ],
                ),
                const SizedBox(height: 4),
                Text(m.name, style: FacultyTypography.titleSm(color: FacultyColors.primary), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _notAvailable,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_calendar, size: 16, color: FacultyColors.onSurface),
                  const SizedBox(width: 4),
                  Text('Edit', style: FacultyTypography.labelMd()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileQuickAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.hub, size: 20, color: FacultyColors.secondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Quick Access', style: FacultyTypography.headlineMd(color: FacultyColors.primary), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _mobileHubItem(
          icon: Icons.menu_book,
          iconBg: FacultyColors.surfaceContainer,
          iconColor: FacultyColors.secondary,
          title: 'Curriculum & Materials',
          subtitle: '$_moduleCount core modules • $_materialCount assets uploaded',
          buttonLabel: 'Edit Syllabus',
          onTap: _openSyllabusEditor,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _mobileStudentRosterSection() {
    final total = _rosterRows.length;
    final avgProgress = total == 0 ? 0 : (_rosterRows.fold<int>(0, (sum, s) => sum + s.progress) / total).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.badge, size: 20, color: FacultyColors.secondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Student Directory', style: FacultyTypography.headlineMd(color: FacultyColors.primary), overflow: TextOverflow.ellipsis),
            ),
            if (_flaggedCount > 0) _mobileBadgePill('$_flaggedCount flagged', FacultyColors.errorContainer, FacultyColors.error, bold: true),
          ],
        ),
        const SizedBox(height: 10),
        if (_rosterRows.isEmpty)
          Text('No students enrolled in this class yet.', style: FacultyTypography.bodySm())
        else ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _mobileStatCard(
                    icon: Icons.groups_outlined,
                    iconBg: FacultyColors.surfaceContainer,
                    iconColor: FacultyColors.secondary,
                    cornerBadge: _mobileBadgePill('$avgProgress% avg', FacultyColors.surfaceContainerLow, FacultyColors.tertiary),
                    value: '$total',
                    label: 'Enrolled Students',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _mobileStatCard(
                    icon: Icons.warning_amber_outlined,
                    iconBg: FacultyColors.errorContainer.withValues(alpha: 0.4),
                    iconColor: FacultyColors.error,
                    cornerBadge: _mobileBadgePill(_flaggedCount > 0 ? 'Action req.' : 'Clear', FacultyColors.errorContainer, FacultyColors.onErrorContainer, bold: true),
                    value: '$_flaggedCount',
                    label: 'Requires Intervention',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          StudentRosterMobileList(rows: _rosterRows, onAction: _rosterRowAction),
        ],
      ],
    );
  }

  Widget _mobileHubItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    String? badgeCount,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              if (badgeCount != null)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: FacultyColors.error, shape: BoxShape.circle),
                    child: Text(
                      badgeCount,
                      style: FacultyTypography.labelXs(color: Colors.white).copyWith(fontSize: 9, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: FacultyTypography.titleSm(color: FacultyColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: FacultyTypography.bodySm(), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
              child: Text(
                buttonLabel,
                style: FacultyTypography.labelMd(color: FacultyColors.secondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileAnnouncementsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.campaign, size: 18, color: FacultyColors.secondary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Announcements', style: FacultyTypography.headlineMd(color: FacultyColors.primary), overflow: TextOverflow.ellipsis),
              ),
              InkWell(
                onTap: () => setState(() => _showAnnouncementForm = !_showAnnouncementForm),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(color: FacultyColors.secondary, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 16, color: Colors.white),
                      const SizedBox(width: 3),
                      Text('Post', style: FacultyTypography.labelMd(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _mobileAnnouncementItem(
            'Office hours moved to Thursday 3 PM',
            'Yesterday',
            'Live architectural consultation for data lake pipeline patterns will be conducted via Telemetry Room B.',
          ),
          const SizedBox(height: 8),
          _mobileAnnouncementItem(
            'Starter repo updated for Assignment 02',
            'Nov 08',
            'New pytest mocks for parquet stream validation are pushed to the main enterprise template.',
          ),
          if (_showAnnouncementForm) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Draft Quick Broadcast', style: FacultyTypography.labelMd()),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: FacultyColors.surfaceContainerLowest,
                      hintText: 'Subject line...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    maxLines: 2,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: FacultyColors.surfaceContainerLowest,
                      hintText: 'Announcement content...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _showAnnouncementForm = false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _showAnnouncementForm = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Announcement published.'), backgroundColor: FacultyColors.primary),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: FacultyColors.primary, foregroundColor: Colors.white, elevation: 0),
                        child: const Text('Publish'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _mobileAnnouncementItem(String title, String time, String body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: FacultyTypography.labelMd(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(time, style: FacultyTypography.labelXs()),
            ],
          ),
          const SizedBox(height: 4),
          Text(body, style: FacultyTypography.bodySm(), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _mobileGovernanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              const Icon(Icons.fact_check, size: 20, color: FacultyColors.secondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Course Governance & Syllabus', style: FacultyTypography.headlineMd(color: FacultyColors.primary), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _mobileGovernanceTile('Passing Benchmark', '80% Aggregate', 'Inclusive of capstone audit'),
          const SizedBox(height: 8),
          _mobileGovernanceTile(
            'Cohort Capacity',
            _capacity != null ? '$_enrolledCount / $_capacity Enrolled' : '$_enrolledCount Enrolled',
            _capacity != null ? '${(_capacity! - _enrolledCount).clamp(0, _capacity!)} enterprise seats remaining' : 'Live roster count',
          ),
          const SizedBox(height: 8),
          _mobileGovernanceTile('Target Credential', 'Enterprise Python Specialist', 'AIEI Industry Accreditation'),
        ],
      ),
    );
  }

  Widget _mobileGovernanceTile(String label, String value, String footnote) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: FacultyTypography.labelXs().copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value, style: FacultyTypography.headlineMd(color: FacultyColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(footnote, style: FacultyTypography.bodySm(), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _DeadlineItem {
  final ModuleMaterial material;
  final int? submittedCount;

  const _DeadlineItem({required this.material, this.submittedCount});
}
