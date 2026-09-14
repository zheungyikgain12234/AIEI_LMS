import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/presentation/screens/credential_detail/executive_leadership_detail_screen.dart';
import 'package:stitch_aiei_lms/presentation/screens/credential_detail/revoked_credential_detail_screen.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/enrolled_courses_catalogue_screen.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/widgets/portal_header.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/widgets/portal_sidebar.dart';
import 'controllers/badges_controller.dart';
import 'controllers/badges_state.dart';
import 'widgets/badge_stats_row.dart';
import 'widgets/earned_credential_card.dart';
import 'widgets/in_progress_badge_card.dart';

class CertificationsBadgesScreen extends ConsumerWidget {
  const CertificationsBadgesScreen({super.key});

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(badgesControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PortalHeader(onSearch: (_) {}),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PortalSidebar(
            selectedIndex: 1,
            onDestinationSelected: (index) {
              if (index == 0) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const EnrolledCoursesCatalogueScreen(),
                  ),
                );
              }
            },
          ),
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.secondary),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1440),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeaderSection(context),
                            const SizedBox(height: 32),
                            BadgeStatsRow(stats: state.stats),
                            const SizedBox(height: 48),
                            _buildSectionHeader(
                              eyebrow: 'Authenticated Proof of Mastery',
                              title: 'Earned Enterprise Credentials',
                            ),
                            const SizedBox(height: 16),
                            _buildEarnedCredentialsGrid(context, state),
                            const SizedBox(height: 48),
                            _buildSectionHeader(
                              eyebrow: 'Active Learning Trajectory',
                              title: 'In-Progress & Locked Badges',
                              trailing:
                                  '${state.inProgressBadges.length} Badges in Curriculum Queue',
                            ),
                            const SizedBox(height: 16),
                            _buildInProgressGrid(context, state),
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6)],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.start,
        spacing: 24,
        runSpacing: 24,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'My Enterprise Credentials & Badges',
                  style: AppTypography.headlineXl(),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: AppTypography.bodyLg(),
                    children: [
                      const TextSpan(
                        text: 'Verifiable cryptographic credentials, accredited digital '
                            'badges, and compliance certificates linked to employee ID ',
                      ),
                      TextSpan(
                        text: 'EMP-88219 (Alex Chen)',
                        style: AppTypography.bodyLg(color: AppColors.primary)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showToast(
                  context,
                  'Official transcript generated and ready for print archive.',
                ),
                icon: const Icon(Icons.download, size: 20),
                label: const Text('Download Transcript'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerLow,
                  foregroundColor: AppColors.onSurface,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showToast(
                  context,
                  'Public shareable profile card generated for LinkedIn.',
                ),
                icon: const Icon(Icons.share, size: 20, color: AppColors.secondary),
                label: const Text('Share All'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerLow,
                  foregroundColor: AppColors.onSurface,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String eyebrow,
    required String title,
    String? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow.toUpperCase(), style: AppTypography.labelSm(color: AppColors.onSurfaceVariant)),
              Text(title, style: AppTypography.headlineLg()),
            ],
          ),
        ),
        if (trailing != null)
          Text(trailing, style: AppTypography.labelMd(color: AppColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildEarnedCredentialsGrid(BuildContext context, BadgesState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final cards = state.earnedCredentials
            .map<Widget>(
              (credential) => EarnedCredentialCard(
                credential: credential,
                onAddToLinkedIn: () => _showToast(
                  context,
                  'Added ${credential.title} to LinkedIn profile.',
                ),
                onDownloadPdf: () => _showToast(
                  context,
                  credential.isRevoked
                      ? 'Downloading Incident Audit & Revocation Transcript PDF...'
                      : 'Downloading ${credential.title} Certificate PDF...',
                ),
                onViewIncidentNotice: () => _showToast(
                  context,
                  'Opening revocation notice for ${credential.incidentBannerText}',
                ),
                onViewLedger: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => credential.isRevoked
                        ? const RevokedCredentialDetailScreen()
                        : const ExecutiveLeadershipDetailScreen(),
                  ),
                ),
              ),
            )
            .toList();

        if (!isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 24),
                cards[i],
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 24),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _buildInProgressGrid(BuildContext context, BadgesState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100 ? 4 : (width >= 720 ? 2 : 1);
        const spacing = 16.0;
        final cardWidth = (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: state.inProgressBadges.map<Widget>((badge) {
            return SizedBox(
              width: cardWidth,
              child: InProgressBadgeCard(
                badge: badge,
                onAction: () => _showToast(context, '${badge.ctaText}: ${badge.title}'),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
