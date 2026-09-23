import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_students_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_exam_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturer_syllabus_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_submission_grading_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/content_block_submission.dart';
import 'package:stitch_aiei_lms/domain/models/roster_student.dart';
import 'exam_grading_screen.dart';
import 'widgets/faculty_mobile_top_bar.dart';

// ---------------------------------------------------------------------------
// MarkExamScreen — reached via "Mark Exam" on an exam content block in the
// Syllabus editor. Shows the class roster, 30 students per page, sortable
// by name/code/status/score; tapping a student opens their answers for
// grading on ExamGradingScreen, which can then step forward through this
// same sorted order via "Save and Mark the Next Student".
// ---------------------------------------------------------------------------

enum _SortColumn { name, code, status, score }

const _pageSize = 30;

class MarkExamScreen extends StatefulWidget {
  final String contentBlockId;
  final String sectionId;
  final String title;

  const MarkExamScreen({super.key, required this.contentBlockId, required this.sectionId, required this.title});

  @override
  State<MarkExamScreen> createState() => _MarkExamScreenState();
}

class _MarkExamScreenState extends State<MarkExamScreen> {
  final _rosterRepository = SupabaseAdminStudentsRepositoryImpl(Supabase.instance.client);
  final _gradingRepository = SupabaseSubmissionGradingRepositoryImpl(Supabase.instance.client);
  final _examRepository = SupabaseExamRepositoryImpl(Supabase.instance.client);
  final _syllabusRepository = SupabaseLecturerSyllabusRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  List<RosterStudent> _roster = const [];
  Map<String, ContentBlockSubmission> _submissions = const {};
  double _maxMarks = 0;
  double? _weightage;

