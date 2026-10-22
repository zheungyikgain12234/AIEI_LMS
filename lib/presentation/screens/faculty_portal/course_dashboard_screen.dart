import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/utils/refresh_on_return.dart';
import 'package:stitch_aiei_lms/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/utils/date_format.dart';
import 'package:stitch_aiei_lms/core/utils/input_formatters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_students_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_announcements_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_app_settings_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_attendance_settings_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_badge_approvals_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_grade_distribution_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/grade_distribution.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_assignment_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_exam_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_faculty_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/attendance_settings.dart';
import 'package:stitch_aiei_lms/domain/models/course_section.dart';
import 'package:stitch_aiei_lms/domain/repositories/submission_grading_repository.dart' show AttendanceStatus;
import 'package:stitch_aiei_lms/domain/models/grade_scale.dart';
import 'package:stitch_aiei_lms/domain/models/roster_student.dart';
import 'package:stitch_aiei_lms/domain/models/content_block_submission.dart';
import 'package:stitch_aiei_lms/domain/models/course_announcement.dart';
import 'package:stitch_aiei_lms/domain/repositories/app_settings_repository.dart';
import 'widgets/announcements_panel.dart';
import 'widgets/faculty_dialog.dart';
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

class _CourseDashboardScreenState extends State<CourseDashboardScreen> with RefreshOnReturn<CourseDashboardScreen> {
  @override
  void onReturnedTo() => _load();

  final _client = Supabase.instance.client;
  final _facultyRepository = SupabaseFacultyRepositoryImpl(Supabase.instance.client);
  final _rosterRepository = SupabaseAdminStudentsRepositoryImpl(Supabase.instance.client);
  final _examRepository = SupabaseExamRepositoryImpl(Supabase.instance.client);
  final _assignmentRepository = SupabaseAssignmentRepositoryImpl(Supabase.instance.client);
  final _announcementsRepository = SupabaseAnnouncementsRepositoryImpl(Supabase.instance.client);
  final _settingsRepository = SupabaseAppSettingsRepositoryImpl(Supabase.instance.client);
  final _attendanceRepository = SupabaseAttendanceSettingsRepositoryImpl(Supabase.instance.client);
  final _distributionRepository = SupabaseGradeDistributionRepositoryImpl(Supabase.instance.client);
  final _directoryKey = GlobalKey();

  // Each part of the page loads on its own and appears as soon as it is
  // ready, so there is no full-screen spinner. These flip to true once and
  // stay true: later refreshes (e.g. coming back from another screen) update
  // the content in place instead of flashing placeholders again.
  bool _headerReady = false;
  bool _rosterReady = false;
  bool _hubReady = false;
  bool _announcementsReady = false;
  bool _gradebookReady = false;
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
  String _syllabusStatus = SyllabusStatus.draft;
  int _totalAssignmentBlocks = 0;
  List<RosterRow> _rosterRows = const [];
  List<AssessmentColumn> _assessmentColumns = const [];
  /// Sum of every exam/assignment weightage (attendance excluded) — what the
  /// Attendance Settings weightage has to fit in alongside.
  double _assessmentWeightage = 0;
  AttendanceSettings _attendanceSettings = AttendanceSettings.defaults;
  static const _attendanceColumnId = '__attendance__';
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
  /// How this class's final grades compare with the admin's grade distribution
  /// limits, and the lecturer's latest request to have them approved.
  GradeDistributionRules _gradeRules = GradeDistributionRules.defaults;

  /// Worked out from the Student Directory as it is right now (each student's
  /// FINAL SCORE = raw score + moderation, capped at 100, turned into a letter
  /// by the grade scale), so moderating a score updates the alert at once.
  GradeDistributionCheck? get _distribution => !_gradebookReady
      ? null
      : _gradeRules.evaluate([for (final r in _rosterRows) _gradeScale.letterFor(r.finalTotalPct)]);
  GradeDistributionRequest? _distributionRequest;
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

  /// Starts every part of the page at once. Each part sets its own state and
  /// its own "ready" flag when done, so the page fills in piece by piece.
  Future<void> _load() async {
    // Shared by several parts, so fetched once.
    final rosterFuture = _rosterRepository.getSectionRoster(widget.sectionId);
    final structureFuture = _loadStructure();
    await Future.wait([
      _loadPart(_loadHeader, () => _headerReady = true),
      _loadPart(() => _loadRoster(rosterFuture), () => _rosterReady = true),
      _loadPart(() => _loadHub(structureFuture), () => _hubReady = true),
      _loadPart(_loadAnnouncements, () => _announcementsReady = true),
      _loadPart(() => _loadGradebook(rosterFuture, structureFuture), () => _gradebookReady = true),
    ]);
  }

