import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/domain/models/enrolled_course.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/widgets/portal_header.dart';
import 'package:stitch_aiei_lms/presentation/screens/assignment_submission/assignment_submission_screen.dart';

// ---------------------------------------------------------------------------
// CourseInfoScreen – Stitch "Course info 1" faithful Flutter conversion
// ---------------------------------------------------------------------------
class CourseInfoScreen extends StatefulWidget {
  final EnrolledCourse course;

  const CourseInfoScreen({super.key, required this.course});

  @override
  State<CourseInfoScreen> createState() => _CourseInfoScreenState();
}

class _CourseInfoScreenState extends State<CourseInfoScreen> {
  // --- Video player state ---
  bool _isPlaying = true;
  bool _ccActive = true;
  double _volume = 0.8;
  String _speed = '1.25x';
  int _currentSeconds = 14 * 60 + 22; // 14:22 (start time shown in design)
  static const int _totalSeconds = 28 * 60 + 50; // 28:50
  Timer? _timer;

  // --- Tab state ---
  int _activeTab = 0; // 0=Materials, 1=Repos, 2=Q&A

  // --- Mobile-only state ---
  bool _mobileAccordionExpanded = true;
  static const List<String> _mobileSpeeds = ['1.0x', '1.25x', '1.5x'];
  int _mobileSpeedIndex = 1;

  // --- Q&A ---
  final TextEditingController _qaController = TextEditingController();

