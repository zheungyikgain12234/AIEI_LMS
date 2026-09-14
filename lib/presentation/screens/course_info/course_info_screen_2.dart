import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/domain/models/enrolled_course.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/widgets/portal_header.dart';
import 'package:stitch_aiei_lms/presentation/screens/compliance_quiz/compliance_quiz_screen.dart';

// ---------------------------------------------------------------------------
// CourseInfoScreen2 – Stitch "Course info 2" (OSHE Workplace Safety) faithful
// Flutter conversion.
// ---------------------------------------------------------------------------
class CourseInfoScreen2 extends StatefulWidget {
  final EnrolledCourse course;

  const CourseInfoScreen2({super.key, required this.course});

  @override
  State<CourseInfoScreen2> createState() => _CourseInfoScreen2State();
}

class _CourseInfoScreen2State extends State<CourseInfoScreen2> {
  // --- Video player state ---
  bool _isPlaying = true;
  bool _ccActive = true;
  int _currentSeconds = 8 * 60 + 16; // 08:16 (start time shown in design)
  static const int _totalSeconds = 16 * 60 + 30; // 16:30
  Timer? _timer;

  // --- Tab state ---
  int _activeTab = 0; // 0=Materials, 1=External Portals, 2=Q&A

  final TextEditingController _qaController = TextEditingController();

