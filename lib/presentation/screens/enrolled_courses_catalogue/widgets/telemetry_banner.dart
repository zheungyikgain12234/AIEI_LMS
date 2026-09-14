import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/domain/models/course_stats.dart';
import 'package:stitch_aiei_lms/domain/models/urgent_notice.dart';

class TelemetryBanner extends StatelessWidget {
  final CourseStats? stats;
  final UrgentNotice? urgentNotice;

  const TelemetryBanner({
    super.key,
    this.stats,
    this.urgentNotice,
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
                child: _UrgentNoticeAndVault(urgentNotice: urgentNotice),
              ),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MainTelemetryCard(stats: stats),
              const SizedBox(height: 24),
              _UrgentNoticeAndVault(urgentNotice: urgentNotice),
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
          enrolledCourses: 6,
          inProgressCourses: 4,
          completedCourses: 2,
          completedLessons: 24,
          totalLessons: 52,
          badgesEarned: 2,
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
                    // Top milestone tags & enterprise ID
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'CURRICULUM OVERVIEW',
                                style: AppTypography.labelSm(
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                            Text(
                              '•',
                              style: AppTypography.bodySm(
                                color: AppColors.outlineVariant,
                              ),
                            ),
                            Text(
                              'Q4 Performance Milestone',
                              style: AppTypography.labelMd(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_user,
                              size: 16,
                              color: AppColors.onTertiaryContainer,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Enterprise ID: SKL-8842-AC',
                              style: AppTypography.labelSm(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

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
                        value: '${s.completedLessons}',
                        suffix: '/${s.totalLessons}',
                        label: 'LESSONS DONE',
                        valueColor: AppColors.primary,
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

class _UrgentNoticeAndVault extends StatelessWidget {
  final UrgentNotice? urgentNotice;

  const _UrgentNoticeAndVault({this.urgentNotice});

  @override
  Widget build(BuildContext context) {
    final notice = urgentNotice ??
        const UrgentNotice(
          title: 'Corporate Cybersecurity & Phishing Defense',
          subtitle:
              'Lesson 7 Incident Escalation Simulation pending final sign-off.',
          badgeText: 'Critical Action',
          dueText: 'Due in 5 Days',
          progressPercentage: 85,
          ctaLabel: 'Resume',
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Urgent Notice Card
        Container(
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
                // Header tags
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          notice.badgeText.toUpperCase(),
                          style: AppTypography.labelSm(
                            color: AppColors.errorContainer,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        notice.dueText,
                        style: AppTypography.labelSm(color: AppColors.onError),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Title & Subtitle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notice.title,
                      style: AppTypography.headlineSm(
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notice.subtitle,
                      style: AppTypography.bodySm(
                        color: AppColors.primaryFixedDim,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Footer with progress & Resume Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${notice.progressPercentage}% Complete',
                      style: AppTypography.labelMd(
                        color: AppColors.secondaryFixed,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.onSecondary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            notice.ctaLabel,
                            style: AppTypography.labelMd(
                              color: AppColors.onSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: AppColors.onSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Credential Vault Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_outlined,
                        size: 22,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Credential Vault',
                            style: AppTypography.labelMd(color: AppColors.onSurface),
                          ),
                          Text(
                            '2 Verifiable PDF Diplomas',
                            style: AppTypography.bodySm(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerLow,
                  foregroundColor: AppColors.secondary,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Download',
                  style: AppTypography.labelMd(color: AppColors.secondary),
                ),
              ),
            ],
          ),
        ),
      ],
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
