import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/domain/models/grade_scale.dart';
import 'package:stitch_aiei_lms/domain/models/roster_student.dart';

/// One quiz/assignment content block, as a column in [StudentRosterTable].
/// [weightage] is the percentage of the final grade this block is worth —
/// each student's cell shows their share of it (marks scored / max marks *
/// [weightage]) against this total.
class AssessmentColumn {
  final String blockId;
  final String label;
  final double weightage;

  const AssessmentColumn({required this.blockId, required this.label, required this.weightage});
}

/// A single roster line, shared by [StudentRosterTable] (desktop) and
/// [StudentRosterMobileList] (mobile) — built from a [RosterStudent] plus
/// that student's real graded-submission coverage against every
/// exam/assignment content block in the class (see
/// [RosterRow.fromRoster]).
class RosterRow {
  final String studentId;
  final String name;
  final String role;
  final String studentCode;
  final String email;
  final int progress;
  final String progressTag;
  final Color progressColor;
  final String assignments;
  final String assignmentsTag;
  final Color assignmentsTagBg;
  /// Raw graded/total counts behind [assignments]/[quiz] — kept alongside
  /// the formatted strings so the table can sort by them numerically
  /// instead of re-parsing "x/y" text.
  final int assignmentsGraded;
  final int assignmentsTotal;
  final int quizGraded;
  final int quizTotal;
  final String quizAvg;
  /// Whether [quizAvg] reflects at least one graded exam — [quizAvg] itself
  /// always renders a number (never a dash), so callers that need to
  /// distinguish "genuinely 0%" from "no graded quiz yet" (e.g. averaging
  /// only scored students) should check this instead of parsing [quizAvg].
  final bool hasQuizScore;
  /// "QUIZ" column on the desktop Student Directory table: graded/total
  /// exam-block count, the same "fraction of the class's quizzes" shape as
  /// [assignments] — distinct from [quizAvg]'s average score percentage,
  /// which the mobile roster card still shows.
  final String quiz;
  final String lastActive;
  final String status;
  final Color statusBg;
  final bool flagged;
  final bool hasSubmission;
  /// Per assessment block: the student's weighted-percentage share of that
  /// block's [AssessmentColumn.weightage] (score / max marks * weightage),
  /// or null when it isn't graded yet.
  final Map<String, double?> assessmentScores;
  /// Per assessment block: the raw marks the student scored (not scaled by
  /// weightage), or null when it isn't graded yet. Display-only.
  final Map<String, double?> assessmentMarks;
  final double totalAchievedPct;
  final double totalPossiblePct;
  /// Lecturer's manual moderation adjustment (`student_courses.moderated_score`),
  /// added on top of [totalAchievedPct] to produce [finalTotalPct].
  final double moderatedScore;

  Color get statusColor => flagged ? FacultyColors.error : (status == 'Top Performer' ? FacultyColors.primary : FacultyColors.tertiary);

  /// "RAW SCORE" column: weighted marks achieved vs. total weightage.
  String get rawScoreLabel => '${_formatPct(totalAchievedPct)}%';

  /// "FINAL SCORE" column: raw score + moderation, capped at 100%.
  double get finalTotalPct => (totalAchievedPct + moderatedScore).clamp(0, 100);

  String get finalTotalLabel => '${_formatPct(finalTotalPct)}%';

  static String _formatPct(double v) => v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  RosterRow copyWithModeratedScore(double moderatedScore) => RosterRow(
        studentId: studentId,
        name: name,
        role: role,
        studentCode: studentCode,
        email: email,
        progress: progress,
        progressTag: progressTag,
        progressColor: progressColor,
        assignments: assignments,
        assignmentsTag: assignmentsTag,
        assignmentsTagBg: assignmentsTagBg,
        assignmentsGraded: assignmentsGraded,
        assignmentsTotal: assignmentsTotal,
        quizGraded: quizGraded,
        quizTotal: quizTotal,
        quizAvg: quizAvg,
        hasQuizScore: hasQuizScore,
        quiz: quiz,
        lastActive: lastActive,
        status: status,
        statusBg: statusBg,
        flagged: flagged,
        hasSubmission: hasSubmission,
        assessmentScores: assessmentScores,
        assessmentMarks: assessmentMarks,
        totalAchievedPct: totalAchievedPct,
        totalPossiblePct: totalPossiblePct,
        moderatedScore: moderatedScore,
      );

