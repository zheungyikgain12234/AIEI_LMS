import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/domain/models/enrolled_course.dart';

/// Vertical, full-width course card used on the mobile (small-screen) layout
/// of the enrolled courses catalogue — mirrors the Stitch mobile mockup.
class MobileCourseCard extends StatelessWidget {
  final EnrolledCourse course;
  final VoidCallback? onAction;

  const MobileCourseCard({super.key, required this.course, this.onAction});

  @override
  Widget build(BuildContext context) {
    final c = course;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImage(c),
          const SizedBox(height: 8),
          Text(c.title, style: AppTypography.headlineSm(color: AppColors.primary)),
          const SizedBox(height: 6),
          _buildInfoRow(c),
          const SizedBox(height: 8),
          _buildStatusPanel(c),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                c.isCompleted
                    ? 'Certified • Verified'
                    : (c.isWarningNextLesson ? 'Due in ${c.deadlineDays} days' : 'In progress'),
                style: AppTypography.labelSm(
                  color: c.isWarningNextLesson ? AppColors.error : AppColors.outline,
                ).copyWith(fontWeight: c.isWarningNextLesson ? FontWeight.w700 : FontWeight.w400),
              ),
              _buildCtaButton(context, c),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImage(EnrolledCourse c) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 144,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              c.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.surfaceContainerHigh,
                child: const Center(child: Icon(Icons.school, size: 40, color: AppColors.secondary)),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x4D091426), Color(0xE6091426)],
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in c.tags)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: tag.backgroundColor, borderRadius: BorderRadius.circular(9999)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (tag.hasCheckIcon) ...[
                            Icon(Icons.check, size: 11, color: tag.textColor),
                            const SizedBox(width: 3),
                          ],
                          Text(tag.label, style: AppTypography.labelSm(color: tag.textColor).copyWith(fontSize: 10)),
                        ],
                      ),
                    ),
                  if (c.durationText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xE6FFFFFF), borderRadius: BorderRadius.circular(9999)),
                      child: Text(c.durationText!, style: AppTypography.labelSm(color: AppColors.onSurface).copyWith(fontSize: 10)),
                    ),
                ],
              ),
            ),
            if (c.isCompleted && c.scoreText != null)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xE6FFFFFF), borderRadius: BorderRadius.circular(9999)),
                  child: Text(c.scoreText!, style: AppTypography.labelSm(color: AppColors.onTertiaryContainer).copyWith(fontSize: 10)),
                ),
              ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(c.isCompleted ? Icons.verified : Icons.play_circle_outline, size: 14, color: const Color(0xFF6FFBBE)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            c.isCompleted ? '${c.completedLessons}/${c.totalLessons} Lessons Validated' : c.category.label,
                            style: AppTypography.labelSm(color: Colors.white).copyWith(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!c.isCompleted)
                    Text('${c.completedLessons}/${c.totalLessons} Lessons',
                        style: AppTypography.labelSm(color: const Color(0xFF6FFBBE)).copyWith(fontSize: 10, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(EnrolledCourse c) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
      child: c.isCompleted
          ? Row(
              children: [
                Icon(c.unlockBadgeIcon, size: 18, color: AppColors.onTertiaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(c.unlockBadgeTitle, style: AppTypography.bodySm(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.w600)),
                ),
                Text('VERIFIED', style: AppTypography.labelSm(color: AppColors.secondary).copyWith(fontWeight: FontWeight.w700)),
              ],
            )
          : Row(
              children: [
                const Icon(Icons.fast_forward, size: 16, color: AppColors.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                      children: [
                        TextSpan(text: 'Next: ', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                        TextSpan(text: c.nextLessonOrStatus.replaceFirst('Next: ', '')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusPanel(EnrolledCourse c) {
    if (c.isCompleted) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(color: AppColors.tertiaryContainer, shape: BoxShape.circle),
              child: const Icon(Icons.verified, size: 16, color: Color(0xFF6FFBBE)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Digital Credential Issued', style: AppTypography.labelMd(color: AppColors.primary)),
                  Text('AIEI Reg #${c.id.toUpperCase()}', style: AppTypography.bodySm()),
                ],
              ),
            ),
            Text('100%', style: AppTypography.headlineSm(color: AppColors.onTertiaryContainer)),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Course Progress', style: AppTypography.labelSm(color: AppColors.onSurfaceVariant)),
              Text('${c.progressPercentage}%', style: AppTypography.labelSm(color: AppColors.secondary).copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: c.progressPercentage / 100,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaButton(BuildContext context, EnrolledCourse c) {
    if (c.isCompleted) {
      return OutlinedButton.icon(
        onPressed: onAction,
        icon: const Icon(Icons.badge_outlined, size: 16),
        label: Text(c.ctaButtonText, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surfaceContainerLow,
          foregroundColor: AppColors.secondary,
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: AppTypography.labelMd(),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onAction,
      icon: const Icon(Icons.arrow_forward, size: 16),
      label: Text(c.ctaButtonText),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.onSecondary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: AppTypography.labelMd(),
      ),
    );
  }
}
