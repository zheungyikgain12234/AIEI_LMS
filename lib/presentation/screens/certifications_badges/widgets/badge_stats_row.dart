import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/domain/models/badge_stats.dart';

class BadgeStatsRow extends StatelessWidget {
  final BadgeStats? stats;

  const BadgeStatsRow({super.key, this.stats});

  @override
  Widget build(BuildContext context) {
    final s = stats;

    final totalCard = _StatCard(
      icon: Icons.military_tech,
      label: 'Total Badges Earned',
      value: '${s?.totalBadgesEarned ?? 0}',
      tag: s?.totalBadgesTag ?? '',
      tagColor: AppColors.tertiaryContainer,
      subtitle: s?.totalBadgesSubtitle ?? '',
    );

    final progressCard = _StatCard(
      icon: Icons.trending_up,
      label: 'In Progress',
      value: '${s?.inProgressCount ?? 0}',
      tag: s?.inProgressTag ?? '',
      tagColor: AppColors.secondary,
      subtitle: s?.inProgressSubtitle ?? '',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              totalCard,
              const SizedBox(height: 16),
              progressCard,
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: totalCard),
              const SizedBox(width: 16),
              Expanded(child: progressCard),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String tag;
  final Color tagColor;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.tag,
    required this.tagColor,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: AppTypography.headlineLg()),
                    const SizedBox(width: 8),
                    Text(
                      tag,
                      style: AppTypography.labelMd(color: tagColor),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTypography.bodySm()),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 24, color: AppColors.secondary),
          ),
        ],
      ),
    );
  }
}