  /// Runs one part; marks it ready even if it failed, so a placeholder never
  /// spins forever (the failure is logged).
  Future<void> _loadPart(Future<void> Function() part, void Function() markReady) async {
    try {
      await part();
    } catch (e) {
      debugPrint('Course dashboard: a section failed to load: $e');
    }
    if (mounted) setState(markReady);
  }

  /// The class's module and session ids and syllabus status — needed by both
  /// the Manage Course Contents card and the gradebook.
  Future<({List<String> moduleIds, List<String> sessionIds, String syllabusStatus})> _loadStructure() async {
    // Supabase queries only start when awaited, so wrap each to run them together.
    final results = await Future.wait<dynamic>([
      Future(() async => await _client.from('course_modules').select('id').eq('section_id', widget.sectionId)),
      Future(() async => await _client.from('course_sections').select('syllabus_status').eq('id', widget.sectionId).maybeSingle()),
    ]);
    final moduleIds = [for (final row in results[0] as List) row['id'] as String];
    final statusRow = results[1] as Map<String, dynamic>?;
    final sessionRows = moduleIds.isEmpty
        ? const <dynamic>[]
        : await _client.from('sessions').select('id').inFilter('module_id', moduleIds);
    return (
      moduleIds: moduleIds,
      sessionIds: [for (final row in sessionRows) row['id'] as String],
      syllabusStatus: statusRow?['syllabus_status'] as String? ?? SyllabusStatus.draft,
    );
  }

  /// Course title, codes and capacity (top of the page).
  Future<void> _loadHeader() async {
    final assignedCourses = await _facultyRepository.getAssignedCourses(DemoIdentity.lecturerId);
    final course = assignedCourses.where((c) => c.sectionId == widget.sectionId).firstOrNull;
    if (!mounted) return;
    setState(() {
      _courseTitle = course?.title ?? 'Course';
      _courseCode = course?.courseCode ?? _courseCode;
      _classCode = course?.sectionCode ?? _classCode;
      _classCapacity = course?.capacity ?? _classCapacity;
    });
  }

  /// How many students are enrolled — available long before the gradebook.
  Future<void> _loadRoster(Future<List<RosterStudent>> rosterFuture) async {
    final students = await rosterFuture;
    if (!mounted) return;
    setState(() => _enrolledCount = students.length);
  }

  /// The Manage Course Contents card: module / session counts and status.
  Future<void> _loadHub(Future<({List<String> moduleIds, List<String> sessionIds, String syllabusStatus})> structureFuture) async {
    final structure = await structureFuture;
    final modules = await _facultyRepository.getCourseModules(widget.sectionId);
    if (!mounted) return;
    setState(() {
      _moduleCount = modules.length;
      _sessionCount = structure.sessionIds.length;
      _syllabusStatus = structure.syllabusStatus;
    });
  }

  Future<void> _loadAnnouncements() async {
    final announcements = await _announcementsRepository.getAnnouncementsForSection(widget.sectionId);
    if (!mounted) return;
    setState(() => _announcements = announcements);
  }

