import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_mobile_top_bar.dart';
import 'widgets/admin_mobile_bottom_nav.dart';
import 'manage_lecturers_screen.dart';
import 'lecturer_allocation_screen.dart';
import 'manage_students_screen.dart';
import 'enroll_students_screen.dart';

// ---------------------------------------------------------------------------
// CourseEnrollmentScreen – Stitch "Manage Students of Courses" faithful
// Flutter conversion.
// ---------------------------------------------------------------------------
class CourseEnrollmentScreen extends StatefulWidget {
  const CourseEnrollmentScreen({super.key});

  @override
  State<CourseEnrollmentScreen> createState() => _CourseEnrollmentScreenState();
}

class _CourseEnrollmentScreenState extends State<CourseEnrollmentScreen> {
  static const _roster = [
    _RosterStudent('Alex Chen', 'EMP-88219', 'alex.chen@enterprise.com', 'Oct 12, 2024', 'Corporate Sponsored', 2, 2, 94, 3, 3, 90, 92.4, 'A', 'On Track', '2 hrs ago', true),
    _RosterStudent('Maya Patel', 'EMP-77402', 'maya.patel@enterprise.com', 'Oct 10, 2024', 'Corporate Sponsored', 2, 2, 98, 3, 3, 95, 96.1, 'A+', 'Cohort Top 5%', '35 mins ago', true),
    _RosterStudent('Liam Nguyen', 'EMP-66381', 'liam.nguyen@enterprise.com', 'Oct 14, 2024', 'Self-Enrolled (Direct)', 2, 2, 86, 3, 3, 91, 88.5, 'B+', 'On Track', 'Yesterday', true),
    _RosterStudent('Jordan Taylor', 'EMP-99214', 'jordan.taylor@enterprise.com', 'Oct 18, 2024', 'Corporate Sponsored', 1, 2, 70, 3, 3, 76, 73.2, 'C', 'At Risk (<80%)', '4 days ago', false, atRisk: true),
    _RosterStudent('Chloe Bennett', 'EMP-44820', 'chloe.bennett@enterprise.com', 'Oct 11, 2024', 'Corporate Sponsored', 2, 2, 90, 3, 3, 88, 89.0, 'B+', 'On Track', '5 hrs ago', true),
  ];

  final Set<String> _selected = {};

