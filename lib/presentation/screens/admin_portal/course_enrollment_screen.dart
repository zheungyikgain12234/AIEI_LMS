import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_students_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/roster_student.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_mobile_top_bar.dart';
import 'widgets/admin_nav.dart';
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
  final _repository = SupabaseAdminStudentsRepositoryImpl(Supabase.instance.client);
  bool _isLoading = true;
  Map<String, dynamic>? _course;
  List<RosterStudent> _roster = [];

  final Set<String> _selected = {};

  String get _courseCode => (_course?['course_code'] as String?) ?? '';
  String get _courseTitle => (_course?['course_title'] as String?) ?? '';
  int get _capacity => (_course?['capacity'] as int?) ?? 0;
  int get _enrolledCount => _roster.length;
  int get _atRiskCount => _roster.where((s) => _isAtRisk(s.riskStatus)).length;
  int get _passingCount => _roster.length - _atRiskCount;

  double? get _averageScore {
    final scores = _roster.map((s) => s.overallScore).whereType<double>().toList();
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final course = await Supabase.instance.client.from('courses').select().eq('id', DemoIdentity.courseSecId).single();
    final roster = await _repository.getCourseRoster(DemoIdentity.courseSecId);
    if (!mounted) return;
    setState(() {
      _course = course;
      _roster = roster;
      _isLoading = false;
    });
  }

  String _riskLabel(String risk) {
    switch (risk) {
      case 'at_risk':
        return 'At Risk';
      case 'critical':
        return 'Critical';
      default:
        return 'On Track';
    }
  }

  bool _isAtRisk(String risk) => risk != 'on_track';

  static const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  String _formatDate(DateTime d) => '${_monthNames[d.month - 1]} ${d.day}, ${d.year}';

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    if (diff.inDays < 2) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  void _handleNav(AdminNavDestination dest) =>
      handleAdminNav(context, AdminNavDestination.courseEnrollment, dest);

  void _notAvailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Not wired up in this preview.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
              Text('Course: $_courseCode', style: AdminTypography.labelSm()),
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
                _tag('$_enrolledCount / $_capacity Enrolled', AdminColors.secondaryFixed, AdminColors.onSecondaryFixedVariant),
              ]),
              const SizedBox(height: 4),
              Text('$_courseCode: $_courseTitle', style: AdminTypography.headlineSm()),
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
      final fillPct = _capacity == 0 ? 0.0 : _enrolledCount / _capacity;
      final cards = <Widget>[
        _metricCard('Enrolled Capacity', '$_enrolledCount / $_capacity', Icons.group_outlined,
            progress: fillPct, footer: '${(fillPct * 100).round()}% filled', footerRight: '${_capacity - _enrolledCount} Seats Available'),
        _metricCard('Passing (On Track)', '$_passingCount Students', Icons.verified_outlined, footer: 'Risk status: on track'),
        _metricCard('At Risk / Critical', '$_atRiskCount Students', Icons.warning_amber_outlined, footer: 'Risk status: at risk or critical'),
        _metricCard('Aggregated Average Grade', _averageScore == null ? '—' : '${_averageScore!.toStringAsFixed(1)}%', Icons.analytics_outlined, footer: 'Across graded students'),
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
              decoration: InputDecoration(isDense: true, filled: true, fillColor: AdminColors.surfaceContainerLow, hintText: 'Search enrolled students in $_courseCode...', hintStyle: AdminTypography.bodySm(color: AdminColors.outline), prefixIcon: const Icon(Icons.search, size: 18, color: AdminColors.onSurfaceVariant), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 10)),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _filterPill('All ($_enrolledCount)', true),
              _filterPill('Passing ($_passingCount)', false),
              _filterPill('At Risk ($_atRiskCount)', false),
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
                Text('${_selected.length} of $_enrolledCount students selected', style: AdminTypography.bodySm()),
                Text('Showing 1–$_enrolledCount of $_enrolledCount', style: AdminTypography.bodySm()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rosterRow(RosterStudent s) {
    final selected = _selected.contains(s.employeeId);
    final atRisk = _isAtRisk(s.riskStatus);
    final gradeLabel = s.overallScore != null ? '${s.overallScore!.toStringAsFixed(1)}% (${s.grade ?? '—'})' : 'No grade yet';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: const Border(bottom: BorderSide(color: AdminColors.surfaceContainer)), color: atRisk ? AdminColors.errorContainer.withValues(alpha: 0.1) : null),
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
            Text(_formatDate(s.enrolledAt), style: AdminTypography.titleSm()),
            Text(s.sponsorship, style: AdminTypography.labelSm()),
          ])),
          SizedBox(width: 170, child: _progressCell('${s.progressPercentage}% Course Progress', s.progressPercentage, s.progressPercentage >= 80)),
          SizedBox(width: 170, child: _progressCell('${s.attendancePercentage}% Attendance', s.attendancePercentage, s.attendancePercentage >= 80)),
          SizedBox(width: 130, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: atRisk ? AdminColors.errorContainer : AdminColors.secondaryFixed, borderRadius: BorderRadius.circular(9999)),
            child: Text(gradeLabel, style: AdminTypography.labelMd(color: atRisk ? AdminColors.onErrorContainer : AdminColors.onSecondaryFixedVariant)),
          )),
          SizedBox(width: 120, child: Text(_timeAgo(s.lastActivityAt), style: AdminTypography.bodySm(color: s.isOnlineNow ? AdminColors.onSurface : AdminColors.onSurfaceVariant))),
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
      appBar: const AdminMobileTopBar.detail(title: 'Course Cohorts'),
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
                Text(_courseCode, style: AdminTypography.labelSm(color: AdminColors.primary).copyWith(fontWeight: FontWeight.w700)),
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
            label: Text('$_courseCode (Active)'),
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
                      _tag(_courseCode, AdminColors.primary, AdminColors.onPrimary),
                      _tag('$_enrolledCount / $_capacity Enrolled', AdminColors.surfaceContainerHigh, AdminColors.onSurfaceVariant),
                    ]),
                    const SizedBox(height: 6),
                    Text(_courseTitle, style: AdminTypography.headlineSm(color: AdminColors.primary)),
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
    final fillPct = _capacity == 0 ? 0.0 : _enrolledCount / _capacity;
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _mobileMetricTile(
                  label: 'Capacity',
                  value: '$_enrolledCount / $_capacity',
                  icon: Icons.group_outlined,
                  progress: fillPct,
                  footerLeft: '${(fillPct * 100).round()}% filled',
                  footerRight: '${_capacity - _enrolledCount} Seats Available',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _mobileMetricTile(
                  label: 'At Risk',
                  value: '$_atRiskCount Students',
                  icon: Icons.warning_amber_outlined,
                  footerLeft: 'Risk status: at risk / critical',
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
                  label: 'Passing',
                  value: '$_passingCount Students',
                  icon: Icons.verified_outlined,
                  footerLeft: 'Risk status: on track',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _mobileMetricTile(
                  label: 'Avg Grade',
                  value: _averageScore == null ? '—' : '${_averageScore!.toStringAsFixed(1)}%',
                  icon: Icons.analytics_outlined,
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
          _mobileFilterChip('All', '$_enrolledCount', true),
          const SizedBox(width: 8),
          _mobileFilterChip('Passing', '$_passingCount', false),
          const SizedBox(width: 8),
          _mobileFilterChip('At Risk', '$_atRiskCount', false, badgeColor: AdminColors.errorContainer, badgeTextColor: AdminColors.onErrorContainer),
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

  Widget _mobileStudentCard(RosterStudent s) {
    final selected = _selected.contains(s.employeeId);
    final atRisk = _isAtRisk(s.riskStatus);
    final gradeLabel = s.overallScore != null ? '${s.overallScore!.toStringAsFixed(0)}%' : '—';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: atRisk ? AdminColors.errorContainer.withValues(alpha: 0.12) : AdminColors.surfaceContainerLowest,
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
                      Text(_formatDate(s.enrolledAt), style: AdminTypography.bodySm(color: AdminColors.outline)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(gradeLabel, style: AdminTypography.headlineSm(color: atRisk ? AdminColors.error : AdminColors.primary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: atRisk ? AdminColors.errorContainer : AdminColors.tertiaryFixed, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    _riskLabel(s.riskStatus),
                    style: AdminTypography.labelSm(color: atRisk ? AdminColors.onErrorContainer : AdminColors.onTertiaryFixedVariant).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          if (atRisk) _mobileAtRiskPanel(s) else _mobileBreakdownPanel(s),
          const SizedBox(height: 8),
          if (atRisk)
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

  Widget _mobileBreakdownPanel(RosterStudent s) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        _mobileProgressRow('Course Progress (${s.progressPercentage}%)', s.progressPercentage),
        const SizedBox(height: 8),
        _mobileProgressRow('Attendance (${s.attendancePercentage}%)', s.attendancePercentage),
      ]),
    );
  }

  Widget _mobileAtRiskPanel(RosterStudent s) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        _mobileProgressRow('Course Progress (${s.progressPercentage}%)', s.progressPercentage),
        const SizedBox(height: 8),
        _mobileProgressRow('Attendance (${s.attendancePercentage}%)', s.attendancePercentage),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.warning, size: 14, color: AdminColors.error),
          const SizedBox(width: 4),
          Expanded(child: Text('Below passing threshold', style: AdminTypography.labelSm(color: AdminColors.error), overflow: TextOverflow.ellipsis)),
        ]),
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
