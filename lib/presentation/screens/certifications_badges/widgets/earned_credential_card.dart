import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/domain/models/earned_credential.dart';

class EarnedCredentialCard extends StatelessWidget {
  final EarnedCredential credential;
  final VoidCallback? onAddToLinkedIn;
  final VoidCallback? onDownloadPdf;
  final VoidCallback? onViewLedger;
  final VoidCallback? onViewIncidentNotice;

  const EarnedCredentialCard({
    super.key,
    required this.credential,
    this.onAddToLinkedIn,
    this.onDownloadPdf,
    this.onViewLedger,
    this.onViewIncidentNotice,
  });

  @override
  Widget build(BuildContext context) {
    final c = credential;
    final accent = c.isRevoked ? AppColors.error : AppColors.secondary;

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
                const SizedBox(height: 16),
                _buildCompetencies(c),
                const SizedBox(height: 24),
                Divider(
                  color: c.isRevoked
                      ? Colors.transparent
                      : AppColors.outlineVariant.withValues(alpha: 0.3),
                  height: 1,
                ),
                const SizedBox(height: 16),
                _buildFooter(c, accent),
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: c.isRevoked
                ? AppColors.surfaceContainerHigh
                : AppColors.primaryFixed,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            c.categoryTag.toUpperCase(),
            style: AppTypography.labelSm(color: AppColors.primary),
          ),
        ),
        Container(
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
              Text(
                c.statusPillText,
                style: AppTypography.labelSm(
                  color: c.isRevoked
                      ? AppColors.onErrorContainer
                      : AppColors.onSurface,
                ).copyWith(fontWeight: c.isRevoked ? FontWeight.w700 : FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
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
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.fingerprint, size: 16, color: AppColors.outline),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Hash: ${c.hash}',
                style: AppTypography.labelSm(color: AppColors.outline)
                    .copyWith(fontFamily: 'monospace'),
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
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        spacing: 8,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.report, size: 20, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                c.incidentBannerText!,
                style: AppTypography.bodySm(color: AppColors.onSurface)
                    .copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          GestureDetector(
            onTap: onViewIncidentNotice,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    c.incidentLinkText ?? '',
                    style: AppTypography.labelMd(color: AppColors.error)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 16, color: AppColors.error),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetencies(EarnedCredential c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          c.competenciesLabel.toUpperCase(),
          style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Opacity(
          opacity: c.isRevoked ? 0.6 : 1,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: c.competencies.map((label) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: AppTypography.labelSm(color: AppColors.onSurface).copyWith(
                    decoration: c.isRevoked ? TextDecoration.lineThrough : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(EarnedCredential c, Color accent) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      spacing: 12,
      runSpacing: 12,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLinkedInButton(c),
            const SizedBox(width: 8),
            _buildPdfButton(),
          ],
        ),
        GestureDetector(
          onTap: onViewLedger,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  c.footerLinkText,
                  style: AppTypography.labelMd(color: accent),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 16, color: accent),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkedInButton(EarnedCredential c) {
    if (!c.linkedInEnabled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, size: 18, color: AppColors.outline),
            const SizedBox(width: 6),
            Text(
              c.linkedInButtonText,
              style: AppTypography.labelMd(color: AppColors.outline),
            ),
          ],
        ),
      );
    }

    return TextButton.icon(
      onPressed: onAddToLinkedIn,
      style: TextButton.styleFrom(
        backgroundColor: AppColors.surfaceContainer,
        foregroundColor: AppColors.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: const Icon(Icons.post_add, size: 18, color: AppColors.secondary),
      label: Text(c.linkedInButtonText, style: AppTypography.labelMd()),
    );
  }

  Widget _buildPdfButton() {
    return GestureDetector(
      onTap: onDownloadPdf,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.picture_as_pdf,
            size: 18,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