  /// Everything that needs the students' grades and submissions: the stat
  /// cards and the Student Directory. The slowest part, so it runs alongside
  /// the others and its own queries run in parallel where they can.
  Future<void> _loadGradebook(
    Future<List<RosterStudent>> rosterFuture,
    Future<({List<String> moduleIds, List<String> sessionIds, String syllabusStatus})> structureFuture,
  ) async {
    // Section-scoped, not course-scoped: a student enrolled in this course
    // through a different section/semester (or with no section assigned at
    // all) must not count toward THIS class's progress/grading stats — this
    // is also what MyAssignedCoursesScreen's table now uses, so the two
    // pages agree on the same number for the same class.
    final numericSettingsFuture = _settingsRepository.getNumericSettings();
    final gradeScaleFuture = _settingsRepository.getGradeScale();
    final attendanceSettingsFuture = _attendanceRepository.getSettings(widget.sectionId);
    final rulesFuture = _distributionRepository.getRules();
    // A missing requests table (not set up yet) just means "no request".
    final requestFuture = _distributionRepository.getLatestRequest(widget.sectionId).then<GradeDistributionRequest?>((r) => r, onError: (_) => null);
    final students = await rosterFuture;
    final sessionIds = (await structureFuture).sessionIds;

    // Attendance rows (physical classes/exams and who was marked) are
    // independent of the assessments, so fetch them at the same time.
    final attendanceFuture = () async {
      final blockRows = sessionIds.isEmpty
          ? const <dynamic>[]
          : await _client.from('content_blocks').select('id').inFilter('session_id', sessionIds).inFilter('block_type', ['physicalClass', 'physicalExam']);
      final ids = [for (final row in blockRows) row['id'] as String];
      final rows = ids.isEmpty
          ? const <dynamic>[]
          : await _client.from('content_block_submissions').select('content_block_id, student_id, submission').inFilter('content_block_id', ids);
      return (ids: ids, rows: rows);
    }();

    // ── Real class-wide assessment coverage (course_modules -> sessions ->
    // content_blocks, filtered to exam/assignment) plus every submission
    // against those blocks — this is what backs the KPI row and the
    // Student Directory's progress/assignment/quiz columns below. ────────
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
    final assignmentMaxMarks = <String, double>{};
    await Future.wait([
      for (final id in examBlockIds) _examRepository.getTotalMarks(id).then((v) => examMaxMarks[id] = v),
      for (final id in assignmentBlockIds) _assignmentRepository.getTotalMarks(id).then((v) => assignmentMaxMarks[id] = v),
    ]);
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

    // ── Attendance: each student's raw score across the class's physical
    // sessions, scored with this class's Attendance Settings. Their share =
    // (sum of their scores) * weightage / (Present score * number of physical
    // classes). ──────────────────────────────────────────────────────────
    final attendanceSettings = await attendanceSettingsFuture;
    final attendanceData = await attendanceFuture;
    final classBlockIds = attendanceData.ids;
    final attendanceRows = attendanceData.rows;
    final attendanceMarksByStudent = <String, double>{};
    for (final row in attendanceRows) {
      final submission = Map<String, dynamic>.from(row['submission'] as Map? ?? {});
      final marked = submission['attendance'];
      final status = marked is String ? marked : (submission['attended'] == true ? AttendanceStatus.present : null);
      if (status == null) continue;
      final studentId = (row['student_id'] as num).toString();
      attendanceMarksByStudent[studentId] = (attendanceMarksByStudent[studentId] ?? 0) + attendanceSettings.marksFor(status);
    }
    // Full attendance = Present in every physical session (classes and exams) of the syllabus.
    final attendanceMaxMarks = classBlockIds.length * attendanceSettings.presentMarks;
    // Always shown, even at 0% weightage, so the lecturer can see attendance.
    assessmentColumns.add(AssessmentColumn(blockId: _attendanceColumnId, label: 'Attendance', weightage: attendanceSettings.weightage));
    final totalWeightagePctWithAttendance = totalWeightagePct + attendanceSettings.weightage;
    if (!mounted) return;

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
      final attendanceMarks = attendanceMarksByStudent[s.studentId] ?? 0;
      final assessmentScores = <String, double?>{
        for (final col in assessmentColumns)
          col.blockId: col.blockId == _attendanceColumnId
              ? (attendanceMaxMarks > 0 ? (attendanceMarks / attendanceMaxMarks * col.weightage).clamp(0.0, col.weightage) : 0.0)
              : gradedScoreByBlock.containsKey(col.blockId) && (maxMarksByBlock[col.blockId] ?? 0) > 0
                  ? gradedScoreByBlock[col.blockId]! / maxMarksByBlock[col.blockId]! * col.weightage
                  : (gradedScoreByBlock.containsKey(col.blockId) ? 0.0 : null),
      };
      final assessmentMarks = <String, double?>{
        for (final col in assessmentColumns)
          col.blockId: col.blockId == _attendanceColumnId
              ? attendanceMarks
              : (gradedScoreByBlock.containsKey(col.blockId) ? gradedScoreByBlock[col.blockId] : null),
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
        totalPossiblePct: totalWeightagePctWithAttendance,
        moderatedScore: s.moderatedScore,
      ));
    }
    final avgProgress = students.isEmpty ? 0 : (progressSum / students.length).round();
    final numericSettings = await numericSettingsFuture;
    final gradeScale = await gradeScaleFuture;
    final gradeRules = await rulesFuture;
    var distributionRequest = await requestFuture;
    // Marks changed since the request was sent (e.g. new grading): the admin
    // would be judging old numbers, so it is withdrawn and must be sent again.
    if (distributionRequest != null && distributionRequest.isPending) {
      final counts = gradeRules.evaluate([for (final r in rosterRows) gradeScale.letterFor(r.finalTotalPct)]).counts;
      if (!_sameCounts(counts, distributionRequest.counts)) {
        try {
          await _distributionRepository.withdrawPending(widget.sectionId);
          distributionRequest = await _distributionRepository.getLatestRequest(widget.sectionId);
        } catch (_) {}
      }
    }
    if (!mounted) return;

    setState(() {
      _gradeRules = gradeRules;
      _distributionRequest = distributionRequest;
      _enrolledCount = students.length;
      _avgProgress = avgProgress;
      _assignmentsToGrade = assignmentsToGrade;
      _quizzesToGrade = quizzesToGrade;
      _assignmentNonSubmissions = assignmentNonSubmissions;
      _quizNonSubmissions = quizNonSubmissions;
      _flaggedCount = flaggedCount;
      _totalAssignmentBlocks = totalAssignmentBlocks;
      _rosterRows = rosterRows;
      _assessmentColumns = assessmentColumns;
      _assessmentWeightage = totalWeightagePct;
      _attendanceSettings = attendanceSettings;
      _maxModeratedScore = numericSettings[AppSettingKeys.maxModeratedScore];
      _gradeScale = gradeScale;
    });
    _passingMark = numericSettings[AppSettingKeys.coursePassingMark] ?? AppSettingKeys.defaultCoursePassingMark;
    _syncBadgeEligibility();
  }

  double _passingMark = AppSettingKeys.defaultCoursePassingMark;
  final _badgeApprovalsRepository = SupabaseBadgeApprovalsRepositoryImpl(Supabase.instance.client);

  /// Students whose final score is above the passing mark are put forward to
  /// the admin for the course's badge; the admin approves it in Badge
  /// Approvals. Nothing is granted here.
  Future<void> _syncBadgeEligibility() async {
    try {
      await _badgeApprovalsRepository.syncEligibility(
        courseId: widget.courseId,
        finalScores: {for (final r in _rosterRows) r.studentId: r.finalTotalPct},
        passingMark: _passingMark,
      );
    } catch (e) {
      debugPrint('Badge eligibility sync failed: $e');
    }
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
    showSuccessSnackBar(context, 'Announcement posted.');
  }

  Future<void> _reloadAnnouncements() async {
    final announcements = await _announcementsRepository.getAnnouncementsForSection(widget.sectionId);
    if (!mounted) return;
    setState(() => _announcements = announcements);
  }

  Future<void> _editAnnouncement(CourseAnnouncement a) async {
    final titleController = TextEditingController(text: a.title);
    final bodyController = TextEditingController(text: a.body);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => FacultyDialog(
        title: 'Edit Announcement',
        subtitle: 'Update this announcement for every student in the class.',
        confirmLabel: 'Save Changes',
        onConfirm: () => Navigator.pop(ctx, true),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FacultyFormField(controller: titleController, label: 'Subject', hint: 'Announcement subject'),
            const SizedBox(height: 14),
            FacultyFormField(controller: bodyController, label: 'Content', required: false, maxLines: 4, hint: 'What do you want to tell the class...'),
          ],
        ),
      ),
    );
    final title = titleController.text.trim();
    final body = bodyController.text.trim();
    titleController.dispose();
    bodyController.dispose();
    if (saved != true || title.isEmpty) return;
    await _announcementsRepository.updateAnnouncement(id: a.id, title: title, body: body);
    await _reloadAnnouncements();
    if (mounted) showSuccessSnackBar(context, 'Announcement updated.');
  }

  Future<void> _deleteAnnouncement(CourseAnnouncement a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => FacultyDialog(
        title: 'Delete announcement?',
        confirmLabel: 'Delete',
        destructive: true,
        onConfirm: () => Navigator.pop(ctx, true),
        child: Text('"${a.title}" will be removed for all students in this class.', style: FacultyTypography.bodyMd()),
      ),
    );
    if (confirmed != true) return;
    await _announcementsRepository.deleteAnnouncement(a.id);
    await _reloadAnnouncements();
    if (mounted) showSuccessSnackBar(context, 'Announcement deleted.');
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

  static bool _sameCounts(Map<String, int> a, Map<String, int> b) =>
      GradeBandLimit.values.every((band) => (a[band.name] ?? 0) == (b[band.name] ?? 0));

  /// Changing marks while the admin is still reviewing cancels that request;
  /// the lecturer has to send the new distribution again.
  Future<void> _withdrawPendingRequest() async {
    final request = _distributionRequest;
    if (request == null || !request.isPending) return;
    try {
      await _distributionRepository.withdrawPending(widget.sectionId);
      final latest = await _distributionRepository.getLatestRequest(widget.sectionId);
      if (!mounted) return;
      setState(() => _distributionRequest = latest);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marks changed, so your pending approval request was removed. Send it again once you are done.')),
      );
    } catch (_) {}
  }

  Future<void> _saveModeratedScore(RosterRow s, double value) async {
    final index = _rosterRows.indexWhere((row) => row.studentId == s.studentId);
    if (index == -1) return;
    final previous = _rosterRows[index];
    setState(() => _rosterRows[index] = previous.copyWithModeratedScore(value));
    try {
      await _rosterRepository.updateModeratedScore(s.studentId, widget.courseId, value, sectionId: widget.sectionId);
      if (mounted) showSuccessSnackBar(context, 'Moderated score saved for ${s.name}.');
      await _withdrawPendingRequest();
      await _syncBadgeEligibility();
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
    if (MediaQuery.of(context).size.width <= 900) {
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
          _buildDistributionAlert(),
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
    // Full width so spaceBetween pushes the settings button to the right edge.
    return SizedBox(width: double.infinity, child: Wrap(
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
            _headerReady ? Text(_courseTitle, style: FacultyTypography.displayLg()) : const _Skeleton(width: 280, height: 36),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (_headerReady) ...[
                  _tag('COURSE ID: $_courseCode', FacultyColors.surfaceContainerHigh, FacultyColors.onSurface),
                  _tag('CLASS: $_classCode', FacultyColors.surfaceContainer, FacultyColors.onSurfaceVariant),
                ] else ...const [
                  _Skeleton(width: 130, height: 24, radius: 8),
                  _Skeleton(width: 110, height: 24, radius: 8),
                ],
              ],
            ),
          ],
        ),
        OutlinedButton.icon(
          // Needs the class's assessment weightage, so waits for the gradebook.
          onPressed: _gradebookReady ? _openAttendanceSettings : null,
          icon: const Icon(Icons.settings_outlined, size: 18),
          label: const Text('Attendance Settings', textAlign: TextAlign.center),
          style: OutlinedButton.styleFrom(
            foregroundColor: FacultyColors.primary,
            side: const BorderSide(color: FacultyColors.outline),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: FacultyTypography.labelMd(),
          ),
        ),
      ],
    ));
  }

  Future<void> _openAttendanceSettings() async {
    final updated = await showDialog<AttendanceSettings>(
      context: context,
      builder: (_) => _AttendanceSettingsDialog(initial: _attendanceSettings, otherWeightage: _assessmentWeightage),
    );
    if (updated == null) return;
    try {
      await _attendanceRepository.saveSettings(widget.sectionId, updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save attendance settings: $e'), backgroundColor: FacultyColors.error),
      );
      return;
    }
    if (!mounted) return;
    showSuccessSnackBar(context, 'Attendance settings saved.');
    await _load();
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

  static String _pctText(double v) => v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toString();

  void _scrollToDirectory() {
    final ctx = _directoryKey.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  Future<void> _sendDistributionForApproval(GradeDistributionCheck check) async {
    final justification = await showDialog<String>(
      context: context,
      builder: (_) => _DistributionRequestDialog(check: check),
    );
    if (justification == null || !mounted) return;
    try {
      await _distributionRepository.submitRequest(
        sectionId: widget.sectionId,
        lecturerId: DemoIdentity.lecturerId,
        justification: justification,
        check: check,
        stats: GradeStatistics.from([for (final r in _rosterRows) r.finalTotalPct], _gradeScale.letterFor),
      );
      final request = await _distributionRepository.getLatestRequest(widget.sectionId);
      if (!mounted) return;
      setState(() => _distributionRequest = request);
      showSuccessSnackBar(context, 'Sent to the admin for approval.');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not send the request: $e')));
    }
  }

  /// Alerts the lecturer when the class has more top grades than the admin's
  /// limits allow. They can either moderate their grading to fit, or send the
  /// distribution to the admin for approval. Hidden while the grades are
  /// within the limits.
  Widget _buildDistributionAlert() {
    final check = _distribution;
    if (!_gradebookReady || check == null || check.isWithinLimits) return const SizedBox.shrink();
    final request = _distributionRequest;
    final approved = request != null && request.isApproved && request.coversCounts(check.counts);
    final pending = request != null && request.isPending;

    final (Color bg, Color border, Color fg, IconData icon, String title) = approved
        ? (const Color(0xFFDCFCE7), const Color(0xFF86EFAC), const Color(0xFF14532D), Icons.verified_outlined, 'Grade distribution approved by the admin')
        : pending
            ? (const Color(0xFFDBEAFE), const Color(0xFF93C5FD), const Color(0xFF1E3A8A), Icons.hourglass_top_outlined, 'Waiting for the admin to review your grade distribution')
            : (const Color(0xFFFEF3C7), const Color(0xFFF59E0B), const Color(0xFF7C2D12), Icons.warning_amber_rounded, 'Your grade distribution is outside the allowed limits');

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: bg, border: Border.all(color: border, width: 1.5), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: fg),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: FacultyTypography.titleSm(color: fg).copyWith(fontSize: 16))),
              ],
            ),
            const SizedBox(height: 10),
            for (final b in check.violations)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '• ${b.band.label}: ${b.actual} of ${check.enrolled} students — at most ${b.allowed} allowed (${_pctText(b.maxPercent!)}%)',
                  style: FacultyTypography.bodyMd(color: fg),
                ),
              ),
            const SizedBox(height: 8),
            if (approved)
              Text('The admin approved these grades${request.decidedAt == null ? '' : ' on ${formatDate(request.decidedAt!)}'}. If you raise more grades, you will need to ask again.',
                  style: FacultyTypography.bodyMd(color: fg))
            else if (pending)
              Text('Sent ${formatDate(request.createdAt)}. You can still moderate your grades if you would rather keep within the limits.',
                  style: FacultyTypography.bodyMd(color: fg))
            else ...[
              if (request != null && request.isRejected)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'The admin did not approve your last request${(request.adminNote ?? '').isEmpty ? '.' : ': "${request.adminNote}"'}',
                    style: FacultyTypography.bodyMd(color: fg).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              Text(
                'Please either moderate your grading to follow the distribution, or send your distribution to the admin for approval.',
                style: FacultyTypography.bodyMd(color: fg),
              ),
            ],
            if (!approved) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _scrollToDirectory,
                    icon: const Icon(Icons.fact_check_outlined, size: 18),
                    label: const Text('Review & moderate grades', textAlign: TextAlign.center),
                    style: OutlinedButton.styleFrom(foregroundColor: fg, side: BorderSide(color: fg)),
                  ),
                  if (!pending)
                    ElevatedButton.icon(
                      onPressed: () => _sendDistributionForApproval(check),
                      icon: const Icon(Icons.send_outlined, size: 18),
                      label: const Text('Send to admin for approval', textAlign: TextAlign.center),
                      style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primaryContainer, foregroundColor: Colors.white, elevation: 0),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKpiRow() {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 1100 ? 5 : (constraints.maxWidth >= 900 ? 3 : (constraints.maxWidth >= 500 ? 2 : 1));
      final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
      final cards = [
        _rosterReady
            ? _kpiCard('ENROLLED STUDENTS', '$_enrolledCount', Icons.groups_outlined, FacultyColors.primary, FacultyColors.surfaceContainer)
            : _kpiSkeleton(),
        if (!_gradebookReady) ...[_kpiSkeleton(), _kpiSkeleton(), _kpiSkeleton(), _kpiSkeleton()] else ...[
        _kpiCard('ASSIGNMENTS TO GRADE', '$_assignmentsToGrade', Icons.assignment_turned_in_outlined, FacultyColors.onSecondaryFixedVariant, FacultyColors.secondaryContainer,
            footer: '$_assignmentNonSubmissions non-submissions', footerColor: FacultyColors.onSecondaryFixedVariant, pillFooter: true),
        _kpiCard('QUIZZES TO GRADE', '$_quizzesToGrade', Icons.quiz_outlined, FacultyColors.primary, FacultyColors.surfaceContainerHigh,
            footer: '$_quizNonSubmissions non-submissions', footerColor: FacultyColors.onSecondaryFixedVariant, pillFooter: true),
        _kpiCard('AVERAGE STUDENT PROGRESS', '$_avgProgress%', Icons.donut_large, FacultyColors.primary, FacultyColors.surfaceContainer,
            progress: _avgProgress / 100),
        ScoreDistributionCard(
          rawScores: [for (final r in _rosterRows) r.totalAchievedPct],
          moderatedScores: [for (final r in _rosterRows) r.finalTotalPct],
        ),
        ],
      ];
      return Wrap(spacing: 16, runSpacing: 16, children: cards.map((c) => SizedBox(width: width, child: c)).toList());
    });
  }

  /// Placeholder with the same footprint as a stat card.
  Widget _kpiSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Skeleton(width: 120, height: 12),
          SizedBox(height: 10),
          _Skeleton(width: 70, height: 32),
          SizedBox(height: 16),
          _Skeleton(height: 8),
        ],
      ),
    );
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
          if (!_hubReady)
            const _Skeleton(height: 68, radius: 12)
          else
          _hubRow(
            icon: Icons.folder_copy_outlined,
            iconBg: FacultyColors.primary,
            iconColor: Colors.white,
            title: 'Modules & Sessions',
            subtitle: '$_moduleCount modules • $_sessionCount sessions',
            statusPill: _syllabusStatusPill(),
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
      key: _directoryKey,
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
                Text('${_gradebookReady ? total : _enrolledCount} enrolled', style: FacultyTypography.labelXs()),
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
          if (!_gradebookReady)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Wrap(spacing: 16, runSpacing: 16, children: [for (var i = 0; i < 4; i++) SizedBox(width: 220, child: _kpiSkeleton())]),
                  const SizedBox(height: 20),
                  for (var i = 0; i < 6; i++) ...const [
                    _Skeleton(height: 44, radius: 8),
                    SizedBox(height: 8),
                  ],
                ],
              ),
            )
          else if (_rosterRows.isEmpty)
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
                  hintText: 'Search by student name, email and code...',
                  prefixIcon: const Icon(Icons.search, size: 18, color: FacultyColors.outline),
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

  Widget _syllabusStatusPill() {
    final (label, color) = switch (_syllabusStatus) {
      SyllabusStatus.approved => ('Approved', const Color(0xFF2E7D32)),
      SyllabusStatus.submitted => ('Submitted for approval', const Color(0xFFB26A00)),
      _ => ('Need approval', FacultyColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: FacultyTypography.labelXs(color: color).copyWith(fontWeight: FontWeight.w700)),
    );
  }

  Widget _hubRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? trailingBadge,
    Widget? statusPill,
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
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(title, style: FacultyTypography.titleSm()),
                    ?statusPill,
                  ],
                ),
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
            label: Text(ctaLabel, textAlign: TextAlign.center),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AdminColors.primaryContainer,
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
                label: const Text('Post', textAlign: TextAlign.center),
                style: TextButton.styleFrom(foregroundColor: AdminColors.primaryContainer, textStyle: FacultyTypography.labelMd()),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!_announcementsReady) ...const [
            _Skeleton(height: 64, radius: 10),
            SizedBox(height: 8),
            _Skeleton(height: 64, radius: 10),
          ] else if (_announcements.isEmpty && !_showAnnouncementForm)
            const AnnouncementsEmptyState()
          else
            for (var i = 0; i < _announcements.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              AnnouncementCard(
                announcement: _announcements[i],
                onEdit: () => _editAnnouncement(_announcements[i]),
                onDelete: () => _deleteAnnouncement(_announcements[i]),
              ),
            ],
          if (_showAnnouncementForm) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Post', style: FacultyTypography.labelMd()),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _announcementTitleController,
                    decoration: InputDecoration(
                      isDense: true,
                      fillColor: FacultyColors.surfaceContainerLowest,
                      hintText: 'Subject line...',
                      ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _announcementBodyController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      fillColor: FacultyColors.surfaceContainerLowest,
                      hintText: 'Announcement content...',
                      ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _postingAnnouncement ? null : () => setState(() => _showAnnouncementForm = false),
                        child: const Text('Cancel', textAlign: TextAlign.center),
                      ),
                      ElevatedButton(
                        onPressed: _postingAnnouncement ? null : _postAnnouncement,
                        style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primaryContainer, foregroundColor: Colors.white, elevation: 0),
                        child: Text(_postingAnnouncement ? 'Posting...' : 'Post', textAlign: TextAlign.center),
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
  // Mobile (≤ 900px) layout — the same content as desktop (class header, KPI
  // cards, course contents, announcements and the Student Directory table).
  // Every desktop section is already responsive (KPIs and announcement cards
  // stack, the directory scrolls horizontally with the student column pinned),
  // so they are reused as-is under the compact mobile top bar.
  // ---------------------------------------------------------------------

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: FacultyMobileTopBar(title: _headerReady ? _courseTitle : ''),
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
              _buildDistributionAlert(),
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