  const RosterRow({
    required this.studentId,
    required this.name,
    required this.role,
    required this.studentCode,
    this.email = '',
    required this.progress,
    required this.progressTag,
    required this.progressColor,
    required this.assignments,
    required this.assignmentsTag,
    required this.assignmentsTagBg,
    this.assignmentsGraded = 0,
    this.assignmentsTotal = 0,
    this.quizGraded = 0,
    this.quizTotal = 0,
    required this.quizAvg,
    this.hasQuizScore = false,
    this.quiz = '0/0',
    required this.lastActive,
    required this.status,
    required this.statusBg,
    this.flagged = false,
    this.hasSubmission = false,
    this.assessmentScores = const {},
    this.assessmentMarks = const {},
    this.totalAchievedPct = 0,
    this.totalPossiblePct = 0,
    this.moderatedScore = 0,
  });

  /// [progress] is the student's graded-submission coverage across every
  /// exam/assignment content block in the class (graded / total, as a
  /// percentage) — computed by the caller from `content_block_submissions`.
  /// [totalAssignments]/[gradedAssignments] are the assignment-only subset
  /// of that same count; [quizAvgPercent] is the average score (as a
  /// percentage of each exam's total marks) across the student's graded
  /// exam submissions, or null if none are graded yet. [hasOverdueSubmission]
  /// is true when the student has at least one exam/assignment past its due
  /// date with no submission recorded — the sole driver of pace/status/
  /// flagged below, computed live rather than read from a stored column.
  factory RosterRow.fromRoster(
    RosterStudent s, {
    required int progress,
    required int totalAssignments,
    required int gradedAssignments,
    required int totalQuizzes,
    required int gradedQuizzes,
    required double? quizAvgPercent,
    required bool hasPendingSubmission,
    required bool hasOverdueSubmission,
    Map<String, double?> assessmentScores = const {},
    Map<String, double?> assessmentMarks = const {},
    double totalAchievedPct = 0,
    double totalPossiblePct = 0,
    double moderatedScore = 0,
  }) {
    final (progressTag, progressColor) = _paceFor(hasOverdueSubmission);
    final (status, statusBg) = _standingFor(hasOverdueSubmission);

    String assignmentsTag;
    Color assignmentsTagBg;
    if (hasPendingSubmission) {
      assignmentsTag = 'Pending Review';
      assignmentsTagBg = FacultyColors.surfaceContainerHigh;
    } else if (totalAssignments == 0) {
      assignmentsTag = 'No Assignments';
      assignmentsTagBg = FacultyColors.surfaceContainer;
    } else if (gradedAssignments == totalAssignments) {
      assignmentsTag = 'Graded';
      assignmentsTagBg = FacultyColors.surfaceContainer;
    } else if (gradedAssignments > 0) {
      assignmentsTag = 'In Progress';
      assignmentsTagBg = FacultyColors.surfaceContainerHigh;
    } else if (hasOverdueSubmission) {
      assignmentsTag = 'Assignment Late';
      assignmentsTagBg = FacultyColors.errorContainer;
    } else {
      assignmentsTag = 'Not Started';
      assignmentsTagBg = FacultyColors.surfaceContainer;
    }

    return RosterRow(
      studentId: s.studentId,
      name: s.name,
      role: s.title ?? 'Enrolled Student',
      studentCode: s.studentCode,
      email: s.email,
      progress: progress,
      progressTag: progressTag,
      progressColor: progressColor,
      assignments: '$gradedAssignments/$totalAssignments',
      assignmentsTag: assignmentsTag,
      assignmentsTagBg: assignmentsTagBg,
      assignmentsGraded: gradedAssignments,
      assignmentsTotal: totalAssignments,
      quizGraded: gradedQuizzes,
      quizTotal: totalQuizzes,
      quizAvg: '${(quizAvgPercent ?? 0).toStringAsFixed(1)}%',
      hasQuizScore: quizAvgPercent != null,
      quiz: '$gradedQuizzes/$totalQuizzes',
      lastActive: _formatLastActive(s.lastActivityAt),
      status: status,
      statusBg: statusBg,
      flagged: hasOverdueSubmission,
      hasSubmission: hasPendingSubmission,
      assessmentScores: assessmentScores,
      assessmentMarks: assessmentMarks,
      totalAchievedPct: totalAchievedPct,
      totalPossiblePct: totalPossiblePct,
      moderatedScore: moderatedScore,
    );
  }

