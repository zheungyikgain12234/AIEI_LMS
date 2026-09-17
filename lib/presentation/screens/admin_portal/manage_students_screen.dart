import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_students_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturers_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/student.dart';
import 'package:stitch_aiei_lms/domain/models/course_section.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_mobile_top_bar.dart';
import 'widgets/admin_mobile_bottom_nav.dart';
import 'widgets/admin_nav.dart';
import 'manage_lecturers_screen.dart';
import 'course_enrollment_screen.dart';
import 'enroll_students_screen.dart';
import 'student_form_screen.dart';

// ---------------------------------------------------------------------------
// ManageStudentsScreen – Stitch "Manage Students" faithful Flutter
// conversion.
// ---------------------------------------------------------------------------
class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final _repository = SupabaseAdminStudentsRepositoryImpl(Supabase.instance.client);
  final _lecturersRepository = SupabaseLecturersRepositoryImpl(Supabase.instance.client);
  bool _isLoading = true;
  List<Student> _students = [];
  Map<String, int> _enrollmentCounts = {};
  Map<String, List<String>> _credentialTitles = {};
  List<(String, int)> _tracks = [];
  List<(String, int)> _trend = [];

  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final students = await _repository.getStudents();
    final counts = await _repository.getEnrollmentCounts();
    final credentials = await _repository.getEarnedCredentialTitles();
    final tracks = await _repository.getProgramTracks();
    final trend = await _repository.getEnrollmentTrend();
    if (!mounted) return;
    setState(() {
      _students = students;
      _enrollmentCounts = counts;
      _credentialTitles = credentials;
      _tracks = tracks;
      _trend = trend;
      _isLoading = false;
    });
  }

  void _handleNav(AdminNavDestination dest) =>
      handleAdminNav(context, AdminNavDestination.manageStudents, dest);

  void _notAvailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Not wired up in this preview.')),
    );
  }

  Future<void> _openRegisterStudent() async {
    final saved = await Navigator.of(context).push<Student>(
      MaterialPageRoute(builder: (_) => const StudentFormScreen()),
    );
    if (saved != null) _load();
  }

  Future<void> _openEditStudent(Student s) async {
    final saved = await Navigator.of(context).push<Student>(
      MaterialPageRoute(builder: (_) => StudentFormScreen(studentId: s.id)),
    );
    if (saved != null) _load();
  }

  Future<void> _deleteSelected() async {
    final count = _selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete students?'),
        content: Text('This will permanently delete $count student${count == 1 ? '' : 's'}. This cannot be undone.'),
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
    await _repository.deleteStudents(_selected.toList());
    if (!mounted) return;
    setState(_selected.clear);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$count student${count == 1 ? '' : 's'} deleted')),
    );
  }

  Future<void> _openBulkEnroll() async {
    final studentIds = _selected.toList();
    final sections = await _lecturersRepository.getAllSections();
    if (!mounted) return;
    final chosen = await showDialog<CourseSection>(
      context: context,
      builder: (ctx) => _BulkEnrollDialog(studentCount: studentIds.length, sections: sections),
    );
    if (chosen == null) return;
    await _repository.enrollStudentsInSection(studentIds, sectionId: chosen.id, courseId: chosen.courseId);
    if (!mounted) return;
    setState(_selected.clear);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${studentIds.length} student${studentIds.length == 1 ? '' : 's'} successfully enrolled in ${chosen.sectionCode}.')),
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
      selected: AdminNavDestination.manageStudents,
      onDestinationSelected: _handleNav,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 16),
          _buildInstructionBanner(),
          const SizedBox(height: 20),
          _buildMetrics(),
          const SizedBox(height: 20),
          _buildTableCard(),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final left = _buildTracksCard();
            final right = _buildCredentialTrendCard();
            if (wide) {
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 4, child: left),
                const SizedBox(width: 16),
                Expanded(flex: 8, child: right),
              ]);
            }
            return Column(children: [left, const SizedBox(height: 16), right]);
          }),
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
            Text('Manage Students', style: AdminTypography.headlineLg()),
            const SizedBox(height: 2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Text('Institutional learner registry, enrollment status, credential tracking, and cohort management across enterprise academies.', style: AdminTypography.bodyMd()),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _openRegisterStudent,
          icon: const Icon(Icons.person_add_outlined, size: 18),
          label: const Text('Register New Student'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.primaryContainer,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  bool _isFlagged(Student s) => s.gpa < 2.0;

  int get _totalEnrolled => _students.length;

  double get _avgGpa => _students.isEmpty ? 0 : _students.map((s) => s.gpa).reduce((a, b) => a + b) / _students.length;

  int get _totalCredentials => _credentialTitles.values.fold(0, (sum, list) => sum + list.length);

  int get _academicReviewCount => _students.where(_isFlagged).length;

  Widget _buildInstructionBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AdminColors.primaryFixed,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: AdminColors.primary, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.check_box_outlined, color: AdminColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AdminTypography.bodySm(color: AdminColors.onPrimaryFixed),
                children: [
                  TextSpan(text: 'Tip: ', style: AdminTypography.titleSm(color: AdminColors.onPrimaryFixed)),
                  const TextSpan(text: 'Check the boxes next to student rows to select them, then click '),
                  TextSpan(text: 'Bulk Enroll', style: AdminTypography.bodySm(color: AdminColors.onPrimaryFixed).copyWith(fontWeight: FontWeight.w700)),
                  const TextSpan(text: ' to enroll them into a class.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics() {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 500 ? 2 : 1);
      final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
      final cards = [
        _metric('TOTAL ENROLLED', '$_totalEnrolled Active', Icons.groups_outlined, 'Registered across all cohorts'),
        _metric('AVG GPA', _avgGpa.toStringAsFixed(2), Icons.percent_outlined, 'Across all registered students'),
        _metric('GRANTED CREDENTIALS', '$_totalCredentials Granted', Icons.workspace_premium_outlined, 'Earned or revoked credentials'),
        _metric('ACADEMIC REVIEW', '$_academicReviewCount Students', Icons.warning_amber_outlined, 'GPA below 2.0 threshold', urgent: _academicReviewCount > 0),
      ];
      return Wrap(spacing: 16, runSpacing: 16, children: cards.map((c) => SizedBox(width: width, child: c)).toList());
    });
  }

  Widget _metric(String label, String value, IconData icon, String footer, {bool urgent = false}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(label, style: AdminTypography.labelMd().copyWith(fontWeight: FontWeight.w600))),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: urgent ? AdminColors.errorContainer : AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: urgent ? AdminColors.onErrorContainer : AdminColors.primary),
            ),
          ]),
          const SizedBox(height: 8),
          Text(value, style: AdminTypography.dataMetric(color: urgent ? AdminColors.error : AdminColors.onSurface)),
          const SizedBox(height: 6),
          Text(footer, style: AdminTypography.bodySm()),
        ],
      ),
    );
  }

  Widget _buildTableCard() {
    return Container(
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: AdminTypography.bodySm(color: AdminColors.onSurface),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AdminColors.surfaceContainerLow,
                hintText: 'Search student by name, student ID, email, or company...',
                hintStyle: AdminTypography.bodySm(color: AdminColors.outline),
                prefixIcon: const Icon(Icons.search, size: 18, color: AdminColors.onSurfaceVariant),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
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
                    Text('${_selected.length} student${_selected.length == 1 ? '' : 's'} selected', style: AdminTypography.titleSm()),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(_selected.clear),
                      child: Text('Deselect all', style: AdminTypography.labelMd(color: AdminColors.secondary)),
                    ),
                  ]),
                  Wrap(spacing: 6, children: [
                    OutlinedButton(onPressed: _openBulkEnroll, style: _pillButtonStyle(), child: const Text('Bulk Enroll')),
                    OutlinedButton(onPressed: _notAvailable, style: _pillButtonStyle(), child: const Text('Issue Notice')),
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
                    ElevatedButton(
                      onPressed: _notAvailable,
                      style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), textStyle: AdminTypography.labelSm()),
                      child: const Text('Export Selected'),
                    ),
                  ]),
                ],
              ),
            ),
          Column(children: [for (final s in _students) _studentRow(s)]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Showing 1 - ${_students.length} of ${_students.length} students', style: AdminTypography.bodySm()),
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

  ButtonStyle _pillButtonStyle() => OutlinedButton.styleFrom(
        foregroundColor: AdminColors.onSurface,
        backgroundColor: AdminColors.surfaceContainerLowest,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: AdminTypography.labelSm(),
      );

  Widget _studentRow(Student s) {
    final selected = _selected.contains(s.id);
    final enrollments = _enrollmentCounts[s.id] ?? 0;
    final credentials = _credentialTitles[s.id] ?? const [];
    final flagged = _isFlagged(s);
    final standing = flagged ? 'Under Review' : 'Good Standing';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: flagged ? AdminColors.errorContainer.withValues(alpha: 0.12) : null,
        border: const Border(bottom: BorderSide(color: AdminColors.surfaceContainer)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: selected,
            onChanged: (v) => setState(() => v == true ? _selected.add(s.id) : _selected.remove(s.id)),
            activeColor: AdminColors.primaryContainer,
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(s.name, style: AdminTypography.titleSm(color: flagged ? AdminColors.error : AdminColors.onSurface), overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _openEditStudent(s),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(Icons.edit_outlined, size: 14, color: AdminColors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  Text(s.email, style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(s.studentId, style: AdminTypography.labelSm(), overflow: TextOverflow.ellipsis),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${s.programTrack} • ${s.cohort}', style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis),
                Text('GPA ${s.gpa.toStringAsFixed(2)} • $enrollments Enrolled', style: AdminTypography.labelSm(color: flagged ? AdminColors.error : AdminColors.onSurfaceVariant)),
              ]),
            ),
          ),
          SizedBox(
            width: 56,
            child: Tooltip(
              message: standing,
              child: Icon(
                flagged ? Icons.error_outline : Icons.check_circle_outline,
                size: 28,
                color: flagged ? AdminColors.error : AdminColors.secondary,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: credentials.isEmpty
                ? Text('—', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant))
                : Tooltip(
                    message: credentials.join('\n'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: flagged ? AdminColors.errorContainer : AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(9999)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.workspace_premium_outlined, size: 14, color: flagged ? AdminColors.onErrorContainer : AdminColors.onSurface),
                        const SizedBox(width: 4),
                        Text('${credentials.length} Badge${credentials.length == 1 ? '' : 's'}', style: AdminTypography.labelSm(color: flagged ? AdminColors.onErrorContainer : AdminColors.onSurface)),
                      ]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTracksCard() {
    final totalStudents = _tracks.fold<int>(0, (sum, t) => sum + t.$2);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Learners by Academy Track', style: AdminTypography.titleMd()),
          const SizedBox(height: 4),
          Text('Distribution across active institutional specializations.', style: AdminTypography.bodySm()),
          const SizedBox(height: 12),
          for (final t in _tracks)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(t.$1, style: AdminTypography.labelMd(color: AdminColors.onSurface))),
                    Text('${t.$2} Students (${totalStudents == 0 ? 0 : (t.$2 * 100 / totalStudents).round()}%)', style: AdminTypography.labelSm()),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: LinearProgressIndicator(value: totalStudents == 0 ? 0 : t.$2 / totalStudents, minHeight: 6, backgroundColor: AdminColors.surfaceContainerLow, valueColor: const AlwaysStoppedAnimation<Color>(AdminColors.secondaryContainer)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCredentialTrendCard() {
    final months = _trend;
    final maxValue = months.isEmpty ? 1 : months.map((m) => m.$2).reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text('Monthly Credential Grant Rate', style: AdminTypography.titleMd())),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AdminColors.surfaceContainer, borderRadius: BorderRadius.circular(6)),
              child: Text('2024–2025 Cycle', style: AdminTypography.labelSm()),
            ),
          ]),
          const SizedBox(height: 4),
          Text('Volume of verified skill badges issued across corporate cohorts.', style: AdminTypography.bodySm()),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: months.map((m) {
                final isLast = m == months.last;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: maxValue == 0 ? 0 : (m.$2 / maxValue) * 140.0,
                          decoration: BoxDecoration(
                            color: isLast ? AdminColors.secondaryContainer : AdminColors.surfaceContainerHigh,
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(m.$1, style: AdminTypography.labelSm(color: isLast ? AdminColors.secondary : AdminColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 6,
              children: [
                Text('Current Term Peak: $maxValue Badges', style: AdminTypography.bodySm(color: AdminColors.onSurface)),
                GestureDetector(
                  onTap: _notAvailable,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(
                      child: Text(
                        'View Accreditation Audit',
                        overflow: TextOverflow.ellipsis,
                        style: AdminTypography.titleSm(color: AdminColors.secondary),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 14, color: AdminColors.secondary),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Mobile (<700px) layout — separate Scaffold, shared AdminMobileTopBar /
  // AdminMobileBottomNav shell. Reuses the existing `_students` data list and
  // the desktop `_buildTracksCard` / `_buildCredentialTrendCard` analytics
  // widgets (already overflow-safe at 170px chart height).
  // -------------------------------------------------------------------------
  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: const AdminMobileTopBar.root(title: 'Students'),
      bottomNavigationBar: AdminMobileBottomNav(
        selected: AdminMobileTab.students,
        onTap: (tab) {
          switch (tab) {
            case AdminMobileTab.lecturers:
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageLecturersScreen()));
              break;
            case AdminMobileTab.students:
              break; // already here
            case AdminMobileTab.cohorts:
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CourseEnrollmentScreen()));
              break;
            case AdminMobileTab.enroll:
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EnrollStudentsScreen()));
              break;
          }
        },
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Institutional learner registry, enrollment status, credential tracking, and cohort management across enterprise academies.',
                style: AdminTypography.bodyMd(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _openRegisterStudent,
                  icon: const Icon(Icons.person_add, size: 20),
                  label: const Text('Register New Student'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.secondary,
                    foregroundColor: AdminColors.onSecondary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: AdminTypography.titleSm(color: AdminColors.onSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildMobileKpiGrid(),
              const SizedBox(height: 20),
              _buildMobileSearchBar(),
              const SizedBox(height: 12),
              _buildMobileFilterPills(),
              const SizedBox(height: 16),
              for (final s in _students) ...[
                _buildMobileStudentCard(s),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 4),
              _buildMobilePagination(),
              const SizedBox(height: 20),
              _buildTracksCard(),
              const SizedBox(height: 16),
              _buildCredentialTrendCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileKpiGrid() {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _mobileKpiCard(
                  label: 'TOTAL ENROLLED',
                  icon: Icons.groups,
                  value: '$_totalEnrolled',
                  valueSuffix: 'Active',
                  footerIcon: Icons.trending_up,
                  footerText: 'Registered students',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _mobileKpiCard(
                  label: 'AVG GPA',
                  icon: Icons.insights,
                  value: _avgGpa.toStringAsFixed(2),
                  footerIcon: Icons.arrow_upward,
                  footerText: 'Across all students',
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
                child: _mobileKpiCard(
                  label: 'GRANTED CREDS',
                  icon: Icons.verified,
                  value: '$_totalCredentials',
                  footerIcon: Icons.check_circle,
                  footerText: 'Earned or revoked',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _mobileKpiCard(
                  label: 'ACAD. REVIEW',
                  icon: Icons.warning,
                  value: '$_academicReviewCount',
                  valueSuffix: 'Flagged',
                  footerIcon: Icons.flag,
                  footerText: 'Action Required',
                  urgent: _academicReviewCount > 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mobileKpiCard({
    required String label,
    required IconData icon,
    required String value,
    String? valueSuffix,
    required IconData footerIcon,
    required String footerText,
    bool urgent = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: urgent ? AdminColors.errorContainer : AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AdminTypography.labelSm(color: urgent ? AdminColors.onErrorContainer : AdminColors.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: urgent ? AdminColors.surfaceContainerLowest.withValues(alpha: 0.8) : AdminColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: urgent ? AdminColors.error : AdminColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: AdminTypography.headlineMd(color: urgent ? AdminColors.onErrorContainer : AdminColors.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (valueSuffix != null) ...[
                const SizedBox(width: 4),
                Text(
                  valueSuffix,
                  style: AdminTypography.labelSm(color: urgent ? AdminColors.onErrorContainer : AdminColors.onTertiaryContainer).copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          if (urgent)
            Text(
              footerText,
              style: AdminTypography.labelSm(color: AdminColors.onErrorContainer).copyWith(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            )
          else
            Row(
              children: [
                Icon(footerIcon, size: 14, color: AdminColors.onTertiaryContainer),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(footerText, style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMobileSearchBar() {
    return TextField(
      style: AdminTypography.bodySm(color: AdminColors.onSurface),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AdminColors.surfaceContainerLowest,
        hintText: 'Search student by name, ID, email...',
        hintStyle: AdminTypography.bodySm(color: AdminColors.outline),
        prefixIcon: const Icon(Icons.search, size: 20, color: AdminColors.outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildMobileFilterPills() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        GestureDetector(
          onTap: _notAvailable,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AdminColors.secondary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('All Cohorts', style: AdminTypography.labelMd(color: AdminColors.onSecondary)),
              const SizedBox(width: 6),
              Container(
                width: 16,
                height: 16,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AdminColors.onSecondary.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Text('${_tracks.length}', style: AdminTypography.labelSm(color: AdminColors.onSecondary).copyWith(fontSize: 10)),
              ),
            ]),
          ),
        ),
        _mobileFilterOutlinePill('All Statuses'),
        _mobileFilterOutlinePill('Credentials'),
        GestureDetector(
          onTap: _notAvailable,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.restart_alt, size: 16, color: AdminColors.secondary),
              const SizedBox(width: 4),
              Text('Reset', style: AdminTypography.labelMd(color: AdminColors.secondary)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _mobileFilterOutlinePill(String label) {
    return GestureDetector(
      onTap: _notAvailable,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AdminColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: AdminTypography.labelMd(color: AdminColors.onSurfaceVariant)),
          const SizedBox(width: 4),
          const Icon(Icons.expand_more, size: 16, color: AdminColors.onSurfaceVariant),
        ]),
      ),
    );
  }

  Widget _buildMobileStudentCard(Student s) {
    final enrollments = _enrollmentCounts[s.id] ?? 0;
    final credentials = _credentialTitles[s.id] ?? const [];
    final flagged = _isFlagged(s);
    final standing = flagged ? 'Under Review' : 'Good Standing';
    final progress = (s.gpa / 4.0).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(color: AdminColors.surfaceContainerHigh, shape: BoxShape.circle),
                child: Icon(flagged ? Icons.person_off : Icons.person, color: flagged ? AdminColors.error : AdminColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          s.name,
                          style: AdminTypography.headlineSm(color: flagged ? AdminColors.error : AdminColors.onSurface),
                        ),
                        InkWell(
                          onTap: () => _openEditStudent(s),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(Icons.edit_outlined, size: 16, color: AdminColors.onSurfaceVariant),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AdminColors.surfaceContainer, borderRadius: BorderRadius.circular(4)),
                          child: Text(s.studentId, style: AdminTypography.labelSm()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(s.email, style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                onPressed: _notAvailable,
                icon: const Icon(Icons.more_vert, size: 20, color: AdminColors.onSurfaceVariant),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.alt_route, size: 16, color: AdminColors.secondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${s.programTrack} (${s.cohort})',
                  style: AdminTypography.bodySm(color: AdminColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: flagged ? AdminColors.errorContainer : AdminColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  standing,
                  style: AdminTypography.labelSm(color: flagged ? AdminColors.onErrorContainer : AdminColors.secondary).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$enrollments Enrolled Courses', style: AdminTypography.labelSm()),
                    Text('GPA ${s.gpa.toStringAsFixed(2)}', style: AdminTypography.labelSm(color: AdminColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AdminColors.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(flagged ? AdminColors.error : AdminColors.secondaryContainer),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: credentials.map((c) {
              final revoked = c.contains('(Revoked)');
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: revoked ? AdminColors.errorContainer : AdminColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(revoked ? Icons.error : Icons.verified, size: 14, color: revoked ? AdminColors.onErrorContainer : AdminColors.onTertiaryContainer),
                  const SizedBox(width: 4),
                  Text(c, style: AdminTypography.labelSm(color: revoked ? AdminColors.onErrorContainer : AdminColors.onSurface)),
                ]),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton.icon(
              onPressed: () => flagged
                  ? _notAvailable()
                  : (enrollments > 0
                      ? Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CourseEnrollmentScreen()))
                      : _notAvailable()),
              icon: Icon(flagged ? Icons.assignment_turned_in : Icons.menu_book, size: 18),
              label: Text(flagged ? 'Resolve Flag & Review' : 'Manage Courses'),
              style: ElevatedButton.styleFrom(
                backgroundColor: flagged ? AdminColors.errorContainer : AdminColors.surfaceContainerLow,
                foregroundColor: flagged ? AdminColors.onErrorContainer : AdminColors.secondary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: AdminTypography.labelMd(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePagination() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Showing 1-${_students.length} of ${_students.length} students', style: AdminTypography.bodySm()),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _pageNavButton(Icons.chevron_left),
            const SizedBox(width: 6),
            for (final p in [1, 2, 3]) ...[
              _pageNumberButton(p, active: p == 1),
              const SizedBox(width: 6),
            ],
            _pageNavButton(Icons.chevron_right),
          ],
        ),
      ],
    );
  }

  Widget _pageNumberButton(int page, {required bool active}) {
    return GestureDetector(
      onTap: _notAvailable,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: active ? AdminColors.secondary : AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(8)),
        child: Text('$page', style: AdminTypography.labelSm(color: active ? AdminColors.onSecondary : AdminColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _pageNavButton(IconData icon) {
    return GestureDetector(
      onTap: _notAvailable,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: AdminColors.onSurfaceVariant),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _BulkEnrollDialog — lets the admin pick a class (course_sections row) to
// enroll the selected students into. Pops the chosen CourseSection, or null
// if cancelled.
// ---------------------------------------------------------------------------
class _BulkEnrollDialog extends StatefulWidget {
  final int studentCount;
  final List<CourseSection> sections;

  const _BulkEnrollDialog({required this.studentCount, required this.sections});

  @override
  State<_BulkEnrollDialog> createState() => _BulkEnrollDialogState();
}

class _BulkEnrollDialogState extends State<_BulkEnrollDialog> {
  String? _selectedSectionId;

  @override
  Widget build(BuildContext context) {
    final count = widget.studentCount;
    return AlertDialog(
      title: Text('Enroll $count student${count == 1 ? '' : 's'}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select a class to enroll ${count == 1 ? 'this student' : 'these students'} into.', style: AdminTypography.bodySm()),
            const SizedBox(height: 14),
            if (widget.sections.isEmpty)
              Text('No classes exist yet. Create one from Manage Assigned Courses first.', style: AdminTypography.bodySm(color: AdminColors.error))
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedSectionId,
                isExpanded: true,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AdminColors.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                hint: const Text('Select a class'),
                items: [
                  for (final s in widget.sections)
                    DropdownMenuItem(
                      value: s.id,
                      child: Text('${s.sectionCode} • ${s.courseTitle}', overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _selectedSectionId = v),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _selectedSectionId == null
              ? null
              : () => Navigator.of(context).pop(widget.sections.firstWhere((s) => s.id == _selectedSectionId)),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
