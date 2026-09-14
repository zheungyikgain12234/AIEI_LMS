import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/domain/models/in_progress_badge.dart';

class InProgressBadgeCard extends StatefulWidget {
  final InProgressBadge badge;
  final VoidCallback? onAction;

  const InProgressBadgeCard({
    super.key,
    required this.badge,
    this.onAction,
  });

  @override
  State<InProgressBadgeCard> createState() => _InProgressBadgeCardState();
}

class _InProgressBadgeCardState extends State<InProgressBadgeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.badge;
    final hasModuleCount = b.totalModules > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: b.iconBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(b.icon, size: 22, color: b.iconColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: b.isUrgent
                      ? AppColors.errorContainer
                      : AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  b.statusChipText,
                  style: AppTypography.labelSm(
                    color: b.isUrgent
                        ? AppColors.onErrorContainer
                        : AppColors.onSurface,
                  ).copyWith(fontWeight: b.isUrgent ? FontWeight.w700 : FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(b.title, style: AppTypography.headlineSm()),
          const SizedBox(height: 4),
          Text(b.description, style: AppTypography.bodySm(), maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Modules', style: AppTypography.labelSm(color: AppColors.onSurfaceVariant)),
              Text(
                hasModuleCount
                    ? '${b.completedModules} / ${b.totalModules} Complete'
                    : '${b.progressPercent}% Complete',
                style: AppTypography.labelSm(color: AppColors.primary)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: b.progressPercent / 100,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainer,
              valueColor: AlwaysStoppedAnimation<Color>(b.progressColor),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: AppColors.onTertiaryContainer),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        b.checklistDoneText,
                        style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(b.checklistPendingIcon, size: 14, color: b.checklistPendingColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        b.checklistPendingText,
                        style: AppTypography.labelSm(color: b.checklistPendingColor).copyWith(
                          fontWeight: b.isUrgent ? FontWeight.w600 : FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTap: widget.onAction,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isHovered ? AppColors.secondary : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      b.ctaText,
                      style: AppTypography.labelMd(
                        color: _isHovered ? AppColors.onSecondary : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: _isHovered ? AppColors.onSecondary : AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