  static (String, Color) _paceFor(bool behind) =>
      behind ? ('Behind', FacultyColors.error) : ('On Pace', FacultyColors.tertiary);

  static (String, Color) _standingFor(bool behind) =>
      behind ? ('Behind Schedule', FacultyColors.errorContainer) : ('On Track', FacultyColors.surfaceContainer);

  static String _formatLastActive(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

/// Desktop table body (header + rows) for a roster — no search bar or
/// pagination chrome, so it can be embedded standalone (course dashboard)
/// or wrapped with that chrome (full Student Directory screen).
class StudentRosterTable extends StatefulWidget {
  final List<RosterRow> rows;
  final void Function(RosterRow row, String action) onAction;
  final List<AssessmentColumn> assessmentColumns;
  final void Function(RosterRow row, double value)? onModeratedScoreSave;
  /// Admin-configured cap (`AppSettingKeys.maxModeratedScore`) on how much
  /// the "MODERATED SCORE" bulk "Apply All" input may add at once — null
  /// means no limit is configured. Enforced by [_BulkModeratedScoreHeader]
  /// itself (it pops up a blocking message instead of applying when
  /// exceeded); per-row individual saves are not capped by this setting.
  final double? maxModeratedScore;
  /// Admin-configured scale used to derive the letter-grade columns from the
  /// scores at render time (letters are never stored).
  final GradeScale gradeScale;

  const StudentRosterTable({
    super.key,
    required this.rows,
    required this.onAction,
    this.assessmentColumns = const [],
    this.onModeratedScoreSave,
    this.maxModeratedScore,
    this.gradeScale = GradeScale.defaultScale,
  });

  @override
  State<StudentRosterTable> createState() => _StudentRosterTableState();
}

/// STUDENT + STUDENT CODE render in a fixed, un-scrolled left panel so they
/// stay visible while the rest of the table scrolls horizontally on the
/// right, with an always-visible [Scrollbar]. The header row itself sits
/// outside the body's vertical [SingleChildScrollView] entirely, so it stays
/// pinned regardless of how far the (height-capped) body scrolls; its
/// horizontal position is mirrored from the body's own horizontal scroll via
/// [_bodyHScroll]'s listener rather than being independently draggable.
/// Every column header is tappable to sort the rows by it (ascending, then
/// descending on a second tap). Both panels use the same fixed
/// [_headerHeight]/[_rowHeight] per row so the two independently-built
/// columns of rows stay pixel-aligned without any cross-panel measurement.
class _StudentRosterTableState extends State<StudentRosterTable> {
  final _headerHScroll = ScrollController();
  final _bodyHScroll = ScrollController();

  static const double _headerHeight = 56;
  static const double _rowHeight = 64;
  static const double _tableMaxHeight = 560;
  static const double _studentColWidth = 220;
  static const double _codeColWidth = 120;
  static const double _progressColWidth = 170;
  static const double _assignColWidth = 90;
  static const double _quizColWidth = 70;
  static const double _statusColWidth = 130;
  static const double _assessmentColWidth = 120;
  static const double _totalColWidth = 90;
  static const double _gradeColWidth = 56;
  static const double _moderatedColWidth = 140;
  static const double _colGap = 16;

  String? _sortColumnId;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _bodyHScroll.addListener(() {
      if (_headerHScroll.hasClients) _headerHScroll.jumpTo(_bodyHScroll.offset);
    });
  }

  @override
  void dispose() {
    _headerHScroll.dispose();
    _bodyHScroll.dispose();
    super.dispose();
  }

  /// Applies one moderation value to every row at once (the header's bulk
  /// input) — each row still gets its own headroom clamp, same as an
  /// individual cell save, so no student's total can be pushed past 100%.
  void _applyBulkModeratedScore(double value) {
    final onSave = widget.onModeratedScoreSave;
    if (onSave == null) return;
    for (final row in widget.rows) {
      final maxAllowed = (100 - row.totalAchievedPct).clamp(0, 100);
      final clamped = value.clamp(0, maxAllowed).toDouble();
      onSave(row, clamped);
    }
  }

  void _onHeaderTap(String columnId) {
    setState(() {
      if (_sortColumnId == columnId) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnId = columnId;
        _sortAscending = true;
      }
    });
  }