  static const List<_ModuleItem> _modules = [
    _ModuleItem('01. Regulatory Framework', '14m • Completed', _ModuleState.completed, '95%'),
    _ModuleItem('02. Hazard Identification & PPE', '22m • Completed', _ModuleState.completed, '100%'),
    _ModuleItem('03. Electrical & Lockout/Tagout', '18m • Completed', _ModuleState.completed, '92%'),
    _ModuleItem('04. Chemical Handling & SDS', '16m • Playing Now', _ModuleState.active, 'Active'),
    _ModuleItem('05. Fire Protection & Suppression', '20m • Locked', _ModuleState.locked, 'Req. L04'),
    _ModuleItem('06. Ergonomics & Physical', '15m • Locked', _ModuleState.locked, 'Req. L05'),
    _ModuleItem('07. Incident Response & Reporting', '25m • Locked', _ModuleState.locked, 'Req. L06'),
    _ModuleItem('08. Final Regulatory Audit Exam', '45m • Comprehensive', _ModuleState.locked, '50 Qs'),
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _qaController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPlaying && _currentSeconds < _totalSeconds) {
        setState(() => _currentSeconds++);
      }
    });
  }

  String get _formattedTime {
    final m = _currentSeconds ~/ 60;
    final s = _currentSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _openComplianceQuiz() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ComplianceQuizScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PortalHeader(onSearch: (_) {}),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSidebar(),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildBreadcrumb(context),
                        const SizedBox(height: 20),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 900;
                            if (isWide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 8, child: _buildLeftColumn()),
                                  const SizedBox(width: 24),
                                  SizedBox(width: 340, child: _buildRightColumn()),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                _buildLeftColumn(),
                                const SizedBox(height: 24),
                                _buildRightColumn(),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sidebar ───────────────────────────────────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      width: 256,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(1, 0))],
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sidebarItem('My Enrolled Courses', false),
          const SizedBox(height: 4),
          _sidebarItem('Certification and Badges', false),
        ],
      ),
    );
  }

  Widget _sidebarItem(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active ? AppColors.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTypography.labelLg(
          color: active ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  // ── Breadcrumb ────────────────────────────────────────────────────────────
  Widget _buildBreadcrumb(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, size: 18, color: AppColors.onSurface),
                  const SizedBox(width: 6),
                  Text('Back to Enrolled Courses', style: AppTypography.labelMd()),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.secondaryFixed,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                'Module 4: Chemical Handling & Hazard Protocols',
                style: AppTypography.labelSm(color: const Color(0xFF00174B)).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Left Column ───────────────────────────────────────────────────────────
  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildVideoPlayer(),
        const SizedBox(height: 16),
        _buildTelemetryBar(),
        const SizedBox(height: 16),
        _buildLessonMeta(),
        const SizedBox(height: 16),
        _buildTabbedSection(),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildComplianceBanner(),
          _buildStreamMonitoredBar(),
          _buildVideoFrame(),
          _buildVideoControls(),
        ],
      ),
    );
  }

  Widget _buildComplianceBanner() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.95),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.gavel, color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'MANDATORY COMPLIANCE POLICY: ',
                    style: AppTypography.labelSm(color: AppColors.surfaceContainerLowest),
                  ),
                  TextSpan(
                    text: 'Playback is strictly unskippable. Scrubbing is permanently locked.',
                    style: AppTypography.bodySm(color: AppColors.surfaceContainerLowest),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.tertiaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulsingDot(color: AppColors.tertiaryFixed),
                const SizedBox(width: 6),
                Text(
                  'LIVE AUDIT',
                  style: AppTypography.labelSm(color: AppColors.tertiaryFixed).copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamMonitoredBar() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        children: [
          Text('STREAM MONITORED', style: AppTypography.labelSm(color: AppColors.secondaryFixed)),
          Text('  |  ', style: AppTypography.bodySm(color: AppColors.outline)),
          Text('Session ID: #AUD-9982-X25', style: AppTypography.bodySm(color: const Color(0xFFD3E4FE))),
          const Spacer(),
          const Icon(Icons.lock, size: 14, color: AppColors.error),
          const SizedBox(width: 4),
          Text('Scrubbing Restricted', style: AppTypography.labelSm(color: AppColors.error)),
        ],
      ),
    );
  }

  Widget _buildVideoFrame() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuBHFKDV4U_1rEaPG8Hskbr6fxbtztry0pzHI4mLNKWZVpyNva1RnCFk3JcZSMC-vOURznDFJx_WMN0HULQN5ns-JVRv-8bGFAJvyoHXvmEw-wXhMle6MhO7uUw03fPqr-_owgrRbHFYj2rrIi_CQk--q4G77_Ifbko23VsUY1JLtEgtZuYx8g-tAQeOxeFghRIIGi6bu2OEHgGmwja4jx1AMZJo275hGZXMrH9NLuQZwUVH5RinojoNLw',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: AppColors.primaryContainer),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'ID: EMP-88219 (Alex Chen)',
                style: AppTypography.bodySm(color: AppColors.surfaceContainerLowest),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoControls() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isPlaying = !_isPlaying),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: AppColors.surfaceContainerLowest,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.volume_up, color: Color(0xFFD3E4FE), size: 18),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.timelapse, size: 14, color: AppColors.tertiaryFixed),
                const SizedBox(width: 4),
                Text(_formattedTime,
                    style: AppTypography.labelMd(color: AppColors.surfaceContainerLowest)
                        .copyWith(fontFeatures: [const FontFeature.tabularFigures()])),
                Text(' / ', style: AppTypography.labelMd(color: const Color(0xFFD3E4FE))),
                Text('16:30', style: AppTypography.labelMd(color: const Color(0xFFD3E4FE))),
              ],
            ),
          ),
          const Spacer(),
          const Icon(Icons.lock_clock, color: AppColors.error, size: 14),
          const SizedBox(width: 4),
          Text('Seeking Disabled', style: AppTypography.labelSm(color: const Color(0xFFD3E4FE))),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => setState(() => _ccActive = !_ccActive),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _ccActive ? AppColors.secondary.withValues(alpha: 0.3) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.closed_caption, size: 16, color: AppColors.secondaryFixed),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.fullscreen, color: Color(0xFFD3E4FE), size: 20),
        ],
      ),
    );
  }

  Widget _buildTelemetryBar() {
    final progressPct = (_currentSeconds / _totalSeconds * 100).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: AppColors.tertiary),
          const SizedBox(width: 8),
          Text('Live Attendance Telemetry Synchronized', style: AppTypography.labelSm()),
          const Spacer(),
          Text('Real-time Progression:', style: AppTypography.bodySm()),
          const SizedBox(width: 6),
          Text('$progressPct%', style: AppTypography.labelMd().copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            height: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9999),
              child: LinearProgressIndicator(
                value: _currentSeconds / _totalSeconds,
                backgroundColor: AppColors.surfaceContainer,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryContainer),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonMeta() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _badge('MODULE 04', AppColors.secondaryFixed, const Color(0xFF00174B)),
                        _badge('Lecture & Practical Lab', AppColors.surfaceContainer, AppColors.onSurfaceVariant),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule, size: 14, color: AppColors.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text('16 Minutes Streaming Required', style: AppTypography.bodySm()),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lesson 04: Chemical Handling, SDS Protocols & Hazard Containment',
                      style: AppTypography.headlineLg(color: AppColors.onSurface),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildOfficerChip(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This module covers standardized chemical container labeling, primary vs. secondary vessel safety under GHS Revision 8, interpreting 16-section Safety Data Sheets (SDS), and immediate physical containment actions during an emergency spill protocol. Completion logs required under OSHA Standard 1910.1200.',
            style: AppTypography.bodyMd(),
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.outlineVariant.withValues(alpha: 0.4), height: 1),
          const SizedBox(height: 16),
          _buildLessonActionBar(),
          const SizedBox(height: 16),
          _buildSpecStrip(),
        ],
      ),
    );
  }

  Widget _buildOfficerChip() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
            ),
            alignment: Alignment.center,
            child: Text('VM', style: AppTypography.headlineSm(color: AppColors.secondary)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Dr. V. Morales', style: AppTypography.labelMd()),
              Text('EHS Compliance Officer', style: AppTypography.bodySm()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLessonActionBar() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Previous: Lesson 03'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.onSurface,
            backgroundColor: AppColors.surfaceContainer,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () => _openComplianceQuiz(),
              icon: const Icon(Icons.quiz, size: 18),
              label: const Text('Take Lesson 4 Compliance Quiz'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: const BorderSide(color: AppColors.secondary),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lesson 04 marked as complete.'),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Mark as Complete & Continue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryContainer,
                foregroundColor: AppColors.onSecondary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecStrip() {
    final specs = [
      ('Standard', '29 CFR 1910'),
      ('Passing Score', '80% Min.'),
      ('Attempts Permitted', '3 Total'),
      ('Quiz Length', '15 Questions'),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final perRow = constraints.maxWidth >= 560 ? 4 : 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: specs.map((s) {
          final width = (constraints.maxWidth - (perRow - 1) * 12) / perRow;
          return SizedBox(
            width: width,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.$1.toUpperCase(), style: AppTypography.labelSm()),
                  Text(s.$2, style: AppTypography.headlineSm().copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildTabbedSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.surfaceContainerLow.withValues(alpha: 0.4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabButton(0, Icons.folder_open, 'Materials & Downloads', badge: '3'),
                  _buildTabButton(1, Icons.public, 'External Compliance Portals'),
                  _buildTabButton(2, Icons.contact_support, 'Ask a Question / Compliance Q&A'),
                ],
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _activeTab == 0
                ? _buildMaterialsTab()
                : _activeTab == 1
                    ? _buildPortalsTab()
                    : _buildQATab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label, {String? badge}) {
    final active = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: active ? AppColors.secondary : Colors.transparent, width: 2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: active ? AppColors.secondary : AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelLg(color: active ? AppColors.secondary : AppColors.onSurfaceVariant)
                    .copyWith(fontWeight: active ? FontWeight.w700 : FontWeight.w400),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(color: AppColors.secondaryFixed, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(badge,
                      style: AppTypography.labelSm(color: const Color(0xFF00174B)).copyWith(fontSize: 10)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialsTab() {
    return Padding(
      key: const ValueKey('materials'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Required Compliance Documents & Protocols', style: AppTypography.headlineSm()),
                    Text('Download essential regulatory checklists and official OSHA reference guides for Lesson 04.',
                        style: AppTypography.bodySm()),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Downloading all Lesson 04 materials (.ZIP • 5.4 MB)...')),
                  );
                },
                icon: const Icon(Icons.cloud_download, size: 16),
                label: const Text('Download All (.ZIP • 5.4 MB)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onSurface,
                  backgroundColor: AppColors.surfaceContainer,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 640;
            final files = const [
              ('OSHA Safety Data Sheets (SDS) Guide', 'PDF • 1.8 MB'),
              ('Emergency Evacuation Blueprint', 'PDF • 3.2 MB'),
              ('Hazardous Spill Checklist', 'PDF • 450 KB'),
            ];
            final children = files
                .map((f) => SizedBox(
                      width: wide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth,
                      child: _downloadCard(f.$1, f.$2),
                    ))
                .toList();
            return Wrap(spacing: 16, runSpacing: 16, children: children);
          }),
        ],
      ),
    );
  }

  Widget _downloadCard(String name, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.picture_as_pdf, color: AppColors.error, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: AppTypography.labelMd().copyWith(fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    Text(subtitle, style: AppTypography.bodySm()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Downloading $name...')),
                );
              },
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Download'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                backgroundColor: AppColors.surfaceContainerLowest,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortalsTab() {
    return Padding(
      key: const ValueKey('portals'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('External Compliance & Regulatory Portals', style: AppTypography.headlineSm()),
          const SizedBox(height: 16),
          _portalRow(Icons.gavel, AppColors.secondary, 'OSHA.gov — 29 CFR 1910.1200 (Hazard Communication)',
              'Official federal regulatory reference text'),
          const SizedBox(height: 10),
          _portalRow(Icons.science, AppColors.error, 'GHS Revision 8 Classification Portal',
              'United Nations Globally Harmonized System reference'),
          const SizedBox(height: 10),
          _portalRow(Icons.badge, AppColors.onTertiaryContainer, 'Accredited Enterprise Safety Board Directory',
              'Verify certification status & renewal requirements'),
        ],
      ),
    );
  }

  Widget _portalRow(IconData icon, Color iconColor, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelLg()),
                Text(subtitle, style: AppTypography.bodySm()),
              ],
            ),
          ),
          const Icon(Icons.open_in_new, color: AppColors.outline, size: 18),
        ],
      ),
    );
  }

  Widget _buildQATab() {
    return Padding(
      key: const ValueKey('qa'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Compliance Question & Answer', style: AppTypography.headlineSm()),
          Text('Typical response time from Dr. V. Morales (EHS) is under 4 business hours.', style: AppTypography.bodySm()),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _qaController,
              maxLines: 3,
              style: AppTypography.bodyMd(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Have a compliance question about this module? Type it here...',
                hintStyle: AppTypography.bodyMd(color: AppColors.outline),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_qaController.text.trim().isNotEmpty) {
                  _qaController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Question submitted to Dr. V. Morales.'),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.send, size: 18),
              label: const Text('Submit Question'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.onSecondary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Right Column ──────────────────────────────────────────────────────────
  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMilestoneCard(),
        const SizedBox(height: 16),
        _buildCurriculumList(),
      ],
    );
  }

  Widget _buildMilestoneCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryContainer, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EARNABLE MILESTONE',
                        style: AppTypography.labelSm(color: AppColors.secondaryFixed)
                            .copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text('Certified Safety Officer 2025 Credential',
                        style: AppTypography.headlineMd(color: AppColors.surfaceContainerLowest)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        value: 0.48,
                        strokeWidth: 3.5,
                        backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryFixed),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    const Icon(Icons.shield, color: AppColors.surfaceContainerLowest, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Curriculum Completion', style: AppTypography.labelSm(color: const Color(0xFFD3E4FE))),
              Text('3 / 8 Completed (48%)',
                  style: AppTypography.labelMd(color: AppColors.surfaceContainerLowest)
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: 0.48,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryFixed),
            ),
          ),
          const SizedBox(height: 8),
          Text('Unlocks after Final Regulatory Audit & 80%+ quiz threshold.',
              style: AppTypography.bodySm(color: const Color(0xFFD3E4FE))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Credential shared to LinkedIn.')),
                    );
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Export to LinkedIn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryContainer,
                    foregroundColor: AppColors.onSecondary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.visibility, color: AppColors.surfaceContainerLowest, size: 20),
                  tooltip: 'View Audit Verification Certificate Preview',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculumList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text('Curriculum Modules', style: AppTypography.headlineSm()),
                const Spacer(),
                Text('8 Modules • 3.2 hrs', style: AppTypography.bodySm()),
              ],
            ),
          ),
          for (final m in _modules) _buildModuleRow(m),
        ],
      ),
    );
  }

  Widget _buildModuleRow(_ModuleItem module) {
    final isActive = module.state == _ModuleState.active;
    final isCompleted = module.state == _ModuleState.completed;
    final isLocked = module.state == _ModuleState.locked;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Opacity(
        opacity: isLocked ? 0.75 : 1.0,
        child: Row(
          children: [
            if (isActive)
              const Icon(Icons.autorenew, size: 18, color: AppColors.surfaceContainerLowest)
            else if (isCompleted)
              const Icon(Icons.check_circle, size: 18, color: AppColors.onTertiaryContainer)
            else
              const Icon(Icons.lock, size: 18, color: AppColors.outline),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.title,
                    style: AppTypography.labelMd(
                      color: isActive ? AppColors.surfaceContainerLowest : AppColors.onSurface,
                    ).copyWith(fontWeight: isActive ? FontWeight.w700 : FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    module.subtitle,
                    style: AppTypography.bodySm(
                      color: isActive ? AppColors.surfaceContainerLowest.withValues(alpha: 0.8) : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.surfaceContainerLowest.withValues(alpha: 0.2)
                    : isCompleted
                        ? AppColors.tertiaryContainer
                        : AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                module.badge,
                style: AppTypography.labelSm(
                  color: isActive
                      ? AppColors.surfaceContainerLowest
                      : isCompleted
                          ? AppColors.tertiaryFixed
                          : AppColors.outline,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: AppTypography.labelSm(color: fg).copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

// ── Supporting data classes ────────────────────────────────────────────────
enum _ModuleState { completed, active, locked }

class _ModuleItem {
  final String title;
  final String subtitle;
  final _ModuleState state;
  final String badge;

  const _ModuleItem(this.title, this.subtitle, this.state, this.badge);
}

// ── Pulsing dot widget ─────────────────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
