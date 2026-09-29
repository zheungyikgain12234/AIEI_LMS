import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/enrolled_courses_catalogue_screen.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/widgets/portal_header.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/widgets/portal_sidebar.dart';
import 'package:stitch_aiei_lms/presentation/widgets/mobile_bottom_nav.dart';
import 'package:stitch_aiei_lms/presentation/widgets/mobile_top_bar.dart';
import 'controllers/badges_controller.dart';
import 'controllers/badges_state.dart';
import 'widgets/badge_stats_row.dart';
import 'widgets/earned_credential_card.dart';

class CertificationsBadgesScreen extends ConsumerWidget {
  const CertificationsBadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(badgesControllerProvider);
    final isMobile = MediaQuery.of(context).size.width < 700;

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const MobileTopBar(),
        bottomNavigationBar: MobileBottomNav(
          selectedIndex: 1,
          onTap: (index) {
            if (index == 0) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const EnrolledCoursesCatalogueScreen()),
              );
            }
          },
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderSection(context, state, mobile: true),
                    const SizedBox(height: 20),
                    BadgeStatsRow(stats: state.stats),
                    const SizedBox(height: 32),
                    _buildSectionHeader(title: 'Earned Badges'),
                    const SizedBox(height: 16),
                    _buildEarnedCredentialsGrid(context, state),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const PortalHeader(),
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
                            _buildHeaderSection(context, state),
                            const SizedBox(height: 32),
                            BadgeStatsRow(stats: state.stats),
                            const SizedBox(height: 48),
                            _buildSectionHeader(title: 'Earned Badges'),
                            const SizedBox(height: 16),
                            _buildEarnedCredentialsGrid(context, state),
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

  Widget _buildHeaderSection(BuildContext context, BadgesState state, {bool mobile = false}) {
    return Container(
      padding: EdgeInsets.all(mobile ? 16 : 32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'My Badges',
            style: mobile ? AppTypography.headlineLg() : AppTypography.headlineXl(),
          ),
          if (state.studentCode != null) ...[
            const SizedBox(height: 8),
            Text(
              'Student ID: ${state.studentCode}',
              style: AppTypography.bodyLg(color: AppColors.primary).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    String? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text(title, style: AppTypography.headlineLg())),
        if (trailing != null)
          Text(trailing, style: AppTypography.labelMd(color: AppColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildEarnedCredentialsGrid(BuildContext context, BadgesState state) {
    if (state.earnedCredentials.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('No badges yet', style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final cards = state.earnedCredentials
            .map<Widget>((credential) => EarnedCredentialCard(credential: credential))
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

}