  List<RosterRow> get _sortedRows {
    final columnId = _sortColumnId;
    if (columnId == null) return widget.rows;
    final sorted = List<RosterRow>.from(widget.rows)..sort((a, b) => _compareRows(a, b, columnId));
    return sorted;
  }

  int _compareRows(RosterRow a, RosterRow b, String columnId) {
    int cmp;
    switch (columnId) {
      case 'student':
        cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case 'code':
        cmp = a.studentCode.toLowerCase().compareTo(b.studentCode.toLowerCase());
      case 'progress':
        cmp = a.progress.compareTo(b.progress);
      case 'assignment':
        cmp = a.assignmentsGraded.compareTo(b.assignmentsGraded);
      case 'quiz':
        cmp = a.quizGraded.compareTo(b.quizGraded);
      case 'status':
        cmp = a.status.compareTo(b.status);
      case 'raw':
        cmp = a.totalAchievedPct.compareTo(b.totalAchievedPct);
      case 'moderated':
        cmp = a.moderatedScore.compareTo(b.moderatedScore);
      case 'total':
        cmp = a.finalTotalPct.compareTo(b.finalTotalPct);
      default:
        // An assessment column's blockId.
        final av = a.assessmentScores[columnId] ?? -1;
        final bv = b.assessmentScores[columnId] ?? -1;
        cmp = av.compareTo(bv);
    }
    return _sortAscending ? cmp : -cmp;
  }