  // Lesson list (matches Stitch design exactly)
  static const List<_LessonItem> _lessons = [
    _LessonItem('01: Enterprise Python Environment Setup', '25 min • Video & Lab', _LessonState.completed, 'Quiz: 100%'),
    _LessonItem('02: Pandas Series & DataFrame Mechanics', '38 min • Video & Lab', _LessonState.completed, 'Quiz: 95%'),
    _LessonItem('03: Data Cleansing, Deduplication & Imputation', '42 min • Video', _LessonState.completed, 'Quiz: 90%'),
    _LessonItem('04: Merging, Joining & Aggregating Datasets', '35 min • Video & Lab', _LessonState.completed, 'Quiz: 100%'),
    _LessonItem('05: Vectorized Operations & Performance', '30 min • Video', _LessonState.completed, 'Quiz: 88%'),
    _LessonItem('06: Working with OpenPyXL & Multi-Tab Books', '40 min • Video & Lab', _LessonState.completed, 'Quiz: 92%'),
    _LessonItem('07: Building Automated Data Pipelines', '45 min • Active Playback', _LessonState.active, 'Playing'),
    _LessonItem('08: Scheduled Automated Cron & Windows Tasks', '32 min • Video & Lab', _LessonState.locked, 'Locked'),
    _LessonItem('09: Automated Email Alerts & PDF Report Delivery', '36 min • Video', _LessonState.locked, 'Locked'),
    _LessonItem('10: Capstone Project: End-to-End Enterprise ETL', '60 min • Evaluation Project', _LessonState.capstone, 'Capstone'),
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

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width < 700) {
      return _buildMobileScaffold(context);
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PortalHeader(onSearch: (_) {}),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sidebar (same as catalogue)
          _buildSidebar(),

          // Main scrollable content
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
                        // Breadcrumb / Back bar
                        _buildBreadcrumb(context),
                        const SizedBox(height: 20),

                        // 12-col responsive grid: left (8) + right (4)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 900;
                            if (isWide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 8,
                                    child: _buildLeftColumn(),
                                  ),
                                  const SizedBox(width: 24),
                                  SizedBox(
                                    width: 340,
                                    child: _buildRightColumn(),
                                  ),
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
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, size: 18, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text('Back to Enrolled Courses', style: AppTypography.labelMd()),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text('Module 2: Automation Pipelines', style: AppTypography.labelSm()),
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
        const SizedBox(height: 24),
        _buildLessonMeta(),
        const SizedBox(height: 24),
        _buildTabbedSection(),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Compliance banner
          _buildComplianceBanner(),

          // Video mock frame
          _buildVideoFrame(),

          // Telemetry bar
          _buildTelemetryBar(),
        ],
      ),
    );
  }

  Widget _buildComplianceBanner() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.lock, color: Color(0xFFB4C5FF), size: 18),
          const SizedBox(width: 8),
          Text(
            'MANDATORY COMPLIANCE POLICY:',
            style: AppTypography.labelSm(color: const Color(0xFFB4C5FF)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Video playback is strictly unskippable. Scrubbing and timeline seeking are permanently disabled.',
              style: AppTypography.bodySm(color: const Color(0xFFDCE9FF)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.tertiaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Live Audit',
              style: AppTypography.labelSm(color: AppColors.onTertiaryContainer)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoFrame() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuAvwREiFxL7-3Mir-Ik4eP-Bhp-ydI0er_2d_w6ADfFtZxG7TUheexNJhEYiitMUVIdtEB62Z7hv2RoWLKuzTEh2UtQZkMgVsLdw4g_cVLlciM4M2Bm-e-EWwiAO40N91KplXCNPwD3-2U1bkkvHqUn3DWtiKJUYeWKYuWqBvxhfK14uI3MGFOO6mK3teXzj7k2uLkn0fkz-3jsyWIlVh8ZSvc4gRgbE6Cjd00hiuEaQxRFrJeAxbOBLA',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: AppColors.primaryContainer),
            ),
          ),
          // Dark gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.4),
                    AppColors.primary.withValues(alpha: 0.3),
                    AppColors.primary.withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // Top overlay info
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _PulsingDot(color: AppColors.error),
                      const SizedBox(width: 6),
                      Text('Stream Monitored', style: AppTypography.labelSm(color: AppColors.onPrimary)),
                      Text('  |  ', style: AppTypography.bodySm(color: AppColors.outline)),
                      Text('Session ID: #EXP-88914-PD', style: AppTypography.labelSm(color: const Color(0xFFD3E4FE))),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_clock, color: AppColors.error, size: 16),
                      const SizedBox(width: 4),
                      Text('Scrubbing Restricted',
                          style: AppTypography.labelSm(color: AppColors.surfaceContainerLowest)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Center watermark
          Center(
            child: Opacity(
              opacity: 0.2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('CHEN.ALEX // CORP-ID-7819',
                      style: AppTypography.headlineSm(color: AppColors.onPrimary)
                          .copyWith(letterSpacing: 4)),
                  Text('Enterprise Regulatory Record',
                      style: AppTypography.bodySm(color: const Color(0xFFD3E4FE))),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.9), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  // Play/Pause button
                  GestureDetector(
                    onTap: () => setState(() => _isPlaying = !_isPlaying),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: AppColors.onSecondary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Timer display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _formattedTime,
                          style: AppTypography.labelMd(color: const Color(0xFFB4C5FF))
                              .copyWith(fontWeight: FontWeight.w700, fontFeatures: [const FontFeature.tabularFigures()]),
                        ),
                        Text(' / ', style: AppTypography.labelMd(color: AppColors.outline)),
                        Text('28:50', style: AppTypography.labelMd(color: const Color(0xFFD3E4FE))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Volume icon
                  GestureDetector(
                    onTap: () => setState(() => _volume = _volume > 0 ? 0 : 0.8),
                    child: Icon(
                      _volume > 0 ? Icons.volume_up : Icons.volume_off,
                      color: const Color(0xFFD3E4FE),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                        activeTrackColor: AppColors.secondary,
                        inactiveTrackColor: AppColors.outline.withValues(alpha: 0.4),
                        thumbColor: AppColors.secondary,
                      ),
                      child: Slider(
                        value: _volume,
                        onChanged: (v) => setState(() => _volume = v),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Speed selector
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: ['1.0x', '1.25x'].map((s) {
                        final active = _speed == s;
                        return GestureDetector(
                          onTap: () => setState(() => _speed = s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: active ? AppColors.secondary : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              s,
                              style: AppTypography.labelSm(
                                color: active ? AppColors.onSecondary : const Color(0xFFD3E4FE),
                              ).copyWith(fontWeight: active ? FontWeight.w700 : FontWeight.w400),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // CC button
                  GestureDetector(
                    onTap: () => setState(() => _ccActive = !_ccActive),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.closed_caption,
                        size: 20,
                        color: _ccActive ? const Color(0xFFB4C5FF) : const Color(0xFFD3E4FE),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Fullscreen button
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fullscreen, size: 20, color: Color(0xFFD3E4FE)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryBar() {
    final progressPct = (_currentSeconds / _totalSeconds * 100).toStringAsFixed(1);
    return Container(
      color: AppColors.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.verified, size: 16, color: Color(0xFF4EDEA3)),
          const SizedBox(width: 6),
          Text('Live Attendance Telemetry Synchronized',
              style: AppTypography.bodySm()),
          const Spacer(),
          Text('Real-time Progression: $progressPct%',
              style: AppTypography.labelSm()),
          const SizedBox(width: 8),
          SizedBox(
            width: 128,
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9999),
              child: LinearProgressIndicator(
                value: _currentSeconds / _totalSeconds,
                backgroundColor: AppColors.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
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
              Expanded(child: _buildLessonTitleBlock()),
              const SizedBox(width: 16),
              _buildInstructorChip(),
            ],
          ),
          const SizedBox(height: 20),
          _buildLessonActionBar(),
        ],
      ),
    );
  }

  Widget _buildLessonTitleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _badge('MODULE 02', AppColors.secondary.withValues(alpha: 0.1), AppColors.secondary),
            _badge('Lecture & Practical Lab', AppColors.surfaceContainer, AppColors.onSurfaceVariant),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule, size: 14, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('45 minutes', style: AppTypography.labelSm()),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Lesson 07: Building Automated Data Pipelines with Pandas & Excel',
          style: AppTypography.headlineLg(color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          'Master automated ingestion of multi-sheet workbooks, schema validation routines, exception quarantine tables, and automated email broadcast alerts.',
          style: AppTypography.bodyMd(),
        ),
      ],
    );
  }

  Widget _buildInstructorChip() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
            child: ClipOval(
              child: Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCoO1JA0P0jqBwcc_Cb6sG87UZ0JzRwPdQhqPUP5dnKIW_ipFrTwJNiJb5VrDkprIdWjoF8KN306H9AsuTu8F1B8IX__lCew4mTEBchZZq_jusEyvZey8trDh4K9GInccDWgx-DEqM2DkSM1V1lRr-dHfBqJxXzrBmawlRB2d_RFXowEk0XNb1EesR9Ke2jV7rQKs_syPqG6MOv7fDhBgu2MyQWXOU12E_0RFWriIH0qFx6k6pwFeDLOQ',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: AppColors.onPrimary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Dr. Sarah Lin', style: AppTypography.labelMd()),
              Text('Lead Data Architect', style: AppTypography.bodySm()),
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
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            // Previous lesson button
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Previous: Lesson 06'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onSurface,
                backgroundColor: AppColors.surfaceContainer,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            // Take Quiz button
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.quiz, size: 18),
              label: const Text('Take Lesson 7 Quiz'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                backgroundColor: AppColors.surfaceContainerHigh,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            // Submit Assignment button
            ElevatedButton(
              onPressed: () => _openAssignmentSubmission(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.onSecondary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.upload_file, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Submit Assignment 02',
                    style: AppTypography.labelLg(color: AppColors.onSecondary),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ],
        ),
        // Mark complete (disabled, locked)
        Tooltip(
          message: 'Unlocks automatically after watching the full 28:50 unskippable video.',
          child: ElevatedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.lock, size: 18),
            label: const Text('Mark as Complete & Continue'),
            style: ElevatedButton.styleFrom(
              disabledBackgroundColor: AppColors.surfaceContainerHighest,
              disabledForegroundColor: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
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
          // Tab bar
          Container(
            color: AppColors.surfaceContainerLow,
            child: Row(
              children: [
                _buildTabButton(0, Icons.folder_zip, 'Materials & Downloads', badge: '3'),
                _buildTabButton(1, Icons.hub, 'External Links & Repos'),
                _buildTabButton(2, Icons.forum, 'Ask a Question / Q&A'),
              ],
            ),
          ),
          // Tab content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _activeTab == 0
                ? _buildMaterialsTab()
                : _activeTab == 1
                    ? _buildReposTab()
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
              bottom: BorderSide(
                color: active ? AppColors.secondary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: active ? AppColors.secondary : AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelLg(
                  color: active ? AppColors.secondary : AppColors.onSurfaceVariant,
                ).copyWith(fontWeight: active ? FontWeight.w700 : FontWeight.w400),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(badge,
                      style: AppTypography.labelSm(color: AppColors.onSecondary)
                          .copyWith(fontSize: 10)),
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
                    Text('Required Lab Files & Resources', style: AppTypography.headlineSm()),
                    Text('Download these artifacts to execute the pipeline locally alongside the tutorial stream.',
                        style: AppTypography.bodySm()),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_for_offline, size: 16),
                label: const Text('Download All (.ZIP - 7.3 MB)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  backgroundColor: AppColors.surfaceContainer,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _downloadCard(Icons.terminal, AppColors.secondaryFixed, AppColors.onSurface, 'lesson_07_pipeline.ipynb', 'Jupyter Notebook • 2.4 MB', 'v2.1 Python 3.11')),
              const SizedBox(width: 16),
              Expanded(child: _downloadCard(Icons.table_chart, AppColors.surfaceContainerHighest, AppColors.primary, 'corp_sales_raw_2025.xlsx', 'Corporate Dataset • 4.1 MB', '54,000 Rows')),
              const SizedBox(width: 16),
              Expanded(child: _downloadCard(Icons.picture_as_pdf, AppColors.errorContainer, AppColors.onErrorContainer, 'Pipeline_Reference_Cheatsheet.pdf', 'Documentation • 820 KB', 'Quick Reference')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _downloadCard(IconData icon, Color iconBg, Color iconFg, String name, String subtitle, String tag) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 22, color: iconFg),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTypography.labelMd(), overflow: TextOverflow.ellipsis),
                    Text(subtitle, style: AppTypography.bodySm()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tag, style: AppTypography.labelSm()),
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.download, size: 18, color: AppColors.onSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReposTab() {
    return Padding(
      key: const ValueKey('repos'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Connected Enterprise Repositories', style: AppTypography.headlineSm()),
          const SizedBox(height: 16),
          _repoRow(Icons.menu_book, AppColors.secondary, 'Official Pandas API Reference (v2.2)', 'https://pandas.pydata.org/docs/reference/io.html#excel'),
          const SizedBox(height: 10),
          _repoRow(Icons.terminal, AppColors.primary, 'Company GitHub Repository: /data-eng/enterprise-pandas-templates', 'Internal GitHub Enterprise • Branch: main • Last push 2d ago'),
          const SizedBox(height: 10),
          _repoRow(Icons.forum, AppColors.secondaryContainer, 'Internal StackOverflow Enterprise Discussion Thread', 'Tagged: [pandas-excel-pipeline] [etl-compliance-2025] • 42 answers'),
        ],
      ),
    );
  }

  Widget _repoRow(IconData icon, Color iconColor, String title, String subtitle) {
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
          Text('Instructor & Peer Discussion', style: AppTypography.headlineSm()),
          Text('Typical response time from Dr. Sarah Lin or assigned TA is under 3 hours.', style: AppTypography.bodySm()),
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
                hintText: 'Have a question about this lesson? Type your question here...',
                hintStyle: AppTypography.bodyMd(color: AppColors.outline),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 14, color: AppColors.tertiary),
                  const SizedBox(width: 6),
                  Text('Will be indexed to timestamp 14:22 for contextual review',
                      style: AppTypography.labelSm()),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (_qaController.text.trim().isNotEmpty) {
                    _qaController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Question submitted to Dr. Sarah Lin.'),
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
            ],
          ),
          const SizedBox(height: 24),
          // Sample Q&A thread
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('Marcus Vance', style: AppTypography.labelMd().copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Peer • Financial Ops', style: AppTypography.labelSm()),
                        ),
                      ],
                    ),
                    Text('2 hours ago', style: AppTypography.bodySm()),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '"Does the `read_excel(engine=\'openpyxl\')` argument handle legacy .xls formats without memory bloat in Lesson 7\'s script?"',
                  style: AppTypography.bodyMd(color: AppColors.onSurface),
                ),
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.only(left: 16),
                  padding: const EdgeInsets.only(left: 12),
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: AppColors.secondary, width: 2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Dr. Sarah Lin (Instructor)', style: AppTypography.labelSm(color: AppColors.secondary).copyWith(fontWeight: FontWeight.w700)),
                          Text('  • 45m ago', style: AppTypography.bodySm()),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "For legacy 97-2003 .xls files, switch to `engine='xlrd'`. However, for modern automated pipelines, configure your ingestion step to pre-convert legacy files into .parquet as covered in Section 3.",
                        style: AppTypography.bodySm(),
                      ),
                    ],
                  ),
                ),
              ],
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
        _buildCredentialCard(),
        const SizedBox(height: 24),
        _buildCurriculumList(),
      ],
    );
  }

  Widget _buildCredentialCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Stack(
        children: [
          // Decorative blur circle
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(),
            ),
          ),
          Column(
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
                            style: AppTypography.labelSm(color: const Color(0xFFB4C5FF))
                                .copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                        const SizedBox(height: 4),
                        Text('Python Automation Specialist 2025 Credential',
                            style: AppTypography.headlineSm(color: AppColors.onPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Circular progress ring SVG-equivalent
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: CircularProgressIndicator(
                            value: 0.70,
                            strokeWidth: 4,
                            backgroundColor: AppColors.primaryContainer,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6FFBBE)),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        const Icon(Icons.military_tech, color: Color(0xFF6FFBBE), size: 24),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Curriculum Completion',
                      style: AppTypography.labelMd(color: const Color(0xFFD3E4FE))),
                  Text('7 / 10 Completed (70%)',
                      style: AppTypography.labelMd(color: AppColors.onPrimary)
                          .copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(9999),
                child: LinearProgressIndicator(
                  value: 0.70,
                  minHeight: 8,
                  backgroundColor: AppColors.primaryContainer,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6FFBBE)),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, size: 18, color: Color(0xFFB4C5FF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Unlocks after Capstone Lesson 10 & 80%+ quiz threshold.',
                        style: AppTypography.bodySm(color: const Color(0xFFD3E4FE)),
                      ),
                    ),
                  ],
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
            color: AppColors.surfaceContainerLow,
            child: Row(
              children: [
                const Icon(Icons.view_timeline, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text('Curriculum Modules', style: AppTypography.headlineSm()),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text('10 Lessons • 6.2 hrs', style: AppTypography.labelSm()),
                ),
              ],
            ),
          ),
          for (var i = 0; i < _lessons.length; i++) ...[
            _buildLessonRow(_lessons[i]),
            if (_lessons[i].state == _LessonState.active) _buildAssignmentRow(),
          ],
        ],
      ),
    );
  }

  void _openAssignmentSubmission() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AssignmentSubmissionScreen()),
    );
  }

  Widget _buildAssignmentRow() {
    return GestureDetector(
      onTap: _openAssignmentSubmission,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLow,
            border: Border(left: BorderSide(color: AppColors.secondary, width: 2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.assignment, size: 20, color: AppColors.secondary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assignment 02: Submit Solution',
                      style: AppTypography.labelMd(color: AppColors.secondary)
                          .copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('Data Pipeline Lab • Required', style: AppTypography.bodySm()),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Submit',
                      style: AppTypography.labelSm(color: AppColors.secondary)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward, size: 14, color: AppColors.secondary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonRow(_LessonItem lesson) {
    final isActive = lesson.state == _LessonState.active;
    final isCompleted = lesson.state == _LessonState.completed;
    final isLocked = lesson.state == _LessonState.locked || lesson.state == _LessonState.capstone;
    final isCapstone = lesson.state == _LessonState.capstone;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.secondaryContainer.withValues(alpha: 0.1)
            : isLocked
                ? AppColors.surfaceContainerLow.withValues(alpha: 0.4)
                : Colors.transparent,
        border: isActive
            ? const Border(left: BorderSide(color: AppColors.secondary, width: 3))
            : null,
      ),
      child: Row(
        children: [
          if (isActive)
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow, size: 14, color: AppColors.onSecondary),
            )
          else if (isCompleted)
            const Icon(Icons.check_circle, size: 20, color: AppColors.onTertiaryContainer)
          else
            Icon(Icons.lock, size: 20, color: isCapstone ? AppColors.outline : AppColors.outline),
          const SizedBox(width: 10),
          Expanded(
            child: Opacity(
              opacity: isLocked ? 0.7 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: AppTypography.labelMd(
                      color: isActive ? AppColors.secondary : AppColors.onSurface,
                    ).copyWith(fontWeight: isActive ? FontWeight.w700 : FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(lesson.subtitle, style: AppTypography.bodySm()),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.secondary
                  : isCompleted
                      ? AppColors.surfaceContainer
                      : AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              lesson.badge,
              style: AppTypography.labelSm(
                color: isActive
                    ? AppColors.onSecondary
                    : isCompleted
                        ? AppColors.tertiaryContainer
                        : AppColors.outline,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
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

  // ── Mobile layout ─────────────────────────────────────────────────────────
  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
        ),
        title: Text('Course Details', style: AppTypography.headlineSm(color: AppColors.onSurface)),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMobileBreadcrumb(context),
              const SizedBox(height: 12),
              _buildMobileVideoCard(),
              const SizedBox(height: 12),
              _buildMobileLessonCard(),
              const SizedBox(height: 12),
              _buildMobileMilestoneCard(),
              const SizedBox(height: 12),
              _buildMobileAccordion(),
              const SizedBox(height: 12),
              _buildMobileTabbedSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBreadcrumb(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back, size: 18, color: AppColors.secondary),
              const SizedBox(width: 4),
              Text('Back to Courses', style: AppTypography.labelMd(color: AppColors.secondary)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(9999)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('Module 2', style: AppTypography.labelSm()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileVideoCard() {
    final progressPct = (_currentSeconds / _totalSeconds * 100).toStringAsFixed(1);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: AppColors.primaryContainer.withValues(alpha: 0.95),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.tertiaryContainer, borderRadius: BorderRadius.circular(4)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PulsingDot(color: const Color(0xFF6FFBBE)),
                      const SizedBox(width: 4),
                      Text('LIVE AUDIT', style: AppTypography.labelSm(color: const Color(0xFF6FFBBE))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('ID: #EXP-88914-PD', style: AppTypography.bodySm(color: AppColors.onPrimary), overflow: TextOverflow.ellipsis),
                ),
                const Icon(Icons.lock, size: 13, color: Color(0xFFB4C5FF)),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuAvwREiFxL7-3Mir-Ik4eP-Bhp-ydI0er_2d_w6ADfFtZxG7TUheexNJhEYiitMUVIdtEB62Z7hv2RoWLKuzTEh2UtQZkMgVsLdw4g_cVLlciM4M2Bm-e-EWwiAO40N91KplXCNPwD3-2U1bkkvHqUn3DWtiKJUYeWKYuWqBvxhfK14uI3MGFOO6mK3teXzj7k2uLkn0fkz-3jsyWIlVh8ZSvc4gRgbE6Cjd00hiuEaQxRFrJeAxbOBLA',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: AppColors.primaryContainer),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.primary.withValues(alpha: 0.95), AppColors.primary.withValues(alpha: 0.3), Colors.transparent],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _isPlaying = !_isPlaying),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.9), shape: BoxShape.circle),
                          child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: AppColors.onSecondary, size: 26),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('MONITORED SESSION STREAM', style: AppTypography.labelSm(color: AppColors.onSecondary.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.verified_user, size: 13, color: Color(0xFF6FFBBE)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'MANDATORY POLICY: Scrubbing permanently disabled.',
                            style: AppTypography.bodySm(color: const Color(0xFFDCE9FF)).copyWith(fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 5,
            child: Stack(
              children: [
                Container(color: AppColors.surfaceContainerHighest),
                FractionallySizedBox(
                  widthFactor: _currentSeconds / _totalSeconds,
                  child: Container(color: AppColors.secondaryContainer),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: AppColors.primaryContainer,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isPlaying = !_isPlaying),
                  child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 20, color: AppColors.onPrimary),
                ),
                const SizedBox(width: 8),
                Text(
                  '$_formattedTime / 28:50',
                  style: AppTypography.labelMd(color: AppColors.onPrimary).copyWith(fontFeatures: [const FontFeature.tabularFigures()]),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _mobileSpeedIndex = (_mobileSpeedIndex + 1) % _mobileSpeeds.length),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.onPrimary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(_mobileSpeeds[_mobileSpeedIndex], style: AppTypography.labelSm(color: AppColors.onPrimary)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _volume = _volume > 0 ? 0 : 0.8),
                  child: Icon(_volume > 0 ? Icons.volume_up : Icons.volume_off, size: 20, color: AppColors.onPrimary),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.fullscreen, size: 20, color: AppColors.onPrimary),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: AppColors.surfaceContainerLow,
            child: Row(
              children: [
                const Icon(Icons.sync_alt, size: 16, color: AppColors.secondary),
                const SizedBox(width: 6),
                Expanded(child: Text('Live Attendance Telemetry Synchronized', style: AppTypography.bodySm())),
                Text('$progressPct%', style: AppTypography.labelMd(color: AppColors.secondary).copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLessonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('MODULE 02', style: AppTypography.labelSm(color: AppColors.secondary).copyWith(fontWeight: FontWeight.w700)),
              Text('•', style: AppTypography.labelSm()),
              Text('Lecture & Lab', style: AppTypography.labelSm()),
              Text('•', style: AppTypography.labelSm()),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.schedule, size: 13, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 3),
                Text('45m', style: AppTypography.labelSm()),
              ]),
            ],
          ),
          const SizedBox(height: 8),
          Text('Lesson 07: Building Automated Data Pipelines with Pandas & Excel', style: AppTypography.headlineMd(color: AppColors.onSurface)),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
                child: ClipOval(
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCoO1JA0P0jqBwcc_Cb6sG87UZ0JzRwPdQhqPUP5dnKIW_ipFrTwJNiJb5VrDkprIdWjoF8KN306H9AsuTu8F1B8IX__lCew4mTEBchZZq_jusEyvZey8trDh4K9GInccDWgx-DEqM2DkSM1V1lRr-dHfBqJxXzrBmawlRB2d_RFXowEk0XNb1EesR9Ke2jV7rQKs_syPqG6MOv7fDhBgu2MyQWXOU12E_0RFWriIH0qFx6k6pwFeDLOQ',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: AppColors.onPrimary, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Dr. Sarah Lin', style: AppTypography.labelMd()),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 14, color: AppColors.secondary),
                    ]),
                    Text('Lead Data Architect, Enterprise Core', style: AppTypography.bodySm()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Master automated ingestion of multi-sheet workbooks, schema validation routines, exception quarantine tables, and export synchronization for operational reporting.',
            style: AppTypography.bodyMd(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Previous: L06', overflow: TextOverflow.ellipsis),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    backgroundColor: AppColors.surfaceContainerLow,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Take Quiz 7'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.onSecondary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openAssignmentSubmission,
              icon: const Icon(Icons.upload_file, size: 16),
              label: const Text('Submit Assignment 02', overflow: TextOverflow.ellipsis),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.onSecondary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.lock, size: 16),
              label: const Text('Mark as Complete (Unlocked at 100%)', overflow: TextOverflow.ellipsis),
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: AppColors.surfaceContainer,
                disabledForegroundColor: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMilestoneCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 0.70,
                  strokeWidth: 3.5,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                  strokeCap: StrokeCap.round,
                ),
                const Icon(Icons.military_tech, color: AppColors.secondary, size: 22),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MILESTONE TRACK', style: AppTypography.labelSm(color: AppColors.onTertiaryContainer)),
                Text('Python Automation Specialist 2025', style: AppTypography.headlineSm(color: AppColors.onSurface).copyWith(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('7 of 10 Modules Passed • 70% Completed', style: AppTypography.bodySm()),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.tertiaryFixed, borderRadius: BorderRadius.circular(4)),
            child: Text('Tier II', style: AppTypography.labelSm(color: AppColors.tertiary).copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileAccordion() {
    final completed = _lessons.where((l) => l.state == _LessonState.completed).length;
    final inProgress = _lessons.where((l) => l.state == _LessonState.active).length;
    return Container(
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _mobileAccordionExpanded = !_mobileAccordionExpanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.dataset_outlined, color: AppColors.secondary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Curriculum Syllabus: Module 02', style: AppTypography.headlineSm(color: AppColors.onSurface).copyWith(fontSize: 14)),
                        Text('${_lessons.length} Lessons • $completed Completed • $inProgress In Progress', style: AppTypography.bodySm()),
                      ],
                    ),
                  ),
                  Icon(_mobileAccordionExpanded ? Icons.expand_less : Icons.expand_more, color: AppColors.onSurfaceVariant),
                ],
              ),
            ),
          ),
          if (_mobileAccordionExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(children: [for (final lesson in _lessons) _mobileLessonRow(lesson)]),
            ),
        ],
      ),
    );
  }

  Widget _mobileLessonRow(_LessonItem lesson) {
    final isActive = lesson.state == _LessonState.active;
    final isCompleted = lesson.state == _LessonState.completed;
    final isLocked = lesson.state == _LessonState.locked || lesson.state == _LessonState.capstone;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.secondary.withValues(alpha: 0.1) : AppColors.surfaceContainerLow.withValues(alpha: isLocked ? 0.4 : 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.play_circle : (isCompleted ? Icons.check_circle : Icons.lock),
            size: 18,
            color: isActive ? AppColors.secondary : (isCompleted ? AppColors.onTertiaryContainer : AppColors.outline),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              lesson.title,
              style: AppTypography.labelMd(color: isActive ? AppColors.secondary : AppColors.onSurface).copyWith(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(4)),
              child: Text('Playing', style: AppTypography.labelSm(color: AppColors.onSecondary)),
            )
          else
            Text(lesson.badge, style: AppTypography.labelSm(color: isCompleted ? AppColors.onTertiaryContainer : AppColors.outline)),
        ],
      ),
    );
  }

  Widget _buildMobileTabbedSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _mobileTabPill('Materials & Downloads (3)', 0),
                const SizedBox(width: 6),
                _mobileTabPill('External Links & Repos', 1),
                const SizedBox(width: 6),
                _mobileTabPill('Ask a Question', 2),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_activeTab == 0) _mobileMaterialsTab() else if (_activeTab == 1) _mobileReposTab() else _mobileAskTab(),
        ],
      ),
    );
  }

  Widget _mobileTabPill(String label, int index) {
    final active = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: active ? AppColors.secondary : AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: AppTypography.labelSm(color: active ? AppColors.onSecondary : AppColors.onSurfaceVariant)),
      ),
    );
  }

  Widget _mobileMaterialsTab() {
    final files = const [
      (Icons.code, 'lesson_07_pipeline.ipynb', '2.4 MB • Complete Jupyter Notebook'),
      (Icons.table_chart, 'corp_sales_raw.xlsx', '4.1 MB • 54,000 Unsanitized Rows'),
      (Icons.description, 'Pipeline_Reference_Guide.pdf', '820 KB • Architecture Handout'),
    ];
    return Column(
      children: [
        for (final f in files)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Icon(f.$1, size: 18, color: AppColors.secondary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.$2, style: AppTypography.labelMd(), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(f.$3, style: AppTypography.bodySm()),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download, size: 14),
                  label: const Text('Get'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    backgroundColor: AppColors.surfaceContainerLowest,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    textStyle: AppTypography.labelSm(),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _mobileReposTab() {
    final links = const [
      (Icons.terminal, 'github.com/enterprise-core/pandas-pipeline', 'Production repo branch: v2.4-stable'),
      (Icons.menu_book, 'Pandas 2.2 Official Documentation', 'Performance indexing & pyarrow engine'),
    ];
    return Column(
      children: [
        for (final l in links)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(l.$1, size: 20, color: AppColors.secondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.$2, style: AppTypography.labelMd(), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(l.$3, style: AppTypography.bodySm()),
                    ],
                  ),
                ),
                const Icon(Icons.open_in_new, size: 16, color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
      ],
    );
  }

  Widget _mobileAskTab() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Post to Cohort Teaching Assistant', style: AppTypography.labelSm()),
          const SizedBox(height: 6),
          TextField(
            controller: _qaController,
            maxLines: 2,
            style: AppTypography.bodySm(color: AppColors.onSurface),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
              hintText: 'Ask about quarantine rules, chunksize settings, or pandas syntax...',
              hintStyle: AppTypography.bodySm(color: AppColors.outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text('Avg response time: < 15 mins', style: AppTypography.labelSm()),
              ElevatedButton(
                onPressed: () {
                  if (_qaController.text.trim().isNotEmpty) {
                    _qaController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Question submitted.'), backgroundColor: AppColors.secondary),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.onSecondary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: AppTypography.labelSm(),
                ),
                child: const Text('Submit Query'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Supporting data classes ────────────────────────────────────────────────
enum _LessonState { completed, active, locked, capstone }

class _LessonItem {
  final String title;
  final String subtitle;
  final _LessonState state;
  final String badge;

  const _LessonItem(this.title, this.subtitle, this.state, this.badge);
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
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
