import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/data/datasources/mock_courses_data_source.dart';
import 'package:stitch_aiei_lms/presentation/screens/course_info/course_info_screen.dart';
import 'widgets/faculty_scaffold.dart';
import 'widgets/faculty_sidebar.dart';
import 'my_assigned_courses_screen.dart';
import 'student_directory_screen.dart';
import 'curriculum_manager_screen.dart';
import 'grade_assignment_screen.dart';
import 'grade_quiz_screen.dart';
import 'widgets/faculty_mobile_top_bar.dart';

// ---------------------------------------------------------------------------
// CourseDashboardScreen – Stitch "Course Management (Python for Enterprise)"
// faithful Flutter conversion.
// ---------------------------------------------------------------------------
class CourseDashboardScreen extends StatefulWidget {
  const CourseDashboardScreen({super.key});

  @override
  State<CourseDashboardScreen> createState() => _CourseDashboardScreenState();
}

class _CourseDashboardScreenState extends State<CourseDashboardScreen> {
  bool _showAnnouncementForm = false;

  void _handleNav(FacultyNavDestination dest) {
    switch (dest) {
      case FacultyNavDestination.myCourses:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyAssignedCoursesScreen()));
        break;
      case FacultyNavDestination.studentDirectory:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentDirectoryScreen()));
        break;
      case FacultyNavDestination.gradingAndSubmissions:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GradeAssignmentScreen()));
        break;
    }
  }

  void _previewAsStudent() {
    final course = MockCoursesDataSource.courses.firstWhere((c) => c.id == 'c1-python');
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CourseInfoScreen(course: course)));
  }

  void _notAvailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Not wired up in this preview.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width < 700) {
      return _buildMobileScaffold(context);
    }
    return FacultyScaffold(
      selected: FacultyNavDestination.myCourses,
      onDestinationSelected: _handleNav,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 20),
          _buildKpiRow(),
          const SizedBox(height: 24),
          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1000;
            final left = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDeadlinesCard(),
                const SizedBox(height: 24),
                _buildQuickSettingsCard(),
              ],
            );
            final right = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickAccessHub(),
                const SizedBox(height: 24),
                _buildAnnouncementsCard(),
              ],
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: left),
                  const SizedBox(width: 24),
                  Expanded(flex: 5, child: right),
                ],
              );
            }
            return Column(children: [left, const SizedBox(height: 24), right]);
          }),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.start,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back, size: 18, color: FacultyColors.secondary),
                    const SizedBox(width: 4),
                    Text('Back to My Courses', style: FacultyTypography.labelMd(color: FacultyColors.secondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('Python for Enterprise Data Analysis & Automation', style: FacultyTypography.displayLg()),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _tag('ACTIVE COHORT', FacultyColors.tertiaryContainer, Colors.white, dot: true),
                _tag('TERM: FALL 2025', FacultyColors.surfaceContainer, FacultyColors.onSurfaceVariant),
                _tag('COURSE ID: PY-402', FacultyColors.surfaceContainerHigh, FacultyColors.onSurface),
              ],
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _previewAsStudent,
              icon: const Icon(Icons.visibility_outlined, size: 18, color: FacultyColors.secondary),
              label: const Text('Preview as Student'),
              style: OutlinedButton.styleFrom(
                foregroundColor: FacultyColors.onSurface,
                backgroundColor: FacultyColors.surfaceContainerLowest,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _notAvailable,
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: const Text('Course Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FacultyColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tag(String text, Color bg, Color fg, {bool dot = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            const Icon(Icons.circle, size: 6, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(text, style: FacultyTypography.labelXs(color: fg).copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildKpiRow() {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 500 ? 2 : 1);
      final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
      final cards = [
        _kpiCard('ENROLLED STUDENTS', '42', Icons.groups_outlined, FacultyColors.primary, FacultyColors.surfaceContainer,
            footer: '+4 this week from waitlist', footerColor: FacultyColors.tertiary, footerIcon: Icons.trending_up),
        _kpiCard('ASSIGNMENTS TO GRADE', '14', Icons.assignment_turned_in_outlined, FacultyColors.onSecondaryFixedVariant, FacultyColors.secondaryContainer,
            footer: '14 pending submissions', footerColor: FacultyColors.onSecondaryFixedVariant, pillFooter: true),
        _kpiCard('QUIZZES TO GRADE', '8', Icons.quiz_outlined, FacultyColors.primary, FacultyColors.surfaceContainerHigh,
            footer: '8 open-ended manual checks'),
        _kpiCard('AVG. COHORT PROGRESS', '72%', Icons.donut_large, FacultyColors.primary, FacultyColors.surfaceContainer,
            progress: 0.72),
      ];
      return Wrap(spacing: 16, runSpacing: 16, children: cards.map((c) => SizedBox(width: width, child: c)).toList());
    });
  }

  Widget _kpiCard(String label, String value, IconData icon, Color iconColor, Color iconBg,
      {String? footer, Color? footerColor, IconData? footerIcon, bool pillFooter = false, double? progress}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
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
                    Text(label, style: FacultyTypography.labelXs().copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(value, style: FacultyTypography.displayLg()),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (progress != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(9999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: FacultyColors.surfaceContainerHigh,
                valueColor: const AlwaysStoppedAnimation<Color>(FacultyColors.primary),
              ),
            )
          else if (pillFooter && footer != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: FacultyColors.secondaryContainer, borderRadius: BorderRadius.circular(6)),
              child: Text(footer, style: FacultyTypography.labelXs(color: footerColor ?? FacultyColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w700)),
            )
          else if (footer != null)
            Row(
              children: [
                if (footerIcon != null) ...[
                  Icon(footerIcon, size: 14, color: footerColor),
                  const SizedBox(width: 3),
                ],
                Expanded(
                  child: Text(footer,
                      style: FacultyTypography.labelXs(color: footerColor ?? FacultyColors.onSurfaceVariant).copyWith(
                        fontWeight: footerIcon != null ? FontWeight.w700 : FontWeight.w400,
                      )),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDeadlinesCard() {
    return Container(
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: FacultyColors.surfaceContainerLow,
            child: Row(
              children: [
                const Icon(Icons.event_note_outlined, color: FacultyColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Upcoming Deadlines & Schedule', style: FacultyTypography.headlineMd())),
                Text('3 items queued', style: FacultyTypography.labelXs()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _deadlineRow(
                  icon: Icons.terminal,
                  title: 'Assignment 02: Building Automated Data Pipelines',
                  dueText: 'Due Nov 15',
                  dueColor: FacultyColors.error,
                  meta: '36 submitted / 42 total',
                  ctaLabel: 'Grade Submissions',
                  ctaIcon: Icons.arrow_forward,
                  ctaPrimary: true,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GradeAssignmentScreen())),
                ),
                const SizedBox(height: 12),
                _deadlineRow(
                  icon: Icons.rule_outlined,
                  title: 'Quiz 03: Compliance & Schema Handling',
                  dueText: 'Due Nov 18',
                  dueColor: FacultyColors.onSurface,
                  meta: '40 submitted / 42 total',
                  ctaLabel: 'Review Answers',
                  ctaIcon: Icons.checklist,
                  ctaPrimary: false,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GradeQuizScreen())),
                ),
                const SizedBox(height: 12),
                _deadlineRow(
                  icon: Icons.flag_outlined,
                  title: 'Final Capstone Project Release',
                  dueText: 'Scheduled for Dec 01, 2025',
                  dueColor: FacultyColors.onSurfaceVariant,
                  meta: null,
                  badge: 'Upcoming',
                  ctaLabel: 'Edit Schedule',
                  ctaIcon: null,
                  ctaPrimary: false,
                  muted: true,
                  onTap: _notAvailable,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deadlineRow({
    required IconData icon,
    required String title,
    required String dueText,
    required Color dueColor,
    String? meta,
    String? badge,
    required String ctaLabel,
    IconData? ctaIcon,
    required bool ctaPrimary,
    bool muted = false,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: muted ? FacultyColors.surfaceContainerLow : FacultyColors.surfaceBright,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: muted ? FacultyColors.surfaceContainerHigh : FacultyColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: muted ? FacultyColors.secondary : FacultyColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(title, style: FacultyTypography.titleSm(), overflow: TextOverflow.ellipsis)),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(4)),
                            child: Text(badge, style: FacultyTypography.labelXs(color: FacultyColors.secondary)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.event, size: 13, color: dueColor),
                          const SizedBox(width: 3),
                          Text(dueText, style: FacultyTypography.bodySm(color: dueColor).copyWith(fontWeight: FontWeight.w500)),
                        ]),
                        if (meta != null) ...[
                          Text('•', style: FacultyTypography.bodySm()),
                          Text(meta, style: FacultyTypography.bodySm(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w500)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (ctaIcon != null)
            ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(ctaIcon, size: 16),
              label: Text(ctaLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: ctaPrimary ? FacultyColors.primary : FacultyColors.surfaceContainerLowest,
                foregroundColor: ctaPrimary ? Colors.white : FacultyColors.onSurface,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: FacultyTypography.labelXs(),
              ),
            )
          else
            OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: FacultyColors.onSurface,
                backgroundColor: FacultyColors.surfaceContainer,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: FacultyTypography.labelXs(),
              ),
              child: Text(ctaLabel),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: FacultyColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Course Quick Settings & Info', style: FacultyTypography.headlineMd())),
              TextButton(
                onPressed: _notAvailable,
                child: Text('Edit Details', style: FacultyTypography.labelMd(color: FacultyColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: FacultyColors.surfaceBright, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SYLLABUS OVERVIEW', style: FacultyTypography.labelXs().copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'Equips modern engineering students with hands-on techniques to architect robust ETL extraction pipelines, operationalize pandas for large datasets, and execute automated reporting workflows directly inside institutional networks.',
                  style: FacultyTypography.bodyMd(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth >= 560 ? 3 : 1;
            final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
            final items = [
              _infoTile('Passing Criteria', '80%', 'Weighted total grade'),
              _infoTile('Enrollment Capacity', '42 / 50', '8 seats remaining'),
              _infoTile('Granted Credential', 'Enterprise Python Specialist', 'Accredited', badge: true),
            ];
            return Wrap(spacing: 16, runSpacing: 16, children: items.map((i) => SizedBox(width: width, child: i)).toList());
          }),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, String footnote, {bool badge = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: FacultyTypography.labelXs()),
          const SizedBox(height: 4),
          Text(value, style: badge ? FacultyTypography.titleSm() : FacultyTypography.headlineMd()),
          const SizedBox(height: 4),
          badge
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.verified, size: 13, color: FacultyColors.tertiary),
                  const SizedBox(width: 3),
                  Text(footnote, style: FacultyTypography.labelXs(color: FacultyColors.tertiary)),
                ])
              : Text(footnote, style: FacultyTypography.labelXs()),
        ],
      ),
    );
  }

  Widget _buildQuickAccessHub() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RESOURCE OVERVIEW', style: FacultyTypography.labelXs().copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('Quick Access Hub', style: FacultyTypography.headlineMd()),
          const SizedBox(height: 16),
          _hubRow(
            icon: Icons.folder_copy_outlined,
            iconBg: FacultyColors.primary,
            iconColor: Colors.white,
            title: 'Curriculum & Materials',
            subtitle: '4 core modules • 28 assets uploaded',
            ctaLabel: 'Manage',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CurriculumManagerScreen())),
          ),
          const SizedBox(height: 12),
          _hubRow(
            icon: Icons.badge_outlined,
            iconBg: FacultyColors.surfaceContainerHigh,
            iconColor: FacultyColors.primary,
            title: 'Student Directory',
            subtitle: '42 active learners',
            trailingBadge: '3 flagged',
            ctaLabel: 'View',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentDirectoryScreen())),
          ),
        ],
      ),
    );
  }

  Widget _hubRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? trailingBadge,
    required String ctaLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: FacultyTypography.titleSm()),
                Row(
                  children: [
                    Text(subtitle, style: FacultyTypography.bodySm()),
                    if (trailingBadge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: FacultyColors.errorContainer, borderRadius: BorderRadius.circular(4)),
                        child: Text(trailingBadge, style: FacultyTypography.labelXs(color: FacultyColors.error).copyWith(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward, size: 14),
            label: Text(ctaLabel),
            style: OutlinedButton.styleFrom(
              foregroundColor: FacultyColors.onSurface,
              backgroundColor: FacultyColors.surfaceContainerLowest,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: FacultyTypography.labelXs(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_outlined, color: FacultyColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Course Announcements', style: FacultyTypography.headlineMd())),
              TextButton.icon(
                onPressed: () => setState(() => _showAnnouncementForm = !_showAnnouncementForm),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Post New'),
                style: TextButton.styleFrom(foregroundColor: FacultyColors.primary, textStyle: FacultyTypography.labelMd()),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _announcement('Office hours moved to Thursday 3 PM', 'Yesterday',
              'Due to the departmental curriculum council meeting, our usual Wednesday slot is moved. Room 402 or via Zoom bridge.'),
          const SizedBox(height: 8),
          _announcement('Starter repo updated for Assignment 02', 'Nov 08',
              'A patch was pushed to address the dataset schema parser warning in Python 3.11. Please run git pull before continuing.'),
          if (_showAnnouncementForm) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Draft Quick Broadcast', style: FacultyTypography.labelMd()),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: FacultyColors.surfaceContainerLowest,
                      hintText: 'Subject line...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    maxLines: 2,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: FacultyColors.surfaceContainerLowest,
                      hintText: 'Announcement content...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _showAnnouncementForm = false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _showAnnouncementForm = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Announcement published.'), backgroundColor: FacultyColors.primary),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: FacultyColors.primary, foregroundColor: Colors.white, elevation: 0),
                        child: const Text('Publish'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _announcement(String title, String time, String body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: FacultyColors.surfaceBright, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: FacultyTypography.bodyMd(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600))),
              Text(time, style: FacultyTypography.labelXs()),
            ],
          ),
          const SizedBox(height: 4),
          Text(body, style: FacultyTypography.bodySm(), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Mobile (<700px) layout — separate Scaffold, does not reuse
  // FacultyScaffold/FacultyHeader/FacultySidebar (desktop-only shell).
  // ---------------------------------------------------------------------

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: const FacultyMobileTopBar(title: 'Course Detail'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _mobileActionBar(),
              const SizedBox(height: 12),
              _mobileCourseIdentityCard(),
              const SizedBox(height: 16),
              _mobileKpiGrid(),
              const SizedBox(height: 20),
              _mobileGradingQueueSection(),
              const SizedBox(height: 20),
              _mobileQuickAccessSection(),
              const SizedBox(height: 20),
              _mobileAnnouncementsCard(),
              const SizedBox(height: 20),
              _mobileGovernanceCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileActionBar() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, size: 18, color: FacultyColors.secondary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Back to My Courses',
                      style: FacultyTypography.labelMd(color: FacultyColors.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _mobileIconSquareButton(icon: Icons.settings, onTap: _notAvailable),
        const SizedBox(width: 8),
        _mobilePreviewButton(),
      ],
    );
  }

  Widget _mobileIconSquareButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: FacultyColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4)],
        ),
        child: Icon(icon, size: 20, color: FacultyColors.onSurfaceVariant),
      ),
    );
  }

  Widget _mobilePreviewButton() {
    return InkWell(
      onTap: _previewAsStudent,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: FacultyColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility_outlined, size: 18, color: FacultyColors.secondary),
            const SizedBox(width: 4),
            Text('Preview', style: FacultyTypography.labelMd(color: FacultyColors.secondary)),
          ],
        ),
      ),
    );
  }

  Widget _mobileCourseIdentityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _tag('ACTIVE COHORT', FacultyColors.tertiaryContainer, Colors.white, dot: true),
              _tag('TERM: FALL 2025', FacultyColors.surfaceContainerLow, FacultyColors.onSurfaceVariant),
              _tag('PY-402', FacultyColors.surfaceContainerLow, FacultyColors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Python for Enterprise Data Analysis & Automation',
            style: FacultyTypography.headlineLg(color: FacultyColors.primary),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.school, size: 16, color: FacultyColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Lead Instructor: Dr. Sarah Lin • Faculty of Applied Computing',
                  style: FacultyTypography.bodySm(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileKpiGrid() {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _mobileStatCard(
                  icon: Icons.group,
                  iconBg: FacultyColors.surfaceContainer,
                  iconColor: FacultyColors.secondary,
                  cornerBadge: _mobileBadgePill('+4 waitlist', FacultyColors.surfaceContainerLow, FacultyColors.tertiary),
                  value: '42',
                  label: 'Enrolled Students',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _mobileStatCard(
                  icon: Icons.assignment_turned_in,
                  iconBg: FacultyColors.errorContainer.withValues(alpha: 0.4),
                  iconColor: FacultyColors.error,
                  cornerBadge: _mobileBadgePill('Action req.', FacultyColors.errorContainer, FacultyColors.onErrorContainer, bold: true),
                  value: '14',
                  label: 'Assignments to Grade',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _mobileStatCard(
                  icon: Icons.quiz,
                  iconBg: FacultyColors.surfaceContainer,
                  iconColor: FacultyColors.secondary,
                  cornerBadge: _mobileBadgePill('8 checks', FacultyColors.surfaceContainer, FacultyColors.secondary),
                  value: '8',
                  label: 'Quizzes to Grade',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _mobileStatCard(
                  icon: Icons.trending_up,
                  iconBg: FacultyColors.surfaceContainer,
                  iconColor: FacultyColors.secondary,
                  cornerBadge: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      value: 0.72,
                      strokeWidth: 3,
                      backgroundColor: FacultyColors.surfaceContainerHigh,
                      valueColor: const AlwaysStoppedAnimation<Color>(FacultyColors.secondary),
                    ),
                  ),
                  value: '72%',
                  label: 'Cohort Progress',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mobileBadgePill(String text, Color bg, Color fg, {bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        text,
        style: FacultyTypography.labelXs(color: fg).copyWith(fontWeight: bold ? FontWeight.w700 : FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _mobileStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Widget cornerBadge,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              Flexible(child: cornerBadge),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: FacultyTypography.headlineLg(color: FacultyColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: FacultyTypography.labelXs().copyWith(fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _mobileGradingQueueSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.pending_actions, size: 20, color: FacultyColors.secondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Grading Queue & Deadlines', style: FacultyTypography.headlineMd(color: FacultyColors.primary), overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 6),
            _mobileBadgePill('3 Active', FacultyColors.surfaceContainerLow, FacultyColors.onSurfaceVariant, bold: true),
          ],
        ),
        const SizedBox(height: 10),
        _mobileQueueCard(
          badgeText: 'High Priority',
          badgeBg: FacultyColors.errorContainer.withValues(alpha: 0.4),
          badgeFg: FacultyColors.error,
          title: 'Assignment 02: Building Automated Data Pipelines',
          subtitle: 'Due Nov 15, 2025 • 36 / 42 Students Submitted',
          progressLabel: 'Submission Status',
          progressValueText: '85% turned in',
          progressValue: 0.857,
          buttonLabel: 'Grade Submissions (14)',
          buttonIcon: Icons.arrow_forward,
          buttonBg: FacultyColors.secondary,
          buttonFg: Colors.white,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GradeAssignmentScreen())),
        ),
        const SizedBox(height: 10),
        _mobileQueueCard(
          badgeText: 'Evaluation',
          badgeBg: FacultyColors.surfaceContainer,
          badgeFg: FacultyColors.secondary,
          title: 'Quiz 03: Compliance & Schema Handling',
          subtitle: 'Due Nov 18, 2025 • 40 / 42 Students Submitted',
          progressLabel: 'Completion Metric',
          progressValueText: '95% completed',
          progressValue: 0.952,
          buttonLabel: 'Review Answers (8)',
          buttonIcon: Icons.rate_review,
          buttonBg: FacultyColors.surfaceContainer,
          buttonFg: FacultyColors.secondary,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GradeQuizScreen())),
        ),
        const SizedBox(height: 10),
        _mobileUpcomingCard(),
      ],
    );
  }

  Widget _mobileQueueCard({
    required String badgeText,
    required Color badgeBg,
    required Color badgeFg,
    required String title,
    required String subtitle,
    required String progressLabel,
    required String progressValueText,
    required double progressValue,
    required String buttonLabel,
    required IconData buttonIcon,
    required Color buttonBg,
    required Color buttonFg,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(4)),
              child: Text(
                badgeText.toUpperCase(),
                style: FacultyTypography.labelXs(color: badgeFg).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(title, style: FacultyTypography.titleSm(color: FacultyColors.primary), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(subtitle, style: FacultyTypography.bodySm(), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(progressLabel, style: FacultyTypography.labelXs(), overflow: TextOverflow.ellipsis)),
                    Text(
                      progressValueText,
                      style: FacultyTypography.labelXs(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 8,
                    backgroundColor: FacultyColors.surfaceContainerHighest,
                    valueColor: const AlwaysStoppedAnimation<Color>(FacultyColors.secondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(buttonIcon, size: 18),
              label: Text(buttonLabel, overflow: TextOverflow.ellipsis),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonBg,
                foregroundColor: buttonFg,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: FacultyTypography.labelMd(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileUpcomingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _mobileBadgePill('Upcoming', FacultyColors.surfaceContainerLow, FacultyColors.onSurfaceVariant, bold: true),
                    Text('Dec 01, 2025', style: FacultyTypography.bodySm()),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Final Capstone Project Release', style: FacultyTypography.titleSm(color: FacultyColors.primary), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('Architecture review & automated rubric setup', style: FacultyTypography.bodySm(), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _notAvailable,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_calendar, size: 16, color: FacultyColors.onSurface),
                  const SizedBox(width: 4),
                  Text('Edit', style: FacultyTypography.labelMd()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileQuickAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.hub, size: 20, color: FacultyColors.secondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Quick Access', style: FacultyTypography.headlineMd(color: FacultyColors.primary), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _mobileHubItem(
          icon: Icons.menu_book,
          iconBg: FacultyColors.surfaceContainer,
          iconColor: FacultyColors.secondary,
          title: 'Curriculum & Materials',
          subtitle: '4 core modules • 28 assets uploaded',
          buttonLabel: 'Manage',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CurriculumManagerScreen())),
        ),
        const SizedBox(height: 10),
        _mobileHubItem(
          icon: Icons.badge,
          iconBg: FacultyColors.surfaceContainerLow,
          iconColor: FacultyColors.primary,
          badgeCount: '3',
          title: 'Student Directory',
          subtitle: '42 active learners • 3 flagged for follow-up',
          buttonLabel: 'View Roster',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentDirectoryScreen())),
        ),
      ],
    );
  }

  Widget _mobileHubItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    String? badgeCount,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              if (badgeCount != null)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: FacultyColors.error, shape: BoxShape.circle),
                    child: Text(
                      badgeCount,
                      style: FacultyTypography.labelXs(color: Colors.white).copyWith(fontSize: 9, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: FacultyTypography.titleSm(color: FacultyColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: FacultyTypography.bodySm(), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
              child: Text(
                buttonLabel,
                style: FacultyTypography.labelMd(color: FacultyColors.secondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileAnnouncementsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.campaign, size: 18, color: FacultyColors.secondary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Announcements', style: FacultyTypography.headlineMd(color: FacultyColors.primary), overflow: TextOverflow.ellipsis),
              ),
              InkWell(
                onTap: () => setState(() => _showAnnouncementForm = !_showAnnouncementForm),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(color: FacultyColors.secondary, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 16, color: Colors.white),
                      const SizedBox(width: 3),
                      Text('Post', style: FacultyTypography.labelMd(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _mobileAnnouncementItem(
            'Office hours moved to Thursday 3 PM',
            'Yesterday',
            'Live architectural consultation for data lake pipeline patterns will be conducted via Telemetry Room B.',
          ),
          const SizedBox(height: 8),
          _mobileAnnouncementItem(
            'Starter repo updated for Assignment 02',
            'Nov 08',
            'New pytest mocks for parquet stream validation are pushed to the main enterprise template.',
          ),
          if (_showAnnouncementForm) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Draft Quick Broadcast', style: FacultyTypography.labelMd()),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: FacultyColors.surfaceContainerLowest,
                      hintText: 'Subject line...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    maxLines: 2,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: FacultyColors.surfaceContainerLowest,
                      hintText: 'Announcement content...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _showAnnouncementForm = false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _showAnnouncementForm = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Announcement published.'), backgroundColor: FacultyColors.primary),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: FacultyColors.primary, foregroundColor: Colors.white, elevation: 0),
                        child: const Text('Publish'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _mobileAnnouncementItem(String title, String time, String body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: FacultyTypography.labelMd(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(time, style: FacultyTypography.labelXs()),
            ],
          ),
          const SizedBox(height: 4),
          Text(body, style: FacultyTypography.bodySm(), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _mobileGovernanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check, size: 20, color: FacultyColors.secondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Course Governance & Syllabus', style: FacultyTypography.headlineMd(color: FacultyColors.primary), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _mobileGovernanceTile('Passing Benchmark', '80% Aggregate', 'Inclusive of capstone audit'),
          const SizedBox(height: 8),
          _mobileGovernanceTile('Cohort Capacity', '42 / 50 Enrolled', '8 enterprise seats remaining'),
          const SizedBox(height: 8),
          _mobileGovernanceTile('Target Credential', 'Enterprise Python Specialist', 'AIEI Industry Accreditation'),
        ],
      ),
    );
  }

  Widget _mobileGovernanceTile(String label, String value, String footnote) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: FacultyTypography.labelXs().copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value, style: FacultyTypography.headlineMd(color: FacultyColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(footnote, style: FacultyTypography.bodySm(), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
