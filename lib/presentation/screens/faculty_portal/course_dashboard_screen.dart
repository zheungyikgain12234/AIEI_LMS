import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_students_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_announcements_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_app_settings_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_assignment_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_exam_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_faculty_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/grade_scale.dart';
import 'package:stitch_aiei_lms/domain/models/content_block_submission.dart';
import 'package:stitch_aiei_lms/domain/models/course_announcement.dart';
import 'package:stitch_aiei_lms/domain/repositories/app_settings_repository.dart';
import 'widgets/announcements_panel.dart';
import 'physical_class_attendance_screen.dart';
import 'widgets/faculty_scaffold.dart';
import 'widgets/faculty_sidebar.dart';
import 'widgets/student_roster_panel.dart';
import 'widgets/score_distribution_card.dart';
import 'my_assigned_courses_screen.dart';
import 'course_syllabus_screen.dart';
import 'grade_assignment_screen.dart';
import 'grading_queue_screen.dart';
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
  final _assignmentRepository = SupabaseAssignmentRepositoryImpl(Supabase.instance.client);
  final _announcementsRepository = SupabaseAnnouncementsRepositoryImpl(Supabase.instance.client);
  final _settingsRepository = SupabaseAppSettingsRepositoryImpl(Supabase.instance.client);

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
  int _sessionCount = 0;
  int _totalAssignmentBlocks = 0;
  List<RosterRow> _rosterRows = const [];
  List<AssessmentColumn> _assessmentColumns = const [];
  final _studentSearchController = TextEditingController();
  String _studentSearchQuery = '';

  List<RosterRow> get _filteredRosterRows {
    final query = _studentSearchQuery.trim().toLowerCase();
    if (query.isEmpty) return _rosterRows;
    return _rosterRows
        .where((r) =>
            r.name.toLowerCase().contains(query) ||
            r.email.toLowerCase().contains(query) ||
            r.studentCode.toLowerCase().contains(query))
        .toList();
  }
  double? _maxModeratedScore;
  GradeScale _gradeScale = GradeScale.defaultScale;
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
    _studentSearchController.dispose();
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
            .inFilter('block_type', ['exam', 'assignment', 'physicalExam', 'physicalAssignment']);
    // Physical (paper-based) exams/assignments count as ordinary exam/assignment
    // columns here; they differ only in having no student submissions to wait
    // for (so never "overdue") and a stored max marks instead of a question tree.
    final assessmentBlocks = [
      for (final row in assessmentRows)
        (
          id: row['id'] as String,
          type: (row['block_type'] as String).replaceFirst('physicalExam', 'exam').replaceFirst('physicalAssignment', 'assignment'),
          physical: (row['block_type'] as String).startsWith('physical'),
          maxMarks: ((row['block_content'] as Map<String, dynamic>?)?['maxMarks'] as num?)?.toDouble() ?? 0.0,
          title: (row['block_content'] as Map<String, dynamic>?)?['title'] as String?,
          weightage: ((row['block_content'] as Map<String, dynamic>?)?['weightage'] as num?)?.toDouble() ?? 0.0,
          dueDate: DateTime.tryParse((row['block_content'] as Map<String, dynamic>?)?['dueDate'] as String? ?? ''),
        ),
    ];
    final typeByBlock = {for (final b in assessmentBlocks) b.id: b.type};
    final totalAssessments = assessmentBlocks.length;
    final totalAssignmentBlocks = assessmentBlocks.where((b) => b.type == 'assignment').length;
    final totalExamBlocks = assessmentBlocks.where((b) => b.type == 'exam').length;
    final examBlockIds = [for (final b in assessmentBlocks) if (b.type == 'exam' && !b.physical) b.id];
    final assignmentBlockIds = [for (final b in assessmentBlocks) if (b.type == 'assignment' && !b.physical) b.id];
    final now = DateTime.now();
    final overdueBlockIds = {for (final b in assessmentBlocks) if (!b.physical && b.dueDate != null && b.dueDate!.isBefore(now)) b.id};

    final examMaxMarks = <String, double>{};
    for (final id in examBlockIds) {
      examMaxMarks[id] = await _examRepository.getTotalMarks(id);
    }
    final assignmentMaxMarks = <String, double>{};
    for (final id in assignmentBlockIds) {
      assignmentMaxMarks[id] = await _assignmentRepository.getTotalMarks(id);
    }
    final maxMarksByBlock = {
      ...examMaxMarks,
      ...assignmentMaxMarks,
      for (final b in assessmentBlocks) if (b.physical) b.id: b.maxMarks,
    };

    // One column per quiz (exam block) and per assignment block, in the
    // order they were queried, followed by a running TOTAL column in the
    // Student Directory table.
    var quizNumber = 0;
    var assignmentNumber = 0;
    final assessmentColumns = <AssessmentColumn>[];
    for (final b in assessmentBlocks) {
      final title = b.title?.trim();
      String label;
      if (b.type == 'exam') {
        quizNumber++;
        label = (title != null && title.isNotEmpty) ? title : 'Quiz $quizNumber';
      } else {
        assignmentNumber++;
        label = (title != null && title.isNotEmpty) ? title : 'Assignment $assignmentNumber';
      }
      assessmentColumns.add(AssessmentColumn(blockId: b.id, label: label, weightage: b.weightage));
    }
    final totalWeightagePct = assessmentColumns.fold<double>(0, (sum, c) => sum + c.weightage);

    final blockIds = [for (final b in assessmentBlocks) b.id];
    final physicalBlockIds = {for (final b in assessmentBlocks) if (b.physical) b.id};
    final submissionRows = blockIds.isEmpty
        ? const <dynamic>[]
        : await _client.from('content_block_submissions').select().inFilter('content_block_id', blockIds);
    final submissionsByStudent = <String, List<ContentBlockSubmission>>{};
    for (final row in submissionRows) {
      final sub = ContentBlockSubmission.fromMap(row as Map<String, dynamic>);
      // A physical exam/assignment's non-graded row is just an attendance tick,
      // not a submission awaiting grading.
      if (physicalBlockIds.contains(sub.contentBlockId) && sub.status != 'graded') continue;
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

      // Each column shows the student's share of that block's weightage:
      // (marks scored / max marks) * weightage%.
      final gradedScoreByBlock = {for (final sub in graded) sub.contentBlockId: sub.totalScore ?? 0};
      final assessmentScores = <String, double?>{
        for (final col in assessmentColumns)
          col.blockId: gradedScoreByBlock.containsKey(col.blockId) && (maxMarksByBlock[col.blockId] ?? 0) > 0
              ? gradedScoreByBlock[col.blockId]! / maxMarksByBlock[col.blockId]! * col.weightage
              : (gradedScoreByBlock.containsKey(col.blockId) ? 0.0 : null),
      };
      final assessmentMarks = <String, double?>{
        for (final col in assessmentColumns) col.blockId: gradedScoreByBlock.containsKey(col.blockId) ? gradedScoreByBlock[col.blockId] : null,
      };
      final totalAchievedPct = assessmentScores.values.fold<double>(0, (sum, v) => sum + (v ?? 0));

      rosterRows.add(RosterRow.fromRoster(
        s,
        progress: progress,
        totalAssignments: totalAssignmentBlocks,
        gradedAssignments: gradedAssignments,
        totalQuizzes: totalExamBlocks,
        gradedQuizzes: gradedExams.length,
        quizAvgPercent: quizAvgPercent,
        hasPendingSubmission: pending.isNotEmpty,
        hasOverdueSubmission: hasOverdue,
        assessmentScores: assessmentScores,
        assessmentMarks: assessmentMarks,
        totalAchievedPct: totalAchievedPct,
        totalPossiblePct: totalWeightagePct,
        moderatedScore: s.moderatedScore,
      ));
    }
    final avgProgress = students.isEmpty ? 0 : (progressSum / students.length).round();
    final numericSettings = await _settingsRepository.getNumericSettings();
    final gradeScale = await _settingsRepository.getGradeScale();
    if (!mounted) return;

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
      _sessionCount = sessionIds.length;
      _totalAssignmentBlocks = totalAssignmentBlocks;
      _rosterRows = rosterRows;
      _assessmentColumns = assessmentColumns;
      _maxModeratedScore = numericSettings[AppSettingKeys.maxModeratedScore];
      _gradeScale = gradeScale;
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
      case FacultyNavDestination.physicalClassAttendance:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PhysicalClassAttendanceScreen()));
        break;
      case FacultyNavDestination.gradingAndSubmissions:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GradingQueueScreen()));
        break;
    }
  }

  Future<void> _openSyllabusEditor() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CourseSyllabusScreen(sectionId: widget.sectionId, courseTitle: _courseTitle)),
    );
    if (!mounted) return;
    _load();
  }

  Future<void> _saveModeratedScore(RosterRow s, double value) async {
    final index = _rosterRows.indexWhere((row) => row.studentId == s.studentId);
    if (index == -1) return;
    final previous = _rosterRows[index];
    setState(() => _rosterRows[index] = previous.copyWithModeratedScore(value));
    try {
      await _rosterRepository.updateModeratedScore(s.studentId, widget.courseId, value, sectionId: widget.sectionId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _rosterRows[index] = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save moderated score for ${s.name}.')),
      );
    }
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
        ScoreDistributionCard(
          rawScores: [for (final r in _rosterRows) r.totalAchievedPct],
          moderatedScores: [for (final r in _rosterRows) r.finalTotalPct],
        ),
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
          Text('Manage Course Contents', style: FacultyTypography.headlineMd()),
          const SizedBox(height: 16),
          _hubRow(
            icon: Icons.folder_copy_outlined,
            iconBg: FacultyColors.primary,
            iconColor: Colors.white,
            title: 'Modules & Sessions',
            subtitle: '$_moduleCount modules • $_sessionCount sessions',
            ctaLabel: 'Edit',
            onTap: _openSyllabusEditor,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRosterCard() {
    final total = _rosterRows.length;
    final scored = _rosterRows.where((s) => s.hasQuizScore).toList();
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
                controller: _studentSearchController,
                onChanged: (v) => setState(() => _studentSearchQuery = v),
                style: FacultyTypography.bodySm(color: FacultyColors.onSurface),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: FacultyColors.surfaceContainerLow,
                  hintText: 'Search by student name, email and code...',
                  hintStyle: FacultyTypography.bodySm(color: FacultyColors.outline),
                  prefixIcon: const Icon(Icons.search, size: 18, color: FacultyColors.outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_filteredRosterRows.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Text('No students match your search.', style: FacultyTypography.bodySm()),
              )
            else
              StudentRosterTable(
                rows: _filteredRosterRows,
                onAction: _rosterRowAction,
                assessmentColumns: _assessmentColumns,
                onModeratedScoreSave: _saveModeratedScore,
                maxModeratedScore: _maxModeratedScore,
                gradeScale: _gradeScale,
              ),
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
  // Mobile (<700px) layout — the same content as desktop (class header, KPI
  // cards, course contents, announcements and the Student Directory table).
  // Every desktop section is already responsive (KPIs and announcement cards
  // stack, the directory scrolls horizontally with the student column pinned),
  // so they are reused as-is under the compact mobile top bar.
  // ---------------------------------------------------------------------

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: FacultyMobileTopBar(title: _courseTitle),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(),
              const SizedBox(height: 20),
              _buildKpiRow(),
              const SizedBox(height: 24),
              _buildQuickAccessHub(),
              const SizedBox(height: 24),
              _buildAnnouncementsCard(),
              const SizedBox(height: 24),
              _buildStudentRosterCard(),
            ],
          ),
        ),
      ),
    );
  }
}