  void _handleNav(AdminNavDestination dest) {
    switch (dest) {
      case AdminNavDestination.manageLecturers:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageLecturersScreen()));
        break;
      case AdminNavDestination.lecturerAllocation:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LecturerAllocationScreen()));
        break;
      case AdminNavDestination.manageStudents:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageStudentsScreen()));
        break;
      case AdminNavDestination.courseEnrollment:
        break;
    }
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
    return AdminScaffold(
      selected: AdminNavDestination.courseEnrollment,
      onDestinationSelected: _handleNav,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 20),
          _buildCourseHeaderCard(),
          const SizedBox(height: 20),
          _buildMetrics(),
          const SizedBox(height: 20),
          _buildToolbar(),
          const SizedBox(height: 12),
          _buildTableCard(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text('ACADEMIC REGISTRATIONS', style: AdminTypography.labelSm(color: AdminColors.secondary).copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              Text('•', style: AdminTypography.labelSm()),
              const SizedBox(width: 6),
              Text('Section ID: SEC-PY402-FA25', style: AdminTypography.labelSm()),
            ]),
            const SizedBox(height: 4),
            Text('Manage Students of Courses', style: AdminTypography.headlineLg()),
            const SizedBox(height: 2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Text('Manage course enrollment caps, register students into course sections, and monitor student academic performance per course.', style: AdminTypography.bodyMd()),
            ),
          ],
        ),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
            onPressed: _notAvailable,
            icon: const Icon(Icons.file_download_outlined, size: 16),
            label: const Text('Export Roster'),
            style: OutlinedButton.styleFrom(foregroundColor: AdminColors.onSurface, backgroundColor: AdminColors.surfaceContainerLowest, side: BorderSide.none, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
          OutlinedButton.icon(
            onPressed: _notAvailable,
            icon: const Icon(Icons.move_up_outlined, size: 16),
            label: const Text('Drop / Transfer'),
            style: OutlinedButton.styleFrom(foregroundColor: AdminColors.onSurface, backgroundColor: AdminColors.surfaceContainerLowest, side: BorderSide.none, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EnrollStudentsScreen())),
            icon: const Icon(Icons.person_add_outlined, size: 16),
            label: const Text('+ Enroll Students'),
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primaryContainer, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ]),
      ],
    );
  }

  Widget _buildCourseHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: AdminColors.secondaryFixed, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.terminal, color: AdminColors.primary, size: 26)),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 6, children: [
                _tag('Active Cohort', AdminColors.surfaceContainer, AdminColors.onSurfaceVariant),
                _tag('Term: Fall 2025', AdminColors.secondaryFixed, AdminColors.onSecondaryFixedVariant),
                _tag('4 Credit Units', AdminColors.surfaceContainerHigh, AdminColors.onSurfaceVariant),
              ]),
              const SizedBox(height: 4),
              Text('PY-402: Python for Enterprise Data Analysis & Automation', style: AdminTypography.headlineSm()),
              const SizedBox(height: 4),
              Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.verified_user, size: 15, color: AdminColors.secondary),
                  const SizedBox(width: 4),
                  Text('Instructor: Dr. Sarah Lin', style: AdminTypography.bodySm(color: AdminColors.onSurface).copyWith(fontWeight: FontWeight.w600)),
                ]),
                Text('Schedule: Mon / Wed 18:00–20:30 UTC', style: AdminTypography.bodySm()),
              ]),
            ]),
          ]),
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Only PY-402 is available in this preview.'))),
            icon: const Icon(Icons.swap_horiz, size: 16, color: AdminColors.onSurfaceVariant),
            label: const Text('Switch Course Section'),
            style: OutlinedButton.styleFrom(foregroundColor: AdminColors.onSurface, backgroundColor: AdminColors.surfaceContainerLow, side: BorderSide.none, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
        child: Text(text, style: AdminTypography.labelSm(color: fg).copyWith(fontWeight: FontWeight.w600)),
      );

  Widget _buildMetrics() {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 500 ? 2 : 1);
      final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
      final cards = <Widget>[
        _metricCard('Enrolled Capacity', '42 / 50', Icons.group_outlined, progress: 0.84, footer: '84% filled', footerRight: '8 Seats Available'),
        _metricCard('Active Waitlist', '4 Students', Icons.hourglass_top_outlined, footer: 'Priority FIFO', action: 'Review Waitlist'),
        _metricCard('Benchmark Standard', '80%', Icons.verified_outlined, footer: 'Passing Criteria Threshold', tag: 'Strict Cutoff'),
        _metricCard('Aggregated Average Grade', '87.2%', Icons.analytics_outlined, footer: 'Assignments & Quizzes', trend: '+3.4% vs Prev. Cohort'),
      ];
      return Wrap(spacing: 16, runSpacing: 16, children: cards.map((c) => SizedBox(width: width, child: c)).toList());
    });
  }

  Widget _metricCard(String label, String value, IconData icon, {double? progress, String? footer, String? footerRight, String? action, String? tag, String? trend}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(label, style: AdminTypography.labelMd())),
            Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: AdminColors.surfaceContainer, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: AdminColors.primary)),
          ]),
          const SizedBox(height: 8),
          Text(value, style: AdminTypography.dataMetric()),
          const SizedBox(height: 10),
          if (progress != null) ...[
            ClipRRect(borderRadius: BorderRadius.circular(9999), child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: AdminColors.surfaceContainerHigh, valueColor: const AlwaysStoppedAnimation<Color>(AdminColors.primaryContainer))),
            const SizedBox(height: 6),
          ],
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            if (footer != null) Expanded(child: Text(footer, style: AdminTypography.bodySm())),
            if (footerRight != null) Text(footerRight, style: AdminTypography.labelSm(color: AdminColors.secondary).copyWith(fontWeight: FontWeight.w700)),
            if (action != null)
              GestureDetector(onTap: _notAvailable, child: Text(action, style: AdminTypography.labelSm(color: AdminColors.primary).copyWith(fontWeight: FontWeight.w700))),
            if (tag != null) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AdminColors.surfaceContainer, borderRadius: BorderRadius.circular(4)), child: Text(tag, style: AdminTypography.labelSm())),
            if (trend != null)
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.trending_up, size: 14, color: AdminColors.secondary),
                Text(trend, style: AdminTypography.labelSm(color: AdminColors.secondary).copyWith(fontWeight: FontWeight.w700)),
              ]),
          ]),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: TextField(
              style: AdminTypography.bodySm(color: AdminColors.onSurface),
              decoration: InputDecoration(isDense: true, filled: true, fillColor: AdminColors.surfaceContainerLow, hintText: 'Search enrolled students in PY-402...', hintStyle: AdminTypography.bodySm(color: AdminColors.outline), prefixIcon: const Icon(Icons.search, size: 18, color: AdminColors.onSurfaceVariant), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 10)),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _filterPill('All (42)', true),
              _filterPill('Passing (≥80%)', false),
              _filterPill('At Risk (<80%)', false),
              _filterPill('Incomplete', false),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _filterPill(String label, bool active) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: active ? AdminColors.surfaceContainerLowest : Colors.transparent, borderRadius: BorderRadius.circular(8), boxShadow: active ? const [BoxShadow(color: Color(0x0D000000), blurRadius: 4)] : null),
        child: Text(label, style: AdminTypography.titleSm(color: active ? AdminColors.onSurface : AdminColors.onSurfaceVariant)),
      );

  Widget _buildTableCard() {
    return Container(
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: 1180, child: Column(children: [for (final s in _roster) _rosterRow(s)])),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text('${_selected.length} of 42 students selected', style: AdminTypography.bodySm()),
                Text('Showing 1–5 of 42', style: AdminTypography.bodySm()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rosterRow(_RosterStudent s) {
    final selected = _selected.contains(s.employeeId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: const Border(bottom: BorderSide(color: AdminColors.surfaceContainer)), color: s.atRisk ? AdminColors.errorContainer.withValues(alpha: 0.1) : null),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(value: selected, onChanged: (v) => setState(() => v == true ? _selected.add(s.employeeId) : _selected.remove(s.employeeId)), activeColor: AdminColors.primaryContainer),
          SizedBox(
            width: 220,
            child: Row(children: [
              Container(width: 36, height: 36, decoration: const BoxDecoration(color: AdminColors.surfaceContainerHigh, shape: BoxShape.circle), child: const Icon(Icons.person, color: AdminColors.primary, size: 18)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.name, style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis),
                Text(s.employeeId, style: AdminTypography.labelSm()),
                Text(s.email, style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
              ])),
            ]),
          ),
          SizedBox(width: 150, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.enrolledDate, style: AdminTypography.titleSm()),
            Text(s.sponsorship, style: AdminTypography.labelSm()),
          ])),
          SizedBox(width: 170, child: _progressCell('${s.assignDone} of ${s.assignTotal} Completed', s.assignPct, s.assignPct >= 100)),
          SizedBox(width: 170, child: _progressCell('${s.quizDone} of ${s.quizTotal} Completed', s.quizPct, true)),
          SizedBox(width: 130, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: s.atRisk ? AdminColors.errorContainer : AdminColors.secondaryFixed, borderRadius: BorderRadius.circular(9999)),
            child: Text('${s.grade}% (${s.letterGrade})', style: AdminTypography.labelMd(color: s.atRisk ? AdminColors.onErrorContainer : AdminColors.onSecondaryFixedVariant)),
          )),
          SizedBox(width: 120, child: Text(s.lastActive, style: AdminTypography.bodySm(color: s.online ? AdminColors.onSurface : AdminColors.onSurfaceVariant))),
          SizedBox(
            width: 110,
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(onPressed: _notAvailable, icon: const Icon(Icons.bar_chart, size: 18), tooltip: 'View Grades', color: AdminColors.onSurfaceVariant, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                const SizedBox(width: 8),
                IconButton(onPressed: _notAvailable, icon: const Icon(Icons.person_remove_outlined, size: 18), tooltip: 'Drop', color: AdminColors.error, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressCell(String label, int pct, bool good) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(label, style: AdminTypography.labelSm(color: good ? AdminColors.onSurface : AdminColors.error).copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
          Text('$pct%', style: AdminTypography.labelSm(color: good ? AdminColors.secondary : AdminColors.error).copyWith(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 3),
        ClipRRect(borderRadius: BorderRadius.circular(9999), child: LinearProgressIndicator(value: pct / 100, minHeight: 5, backgroundColor: AdminColors.surfaceContainerHigh, valueColor: AlwaysStoppedAnimation<Color>(good ? AdminColors.primaryContainer : AdminColors.error))),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Mobile (< 700px) layout — separate Scaffold, reuses the same _roster data.
  // -------------------------------------------------------------------------

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: const AdminMobileTopBar.root(title: 'Course Cohorts'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _mobileStatusStrip(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _mobileHeader(),
                  const SizedBox(height: 16),
                  _mobileQuickActions(context),
                  const SizedBox(height: 16),
                  _mobileCohortCard(),
                  const SizedBox(height: 16),
                  _mobileMetricsGrid(),
                  const SizedBox(height: 16),
                  _mobileSearchField(),
                  const SizedBox(height: 10),
                  _mobileFilterChips(),
                  const SizedBox(height: 16),
                  for (final s in _roster) ...[
                    _mobileStudentCard(s),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminMobileBottomNav(
        selected: AdminMobileTab.cohorts,
        onTap: (tab) {
          switch (tab) {
            case AdminMobileTab.lecturers:
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageLecturersScreen()));
              break;
            case AdminMobileTab.students:
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageStudentsScreen()));
              break;
            case AdminMobileTab.cohorts:
              break;
            case AdminMobileTab.enroll:
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EnrollStudentsScreen()));
              break;
          }
        },
      ),
    );
  }

  Widget _mobileStatusStrip() {
    return Container(
      color: AdminColors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: AdminColors.tertiaryContainer, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Flexible(child: Text('Academic Registrations', style: AdminTypography.labelSm(), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 6),
                Text('•', style: AdminTypography.labelSm(color: AdminColors.outlineVariant)),
                const SizedBox(width: 6),
                Text('SEC-PY402-FA25', style: AdminTypography.labelSm(color: AdminColors.primary).copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AdminColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
            child: Text('Live Sync', style: AdminTypography.labelSm(color: AdminColors.secondary)),
          ),
        ],
      ),
    );
  }

  Widget _mobileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ROSTER CONTROL', style: AdminTypography.labelSm(color: AdminColors.secondary).copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.0)),
            Text('Fall 2025', style: AdminTypography.labelSm()),
          ],
        ),
        const SizedBox(height: 4),
        Text('Manage Students', style: AdminTypography.headlineLg(color: AdminColors.primary)),
        const SizedBox(height: 4),
        Text('Manage course caps, register learners, and track academic telemetry.', style: AdminTypography.bodySm()),
      ],
    );
  }

  Widget _mobileQuickActions(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EnrollStudentsScreen())),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('+ Enroll Students'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.secondary,
              foregroundColor: AdminColors.onSecondary,
              elevation: 1,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: _notAvailable,
            icon: const Icon(Icons.unfold_more, size: 18),
            label: const Text('SEC-PY402 (Active)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminColors.onSurfaceVariant,
              backgroundColor: AdminColors.surfaceContainerLowest,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: _notAvailable,
            icon: const Icon(Icons.file_download, size: 18),
            label: const Text('Export'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminColors.onSurfaceVariant,
              backgroundColor: AdminColors.surfaceContainerLowest,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: _notAvailable,
            icon: const Icon(Icons.swap_horiz, size: 18),
            label: const Text('Drop/Transfer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminColors.onSurfaceVariant,
              backgroundColor: AdminColors.surfaceContainerLowest,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileCohortCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
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
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      _tag('PY-402', AdminColors.primary, AdminColors.onPrimary),
                      _tag('4 Credit Units', AdminColors.surfaceContainerHigh, AdminColors.onSurfaceVariant),
                    ]),
                    const SizedBox(height: 6),
                    Text('Python for Enterprise Data Analysis & Automation', style: AdminTypography.headlineSm(color: AdminColors.primary)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AdminColors.secondaryFixed.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.terminal, color: AdminColors.secondary, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(radius: 14, backgroundColor: AdminColors.surfaceContainerHigh, child: Icon(Icons.person, size: 16, color: AdminColors.primary)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dr. Sarah Lin', style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis),
                          Text('Lead Data Architect & Research Fellow', style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: AdminColors.outline),
                    const SizedBox(width: 6),
                    Expanded(child: Text('Mon / Wed 18:00 – 20:30 UTC • Virtual Lab', style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileMetricsGrid() {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _mobileMetricTile(
                  label: 'Capacity',
                  value: '42 / 50',
                  icon: Icons.group_outlined,
                  progress: 0.84,
                  footerLeft: '84% filled',
                  footerRight: '8 Seats Available',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _mobileMetricTile(
                  label: 'Waitlist',
                  value: '4 Learners',
                  icon: Icons.hourglass_top_outlined,
                  footerAction: 'Review Queue',
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
                child: _mobileMetricTile(
                  label: 'Benchmark',
                  value: '80%',
                  icon: Icons.verified_outlined,
                  footerLeft: 'Passing Threshold',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _mobileMetricTile(
                  label: 'Avg Grade',
                  value: '87.2%',
                  icon: Icons.analytics_outlined,
                  trend: '+3.4% vs Prev.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mobileMetricTile({
    required String label,
    required String value,
    required IconData icon,
    double? progress,
    String? footerLeft,
    String? footerRight,
    String? footerAction,
    String? trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AdminTypography.labelMd(), overflow: TextOverflow.ellipsis)),
              Icon(icon, size: 16, color: AdminColors.primary),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: AdminTypography.headlineSm(color: AdminColors.primary)),
          const SizedBox(height: 8),
          if (progress != null) ...[
            ClipRRect(borderRadius: BorderRadius.circular(9999), child: LinearProgressIndicator(value: progress, minHeight: 5, backgroundColor: AdminColors.surfaceContainerHigh, valueColor: const AlwaysStoppedAnimation<Color>(AdminColors.primaryContainer))),
            const SizedBox(height: 6),
          ],
          if (footerLeft != null) Text(footerLeft, style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
          if (footerRight != null)
            Text(footerRight, style: AdminTypography.labelSm(color: AdminColors.secondary).copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
          if (footerAction != null)
            GestureDetector(
              onTap: _notAvailable,
              child: Row(children: [
                Flexible(
                  child: Text(
                    footerAction,
                    overflow: TextOverflow.ellipsis,
                    style: AdminTypography.labelSm(color: AdminColors.primary).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward, size: 12, color: AdminColors.primary),
              ]),
            ),
          if (trend != null)
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.trending_up, size: 12, color: AdminColors.secondary),
              const SizedBox(width: 2),
              Flexible(child: Text(trend, style: AdminTypography.labelSm(color: AdminColors.secondary).copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
            ]),
        ],
      ),
    );
  }

  Widget _mobileSearchField() {
    return TextField(
      style: AdminTypography.bodySm(color: AdminColors.onSurface),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AdminColors.surfaceContainerLowest,
        hintText: 'Search by name, ID or email...',
        hintStyle: AdminTypography.bodySm(color: AdminColors.outline),
        prefixIcon: const Icon(Icons.search, size: 20, color: AdminColors.outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _mobileFilterChips() {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _mobileFilterChip('All', '42', true),
          const SizedBox(width: 8),
          _mobileFilterChip('Passing (≥80%)', '38', false),
          const SizedBox(width: 8),
          _mobileFilterChip('At Risk (<80%)', '4', false, badgeColor: AdminColors.errorContainer, badgeTextColor: AdminColors.onErrorContainer),
          const SizedBox(width: 8),
          _mobileFilterChip('Incomplete', '1', false),
        ],
      ),
    );
  }

  Widget _mobileFilterChip(String label, String count, bool active, {Color? badgeColor, Color? badgeTextColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: active ? AdminColors.secondary : AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4)]),
      alignment: Alignment.center,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: AdminTypography.labelMd(color: active ? AdminColors.onSecondary : AdminColors.onSurfaceVariant)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(color: active ? Colors.white.withValues(alpha: 0.2) : (badgeColor ?? AdminColors.surfaceContainer), borderRadius: BorderRadius.circular(8)),
          child: Text(count, style: AdminTypography.labelSm(color: active ? AdminColors.onSecondary : (badgeTextColor ?? AdminColors.onSurfaceVariant)).copyWith(fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _mobileStudentCard(_RosterStudent s) {
    final selected = _selected.contains(s.employeeId);
    final compact = !s.atRisk && s.standing.toLowerCase().contains('top');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: s.atRisk ? AdminColors.errorContainer.withValues(alpha: 0.12) : AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: selected,
                onChanged: (v) => setState(() => v == true ? _selected.add(s.employeeId) : _selected.remove(s.employeeId)),
                activeColor: AdminColors.primaryContainer,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 4),
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(color: AdminColors.surfaceContainerHigh, shape: BoxShape.circle),
                child: const Icon(Icons.person, color: AdminColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: AdminTypography.headlineSm(), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(children: [
                      Flexible(
                        child: Text(s.employeeId, style: AdminTypography.labelSm(), overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      Text('•', style: AdminTypography.bodySm()),
                      const SizedBox(width: 6),
                      Expanded(flex: 2, child: Text(s.email, style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 4),
                    Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(6)),
                        child: Text(s.sponsorship, style: AdminTypography.labelSm(color: AdminColors.secondary).copyWith(fontWeight: FontWeight.w700)),
                      ),
                      Text(s.enrolledDate, style: AdminTypography.bodySm(color: AdminColors.outline)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${s.grade}%', style: AdminTypography.headlineSm(color: s.atRisk ? AdminColors.error : AdminColors.primary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: s.atRisk ? AdminColors.errorContainer : AdminColors.tertiaryFixed, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    s.standing,
                    style: AdminTypography.labelSm(color: s.atRisk ? AdminColors.onErrorContainer : AdminColors.onTertiaryFixedVariant).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          if (s.atRisk)
            _mobileAtRiskPanel(s)
          else if (compact)
            _mobileCompactPanel(s)
          else
            _mobileBreakdownPanel(s),
          const SizedBox(height: 8),
          if (s.atRisk)
            Row(children: [
              const Icon(Icons.notification_important, size: 16, color: AdminColors.error),
              const SizedBox(width: 6),
              Expanded(child: Text('Academic Warning — Intervention Suggested', style: AdminTypography.labelSm(color: AdminColors.error).copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
            ])
          else
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton.icon(
                onPressed: _notAvailable,
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('Transcript'),
                style: TextButton.styleFrom(foregroundColor: AdminColors.onSurfaceVariant, padding: const EdgeInsets.symmetric(horizontal: 8)),
              ),
              TextButton.icon(
                onPressed: _notAvailable,
                icon: const Icon(Icons.mail, size: 16),
                label: const Text('Message'),
                style: TextButton.styleFrom(foregroundColor: AdminColors.onSurfaceVariant, padding: const EdgeInsets.symmetric(horizontal: 8)),
              ),
            ]),
        ],
      ),
    );
  }

  Widget _mobileBreakdownPanel(_RosterStudent s) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        _mobileProgressRow('Assignments: ${s.assignDone} of ${s.assignTotal} (${s.assignPct}%)', s.assignPct),
        const SizedBox(height: 8),
        _mobileProgressRow('Quizzes: ${s.quizDone} of ${s.quizTotal} (${s.quizPct}%)', s.quizPct),
      ]),
    );
  }

  Widget _mobileAtRiskPanel(_RosterStudent s) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        _mobileProgressRow('Assignments: ${s.assignDone} of ${s.assignTotal} (${s.assignPct}%)', s.assignPct),
        const SizedBox(height: 8),
        _mobileProgressRow('Quizzes: ${s.quizDone} of ${s.quizTotal} (${s.quizPct}%)', s.quizPct),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.warning, size: 14, color: AdminColors.error),
          const SizedBox(width: 4),
          Expanded(child: Text('Below passing threshold', style: AdminTypography.labelSm(color: AdminColors.error), overflow: TextOverflow.ellipsis)),
        ]),
      ]),
    );
  }

  Widget _mobileCompactPanel(_RosterStudent s) {
    final done = s.assignDone + s.quizDone;
    final total = s.assignTotal + s.quizTotal;
    final pct = total == 0 ? 0 : ((done / total) * 100).round();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        const Icon(Icons.checklist, size: 16, color: AdminColors.secondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Core Milestones: $done of $total Complete ($pct%)',
            style: AdminTypography.labelSm(color: AdminColors.onSurface).copyWith(fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }

  Widget _mobileProgressRow(String label, int pct) {
    final good = pct >= 80;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AdminTypography.labelSm(color: AdminColors.onSurface).copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(9999),
          child: LinearProgressIndicator(value: pct / 100, minHeight: 5, backgroundColor: AdminColors.surfaceContainerHighest, valueColor: AlwaysStoppedAnimation<Color>(good ? AdminColors.secondary : AdminColors.error)),
        ),
      ],
    );
  }
}

class _RosterStudent {
  final String name, employeeId, email, enrolledDate, sponsorship, letterGrade, standing, lastActive;
  final int assignDone, assignTotal, assignPct, quizDone, quizTotal, quizPct;
  final double grade;
  final bool online, atRisk;

  const _RosterStudent(
    this.name,
    this.employeeId,
    this.email,
    this.enrolledDate,
    this.sponsorship,
    this.assignDone,
    this.assignTotal,
    this.assignPct,
    this.quizDone,
    this.quizTotal,
    this.quizPct,
    this.grade,
    this.letterGrade,
    this.standing,
    this.lastActive,
    this.online, {
    this.atRisk = false,
  });
}
