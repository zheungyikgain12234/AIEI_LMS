import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
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
  final int progress;
  final String progressTag;
  final Color progressColor;
  final String assignments;
  final String assignmentsTag;
  final Color assignmentsTagBg;
  final String quizAvg;
  /// Whether [quizAvg] reflects at least one graded exam — [quizAvg] itself
  /// always renders a number (never a dash), so callers that need to
  /// distinguish "genuinely 0%" from "no graded quiz yet" (e.g. averaging
  /// only scored students) should check this instead of parsing [quizAvg].
  final bool hasQuizScore;
  final String lastActive;
  final String status;
  final Color statusBg;
  final bool flagged;
  final bool hasSubmission;
  /// Per assessment block: the student's weighted-percentage share of that
  /// block's [AssessmentColumn.weightage] (score / max marks * weightage),
  /// or null when it isn't graded yet.
  final Map<String, double?> assessmentScores;
  final double totalAchievedPct;
  final double totalPossiblePct;
  /// Lecturer's manual moderation adjustment (`student_courses.moderated_score`),
  /// added on top of [totalAchievedPct] to produce [finalTotalPct].
  final double moderatedScore;

  Color get statusColor => flagged ? FacultyColors.error : (status == 'Top Performer' ? FacultyColors.primary : FacultyColors.tertiary);

  /// "RAW SCORE" column: weighted marks achieved vs. total weightage.
  String get rawScoreLabel => '${_formatPct(totalAchievedPct)}%/${_formatPct(totalPossiblePct)}%';

  /// "TOTAL" column: raw score + moderation, capped at 100%.
  double get finalTotalPct => (totalAchievedPct + moderatedScore).clamp(0, 100);

  String get finalTotalLabel => '${_formatPct(finalTotalPct)}%';

  static String _formatPct(double v) => v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  RosterRow copyWithModeratedScore(double moderatedScore) => RosterRow(
        studentId: studentId,
        name: name,
        role: role,
        studentCode: studentCode,
        progress: progress,
        progressTag: progressTag,
        progressColor: progressColor,
        assignments: assignments,
        assignmentsTag: assignmentsTag,
        assignmentsTagBg: assignmentsTagBg,
        quizAvg: quizAvg,
        hasQuizScore: hasQuizScore,
        lastActive: lastActive,
        status: status,
        statusBg: statusBg,
        flagged: flagged,
        hasSubmission: hasSubmission,
        assessmentScores: assessmentScores,
        totalAchievedPct: totalAchievedPct,
        totalPossiblePct: totalPossiblePct,
        moderatedScore: moderatedScore,
      );

  const RosterRow({
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
    this.hasQuizScore = false,
    required this.lastActive,
    required this.status,
    required this.statusBg,
    this.flagged = false,
    this.hasSubmission = false,
    this.assessmentScores = const {},
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
    required double? quizAvgPercent,
    required bool hasPendingSubmission,
    required bool hasOverdueSubmission,
    Map<String, double?> assessmentScores = const {},
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
      progress: progress,
      progressTag: progressTag,
      progressColor: progressColor,
      assignments: '$gradedAssignments/$totalAssignments',
      assignmentsTag: assignmentsTag,
      assignmentsTagBg: assignmentsTagBg,
      quizAvg: '${(quizAvgPercent ?? 0).toStringAsFixed(1)}%',
      hasQuizScore: quizAvgPercent != null,
      lastActive: _formatLastActive(s.lastActivityAt),
      status: status,
      statusBg: statusBg,
      flagged: hasOverdueSubmission,
      hasSubmission: hasPendingSubmission,
      assessmentScores: assessmentScores,
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
class StudentRosterTable extends StatelessWidget {
  final List<RosterRow> rows;
  final void Function(RosterRow row, String action) onAction;
  final List<AssessmentColumn> assessmentColumns;
  final void Function(RosterRow row, double value)? onModeratedScoreSave;
  final double? minWidth;

  static const double _assessmentColWidth = 84;
  static const double _totalColWidth = 90;
  static const double _moderatedColWidth = 140;
  static const double _colGap = 16;

  const StudentRosterTable({
    super.key,
    required this.rows,
    required this.onAction,
    this.assessmentColumns = const [],
    this.onModeratedScoreSave,
    this.minWidth,
  });

  double get _resolvedMinWidth =>
      minWidth ??
      (1100 + assessmentColumns.length * (_assessmentColWidth + _colGap) + _totalColWidth + _colGap + _moderatedColWidth + _colGap);

  /// Applies one moderation value to every row at once (the header's bulk
  /// input) — each row still gets its own headroom clamp, same as an
  /// individual cell save, so no student's total can be pushed past 100%.
  void _applyBulkModeratedScore(double value) {
    final onSave = onModeratedScoreSave;
    if (onSave == null) return;
    for (final row in rows) {
      final maxAllowed = (100 - row.totalAchievedPct).clamp(0, 100);
      final clamped = value.clamp(0, maxAllowed).toDouble();
      onSave(row, clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _resolvedMinWidth,
        child: Column(
          children: [
            _headerRow(),
            for (final s in rows) _row(s),
          ],
        ),
      ),
    );
  }

  Widget _headerRow() {
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
          for (final col in assessmentColumns)
            Padding(
              padding: const EdgeInsets.only(left: _colGap),
              child: SizedBox(
                width: _assessmentColWidth,
                child: Tooltip(
                  message: col.label,
                  child: Text(col.label.toUpperCase(), style: s(), textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: _colGap),
            child: SizedBox(width: _totalColWidth, child: Text('RAW SCORE', style: s(), textAlign: TextAlign.right)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: _colGap),
            child: SizedBox(
              width: _moderatedColWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('MODERATED SCORE', style: s(), textAlign: TextAlign.right),
                  const SizedBox(height: 4),
                  _BulkModeratedScoreHeader(onApplyAll: onModeratedScoreSave == null ? null : _applyBulkModeratedScore),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: _colGap),
            child: SizedBox(width: _totalColWidth, child: Text('TOTAL', style: s(), textAlign: TextAlign.right)),
          ),
        ],
      ),
    );
  }

  Widget _row(RosterRow s) {
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
          for (final col in assessmentColumns)
            Padding(
              padding: const EdgeInsets.only(left: _colGap),
              child: SizedBox(
                width: _assessmentColWidth,
                child: Builder(builder: (context) {
                  final pct = s.assessmentScores[col.blockId] ?? 0;
                  return Text(
                    '${RosterRow._formatPct(pct)}%/${RosterRow._formatPct(col.weightage)}%',
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
          Padding(
            padding: const EdgeInsets.only(left: _colGap),
            child: SizedBox(
              width: _moderatedColWidth,
              child: _ModeratedScoreCell(
                row: s,
                onSave: onModeratedScoreSave == null ? null : (value) => onModeratedScoreSave!(s, value),
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
        ],
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
/// clamps per-student to that row's remaining headroom under 100%).
class _BulkModeratedScoreHeader extends StatefulWidget {
  final void Function(double value)? onApplyAll;

  const _BulkModeratedScoreHeader({required this.onApplyAll});

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
