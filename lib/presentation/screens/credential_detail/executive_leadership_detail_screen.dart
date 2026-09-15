import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/enrolled_courses_catalogue_screen.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/widgets/portal_header.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/widgets/portal_sidebar.dart';
import 'package:stitch_aiei_lms/presentation/screens/certifications_badges/certifications_badges_screen.dart';
import 'package:stitch_aiei_lms/presentation/widgets/mobile_bottom_nav.dart';

const _linkedInBlue = Color(0xFF0A66C2);
const _gold300 = Color(0xFFFCD34D);
const _gold400 = Color(0xFFFBBF24);
const _emerald600 = Color(0xFF059669);

class ExecutiveLeadershipDetailScreen extends StatelessWidget {
  const ExecutiveLeadershipDetailScreen({super.key});

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
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceContainerLowest,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          ),
          title: Text('Credential Details', style: AppTypography.headlineSm(color: AppColors.onSurface)),
        ),
        bottomNavigationBar: MobileBottomNav(
          selectedIndex: 1,
          onTap: (index) {
            if (index == 0) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const EnrolledCoursesCatalogueScreen()),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const CertificationsBadgesScreen()),
              );
            }
          },
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBreadcrumbBar(context),
              const SizedBox(height: 16),
              _buildHeroCard(context, mobile: true),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    }

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildBreadcrumbBar(context),
                      const SizedBox(height: 24),
                      _buildHeroCard(context),
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

  Widget _buildBreadcrumbBar(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back, size: 18, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Back to Certifications & Badges',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMd(color: AppColors.onSurfaceVariant)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _showToast(
                context,
                'Public shareable profile card generated for LinkedIn.',
              ),
              icon: const Icon(Icons.share, size: 16, color: AppColors.onSurfaceVariant),
              label: const Text('Share Credential'),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.surfaceContainerLowest,
                foregroundColor: AppColors.onSurface,
                side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: AppTypography.labelMd(),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _showToast(
                context,
                'Downloading Official Executive Leadership Communicator Certificate PDF...',
              ),
              icon: const Icon(Icons.download, size: 16, color: AppColors.onSurfaceVariant),
              label: const Text('Download Official Certificate (PDF)'),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.surfaceContainerLowest,
                foregroundColor: AppColors.onSurface,
                side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: AppTypography.labelMd(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context, {bool mobile = false}) {
    return Container(
      padding: EdgeInsets.all(mobile ? 16 : 32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8)],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final left = _buildEmblemColumn(context);
          final right = _buildDetailsColumn();

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [left, const SizedBox(height: 32), right],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 320, child: left),
              const SizedBox(width: 32),
              Expanded(child: right),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmblemColumn(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBadgeEmblem(),
          const SizedBox(height: 16),
          Text(
            'Issued: Oct 24, 2024 • Expiration: Lifetime Credential',
            textAlign: TextAlign.center,
            style: AppTypography.bodySm(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showToast(context, 'Added Executive Leadership Communicator to LinkedIn profile.'),
              icon: const Icon(Icons.link, size: 18),
              label: const Text('Add to LinkedIn Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _linkedInBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: AppTypography.labelMd(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showToast(context, 'Embed code copied to clipboard.'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerLowest,
                    foregroundColor: AppColors.onSurface,
                    side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text('</> Copy Embed Code', style: AppTypography.labelSm(color: AppColors.onSurface)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showToast(context, 'Exporting badge as SVG / PNG...'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerLowest,
                    foregroundColor: AppColors.onSurface,
                    side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text('Export SVG / PNG', style: AppTypography.labelSm(color: AppColors.onSurface)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeEmblem() {
    return Container(
      width: 192,
      height: 230,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const RadialGradient(
          center: Alignment(-0.4, -0.6),
          radius: 1.1,
          colors: [AppColors.secondary, AppColors.primary, AppColors.onSurface],
          stops: [0.0, 0.6, 1.0],
        ),
        border: Border.all(color: AppColors.secondaryFixedDim.withValues(alpha: 0.4), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: AppColors.tertiaryFixed, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'VERIFIED',
                    style: AppTypography.labelSm(color: AppColors.secondaryFixedDim).copyWith(fontSize: 10),
                  ),
                ],
              ),
              Text(
                'OCT 2024',
                style: AppTypography.labelSm(color: AppColors.secondaryFixedDim).copyWith(fontSize: 10),
              ),
            ],
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.diversity_3, size: 40, color: _gold300),
          ),
          Column(
            children: [
              Text(
                'EXEC-COMM',
                style: AppTypography.labelMd(color: _gold300).copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
              Text(
                'LEADERSHIP COHORT',
                style: AppTypography.bodySm(color: AppColors.surfaceContainerHigh).copyWith(fontSize: 10),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: _gold400, borderRadius: BorderRadius.circular(4)),
            child: Text(
              '★ Top 5% Cohort Score',
              textAlign: TextAlign.center,
              style: AppTypography.labelSm(color: AppColors.onSurface).copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primaryFixed,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 2,
            children: [
              Text('Executive Leadership Track', style: AppTypography.labelSm(color: AppColors.secondary)),
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)),
              Text('Cohort Fall 2024', style: AppTypography.labelSm(color: AppColors.secondary)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text('Executive Leadership Communicator', style: AppTypography.headlineXl()),
        const SizedBox(height: 4),
        Text(
          'Enterprise Leadership & Strategic Influence Mastery Program',
          style: AppTypography.bodyLg(color: AppColors.secondary).copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            style: AppTypography.bodySm(),
            children: [
              const TextSpan(text: 'Accredited by '),
              TextSpan(
                text: 'AIEI Executive Leadership Academy',
                style: AppTypography.bodySm(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: ' & '),
              TextSpan(
                text: 'Wharton Executive Education Partner Alliance',
                style: AppTypography.bodySm(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildMetricsBar(),
        const SizedBox(height: 20),
        Text(
          'This credential certifies that Alex Chen (EMP-88219) has demonstrated exceptional '
          'executive presence, strategic narrative design, and high-impact negotiation in '
          'mission-critical corporate settings.',
          style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Text(
          'Completion required passing four intensive boardroom simulation defenses before an '
          'executive panel, managing multi-tier crisis communications scenarios, and synthesizing '
          'complex enterprise initiatives into actionable operational roadmaps for C-suite '
          'stakeholders.',
          style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.4))),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text('Core Focus:', style: AppTypography.labelSm(color: AppColors.outline)),
              _focusPill('Boardroom Presentations'),
              _focusPill('Crisis Communications'),
              _focusPill('Cross-Functional Negotiation'),
              _focusPill('Executive Presence'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _focusPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: AppTypography.labelSm(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildMetricsBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        children: [
          _metricTile('Cohort Standing', 'Top 5%', 'Score: 98.4 / 100', _emerald600),
          _metricTile('Capstone Defense', 'Distinction', 'Unanimous Board Pass', AppColors.onSurfaceVariant),
          _metricTile('Learning Hours', '16.0 Hours', 'Accredited Units', AppColors.secondary),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, String caption, Color captionColor) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(), style: AppTypography.labelSm(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(value, style: AppTypography.headlineSm()),
          Text(caption, style: AppTypography.labelSm(color: captionColor).copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
