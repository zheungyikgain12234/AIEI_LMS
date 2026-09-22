import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/domain/models/roster_student.dart';

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
  final String lastActive;
  final String status;
  final Color statusBg;
  final bool flagged;
  final bool hasSubmission;

  Color get statusColor =>
      status == 'Needs Review' ? FacultyColors.onErrorContainer : (status == 'Top Performer' ? FacultyColors.primary : FacultyColors.tertiary);

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
    required this.lastActive,
    required this.status,
    required this.statusBg,
    this.flagged = false,
    this.hasSubmission = false,
  });

  /// [progress] is the student's graded-submission coverage across every
  /// exam/assignment content block in the class (graded / total, as a
  /// percentage) — computed by the caller from `content_block_submissions`.
  /// [totalAssignments]/[gradedAssignments] are the assignment-only subset
  /// of that same count; [quizAvgPercent] is the average score (as a
  /// percentage of each exam's total marks) across the student's graded
  /// exam submissions, or null if none are graded yet.
  factory RosterRow.fromRoster(
    RosterStudent s, {
    required int progress,
    required int totalAssignments,
    required int gradedAssignments,
    required double? quizAvgPercent,
    required bool hasPendingSubmission,
  }) {
    final (progressTag, progressColor) = _paceFor(s.riskStatus);
    final (status, statusBg) = _standingFor(s.riskStatus);

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
    } else if (s.riskStatus == 'critical') {
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
      quizAvg: quizAvgPercent != null ? '${quizAvgPercent.toStringAsFixed(1)}%' : '—',
      lastActive: _formatLastActive(s.lastActivityAt),
      status: status,
      statusBg: statusBg,
      flagged: s.riskStatus == 'critical',
      hasSubmission: hasPendingSubmission,
    );
  }

  static (String, Color) _paceFor(String riskStatus) {
    switch (riskStatus) {
      case 'critical':
        return ('Stalled', FacultyColors.error);
      case 'at_risk':
        return ('Behind', FacultyColors.secondary);
      default:
        return ('On Pace', FacultyColors.tertiary);
    }
  }

  static (String, Color) _standingFor(String riskStatus) {
    switch (riskStatus) {
      case 'critical':
        return ('Needs Review', FacultyColors.errorContainer);
      case 'at_risk':
        return ('Behind Schedule', FacultyColors.surfaceContainer);
      default:
        return ('On Track', FacultyColors.surfaceContainer);
    }
  }

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
  final double minWidth;

  const StudentRosterTable({super.key, required this.rows, required this.onAction, this.minWidth = 1100});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: minWidth,
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
          const SizedBox(width: 32),
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
          SizedBox(
            width: 32,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18, color: FacultyColors.secondary),
              onSelected: (action) => onAction(s, action),
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