/// "Attendance Settings" dialog: the raw score each attendance status earns
/// and the attendance share of the final grade. [otherWeightage] is what the
/// class's exam/assignment blocks already use, so attendance can only take
/// the remainder of the 100%.
class _AttendanceSettingsDialog extends StatefulWidget {
  final AttendanceSettings initial;
  final double otherWeightage;

  const _AttendanceSettingsDialog({required this.initial, required this.otherWeightage});

  @override
  State<_AttendanceSettingsDialog> createState() => _AttendanceSettingsDialogState();
}

class _AttendanceSettingsDialogState extends State<_AttendanceSettingsDialog> {
  late final _present = TextEditingController(text: _fmt(widget.initial.presentMarks));
  late final _late = TextEditingController(text: _fmt(widget.initial.lateMarks));
  late final _validAbsent = TextEditingController(text: _fmt(widget.initial.validAbsentMarks));
  late final _invalidAbsent = TextEditingController(text: _fmt(widget.initial.invalidAbsentMarks));
  late final _weightage = TextEditingController(text: _fmt(widget.initial.weightage));
  bool _submitted = false;

  static String _fmt(double v) => v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);

  double get _budget => (100 - widget.otherWeightage).clamp(0, 100).toDouble();

  @override
  void dispose() {
    for (final c in [_present, _late, _validAbsent, _invalidAbsent, _weightage]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Present >= Late >= Valid absent >= Invalid absent: the attendance share
  /// divides by (Present score x classes), so no status may beat the one above.
  String? _marksError(TextEditingController c) {
    final order = [(_present, 'Present'), (_late, 'Late'), (_validAbsent, 'Valid absent'), (_invalidAbsent, 'Invalid absent')];
    final value = double.tryParse(c.text.trim());
    if (value == null) return 'Enter a score (0 or more).';
    final i = order.indexWhere((e) => e.$1 == c);
    if (i > 0) {
      final above = double.tryParse(order[i - 1].$1.text.trim());
      if (above != null && value > above) {
        return '${order[i].$2} cannot be higher than ${order[i - 1].$2} (${_fmt(above)}). Use Present ≥ Late ≥ Valid absent ≥ Invalid absent.';
      }
    }
    return null;
  }

  String? get _weightageError {
    final w = double.tryParse(_weightage.text.trim());
    if (w == null) return 'Enter a number between 0 and 100.';
    if (w > _budget + 0.001) {
      return 'Only ${_fmt(_budget)}% is available — assignments and exams already use ${_fmt(widget.otherWeightage)}%, and the total cannot exceed 100%.';
    }
    return null;
  }

  void _save() {
    setState(() => _submitted = true);
    if ([_present, _late, _validAbsent, _invalidAbsent].any((c) => _marksError(c) != null) || _weightageError != null) return;
    Navigator.pop(
      context,
      AttendanceSettings(
        presentMarks: double.parse(_present.text.trim()),
        lateMarks: double.parse(_late.text.trim()),
        validAbsentMarks: double.parse(_validAbsent.text.trim()),
        invalidAbsentMarks: double.parse(_invalidAbsent.text.trim()),
        weightage: double.parse(_weightage.text.trim()),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {String? error, String? suffix, String? helper}) {
    return FacultyFormField(
      controller: c,
      label: label,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: decimalOnly,
      onChanged: (_) => setState(() {}),
      suffixText: suffix,
      helperText: helper,
      errorText: _submitted ? error : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FacultyDialog(
      title: 'Attendance Settings',
      subtitle: 'Set the raw score each attendance status earns, and how much attendance counts toward the final grade.',
      confirmLabel: 'Save Settings',
      onConfirm: _save,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Raw score per physical class', style: FacultyTypography.labelMd().copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _field(_present, 'Present', error: _marksError(_present)),
          const SizedBox(height: 14),
          _field(_late, 'Late', error: _marksError(_late)),
          const SizedBox(height: 14),
          Text('Absent', style: FacultyTypography.labelMd()),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _field(_validAbsent, 'Valid reason', error: _marksError(_validAbsent))),
              const SizedBox(width: 12),
              Expanded(child: _field(_invalidAbsent, 'Invalid reason', error: _marksError(_invalidAbsent))),
            ],
          ),
          const SizedBox(height: 20),
          Text('Weightage', style: FacultyTypography.labelMd().copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _field(
            _weightage,
            'Attendance weightage',
            suffix: '%',
            error: _weightageError,
            helper: '${_fmt(_budget)}% available — assignments and exams use ${_fmt(widget.otherWeightage)}%. Everything together cannot exceed 100%.',
          ),
        ],
      ),
    );
  }
}

