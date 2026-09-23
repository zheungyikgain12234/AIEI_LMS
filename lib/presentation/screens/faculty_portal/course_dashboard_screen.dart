import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_students_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_announcements_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_exam_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_faculty_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/content_block_submission.dart';
import 'package:stitch_aiei_lms/domain/models/course_announcement.dart';
import 'widgets/announcements_panel.dart';
import 'widgets/faculty_scaffold.dart';
import 'widgets/faculty_sidebar.dart';
import 'widgets/student_roster_panel.dart';
import 'my_assigned_courses_screen.dart';
import 'course_syllabus_screen.dart';
import 'grade_assignment_screen.dart';
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
  final _examRepository = SupabaseExamRepositoryImpl(Supabase.instance.client);
  final _announcementsRepository = SupabaseAnnouncementsRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  bool _showAnnouncementForm = false;
  bool _postingAnnouncement = false;
  final _announcementTitleController = TextEditingController();
  final _announcementBodyController = TextEditingController();

  String _courseTitle = 'Course';
  String _courseCode = '';
  String _classCode = '';
  int _classCapacity = 0;
  int _enrolledCount = 0;
  int _avgProgress = 0;
  int _assignmentsToGrade = 0;
  int _quizzesToGrade = 0;
  int _assignmentNonSubmissions = 0;
  int _quizNonSubmissions = 0;
  int _flaggedCount = 0;
  int _moduleCount = 0;
  int _materialCount = 0;
  int _totalAssignmentBlocks = 0;
  List<RosterRow> _rosterRows = const [];
  List<CourseAnnouncement> _announcements = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _announcementTitleController.dispose();
    _announcementBodyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final assignedCourses = await _facultyRepository.getAssignedCourses(DemoIdentity.lecturerId);
    // Section-scoped, not course-scoped: a student enrolled in this course
    // through a different section/cohort (or with no section assigned at
    // all) must not count toward THIS class's progress/grading stats — this
    // is also what MyAssignedCoursesScreen's table now uses, so the two
    // pages agree on the same number for the same class.
    final students = await _rosterRepository.getSectionRoster(widget.sectionId);
    final modules = await _facultyRepository.getCourseModules(widget.sectionId);
    final materials = await _facultyRepository.getCourseMaterials(widget.sectionId);
    final announcements = await _announcementsRepository.getAnnouncementsForSection(widget.sectionId);

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
            .select('id, block_type, block_content')
            .inFilter('session_id', sessionIds)
            .inFilter('block_type', ['exam', 'assignment']);
    final assessmentBlocks = [
      for (final row in assessmentRows)
        (
          id: row['id'] as String,
          type: row['block_type'] as String,
          dueDate: DateTime.tryParse((row['block_content'] as Map<String, dynamic>?)?['dueDate'] as String? ?? ''),
        ),
    ];
    final typeByBlock = {for (final b in assessmentBlocks) b.id: b.type};
    final totalAssessments = assessmentBlocks.length;
    final totalAssignmentBlocks = assessmentBlocks.where((b) => b.type == 'assignment').length;
    final totalExamBlocks = assessmentBlocks.where((b) => b.type == 'exam').length;
    final examBlockIds = [for (final b in assessmentBlocks) if (b.type == 'exam') b.id];
    final now = DateTime.now();
    final overdueBlockIds = {for (final b in assessmentBlocks) if (b.dueDate != null && b.dueDate!.isBefore(now)) b.id};

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

    final course = assignedCourses.where((c) => c.sectionId == widget.sectionId).firstOrNull;

    var assignmentsToGrade = 0;
    var quizzesToGrade = 0;
    var assignmentNonSubmissions = 0;
    var quizNonSubmissions = 0;
    var flaggedCount = 0;
    var progressSum = 0;
    final rosterRows = <RosterRow>[];
    for (final s in students) {
      final subs = submissionsByStudent[s.studentId] ?? const <ContentBlockSubmission>[];
      final submittedBlockIds = {for (final sub in subs) sub.contentBlockId};
      final graded = subs.where((sub) => sub.status == 'graded').toList();
      final pending = subs.where((sub) => sub.status == 'submitted').toList();
      final gradedAssignments = graded.where((sub) => typeByBlock[sub.contentBlockId] == 'assignment').length;
      final gradedExams = graded.where((sub) => typeByBlock[sub.contentBlockId] == 'exam').toList();
      final presentAssignments = subs.where((sub) => typeByBlock[sub.contentBlockId] == 'assignment').length;
      final presentExams = subs.where((sub) => typeByBlock[sub.contentBlockId] == 'exam').length;

      assignmentsToGrade += pending.where((sub) => typeByBlock[sub.contentBlockId] == 'assignment').length;
      quizzesToGrade += pending.where((sub) => typeByBlock[sub.contentBlockId] == 'exam').length;
      assignmentNonSubmissions += totalAssignmentBlocks - presentAssignments;
      quizNonSubmissions += totalExamBlocks - presentExams;

      // Behind schedule = at least one exam/assignment whose due date has
      // passed with no submission recorded for this student at all.
      final hasOverdue = overdueBlockIds.any((id) => !submittedBlockIds.contains(id));
      if (hasOverdue) flaggedCount++;

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
        hasOverdueSubmission: hasOverdue,
      ));
    }
    final avgProgress = students.isEmpty ? 0 : (progressSum / students.length).round();

    setState(() {
      _courseTitle = course?.title ?? 'Course';
      _courseCode = course?.courseCode ?? _courseCode;
      _classCode = course?.sectionCode ?? _classCode;
      _classCapacity = course?.capacity ?? _classCapacity;
      _enrolledCount = students.length;
      _avgProgress = avgProgress;
      _assignmentsToGrade = assignmentsToGrade;
      _quizzesToGrade = quizzesToGrade;
      _assignmentNonSubmissions = assignmentNonSubmissions;
      _quizNonSubmissions = quizNonSubmissions;
      _flaggedCount = flaggedCount;
      _moduleCount = modules.length;
      _materialCount = materials.length;
      _totalAssignmentBlocks = totalAssignmentBlocks;
      _rosterRows = rosterRows;
      _announcements = announcements;
      _isLoading = false;
    });
  }

  Future<void> _postAnnouncement() async {
    final title = _announcementTitleController.text.trim();
    final body = _announcementBodyController.text.trim();
    if (title.isEmpty) return;
    setState(() => _postingAnnouncement = true);
    await _announcementsRepository.postAnnouncement(
      sectionId: widget.sectionId,
      lecturerId: DemoIdentity.lecturerId,
      title: title,
      body: body,
    );
    final announcements = await _announcementsRepository.getAnnouncementsForSection(widget.sectionId);
    if (!mounted) return;
    _announcementTitleController.clear();
    _announcementBodyController.clear();
    setState(() {
      _announcements = announcements;
      _showAnnouncementForm = false;
      _postingAnnouncement = false;
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
            final left = _buildQuickAccessHub();
            final right = _buildAnnouncementsCard();
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: left),
                  const SizedBox(width: 24),
                  Expanded(flex: 7, child: right),
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
                _tag('COURSE ID: $_courseCode', FacultyColors.surfaceContainerHigh, FacultyColors.onSurface),
                _tag('CLASS: $_classCode', FacultyColors.surfaceContainer, FacultyColors.onSurfaceVariant),
              ],
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
      final cols = constraints.maxWidth >= 1100 ? 5 : (constraints.maxWidth >= 900 ? 3 : (constraints.maxWidth >= 500 ? 2 : 1));
      final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
      final cards = [
        _kpiCard('ENROLLED STUDENTS', '$_enrolledCount', Icons.groups_outlined, FacultyColors.primary, FacultyColors.surfaceContainer,
            footer: 'Live roster count'),
        _kpiCard('ASSIGNMENTS TO GRADE', '$_assignmentsToGrade', Icons.assignment_turned_in_outlined, FacultyColors.onSecondaryFixedVariant, FacultyColors.secondaryContainer,
            footer: '$_assignmentNonSubmissions non-submissions', footerColor: FacultyColors.onSecondaryFixedVariant, pillFooter: true),
        _kpiCard('QUIZZES TO GRADE', '$_quizzesToGrade', Icons.quiz_outlined, FacultyColors.primary, FacultyColors.surfaceContainerHigh,
            footer: '$_quizNonSubmissions non-submissions'),
        _kpiCard('AVERAGE STUDENT PROGRESS', '$_avgProgress%', Icons.donut_large, FacultyColors.primary, FacultyColors.surfaceContainer,
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
    final scored = _rosterRows.where((s) => s.quizAvg != '—').toList();
    final avgQuiz = scored.isEmpty
        ? null
        : scored.fold<double>(0, (sum, s) => sum + double.parse(s.quizAvg.replaceAll('%', ''))) / scored.length;
    final assignmentDone = _rosterRows.fold<int>(0, (sum, s) => sum + int.parse(s.assignments.split('/').first));
    final assignmentCompletionPct =
        total == 0 || _totalAssignmentBlocks == 0 ? 0.0 : assignmentDone / (total * _totalAssignmentBlocks);
    // "On pace" = not flagged for an overdue, unsubmitted assessment (the
    // same signal RosterRow.fromRoster uses for progressTag == 'On Pace').
    // The previous `s.status != 'Needs Review'` check compared against a
    // value RosterRow.status never actually produces (it's only ever
    // 'Behind Schedule' or 'On Track'), so it was always true — i.e. this
    // always rendered as "$total of $total on pace" regardless of real data.
    final onPace = _rosterRows.where((s) => !s.flagged).length;

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
                  _kpiCard('CLASS CAPACITY', '$_classCapacity', Icons.groups_outlined, FacultyColors.primary, FacultyColors.surfaceContainer,
                      footer: '$total / $_classCapacity Enrolled'),
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
          if (_announcements.isEmpty && !_showAnnouncementForm)
            const AnnouncementsEmptyState()
          else
            for (var i = 0; i < _announcements.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              AnnouncementCard(announcement: _announcements[i]),
            ],
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
                    controller: _announcementTitleController,
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
                    controller: _announcementBodyController,
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
                        onPressed: _postingAnnouncement ? null : () => setState(() => _showAnnouncementForm = false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: _postingAnnouncement ? null : _postAnnouncement,
                        style: ElevatedButton.styleFrom(backgroundColor: FacultyColors.primary, foregroundColor: Colors.white, elevation: 0),
                        child: Text(_postingAnnouncement ? 'Publishing...' : 'Publish'),
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
              _mobileQuickAccessSection(),
              const SizedBox(height: 20),
              _mobileAnnouncementsCard(),
              const SizedBox(height: 20),
              _mobileStudentRosterSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileActionBar() {
    return InkWell(
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
              _tag('COURSE ID: $_courseCode', FacultyColors.surfaceContainerLow, FacultyColors.onSurfaceVariant),
              _tag('CLASS: $_classCode', FacultyColors.surfaceContainerLow, FacultyColors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _courseTitle,
            style: FacultyTypography.headlineLg(color: FacultyColors.primary),
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
                  label: 'Average Student Progress',
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
          if (_announcements.isEmpty && !_showAnnouncementForm)
            const AnnouncementsEmptyState()
          else
            for (var i = 0; i < _announcements.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              AnnouncementCard(announcement: _announcements[i]),
            ],
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
                    controller: _announcementTitleController,
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
                    controller: _announcementBodyController,
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
                        onPressed: _postingAnnouncement ? null : () => setState(() => _showAnnouncementForm = false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: _postingAnnouncement ? null : _postAnnouncement,
                        style: ElevatedButton.styleFrom(backgroundColor: FacultyColors.primary, foregroundColor: Colors.white, elevation: 0),
                        child: Text(_postingAnnouncement ? 'Publishing...' : 'Publish'),
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
}
