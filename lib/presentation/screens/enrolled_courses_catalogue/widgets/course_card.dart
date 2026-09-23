import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/domain/models/enrolled_course.dart';

class CourseCard extends StatefulWidget {
  final EnrolledCourse course;
  final VoidCallback? onAction;

  const CourseCard({
    super.key,
    required this.course,
    this.onAction,
  });

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.course;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? const Color(0x1A000000)
                  : const Color(0x0A000000),
              blurRadius: _isHovered ? 16 : 8,
              offset: Offset(0, _isHovered ? 6 : 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Section (Media + Title + Instructor + Progress + Badge)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Media Thumbnail with Gradient & Overlays
                _buildThumbnail(c),

                const SizedBox(height: 16),

                // Title
                Text(
                  c.title,
                  style: AppTypography.headlineSm(
                    color: _isHovered
                        ? AppColors.secondary
                        : AppColors.primary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Instructor / Division + Class Code
                Row(
                  children: [
                    Icon(
                      c.instructorIcon,
                      size: 16,
                      color: c.instructorIconColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Instructor: ${c.instructorOrBoard}',
                        style: AppTypography.bodySm(
                          color: AppColors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (c.classCode != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          c.classCode!,
                          style: AppTypography.labelSm(color: AppColors.onSurfaceVariant).copyWith(fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // Progress Telemetry Panel
                _buildProgressPanel(c),

                const SizedBox(height: 12),

                // Earnable / Earned Badge Preview Snippet
                _buildBadgeSnippet(c),
              ],
            ),

            const SizedBox(height: 16),

            // Bottom CTA Button
            _buildCtaButton(c),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(EnrolledCourse c) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          // Background Image
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Image.network(
              c.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.surfaceContainerHigh,
                child: const Center(
                  child: Icon(
                    Icons.school,
                    size: 48,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ),
          ),

          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x33091426),
                    Color(0xCC091426),
                  ],
                ),
              ),
            ),
          ),

          // Top Badges
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: c.tags.map((tag) {
                // Fixed amber/black styling for every tag shown on the
                // thumbnail, regardless of the tag's own stored color —
                // keeps the catalogue cards visually consistent.
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (tag.hasCheckIcon) ...[
                        const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        tag.label,
                        style: AppTypography.labelSm(
                          color: Colors.black,
                        ).copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Bottom Media Metadata (Time, Track, Score, or Urgency)
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (c.durationText != null)
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            c.durationText!,
                            style: AppTypography.labelSm(
                              color: Colors.white,
                            ).copyWith(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox.shrink(),
                if (c.trackTypeText != null)
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.military_tech,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            c.trackTypeText!,
                            style: AppTypography.labelSm(
                              color: Colors.white,
                            ).copyWith(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (c.scoreText != null)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: c.isCompleted
                            ? const Color(0xE6FFFFFF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        c.scoreText!,
                        style: AppTypography.labelSm(
                          color: c.isCompleted
                              ? AppColors.onTertiaryContainer
                              : Colors.white,
                        ).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPanel(EnrolledCourse c) {
    final isDone = c.isCompleted;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isDone ? 'Fully Completed' : 'In Progress',
                  style: AppTypography.labelSm(
                    color: isDone
                        ? AppColors.onTertiaryContainer
                        : AppColors.onSurfaceVariant,
                  ).copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${c.progressPercentage}%',
                style: AppTypography.labelSm(
                  color: AppColors.primary,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Linear Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: c.progressPercentage / 100,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDone
                    ? AppColors.onTertiaryContainer
                    : AppColors.secondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeSnippet(EnrolledCourse c) {
    if (c.badgeCount == 0) return const SizedBox.shrink();
    return Tooltip(
      message: c.badgeNames.join(', '),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.isCompleted
              ? AppColors.surfaceContainerHigh.withValues(alpha: 0.6)
              : AppColors.surfaceContainerHigh.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.military_tech_outlined,
              size: 18,
              color: c.isCompleted
                  ? AppColors.onTertiaryContainer
                  : AppColors.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              '${c.badgeCount} Badge${c.badgeCount == 1 ? '' : 's'} to Unlock',
              style: AppTypography.labelSm(
                color: AppColors.onSurface,
              ).copyWith(
                fontWeight: c.isCompleted ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCtaButton(EnrolledCourse c) {
    if (c.isCompleted) {
      return OutlinedButton(
        onPressed: widget.onAction,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surfaceContainerLow,
          foregroundColor: AppColors.secondary,
          side: BorderSide.none,
          minimumSize: const Size(double.infinity, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified, size: 16),
            const SizedBox(width: 6),
            Text(
              c.ctaButtonText,
              style: AppTypography.labelMd(color: AppColors.secondary),
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: widget.onAction,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.onSecondary,
        elevation: 0,
        minimumSize: const Size(double.infinity, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            c.ctaButtonText,
            style: AppTypography.labelMd(color: AppColors.onSecondary),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_forward, size: 16),
        ],
      ),
    );
  }
}