/// A softly pulsing grey block shown where content is still loading.
class _Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const _Skeleton({this.width, required this.height, this.radius = 6});

  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(const Color(0xFFE2E8F0), const Color(0xFFF1F5F9), _controller.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Asks the lecturer why their grade distribution is outside the limits, then
/// sends it to the admin. Pops the reason, or nothing if cancelled.
class _DistributionRequestDialog extends StatefulWidget {
  final GradeDistributionCheck check;

  const _DistributionRequestDialog({required this.check});

  @override
  State<_DistributionRequestDialog> createState() => _DistributionRequestDialogState();
}

class _DistributionRequestDialogState extends State<_DistributionRequestDialog> {
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _send() {
    final text = _reason.text.trim();
    if (text.length < 10) {
      setState(() => _error = 'Please explain why in a sentence or two (at least 10 characters).');
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return FacultyDialog(
      title: 'Send to admin for approval',
      subtitle: 'The admin will review your grade distribution and either approve it or ask you to moderate it.',
      confirmLabel: 'Send Request',
      onConfirm: _send,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final b in widget.check.bands)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(child: Text(b.band.label, style: FacultyTypography.bodyMd(color: FacultyColors.onSurface))),
                  Text(
                    '${b.actual} of ${widget.check.enrolled}'
                    '${b.allowed == null ? '' : '  (limit ${b.allowed})'}',
                    style: FacultyTypography.titleSm(color: b.exceeds ? FacultyColors.error : FacultyColors.onSurface),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          FacultyFormField(
            controller: _reason,
            label: 'Why is the distribution higher than the limits?',
            maxLines: 4,
            errorText: _error,
            hint: 'e.g. This semester did exceptionally well on the final project.',
            onChanged: (_) => setState(() => _error = null),
          ),
        ],
      ),
    );
  }
}