  /// A header cell's label plus a sort-direction arrow when [columnId] is
  /// the active sort column — tapping anywhere on it sorts by that column
  /// (ascending first, descending on a repeat tap).
  ///
  /// [suffix] is appended after [label] and is never truncated — only the
  /// label ellipsizes when space runs out.
  Widget _sortableHeader(String label, String columnId, TextStyle style,
      {TextAlign align = TextAlign.left, int maxLines = 1, String? suffix}) {
    final active = _sortColumnId == columnId;
    final icon = active ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward) : null;
    final labelText = Text(label, style: style, textAlign: align, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    final text = suffix == null
        ? Flexible(child: labelText)
        : Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [Flexible(child: labelText), Text(' $suffix', style: style, maxLines: 1)],
            ),
          );
    final mainAxisAlignment = align == TextAlign.right
        ? MainAxisAlignment.end
        : (align == TextAlign.center ? MainAxisAlignment.center : MainAxisAlignment.start);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _onHeaderTap(columnId),
        child: Row(
          mainAxisAlignment: mainAxisAlignment,
          children: [
            if (icon != null && align == TextAlign.right) ...[Icon(icon, size: 11, color: FacultyColors.primary), const SizedBox(width: 2)],
            text,
            if (icon != null && align != TextAlign.right) ...[const SizedBox(width: 2), Icon(icon, size: 11, color: FacultyColors.primary)],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pinned header — outside the vertical scroll below entirely, so it
        // never scrolls away; its horizontal offset is mirrored from the
        // body's own horizontal scroll (see initState).
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stickyHeaderRow(),
            Expanded(
              child: SingleChildScrollView(
                controller: _headerHScroll,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: _scrollableHeaderRow(),
              ),
            ),
          ],
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: _tableMaxHeight),
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _stickyRowsColumn(),
                Expanded(
                  child: Scrollbar(
                    controller: _bodyHScroll,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: SingleChildScrollView(
                      controller: _bodyHScroll,
                      scrollDirection: Axis.horizontal,
                      child: Column(children: [for (final s in _sortedRows) _scrollableDataRow(s)]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Sticky left panel: STUDENT + STUDENT CODE ───────────────────────────
  Widget _stickyRowsColumn() {
    return DecoratedBox(
      decoration: const BoxDecoration(border: Border(right: BorderSide(color: FacultyColors.surfaceContainer, width: 1))),
      child: Column(children: [for (final s in _sortedRows) _stickyDataRow(s)]),
    );
  }

  Widget _stickyHeaderRow() {
    TextStyle s() => FacultyTypography.labelXs().copyWith(fontWeight: FontWeight.w700);
    return Container(
      height: _headerHeight,
      decoration: const BoxDecoration(
        color: FacultyColors.surfaceContainerLow,
        border: Border(right: BorderSide(color: FacultyColors.surfaceContainer, width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _studentColWidth,
            child: Padding(padding: const EdgeInsets.only(left: 16, right: 8), child: _sortableHeader('STUDENT', 'student', s())),
          ),
          SizedBox(
            width: _codeColWidth,
            child: Padding(padding: const EdgeInsets.only(right: 16), child: _sortableHeader('STUDENT CODE', 'code', s())),
          ),
        ],
      ),
    );
  }

  Widget _stickyDataRow(RosterRow s) {
    return Container(
      height: _rowHeight,
      decoration: BoxDecoration(
        color: s.flagged ? FacultyColors.errorContainer.withValues(alpha: 0.15) : FacultyColors.surfaceContainerLowest,
        border: const Border(bottom: BorderSide(color: FacultyColors.surfaceContainerLow)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _studentColWidth,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
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
                      mainAxisSize: MainAxisSize.min,
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
          ),
          SizedBox(
            width: _codeColWidth,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(s.studentCode, style: FacultyTypography.bodySm(color: FacultyColors.secondary), overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }

  // ── Scrollable right panel: everything else ─────────────────────────────
  Widget _scrollableHeaderRow() {
    TextStyle s() => FacultyTypography.labelXs().copyWith(fontWeight: FontWeight.w700);
    return Container(
      height: _headerHeight,
      color: FacultyColors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(width: _progressColWidth, child: _sortableHeader('PROGRESS', 'progress', s())),
          Padding(
            padding: const EdgeInsets.only(left: _colGap),
            child: SizedBox(width: _assignColWidth, child: _sortableHeader('ASSIGNMENT', 'assignment', s())),
          ),
          Padding(
            padding: const EdgeInsets.only(left: _colGap),
            child: SizedBox(width: _quizColWidth, child: _sortableHeader('QUIZ', 'quiz', s(), align: TextAlign.right)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: _colGap),
            child: SizedBox(width: _statusColWidth, child: _sortableHeader('STATUS', 'status', s(), align: TextAlign.center)),
          ),
          for (final col in widget.assessmentColumns)
            Padding(
              padding: const EdgeInsets.only(left: _colGap),
              child: SizedBox(
                width: _assessmentColWidth,
                child: Tooltip(
                  message: col.label,
                  child: _sortableHeader(col.label.toUpperCase(), col.blockId, s(),
                      align: TextAlign.right, suffix: '(${RosterRow._formatPct(col.weightage)}%)'),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: _colGap),
            child: SizedBox(width: _totalColWidth, child: _sortableHeader('RAW SCORE', 'raw', s(), align: TextAlign.right)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: _colGap),
            child: SizedBox(width: _gradeColWidth, child: _sortableHeader('GRADE', 'raw', s(), align: TextAlign.center)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: _colGap),
            child: SizedBox(
              width: _moderatedColWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sortableHeader('MODERATED SCORE', 'moderated', s(), align: TextAlign.right),
                  const SizedBox(height: 4),
                  _BulkModeratedScoreHeader(
                    onApplyAll: widget.onModeratedScoreSave == null ? null : _applyBulkModeratedScore,
                    maxModeratedScore: widget.maxModeratedScore,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: _colGap),
            child: SizedBox(width: _totalColWidth, child: _sortableHeader('FINAL SCORE', 'total', s(), align: TextAlign.right)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: _colGap),
            child: SizedBox(width: _gradeColWidth, child: _sortableHeader('GRADE', 'total', s(), align: TextAlign.center)),
          ),
        ],
      ),
    );
  }

  Widget _scrollableDataRow(RosterRow s) {
    return Container(
      height: _rowHeight,
      decoration: BoxDecoration(
        color: s.flagged ? FacultyColors.errorContainer.withValues(alpha: 0.15) : null,
        border: const Border(bottom: BorderSide(color: FacultyColors.surfaceContainerLow)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: _progressColWidth,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
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
          Padding(
            padding: const EdgeInsets.only(left: _colGap),
            child: SizedBox(
              width: _assignColWidth,
              child: Text(s.assignments, style: FacultyTypography.bodySm(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: _colGap),
            child: SizedBox(
              width: _quizColWidth,
              child: Text(s.quiz, textAlign: TextAlign.right, style: FacultyTypography.titleSm(color: s.flagged ? FacultyColors.error : FacultyColors.onSurface)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: _colGap),
            child: SizedBox(
              width: _statusColWidth,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: s.statusBg, borderRadius: BorderRadius.circular(4)),
                  child: Text(s.status, style: FacultyTypography.labelXs(color: s.statusColor).copyWith(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
          for (final col in widget.assessmentColumns)
            Padding(
              padding: const EdgeInsets.only(left: _colGap),
              child: SizedBox(
                width: _assessmentColWidth,
                child: Builder(builder: (context) {
                  final marks = s.assessmentMarks[col.blockId] ?? 0;
                  return Text(
                    RosterRow._formatPct(marks),
                    textAlign: TextAlign.right,
                    style: FacultyTypography.bodySm(color: FacultyColors.onSurface),
                  );
                }),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: _colGap),
            child: SizedBox(
              width: _totalColWidth,
              child: Text(
                s.rawScoreLabel,
                textAlign: TextAlign.right,
                style: FacultyTypography.titleSm(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          _gradeCell(s.totalAchievedPct),
          Padding(
            padding: const EdgeInsets.only(left: _colGap),
            child: SizedBox(
              width: _moderatedColWidth,
              child: _ModeratedScoreCell(
                row: s,
                onSave: widget.onModeratedScoreSave == null ? null : (value) => widget.onModeratedScoreSave!(s, value),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: _colGap),
            child: SizedBox(
              width: _totalColWidth,
              child: Text(
                s.finalTotalLabel,
                textAlign: TextAlign.right,
                style: FacultyTypography.titleSm(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          _gradeCell(s.finalTotalPct),
        ],
      ),
    );
  }

  /// Letter grade derived from [score] via the admin's scale — computed per
  /// render, never persisted.
  Widget _gradeCell(double score) {
    return Padding(
      padding: const EdgeInsets.only(left: _colGap),
      child: SizedBox(
        width: _gradeColWidth,
        child: Text(
          widget.gradeScale.letterFor(score),
          textAlign: TextAlign.center,
          style: FacultyTypography.titleSm(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Editable moderated-score input for one roster row — a number field plus
/// an inline "tick" button that commits the value via [onSave] (persisted to
/// `student_courses.moderated_score` by the caller). The total this feeds
/// into is capped at 100%, so a save that would push the row's raw score +
/// moderation past 100 is clamped down to the remaining headroom first.
class _ModeratedScoreCell extends StatefulWidget {
  final RosterRow row;
  final void Function(double value)? onSave;

  const _ModeratedScoreCell({required this.row, required this.onSave});

  @override
  State<_ModeratedScoreCell> createState() => _ModeratedScoreCellState();
}

class _ModeratedScoreCellState extends State<_ModeratedScoreCell> {
  late final TextEditingController _controller;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: RosterRow._formatPct(widget.row.moderatedScore));
  }

  @override
  void didUpdateWidget(covariant _ModeratedScoreCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dirty && oldWidget.row.moderatedScore != widget.row.moderatedScore) {
      _controller.text = RosterRow._formatPct(widget.row.moderatedScore);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final onSave = widget.onSave;
    if (onSave == null) return;
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed == null) return;
    final maxAllowed = (100 - widget.row.totalAchievedPct).clamp(0, 100);
    final clamped = parsed.clamp(0, maxAllowed).toDouble();
    _controller.text = RosterRow._formatPct(clamped);
    setState(() => _dirty = false);
    onSave(clamped);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: SizedBox(
            height: 30,
            child: TextField(
              controller: _controller,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: FacultyTypography.bodySm(color: FacultyColors.onSurface),
              onChanged: (_) => setState(() => _dirty = true),
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: FacultyColors.surfaceContainerLow,
                suffixText: '%',
                suffixStyle: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: widget.onSave == null ? null : _save,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _dirty ? FacultyColors.primary : FacultyColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.check, size: 16, color: _dirty ? Colors.white : FacultyColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// Header-row bulk input for the "MODERATED SCORE" column — applies one
/// value to every student's row at once via [onApplyAll] (which still
/// clamps per-student to that row's remaining headroom under 100%). When
/// [maxModeratedScore] is set (the admin's global cap on moderated score
/// additions) and the entered value exceeds it, this blocks the apply
/// entirely and shows a message instead — the per-row clamp above only
/// protects the 100% ceiling, not this separate admin-configured limit.
class _BulkModeratedScoreHeader extends StatefulWidget {
  final void Function(double value)? onApplyAll;
  final double? maxModeratedScore;

  const _BulkModeratedScoreHeader({required this.onApplyAll, this.maxModeratedScore});

  @override
  State<_BulkModeratedScoreHeader> createState() => _BulkModeratedScoreHeaderState();
}

class _BulkModeratedScoreHeaderState extends State<_BulkModeratedScoreHeader> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final onApplyAll = widget.onApplyAll;
    if (onApplyAll == null) return;
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed == null) return;
    final max = widget.maxModeratedScore;
    if (max != null && parsed > max) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Exceeds maximum moderated score'),
          content: Text(
            'The admin has capped moderated score adjustments at ${RosterRow._formatPct(max)}%. Enter a value at or below this limit.',
          ),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
        ),
      );
      return;
    }
    onApplyAll(parsed.clamp(0, 100).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: SizedBox(
            height: 26,
            child: TextField(
              controller: _controller,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: FacultyTypography.bodySm(color: FacultyColors.onSurface),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: FacultyColors.surfaceContainerLowest,
                hintText: 'All',
                hintStyle: FacultyTypography.labelXs(color: FacultyColors.outline),
                suffixText: '%',
                suffixStyle: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant),
                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _apply(),
            ),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: widget.onApplyAll == null ? null : _apply,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.check, size: 14, color: FacultyColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// Mobile card list for a roster — the compact per-student cards used on
/// the Student Directory screen, reusable wherever a class's roster needs
/// to show up on a narrow layout (e.g. embedded in the course dashboard).
class StudentRosterMobileList extends StatelessWidget {
  final List<RosterRow> rows;
  final void Function(RosterRow row, String action) onAction;

  const StudentRosterMobileList({super.key, required this.rows, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _card(rows[i]),
        ],
      ],
    );
  }

  Widget _card(RosterRow s) {
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
          _footer(s, isTop: isTop, isBehind: isBehind),
        ],
      ),
    );
  }

  Widget _footer(RosterRow s, {required bool isTop, required bool isBehind}) {
    if (s.flagged) {
      return Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => onAction(s, 'submissions'),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
              child: Text('View Submissions', style: FacultyTypography.labelMd(color: FacultyColors.secondary), overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => onAction(s, 'email'),
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
          onPressed: () => onAction(s, 'submissions'),
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
            onPressed: () => onAction(s, isTop ? 'telemetry' : 'submissions'),
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
          onPressed: () => onAction(s, rightAction),
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
}
