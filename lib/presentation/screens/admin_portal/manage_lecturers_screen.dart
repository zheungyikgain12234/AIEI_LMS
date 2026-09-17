import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturers_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/lecturer.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_mobile_top_bar.dart';
import 'widgets/admin_mobile_bottom_nav.dart';
import 'widgets/admin_nav.dart';
import 'manage_students_screen.dart';
import 'course_enrollment_screen.dart';
import 'enroll_students_screen.dart';
import 'lecturer_form_screen.dart';
import 'lecturer_course_assignment_screen.dart';

// ---------------------------------------------------------------------------
// ManageLecturersScreen – Stitch "Manage Lecturers" faithful Flutter
// conversion.
// ---------------------------------------------------------------------------
class ManageLecturersScreen extends StatefulWidget {
  const ManageLecturersScreen({super.key});

  @override
  State<ManageLecturersScreen> createState() => _ManageLecturersScreenState();
}

class _ManageLecturersScreenState extends State<ManageLecturersScreen> {
  final _repository = SupabaseLecturersRepositoryImpl(Supabase.instance.client);
  bool _isLoading = true;
  List<Lecturer> _lecturers = [];
  Map<String, List<String>> _courseCodesByLecturer = {};
  final Set<String> _selected = {};

  List<String> _coursesFor(Lecturer l) => _courseCodesByLecturer[l.id] ?? const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lecturers = await _repository.getLecturers();
    final codes = await _repository.getLecturerCourseCodes();
    if (!mounted) return;
    setState(() {
      _lecturers = lecturers;
      _courseCodesByLecturer = codes;
      _isLoading = false;
    });
  }

  void _handleNav(AdminNavDestination dest) =>
      handleAdminNav(context, AdminNavDestination.manageLecturers, dest);

  void _notAvailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Not wired up in this preview.')),
    );
  }

  Future<void> _openAssignedCourses(Lecturer l) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LecturerCourseAssignmentScreen(lecturerId: l.id)),
    );
    _load();
  }

  Future<void> _openAddLecturer() async {
    final saved = await Navigator.of(context).push<Lecturer>(
      MaterialPageRoute(builder: (_) => const LecturerFormScreen()),
    );
    if (saved != null) _load();
  }

  Future<void> _openEditLecturer(Lecturer l) async {
    final saved = await Navigator.of(context).push<Lecturer>(
      MaterialPageRoute(builder: (_) => LecturerFormScreen(lecturerId: l.id)),
    );
    if (saved != null) _load();
  }

  Future<void> _deleteSelected() async {
    final count = _selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete lecturers?'),
        content: Text('This will permanently delete $count lecturer${count == 1 ? '' : 's'}. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AdminColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.deleteLecturers(_selected.toList());
    if (!mounted) return;
    setState(_selected.clear);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$count lecturer${count == 1 ? '' : 's'} deleted')),
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
      selected: AdminNavDestination.manageLecturers,
      onDestinationSelected: _handleNav,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 20),
          _buildMetrics(),
          const SizedBox(height: 20),
          _buildDirectoryCard(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 16,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AdminColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(4)),
                child: Text('Faculty Governance', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant)),
              ),
              Text('/ Q3 Academic Term', style: AdminTypography.labelSm()),
            ]),
            const SizedBox(height: 4),
            Text('Manage Lecturers', style: AdminTypography.headlineLg()),
            const SizedBox(height: 2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Text('Institutional faculty roster, onboarding, credentials, and departmental appointments.', style: AdminTypography.bodyMd()),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _openAddLecturer,
          icon: const Icon(Icons.person_add_outlined, size: 18),
          label: const Text('+ Add New Lecturer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.primaryContainer,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildMetrics() {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 700 ? 2 : 1;
      final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
      final cards = [
        _metricCard('TOTAL FACULTY', '38 Active', Icons.groups_outlined, '+3', 'vs last quarter onboarding', 0.82),
        _metricCard('ASSIGNED COURSES', '112 Sections', Icons.menu_book_outlined, null, '94% capacity across 4 schools', 0.94),
      ];
      return Wrap(spacing: 16, runSpacing: 16, children: cards.map((c) => SizedBox(width: width, child: c)).toList());
    });
  }

  Widget _metricCard(String label, String value, IconData icon, String? delta, String footer, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(label, style: AdminTypography.labelMd().copyWith(fontWeight: FontWeight.w600))),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: AdminColors.primary, size: 18),
            ),
          ]),
          const SizedBox(height: 8),
          Text(value, style: AdminTypography.dataMetric()),
          const SizedBox(height: 4),
          Row(children: [
            if (delta != null) ...[
              Icon(Icons.arrow_upward, size: 13, color: AdminColors.secondary),
              Text(delta, style: AdminTypography.labelMd(color: AdminColors.secondary)),
              const SizedBox(width: 4),
            ],
            Expanded(child: Text(footer, style: AdminTypography.labelSm())),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(value: progress, minHeight: 4, backgroundColor: AdminColors.surfaceContainerLow, valueColor: const AlwaysStoppedAnimation<Color>(AdminColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryCard() {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AdminColors.surfaceContainerLow,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: TextField(
                    style: AdminTypography.bodySm(color: AdminColors.onSurface),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: AdminColors.surfaceContainerLowest,
                      hintText: 'Search by faculty name, employee ID, email, or department...',
                      hintStyle: AdminTypography.bodySm(color: AdminColors.outline),
                      prefixIcon: const Icon(Icons.search, size: 18, color: AdminColors.onSurfaceVariant),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(color: AdminColors.surfaceContainer, borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _statusPill('All Status', true),
                    _statusPill('Active', false),
                    _statusPill('Contract', false),
                  ]),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.tune, size: 16, color: AdminColors.onSurfaceVariant),
                  label: const Text('More Filters'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminColors.onSurface,
                    backgroundColor: AdminColors.surfaceContainerLowest,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: AdminTypography.labelSm(),
                  ),
                ),
              ],
            ),
          ),
          if (_selected.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_box, size: 18, color: AdminColors.secondary),
                    const SizedBox(width: 6),
                    Text('${_selected.length} lecturer${_selected.length == 1 ? '' : 's'} selected', style: AdminTypography.titleSm()),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(_selected.clear),
                      child: Text('Deselect all', style: AdminTypography.labelMd(color: AdminColors.secondary)),
                    ),
                  ]),
                  OutlinedButton.icon(
                    onPressed: _deleteSelected,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminColors.error,
                      backgroundColor: AdminColors.errorContainer,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: AdminTypography.labelSm(),
                    ),
                  ),
                ],
              ),
            ),
          Column(children: [for (final l in _lecturers) _lecturerRow(l, _coursesFor(l))]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Showing 1 – 5 of 38 faculty members', style: AdminTypography.bodySm()),
                Row(mainAxisSize: MainAxisSize.min, children: [1, 2, 3].map((p) {
                  final active = p == 1;
                  return Container(
                    margin: const EdgeInsets.only(left: 4),
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: active ? AdminColors.primaryContainer : AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
                    child: Text('$p', style: AdminTypography.labelSm(color: active ? Colors.white : AdminColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
                  );
                }).toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: active ? AdminColors.surfaceContainerLowest : Colors.transparent, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: AdminTypography.labelSm(color: active ? AdminColors.onSurface : AdminColors.onSurfaceVariant)),
    );
  }

  Widget _lecturerRow(Lecturer l, List<String> courses) {
    final selected = _selected.contains(l.id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AdminColors.surfaceContainer))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: selected,
            onChanged: (v) => setState(() => v == true ? _selected.add(l.id) : _selected.remove(l.id)),
            activeColor: AdminColors.primaryContainer,
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(color: AdminColors.surfaceContainerHigh, shape: BoxShape.circle),
                    child: const Icon(Icons.person, color: AdminColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(l.name, style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis)),
                            if (l.accredited) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.verified, size: 14, color: AdminColors.secondary)),
                            const SizedBox(width: 2),
                            InkWell(
                              onTap: () => _openEditLecturer(l),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(Icons.edit_outlined, size: 14, color: AdminColors.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                        Text(l.title, style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
                        Text('${l.employeeId} • ${l.email}', style: AdminTypography.labelSm(), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.department, style: AdminTypography.titleSm()),
                  Text(l.specialization, style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(courses.isEmpty ? '0 Courses Assigned' : '${courses.length} Active Courses',
                      style: AdminTypography.labelSm(color: courses.isEmpty ? AdminColors.onSurfaceVariant : AdminColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 4, runSpacing: 4, children: courses.map((c) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AdminColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(4)),
                    child: Text(c, style: AdminTypography.labelSm(color: AdminColors.onPrimaryFixed).copyWith(fontWeight: FontWeight.w700)),
                  )).toList()),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${l.creditsUsed} / ${l.creditsMax}', style: AdminTypography.labelSm(color: AdminColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
                    Text('${l.capacityPercent}%', style: AdminTypography.labelSm(color: l.capacityPercent >= 100 ? AdminColors.secondary : AdminColors.onSurfaceVariant)),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: LinearProgressIndicator(
                      value: l.capacityPercent / 100,
                      minHeight: 6,
                      backgroundColor: AdminColors.surfaceContainerHigh,
                      valueColor: AlwaysStoppedAnimation<Color>(l.capacityPercent >= 100 ? AdminColors.secondary : AdminColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: l.status == 'Active' ? AdminColors.surfaceContainerLow : AdminColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: l.status == 'Active' ? AdminColors.primary : AdminColors.onSurfaceVariant, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l.status,
                      overflow: TextOverflow.ellipsis,
                      style: AdminTypography.labelSm(color: l.status == 'Active' ? AdminColors.primary : AdminColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ]),
              ),
            ),
          ),
          SizedBox(
            width: 170,
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => _openAssignedCourses(l),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminColors.primary,
                  backgroundColor: AdminColors.surfaceContainerLow,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: AdminTypography.labelSm(),
                ),
                child: const Text('Manage Assigned Courses'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Mobile (<700px) layout
  // ---------------------------------------------------------------------

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: const AdminMobileTopBar.root(title: 'Lecturers'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _mobileEyebrowRow(),
              const SizedBox(height: 8),
              _mobileTitleRow(),
              const SizedBox(height: 16),
              _mobileKpiGrid(),
              const SizedBox(height: 16),
              _mobileSearchField(),
              const SizedBox(height: 10),
              _mobileFilterChips(),
              const SizedBox(height: 16),
              for (final l in _lecturers) ...[
                _mobileLecturerCard(l, _coursesFor(l)),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 4),
              _mobilePaginationFooter(),
              const SizedBox(height: 12),
              _mobileFooterBanner(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AdminMobileBottomNav(
        selected: AdminMobileTab.lecturers,
        onTap: (tab) {
          switch (tab) {
            case AdminMobileTab.lecturers:
              break; // already here
            case AdminMobileTab.students:
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageStudentsScreen()));
              break;
            case AdminMobileTab.cohorts:
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CourseEnrollmentScreen()));
              break;
            case AdminMobileTab.enroll:
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EnrollStudentsScreen()));
              break;
          }
        },
      ),
    );
  }

  Widget _mobileEyebrowRow() {
    return Row(
      children: [
        Icon(Icons.account_balance, size: 16, color: AdminColors.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'FACULTY GOVERNANCE • Q3 ACADEMIC TERM',
            style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AdminColors.tertiaryFixed, borderRadius: BorderRadius.circular(9999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: AdminColors.onTertiaryContainer, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('Term Active', style: AdminTypography.labelSm(color: AdminColors.onTertiaryContainer)),
          ]),
        ),
      ],
    );
  }

  Widget _mobileTitleRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Faculty Directory', style: AdminTypography.headlineLg(color: AdminColors.primary)),
              const SizedBox(height: 2),
              Text('Capacity telemetry & curriculum allocation', style: AdminTypography.bodySm(color: AdminColors.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _openAddLecturer,
          icon: const Icon(Icons.person_add, size: 18),
          label: const Text('Add Lecturer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.secondary,
            foregroundColor: AdminColors.onPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: AdminTypography.labelMd(),
          ),
        ),
      ],
    );
  }

  Widget _mobileKpiGrid() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _mobileKpiCard(
              label: 'Active Faculty',
              icon: Icons.groups,
              value: '38',
              delta: '+3',
              footer: 'Onboarded this term',
              progress: 0.82,
              progressColor: AdminColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _mobileKpiCard(
              label: 'Sections Open',
              icon: Icons.domain_verification,
              value: '112',
              delta: '94%',
              footer: 'Across 4 colleges',
              progress: 0.94,
              progressColor: AdminColors.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileKpiCard({
    required String label,
    required IconData icon,
    required String value,
    required String delta,
    required String footer,
    required double progress,
    required Color progressColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: AdminColors.secondary),
            ),
          ]),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: AdminTypography.headlineLg(color: AdminColors.primary).copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.trending_up, size: 14, color: AdminColors.onTertiaryContainer),
                  Flexible(
                    child: Text(
                      delta,
                      style: AdminTypography.labelSm(color: AdminColors.onTertiaryContainer).copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            footer,
            style: AdminTypography.bodySm(color: AdminColors.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AdminColors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileSearchField() {
    return TextField(
      style: AdminTypography.bodySm(color: AdminColors.onSurface),
      decoration: InputDecoration(
        filled: true,
        fillColor: AdminColors.surfaceContainerLowest,
        hintText: 'Search by name, ID, or dept...',
        hintStyle: AdminTypography.bodySm(color: AdminColors.outline),
        prefixIcon: const Icon(Icons.search, size: 20, color: AdminColors.outline),
        suffixIcon: const Icon(Icons.qr_code_scanner, size: 18, color: AdminColors.outlineVariant),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _mobileFilterChips() {
    Widget chip({required Widget child, required Color bg, required Color fg, VoidCallback? onTap}) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap ?? _notAvailable,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              child: DefaultTextStyle(
                style: AdminTypography.labelMd(color: fg),
                child: child,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          chip(
            bg: AdminColors.secondary,
            fg: AdminColors.onPrimary,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('All Departments'),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(4)),
                child: Text('${_lecturers.length}', style: AdminTypography.labelSm(color: AdminColors.onPrimary)),
              ),
            ]),
          ),
          chip(
            bg: AdminColors.surfaceContainerLowest,
            fg: AdminColors.onSurfaceVariant,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('Active'),
              const SizedBox(width: 6),
              Container(width: 8, height: 8, decoration: BoxDecoration(color: AdminColors.onTertiaryContainer, shape: BoxShape.circle)),
            ]),
          ),
          chip(bg: AdminColors.surfaceContainerLowest, fg: AdminColors.onSurfaceVariant, child: const Text('Contract')),
          chip(bg: AdminColors.surfaceContainerLowest, fg: AdminColors.onSurfaceVariant, child: const Text('Sabbatical')),
          chip(
            bg: AdminColors.surfaceContainerLowest,
            fg: AdminColors.onSurfaceVariant,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.tune, size: 16),
              const SizedBox(width: 4),
              const Text('Filters'),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _mobileLecturerCard(Lecturer l, List<String> courses) {
    final isSabbatical = courses.isEmpty;
    final isMaxLoad = !isSabbatical && l.capacityPercent >= 100;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(color: AdminColors.surfaceContainerHigh, shape: BoxShape.circle),
                child: const Icon(Icons.person, color: AdminColors.primary, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(
                          l.name,
                          style: AdminTypography.headlineSm(color: AdminColors.primary).copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: AdminColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(4)),
                        child: Text(l.employeeId, style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant)),
                      ),
                    ]),
                    Text(
                      l.title,
                      style: AdminTypography.labelMd(color: AdminColors.secondary).copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      l.department,
                      style: AdminTypography.bodySm(color: AdminColors.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _notAvailable,
                icon: const Icon(Icons.more_vert, size: 20, color: AdminColors.onSurfaceVariant),
                tooltip: 'Faculty actions',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      'WORKLOAD CAPACITY',
                      style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      '${l.creditsUsed} / ${l.creditsMax} Credits',
                      style: AdminTypography.labelMd(color: AdminColors.primary).copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '(${l.capacityPercent}% ${isMaxLoad ? 'Max' : 'Optimal'})',
                    style: AdminTypography.labelSm(color: AdminColors.onTertiaryContainer).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: LinearProgressIndicator(
                    value: l.capacityPercent / 100,
                    minHeight: 8,
                    backgroundColor: AdminColors.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isMaxLoad ? AdminColors.error : AdminColors.secondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (isSabbatical)
            Text(
              '0 Assigned • Approved Research Term',
              style: AdminTypography.bodySm(color: AdminColors.onSurfaceVariant).copyWith(fontStyle: FontStyle.italic),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIVE COURSES (${courses.length})',
                  style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: courses
                      .map((c) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AdminColors.surfaceContainer, borderRadius: BorderRadius.circular(6)),
                            child: Text(c, style: AdminTypography.labelSm(color: AdminColors.onSurface)),
                          ))
                      .toList(),
                ),
              ],
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: _mobileStatusPill(isSabbatical: isSabbatical, isMaxLoad: isMaxLoad)),
              const SizedBox(width: 8),
              _mobileCardActionButton(l, isSabbatical: isSabbatical),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileStatusPill({required bool isSabbatical, required bool isMaxLoad}) {
    if (isSabbatical) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: AdminColors.surfaceContainer, borderRadius: BorderRadius.circular(9999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: AdminColors.onSurfaceVariant, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Sabbatical',
              style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      );
    }
    if (isMaxLoad) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: AdminColors.errorContainer, borderRadius: BorderRadius.circular(9999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.warning_amber_rounded, size: 12, color: AdminColors.onErrorContainer),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Max Load',
              style: AdminTypography.labelSm(color: AdminColors.onErrorContainer).copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: AdminColors.tertiaryFixed, borderRadius: BorderRadius.circular(9999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: AdminColors.onTertiaryContainer, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Active',
            style: AdminTypography.labelSm(color: AdminColors.onTertiaryContainer).copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }

  Widget _mobileCardActionButton(Lecturer l, {required bool isSabbatical}) {
    return ElevatedButton.icon(
      onPressed: () => _openAssignedCourses(l),
      icon: const Icon(Icons.menu_book, size: 16),
      label: const Text('Manage Assigned Courses'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSabbatical ? AdminColors.primary : AdminColors.surfaceContainerLow,
        foregroundColor: isSabbatical ? AdminColors.onPrimary : AdminColors.secondary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: AdminTypography.labelMd(),
      ),
    );
  }

  Widget _mobilePaginationFooter() {
    Widget pageBtn(String label, {bool active = false}) {
      return Container(
        margin: const EdgeInsets.only(left: 4),
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AdminColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AdminTypography.labelSm(color: active ? AdminColors.onPrimary : AdminColors.onSurfaceVariant)
              .copyWith(fontWeight: FontWeight.w700),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            'Showing 1-${_lecturers.length} of 38 faculty',
            style: AdminTypography.bodySm(color: AdminColors.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            onPressed: _notAvailable,
            icon: const Icon(Icons.chevron_left, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          pageBtn('1', active: true),
          pageBtn('2'),
          pageBtn('3'),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Text('…', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant))),
          pageBtn('8'),
          IconButton(
            onPressed: _notAvailable,
            icon: const Icon(Icons.chevron_right, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ]),
      ],
    );
  }

  Widget _mobileFooterBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user, size: 16, color: AdminColors.secondary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Academic Year 2024–2025 Admin Console Active',
              style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