  _SortColumn _sortColumn = _SortColumn.name;
  bool _sortAscending = true;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final roster = await _rosterRepository.getSectionRoster(widget.sectionId);
    final submissions = await _gradingRepository.getRosterSubmissions(widget.contentBlockId);
    final maxMarks = await _examRepository.getTotalMarks(widget.contentBlockId);
    final block = await _syllabusRepository.getContentBlock(widget.contentBlockId);
    if (!mounted) return;
    setState(() {
      _roster = roster;
      _submissions = submissions;
      _maxMarks = maxMarks;
      _weightage = block?.weightage;
      _page = 0;
      _isLoading = false;
    });
  }

  /// This student's score as a percentage of [_maxMarks] — null until
  /// they're graded, or if the exam has no questions/marks set up yet.
  double? _percentFor(ContentBlockSubmission? submission) {
    if (submission?.totalScore == null || _maxMarks <= 0) return null;
    return submission!.totalScore! / _maxMarks * 100;
  }

  /// The marks this submission actually carries toward the class's final
  /// grade — this block's `weightage` (0-100, from the syllabus editor)
  /// scaled by the student's percentage score on it. Null until graded, or
  /// if no weightage has been set for this block.
  double? _carryMarkFor(ContentBlockSubmission? submission) {
    final percent = _percentFor(submission);
    if (percent == null || _weightage == null) return null;
    return percent / 100 * _weightage!;
  }

  int _statusRank(RosterStudent s) {
    final submission = _submissions[s.studentId];
    if (submission == null) return 0;
    if (submission.isGraded) return 2;
    return 1;
  }

  List<RosterStudent> get _sortedRoster {
    final rows = [..._roster];
    int cmp(RosterStudent a, RosterStudent b) {
      switch (_sortColumn) {
        case _SortColumn.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case _SortColumn.code:
          return a.studentCode.toLowerCase().compareTo(b.studentCode.toLowerCase());
        case _SortColumn.status:
          return _statusRank(a).compareTo(_statusRank(b));
        case _SortColumn.score:
          final scoreA = _submissions[a.studentId]?.totalScore;
          final scoreB = _submissions[b.studentId]?.totalScore;
          if (scoreA == null && scoreB == null) return 0;
          if (scoreA == null) return -1;
          if (scoreB == null) return 1;
          return scoreA.compareTo(scoreB);
      }
    }

    rows.sort(cmp);
    if (!_sortAscending) return rows.reversed.toList();
    return rows;
  }

  void _onSort(_SortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
      _page = 0;
    });
  }

  Future<void> _openStudent(List<RosterStudent> orderedRoster, int index) async {
    final s = orderedRoster[index];
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExamGradingScreen(
          contentBlockId: widget.contentBlockId,
          studentId: s.studentId,
          studentName: s.name,
          orderedStudents: [for (final r in orderedRoster) (studentId: r.studentId, studentName: r.name)],
          currentIndex: index,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final sorted = _sortedRoster;
    final totalPages = sorted.isEmpty ? 1 : (sorted.length / _pageSize).ceil();
    final page = _page.clamp(0, totalPages - 1);
    final pageStart = page * _pageSize;
    final pageRows = sorted.skip(pageStart).take(_pageSize).toList();

    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: FacultyMobileTopBar(title: widget.title),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Mark Exam', style: FacultyTypography.headlineMd()),
                  const SizedBox(height: 4),
                  Text('Select a student to grade their answers.', style: FacultyTypography.bodySm()),
                  const SizedBox(height: 16),
                  if (sorted.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: Text('No students enrolled in this class yet.', style: FacultyTypography.bodyMd()),
                    )
                  else ...[
                    _rosterTable(sorted, pageRows, pageStart),
                    const SizedBox(height: 12),
                    _paginationBar(sorted.length, page, totalPages, pageStart, pageRows.length),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rosterTable(List<RosterStudent> sorted, List<RosterStudent> pageRows, int pageStart) {
    return Container(
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(builder: (context, constraints) {
        // Stretch to fill the available width on desktop instead of always
        // sitting at a fixed 940px (leaving dead space on wide screens);
        // only fall back to the 940px minimum + horizontal scroll when the
        // viewport is narrower than that (tablet/mobile).
        final width = constraints.maxWidth > 940 ? constraints.maxWidth : 940.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                _headerRow(),
                for (var i = 0; i < pageRows.length; i++) _dataRow(sorted, pageStart + i),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _headerRow() {
    return Container(
      color: FacultyColors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: _headerCell('Student', _SortColumn.name)),
          Expanded(flex: 2, child: _headerCell('Student Code', _SortColumn.code)),
          Expanded(flex: 2, child: _headerCell('Status', _SortColumn.status)),
          Expanded(flex: 2, child: _headerCell('Score', _SortColumn.score, alignEnd: true)),
          Expanded(flex: 2, child: _plainHeaderCell('Mark %', alignEnd: true)),
          Expanded(flex: 2, child: _plainHeaderCell('Carry Mark', alignEnd: true)),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _headerCell(String label, _SortColumn column, {bool alignEnd = false}) {
    final active = _sortColumn == column;
    return InkWell(
      onTap: () => _onSort(column),
      child: Row(
        mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: FacultyTypography.labelXs(color: active ? FacultyColors.primary : FacultyColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 2),
          Icon(
            active ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward) : Icons.unfold_more,
            size: 14,
            color: active ? FacultyColors.primary : FacultyColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  /// A header cell for a column that isn't sortable (Mark %/Carry Mark are
  /// derived, not stored, so sorting by them isn't supported).
  Widget _plainHeaderCell(String label, {bool alignEnd = false}) {
    return Row(
      mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _dataRow(List<RosterStudent> sorted, int index) {
    final s = sorted[index];
    final submission = _submissions[s.studentId];
    final (statusLabel, statusColor, statusBg) = _statusFor(submission);
    final percent = _percentFor(submission);
    final carryMark = _carryMarkFor(submission);
    return InkWell(
      onTap: () => _openStudent(sorted, index),
      child: Container(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: FacultyColors.surfaceContainerLow))),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(color: FacultyColors.surfaceContainerHigh, shape: BoxShape.circle),
                    child: const Icon(Icons.person, color: FacultyColors.primary, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.name,
                      style: FacultyTypography.bodyMd(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: 2, child: Text(s.studentCode, style: FacultyTypography.bodySm(color: FacultyColors.secondary))),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(statusLabel, style: FacultyTypography.labelXs(color: statusColor).copyWith(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                submission?.totalScore != null ? _formatScore(submission!.totalScore!) : '—',
                textAlign: TextAlign.end,
                style: FacultyTypography.titleSm(color: FacultyColors.primary),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                percent != null ? '${percent.toStringAsFixed(1)}%' : '—',
                textAlign: TextAlign.end,
                style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                carryMark != null ? _formatScore(carryMark) : '—',
                textAlign: TextAlign.end,
                style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: FacultyColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _paginationBar(int total, int page, int totalPages, int pageStart, int pageCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing ${total == 0 ? 0 : pageStart + 1}–${pageStart + pageCount} of $total students',
          style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant),
        ),
        Row(
          children: [
            IconButton(
              onPressed: page > 0 ? () => setState(() => _page = page - 1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('Page ${page + 1} of $totalPages', style: FacultyTypography.bodySm()),
            IconButton(
              onPressed: page < totalPages - 1 ? () => setState(() => _page = page + 1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }

  String _formatScore(double score) => score.toStringAsFixed(score.truncateToDouble() == score ? 0 : 1);

  (String, Color, Color) _statusFor(ContentBlockSubmission? submission) {
    if (submission == null) return ('Not submitted', FacultyColors.onSurfaceVariant, FacultyColors.surfaceContainer);
    if (submission.isGraded) return ('Graded', FacultyColors.primary, FacultyColors.secondaryContainer);
    return ('Needs grading', FacultyColors.error, FacultyColors.errorContainer);
  }
}
