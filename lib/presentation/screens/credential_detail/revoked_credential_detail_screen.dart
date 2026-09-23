import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/domain/models/earned_credential.dart';
import 'package:stitch_aiei_lms/domain/models/student.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/enrolled_courses_catalogue_screen.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/widgets/portal_header.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/widgets/portal_sidebar.dart';
import 'package:stitch_aiei_lms/presentation/screens/certifications_badges/certifications_badges_screen.dart';
import 'package:stitch_aiei_lms/presentation/widgets/mobile_bottom_nav.dart';

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime date) => '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';

String _formatDateTime(DateTime date) {
  final hour24 = date.hour;
  final period = hour24 >= 12 ? 'PM' : 'AM';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  return '${_formatDate(date)} ($hour12:$minute $period)';
}

class RevokedCredentialDetailScreen extends StatelessWidget {
  const RevokedCredentialDetailScreen({super.key, required this.credential});

  final EarnedCredential credential;

  Future<Student> _fetchStudent() async {
    final row = await Supabase.instance.client
        .from('students')
        .select()
        .eq('id', DemoIdentity.studentId)
        .single();
    return Student.fromMap(row);
  }

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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, size: 18, color: AppColors.onSurface),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Back to Certifications & Badges',
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMd().copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 2,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(
                        'REVOKED / CONFISCATED',
                        style: AppTypography.labelSm(color: AppColors.error).copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  Text(
                    credential.caseRef != null ? '#${credential.caseRef}' : '',
                    style: AppTypography.labelMd(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _showToast(context, 'Exporting incident audit transcript...'),
              icon: const Icon(Icons.print, size: 16, color: AppColors.onSurfaceVariant),
              label: const Text('Export Transcript'),
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
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8)],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final left = _buildEmblemColumn();
          final right = _buildDetailsColumn();

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [left, const SizedBox(height: 32), right],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 280, child: left),
              const SizedBox(width: 32),
              Expanded(child: right),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmblemColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.surfaceContainerLow, AppColors.surfaceContainer.withValues(alpha: 0.6)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 168,
                    height: 168,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outline.withValues(alpha: 0.5), width: 1.5),
                    ),
                    child: Opacity(
                      opacity: 0.5,
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.matrix(<double>[
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0, 0, 0, 1, 0,
                        ]),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(color: AppColors.outlineVariant.withValues(alpha: 0.6), shape: BoxShape.circle),
                              child: const Icon(Icons.shield_moon, size: 42, color: AppColors.outline),
                            ),
                            const SizedBox(height: 6),
                            Text(credential.emblemCode, style: AppTypography.headlineSm(color: AppColors.onSurfaceVariant)),
                            Text(
                              'TIER-1 FIELD SPEC',
                              style: AppTypography.labelSm(color: AppColors.outline),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.do_not_disturb_on, size: 16, color: AppColors.onError),
                        const SizedBox(width: 6),
                        Text(
                          'VOIDED CREDENTIAL',
                          style: AppTypography.labelMd(color: AppColors.onError).copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5))),
                    ),
                    child: Column(
                      children: [
                        _idRow('Credential ID:', 'CSO-88219-NA'),
                        const SizedBox(height: 4),
                        _idRow('Original Tier:', 'Level 3 Specialist'),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 30,
                left: -48,
                right: -48,
                child: Transform.rotate(
                  angle: -25 * math.pi / 180,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    color: AppColors.error,
                    alignment: Alignment.center,
                    child: Text(
                      'REVOKED',
                      style: AppTypography.headlineSm(color: AppColors.onError).copyWith(
                        letterSpacing: 4,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _idRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: AppTypography.bodySm().copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySm(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.w700, fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _tag('Tier-1 Operational Level', AppColors.surfaceContainer, AppColors.onSurfaceVariant),
            _tag(
              credential.revokedAt != null
                  ? 'Confiscated ${_formatDate(credential.revokedAt!)}'
                  : 'Confiscated',
              AppColors.errorContainer,
              AppColors.onErrorContainer,
            ),
            _tag(
              'Field Privileges Suspended',
              AppColors.error.withValues(alpha: 0.1),
              AppColors.error,
              icon: Icons.lock,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(credential.title, style: AppTypography.headlineXl()),
        const SizedBox(height: 6),
        Text(
          'Accredited by ${credential.accreditingBodies.join(' & ')}',
          style: AppTypography.bodyLg(),
        ),
        const SizedBox(height: 16),
        _buildMetadataGrid(),
        const SizedBox(height: 16),
        _buildReasonBox(),
      ],
    );
  }

  Widget _tag(String label, Color bg, Color fg, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSm(color: fg).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataGrid() {
    return FutureBuilder<Student>(
      future: _fetchStudent(),
      builder: (context, snapshot) {
        final student = snapshot.data;
        final issuedTo = student != null ? '${student.name} (${student.studentCode})' : '';

        final entries = [
          ['ISSUED TO', issuedTo, false],
          [
            'ORIGINAL ISSUE DATE',
            credential.issuedAt != null ? _formatDate(credential.issuedAt!) : '',
            false,
          ],
          [
            'ORIGINAL EXPIRY DATE',
            credential.expiresAt != null ? _formatDate(credential.expiresAt!) : '',
            true,
          ],
          [
            'REVOCATION EFFECTIVE',
            credential.revokedAt != null ? _formatDateTime(credential.revokedAt!) : '',
            false,
          ],
          ['INSPECTING OFFICER', credential.inspectingOfficer ?? '', false],
          ['CASE REFERENCE', credential.caseRef != null ? '#${credential.caseRef}' : '', false],
        ];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            children: entries.map((e) {
              final label = e[0] as String;
              final value = e[1] as String;
              final strike = e[2] as bool;
              final isRevocation = label == 'REVOCATION EFFECTIVE';
              final isCaseRef = label == 'CASE REFERENCE';
              return SizedBox(
                width: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: AppTypography.labelSm(color: AppColors.outline)),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: AppTypography.bodySm(
                        color: isRevocation
                            ? AppColors.error
                            : isCaseRef
                                ? AppColors.secondary
                                : AppColors.onSurface,
                      ).copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: strike ? TextDecoration.lineThrough : null,
                        fontFamily: isCaseRef ? 'monospace' : null,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildReasonBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: AppColors.error, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, size: 22, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Official Reason for Credential Revocation',
                  style: AppTypography.headlineSm(color: AppColors.onErrorContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            credential.incidentBannerText ?? 'No revocation reason on record.',
            style: AppTypography.bodyMd(color: AppColors.onErrorContainer),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.no_accounts, size: 18, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Access Suspended: Physical NFC Badge & High-Hazard Zone Clearance Frozen.',
                  style: AppTypography.labelMd(color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
