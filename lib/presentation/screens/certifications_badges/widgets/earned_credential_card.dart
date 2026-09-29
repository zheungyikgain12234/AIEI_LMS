import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/domain/models/earned_credential.dart';

class EarnedCredentialCard extends StatelessWidget {
  final EarnedCredential credential;

  const EarnedCredentialCard({
    super.key,
    required this.credential,
  });

  @override
  Widget build(BuildContext context) {
    final c = credential;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: c.isRevoked ? Border.all(color: AppColors.error, width: 2) : null,
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopTagBar(c),
                const SizedBox(height: 16),
                _buildContentRow(c),
                if (c.incidentBannerText != null) ...[
                  const SizedBox(height: 16),
                  _buildIncidentBanner(c),
                ],
              ],
            ),
          ),
          if (c.isRevoked) _buildRevokedRibbon(),
        ],
      ),
    );
  }

  Widget _buildRevokedRibbon() {
    return Positioned(
      top: 24,
      right: -40,
      child: Transform.rotate(
        angle: math.pi / 4,
        child: Container(
          width: 160,
          padding: const EdgeInsets.symmetric(vertical: 4),
          color: AppColors.error,
          alignment: Alignment.center,
          child: Text(
            'REVOKED',
            textAlign: TextAlign.center,
            style: AppTypography.labelSm(color: AppColors.onError)
                .copyWith(letterSpacing: 2, fontSize: 11),
          ),
        ),
      ),
    );
  }

  Widget _buildTopTagBar(EarnedCredential c) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: c.isRevoked
              ? AppColors.errorContainer
              : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(999),
          border: c.isRevoked
              ? Border.all(color: AppColors.error.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              c.statusPillIcon,
              size: 16,
              color: c.isRevoked ? AppColors.error : AppColors.secondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                c.statusPillText,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSm(
                  color: c.isRevoked
                      ? AppColors.onErrorContainer
                      : AppColors.onSurface,
                ).copyWith(fontWeight: c.isRevoked ? FontWeight.w700 : FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentRow(EarnedCredential c) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 420;
        final emblem = _buildEmblem(c);
        final details = _buildDetails(c);

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [emblem, const SizedBox(height: 16), details],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            emblem,
            const SizedBox(width: 24),
            Expanded(child: details),
          ],
        );
      },
    );
  }

  Widget _buildEmblem(EarnedCredential c) {
    final gradientColors = c.isRevoked
        ? [AppColors.error, AppColors.errorContainer, AppColors.outline]
        : [AppColors.primary, AppColors.secondary, AppColors.primaryContainer];

    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        children: [
          Positioned.fill(
            child: Transform.rotate(
              angle: c.isRevoked ? 0.05 : -0.05,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            left: 6,
            right: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: c.isRevoked
                    ? Border.all(color: AppColors.error.withValues(alpha: 0.3))
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: c.isRevoked
                          ? AppColors.errorContainer
                          : AppColors.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      c.emblemIcon,
                      size: 20,
                      color: c.isRevoked ? AppColors.error : AppColors.primary,
                    ),
                  ),
                  Text(
                    c.emblemCode,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSm(
                      color: c.isRevoked ? AppColors.error : AppColors.primary,
                    ).copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      decoration:
                          c.isRevoked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(
                    c.emblemSubtext,
                    style: AppTypography.bodySm(
                      color: c.isRevoked
                          ? AppColors.error
                          : AppColors.onSurfaceVariant,
                    ).copyWith(
                      fontSize: 10,
                      fontWeight: c.isRevoked ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(EarnedCredential c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                c.title,
                style: AppTypography.headlineMd(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (c.titleChipText != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  c.titleChipText!.toUpperCase(),
                  style: AppTypography.labelSm(color: AppColors.error)
                      .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          c.description,
          style: AppTypography.bodySm(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(c.metaIcon, size: 16, color: c.isRevoked ? AppColors.error : AppColors.secondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                c.metaText,
                style: AppTypography.labelSm(
                  color: c.isRevoked ? AppColors.error : AppColors.primary,
                ).copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIncidentBanner(EarnedCredential c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.report, size: 20, color: AppColors.error),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              c.incidentBannerText!,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: AppTypography.bodySm(color: AppColors.onSurface)
                  .copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
