import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/domain/models/course_stats.dart';
import 'package:stitch_aiei_lms/domain/models/critical_action_item.dart';

class TelemetryBanner extends StatelessWidget {
  final CourseStats? stats;
  final List<CriticalActionItem> criticalActions;
  final ValueChanged<CriticalActionItem>? onOpenAction;

  const TelemetryBanner({
    super.key,
    this.stats,
    this.criticalActions = const [],
    this.onOpenAction,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1024;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 8,
                child: _MainTelemetryCard(stats: stats),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 4,
                child: _CriticalActionsCard(actions: criticalActions, onOpenAction: onOpenAction),
              ),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MainTelemetryCard(stats: stats),
              const SizedBox(height: 24),
              _CriticalActionsCard(actions: criticalActions, onOpenAction: onOpenAction),
            ],
          );
        }
      },
    );
  }
}

class _MainTelemetryCard extends StatelessWidget {
  final CourseStats? stats;

  const _MainTelemetryCard({this.stats});

  @override
  Widget build(BuildContext context) {
    final s = stats ??
        const CourseStats(
          enrolledCourses: 0,
          inProgressCourses: 0,
          completedCourses: 0,
          badgesEarned: 0,
        );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background ambient blur & subtle telemetry curve
          Positioned(
            right: -60,
            top: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 48,
            bottom: 24,
            child: Opacity(
              opacity: 0.12,
              child: CustomPaint(
                size: const Size(220, 100),
                painter: _TelemetryCurvePainter(),
              ),
            ),
          ),

          // Main Foreground Content
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Headline
                    Text(
                      'My Enrolled Courses',
                      style: AppTypography.headlineLg(color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle description
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 672),
                      child: Text(
                        'Track real-time completion telemetry, verifiable enterprise credentials, and urgent regulatory compliance windows across your active cohort assignments.',
                        style: AppTypography.bodyMd(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Metric Pill Counter Row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricItem(
                        value: '${s.enrolledCourses}',
                        label: 'ENROLLED COURSES',
                        valueColor: AppColors.primary,
                      ),
                      _buildDivider(),
                      _buildMetricItem(
                        value: '${s.inProgressCourses}',
                        label: 'IN PROGRESS',
                        valueColor: AppColors.secondary,
                        icon: Icons.pending_outlined,
                        iconColor: AppColors.secondary,
                      ),
                      _buildDivider(),
                      _buildMetricItem(
                        value: '${s.completedCourses}',
                        label: 'COMPLETED',
                        valueColor: AppColors.onTertiaryContainer,
                        icon: Icons.check_circle_outline,
                        iconColor: AppColors.onTertiaryContainer,
                      ),
                      _buildDivider(),
                      _buildMetricItem(
                        value: '${s.badgesEarned}',
                        label: 'BADGES EARNED',
                        valueColor: AppColors.secondaryContainer,
                        icon: Icons.military_tech_outlined,
                        iconColor: AppColors.secondaryContainer,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.surfaceContainerHigh,
    );
  }

  Widget _buildMetricItem({
    required String value,
    String? suffix,
    required String label,
    required Color valueColor,
    IconData? icon,
    Color? iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: AppTypography.headlineLg(color: valueColor).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (suffix != null)
              Text(
                suffix,
                style: AppTypography.bodyMd(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 18, color: iconColor),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSm(
            color: AppColors.onSurfaceVariant,
          ).copyWith(
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

/// Real "what needs my attention next" box — the two ungraded assignments/
/// quizzes (across every enrolled course) with the nearest due dates,
/// replacing the old fabricated single-course "Urgent Notice" + Credential
/// Vault combo.
class _CriticalActionsCard extends StatelessWidget {
  final List<CriticalActionItem> actions;
  final ValueChanged<CriticalActionItem>? onOpenAction;

  const _CriticalActionsCard({required this.actions, this.onOpenAction});

  String _dueText(CriticalActionItem item) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(item.dueDate.year, item.dueDate.month, item.dueDate.day);
    final diff = due.difference(today).inDays;
    if (diff < 0) return 'Overdue by ${-diff} Day${-diff == 1 ? '' : 's'}';
    if (diff == 0) return 'Due Today';
    return 'Due in $diff Day${diff == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'CRITICAL ACTION',
                style: AppTypography.labelSm(color: AppColors.errorContainer),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (actions.isEmpty)
            Text(
              'Nothing due — every assignment and quiz is submitted.',
              style: AppTypography.bodySm(color: AppColors.primaryFixedDim),
            )
          else
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _actionRow(actions[i]),
            ],
        ],
      ),
    );
  }

  Widget _actionRow(CriticalActionItem item) {
    final isExam = item.type == 'exam';
    return InkWell(
      onTap: onOpenAction == null ? null : () => onOpenAction!(item),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(isExam ? Icons.quiz_outlined : Icons.assignment_outlined, size: 18, color: AppColors.secondaryFixed),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.bodyMd(color: AppColors.onPrimary).copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.courseTitle,
                    style: AppTypography.bodySm(color: AppColors.primaryFixedDim),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(4)),
              child: Text(_dueText(item), style: AppTypography.labelSm(color: AppColors.onError)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TelemetryCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(10, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.1,
      size.width * 0.5,
      size.height * 0.55,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.9,
      size.width * 0.95,
      size.height * 0.25,
    );

    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.55),
      6,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.95, size.height * 0.25),
      8,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
