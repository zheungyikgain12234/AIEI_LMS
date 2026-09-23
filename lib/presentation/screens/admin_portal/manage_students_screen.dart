import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_students_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturers_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_master_data_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_badges_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/student.dart';
import 'package:stitch_aiei_lms/domain/models/course_section.dart';
import 'package:stitch_aiei_lms/domain/models/department.dart';
import 'package:stitch_aiei_lms/domain/models/program_track.dart';
import 'package:stitch_aiei_lms/domain/models/role.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_mobile_top_bar.dart';
import 'widgets/admin_mobile_bottom_nav.dart';
import 'widgets/admin_nav.dart';
import 'widgets/admin_more_menu.dart';
import 'widgets/admin_mobile_selection_bar.dart';
import 'widgets/admin_pagination.dart';
import 'student_form_screen.dart';
import 'student_enrolled_courses_screen.dart';

// ---------------------------------------------------------------------------
// ManageStudentsScreen – Stitch "Manage Students" faithful Flutter
// conversion.
// ---------------------------------------------------------------------------
class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

enum _SortColumn { name, code, track, department }

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final _client = Supabase.instance.client;
  final _repository = SupabaseAdminStudentsRepositoryImpl(Supabase.instance.client);
  final _badgesRepository = SupabaseAdminBadgesRepositoryImpl(Supabase.instance.client);
  final _lecturersRepository = SupabaseLecturersRepositoryImpl(Supabase.instance.client);
  final _masterDataRepository = SupabaseAdminMasterDataRepositoryImpl(Supabase.instance.client);
  bool _isLoading = true;
  String? _errorMessage;
  List<Student> _students = [];
  Map<String, int> _enrollmentCounts = {};
  Map<String, List<String>> _credentialTitles = {};
  List<(String, int)> _tracks = [];
  List<(String, int)> _trend = [];
  Set<String> _courseMismatchStudentIds = {};
  _SortColumn _sortColumn = _SortColumn.name;
  bool _sortAscending = true;
  int _page = 1;
  int _pageSize = adminPageSizeOptions.first;
  final _searchController = TextEditingController();
  String _query = '';

  final Set<String> _selected = {};

  List<Student> get _filteredStudents {
    if (_query.isEmpty) return _students;
    return _students.where((s) =>
        s.name.toLowerCase().contains(_query) ||
        s.studentCode.toLowerCase().contains(_query) ||
        s.email.toLowerCase().contains(_query) ||
        (s.department ?? '').toLowerCase().contains(_query) ||
        (s.role ?? '').toLowerCase().contains(_query) ||
        (s.programTrack ?? '').toLowerCase().contains(_query)).toList();
  }

  List<Student> get _sortedStudents {
    final sorted = [..._filteredStudents];
    sorted.sort((a, b) {
      final int cmp;
      switch (_sortColumn) {
        case _SortColumn.name:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case _SortColumn.code:
          cmp = a.studentCode.toLowerCase().compareTo(b.studentCode.toLowerCase());
        case _SortColumn.track:
          cmp = (a.programTrack ?? '').toLowerCase().compareTo((b.programTrack ?? '').toLowerCase());
        case _SortColumn.department:
          cmp = (a.department ?? a.role ?? '').toLowerCase().compareTo((b.department ?? b.role ?? '').toLowerCase());
      }
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  List<Student> get _pagedStudents {
    final sorted = _sortedStudents;
    final pageCount = sorted.isEmpty ? 1 : (sorted.length / _pageSize).ceil();
    if (_page > pageCount) _page = pageCount;
    final start = ((_page - 1) * _pageSize).clamp(0, sorted.length);
    final end = (start + _pageSize).clamp(0, sorted.length);
    return sorted.sublist(start, end);
  }

  void _toggleSort(_SortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  Widget _sortHeader(String label, _SortColumn column) {
    final active = _sortColumn == column;
    return InkWell(
      onTap: () => _toggleSort(column),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AdminTypography.labelSm(color: active ? AdminColors.onSurface : AdminColors.onSurfaceVariant)),
          const SizedBox(width: 2),
          Icon(
            active && !_sortAscending ? Icons.arrow_downward : Icons.arrow_upward,
            size: 12,
            color: active ? AdminColors.onSurface : AdminColors.outline,
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {
          _query = _searchController.text.trim().toLowerCase();
          _page = 1;
        }));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final students = await _repository.getStudents();
      final counts = await _repository.getEnrollmentCounts();
      final credentials = await _repository.getEarnedCredentialTitles();
      final tracks = await _repository.getProgramTracks();
      final trend = await _badgesRepository.getMonthlyIssueCounts();
      final enrolledCourseIds = await _repository.getEnrolledCourseIdsByStudent();
      final roles = await _masterDataRepository.getRoles();
      final programTracks = await _masterDataRepository.getProgramTracks();
      final departments = await _masterDataRepository.getDepartments();
      final mismatches = await _computeCourseMismatches(
        students: students,
        enrolledCourseIds: enrolledCourseIds,
        roles: roles,
        programTracks: programTracks,
        departments: departments,
      );

      if (!mounted) return;
      setState(() {
        _students = students;
        _enrollmentCounts = counts;
        _credentialTitles = credentials;
        _tracks = tracks;
        _trend = trend;
        _courseMismatchStudentIds = mismatches;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load students: $e';
        _isLoading = false;
      });
    }
  }

  /// A student's enrollment "mismatches" when a course they're enrolled in
  /// isn't mapped to their profile — for an Internal student that means
  /// neither their Role (`role_courses`) nor their Department
  /// (`department_courses`) covers the course; for an External student it
  /// means the course isn't mapped to their Program Track (`track_courses`).
  /// This only drives the warning icon in the table — it never blocks
  /// enrollment.
  ///
  /// Every (track/role/department) → course mapping this page could need is
  /// fetched in three bulk queries up front rather than one query per
  /// student — with 18+ students that was 30+ sequential round trips with no
  /// timeout, so a single slow request stalled the whole screen forever.
  Future<Set<String>> _computeCourseMismatches({
    required List<Student> students,
    required Map<String, List<String>> enrolledCourseIds,
    required List<dynamic> roles,
    required List<dynamic> programTracks,
    required List<dynamic> departments,
  }) async {
    final roleIdByName = {for (final r in roles) r.name as String: r.id as String};
    final trackIdByName = {for (final t in programTracks) t.name as String: t.id as String};
    final departmentIdByName = {for (final d in departments) d.name as String: d.id as String};

    final neededTrackIds = <String>{};
    final neededRoleIds = <String>{};
    final neededDepartmentIds = <String>{};
    for (final s in students) {
      if ((enrolledCourseIds[s.id] ?? const []).isEmpty) continue;
      if (s.studentType == StudentType.external) {
        final trackId = trackIdByName[s.programTrack];
        if (trackId != null) neededTrackIds.add(trackId);
      } else {
        final roleId = roleIdByName[s.role];
        final departmentId = departmentIdByName[s.department];
        if (roleId != null) neededRoleIds.add(roleId);
        if (departmentId != null) neededDepartmentIds.add(departmentId);
      }
    }

    final trackRows = neededTrackIds.isEmpty
        ? const <dynamic>[]
        : await _client.from('track_courses').select('track_id, course_id').inFilter('track_id', neededTrackIds.toList());
    final roleRows = neededRoleIds.isEmpty
        ? const <dynamic>[]
        : await _client.from('role_courses').select('role_id, course_id').inFilter('role_id', neededRoleIds.toList());
    final departmentRows = neededDepartmentIds.isEmpty
        ? const <dynamic>[]
        : await _client
            .from('department_courses')
            .select('department_id, course_id')
            .inFilter('department_id', neededDepartmentIds.toList());

    final courseIdsByTrackId = <String, Set<String>>{};
    for (final row in trackRows) {
      courseIdsByTrackId.putIfAbsent(row['track_id'] as String, () => {}).add(row['course_id'] as String);
    }
    final courseIdsByRoleId = <String, Set<String>>{};
    for (final row in roleRows) {
      courseIdsByRoleId.putIfAbsent(row['role_id'] as String, () => {}).add(row['course_id'] as String);
    }
    final courseIdsByDepartmentId = <String, Set<String>>{};
    for (final row in departmentRows) {
      courseIdsByDepartmentId.putIfAbsent(row['department_id'] as String, () => {}).add(row['course_id'] as String);
    }

    final mismatches = <String>{};
    for (final s in students) {
      final enrolled = enrolledCourseIds[s.id] ?? const [];
      if (enrolled.isEmpty) continue;
      final Set<String> allowed;
      if (s.studentType == StudentType.external) {
        final trackId = trackIdByName[s.programTrack];
        if (trackId == null) continue;
        allowed = courseIdsByTrackId[trackId] ?? const {};
      } else {
        final roleId = roleIdByName[s.role];
        final departmentId = departmentIdByName[s.department];
        if (roleId == null && departmentId == null) continue;
        allowed = {
          ...?roleId == null ? null : courseIdsByRoleId[roleId],
          ...?departmentId == null ? null : courseIdsByDepartmentId[departmentId],
        };
      }
      if (enrolled.any((courseId) => !allowed.contains(courseId))) mismatches.add(s.id);
    }
    return mismatches;
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

  Future<void> _openEnrolledCourses(Student s) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StudentEnrolledCoursesScreen(studentId: s.id)),
    );
    _load();
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
    final programTracks = await _masterDataRepository.getProgramTracks();
    final departments = await _masterDataRepository.getDepartments();
    final roles = await _masterDataRepository.getRoles();
    // Bulk-fetched once (small tables) so the dialog's Track/Department/Role
    // filter is instant client-side instead of a query per selection.
    final trackRows = await _client.from('track_courses').select('track_id, course_id');
    final roleRows = await _client.from('role_courses').select('role_id, course_id');
    final departmentRows = await _client.from('department_courses').select('department_id, course_id');
    final courseIdsByTrackId = <String, Set<String>>{};
    for (final row in trackRows as List) {
      courseIdsByTrackId.putIfAbsent(row['track_id'] as String, () => {}).add(row['course_id'] as String);
    }
    final courseIdsByRoleId = <String, Set<String>>{};
    for (final row in roleRows as List) {
      courseIdsByRoleId.putIfAbsent(row['role_id'] as String, () => {}).add(row['course_id'] as String);
    }
    final courseIdsByDepartmentId = <String, Set<String>>{};
    for (final row in departmentRows as List) {
      courseIdsByDepartmentId.putIfAbsent(row['department_id'] as String, () => {}).add(row['course_id'] as String);
    }
    if (!mounted) return;
    final chosen = await showDialog<CourseSection>(
      context: context,
      builder: (ctx) => _BulkEnrollDialog(
        studentCount: studentIds.length,
        sections: sections,
        programTracks: programTracks,
        departments: departments,
        roles: roles,
        courseIdsByTrackId: courseIdsByTrackId,
        courseIdsByRoleId: courseIdsByRoleId,
        courseIdsByDepartmentId: courseIdsByDepartmentId,
      ),
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
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_errorMessage!, style: AdminTypography.bodyMd(color: AdminColors.error), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
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

  int get _totalCredentials => _credentialTitles.values.fold(0, (sum, list) => sum + list.length);

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
      final cols = constraints.maxWidth >= 500 ? 2 : 1;
      final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
      final cards = [
        _metric('TOTAL ENROLLED', '$_totalEnrolled Active', Icons.groups_outlined, 'Registered across all cohorts'),
        _metric('GRANTED CREDENTIALS', '$_totalCredentials Granted', Icons.workspace_premium_outlined, 'Earned or revoked credentials'),
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
              controller: _searchController,
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
                  ]),
                ],
              ),
            ),
          if (_filteredStudents.isNotEmpty) _headerRow(),
          if (_students.isNotEmpty && _filteredStudents.isEmpty)
            Padding(padding: const EdgeInsets.all(32), child: Text('No students found.', style: AdminTypography.bodyMd())),
          Column(children: [for (final s in _pagedStudents) _studentRow(s)]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AdminPagination(
              totalItems: _filteredStudents.length,
              page: _page,
              pageSize: _pageSize,
              itemLabel: 'student',
              onPageChanged: (p) => setState(() => _page = p),
              onPageSizeChanged: (s) => setState(() {
                _pageSize = s;
                _page = 1;
              }),
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

  Widget _headerRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AdminColors.surfaceContainer))),
      child: Row(
        children: [
          const SizedBox(width: 48),
          Expanded(flex: 2, child: _sortHeader('Code', _SortColumn.code)),
          Expanded(flex: 4, child: _sortHeader('Student', _SortColumn.name)),
          Expanded(flex: 2, child: Text('Student Type', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant))),
          Expanded(flex: 2, child: _sortHeader('Track', _SortColumn.track)),
          Expanded(flex: 3, child: _sortHeader('Department / Role', _SortColumn.department)),
          Expanded(flex: 3, child: Text('Badges', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant))),
        ],
      ),
    );
  }

  Widget _studentRow(Student s) {
    final selected = _selected.contains(s.id);
    final credentials = _credentialTitles[s.id] ?? const [];
    final flagged = _isFlagged(s);
    final courseMismatch = _courseMismatchStudentIds.contains(s.id);
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
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(s.studentCode, style: AdminTypography.labelSm(), overflow: TextOverflow.ellipsis),
            ),
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
                      if (courseMismatch) ...[
                        const SizedBox(width: 4),
                        Tooltip(
                          message: s.studentType == StudentType.external
                              ? 'One or more enrolled course is not mapped to this student\'s track'
                              : 'One or more enrolled course is not mapped to this student\'s role or department',
                          child: Icon(Icons.error, size: 15, color: AdminColors.error),
                        ),
                      ],
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: s.studentType == StudentType.internal ? AdminColors.primaryFixed : AdminColors.tertiaryFixed,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  s.studentType.label,
                  style: AdminTypography.labelSm(
                    color: s.studentType == StudentType.internal ? AdminColors.onPrimaryFixed : AdminColors.onTertiaryFixedVariant,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(s.programTrack ?? '—', style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.department ?? '—', style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis),
                Text(s.role ?? '—', style: AdminTypography.labelSm(), overflow: TextOverflow.ellipsis),
              ]),
            ),
          ),
          Expanded(
            flex: 3,
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
          SizedBox(
            width: 190,
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => _openEnrolledCourses(s),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminColors.primary,
                  backgroundColor: AdminColors.surfaceContainerLow,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: AdminTypography.labelSm(),
                ),
                child: const Text('Manage Enrolled Courses'),
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
              child: Text('Last 6 Months', style: AdminTypography.labelSm()),
            ),
          ]),
          const SizedBox(height: 4),
          Text('Volume of verified skill badges issued across corporate cohorts.', style: AdminTypography.bodySm()),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 26,
                      height: 140,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final fraction in [1.0, 0.5, 0.0])
                            Text('${(maxValue * fraction).round()}', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    // Reserves the same vertical space as the month-label row
                    // below each bar, so the "0" tick lines up with the bars'
                    // baseline rather than the month labels underneath them.
                    const SizedBox(height: 4),
                    Opacity(opacity: 0, child: Text('0', style: AdminTypography.labelSm())),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
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
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
            child: Text('Current Term Peak: $maxValue Badges', style: AdminTypography.bodySm(color: AdminColors.onSurface)),
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
        onTap: (tab) => handleAdminMobileTab(context, AdminMobileTab.students, tab),
        onMore: () => showAdminMoreMenu(context),
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
              _buildInstructionBanner(),
              const SizedBox(height: 16),
              _buildMobileKpiGrid(),
              const SizedBox(height: 20),
              _buildMobileSearchBar(),
              const SizedBox(height: 12),
              _buildMobileFilterPills(),
              if (_selected.isNotEmpty) ...[
                const SizedBox(height: 12),
                adminMobileSelectionBar(
                  count: _selected.length,
                  itemLabel: 'student',
                  onDeselectAll: () => setState(_selected.clear),
                  onDelete: _deleteSelected,
                  extraActions: [
                    OutlinedButton(onPressed: _openBulkEnroll, style: _pillButtonStyle(), child: const Text('Bulk Enroll')),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (_students.isNotEmpty && _filteredStudents.isEmpty)
                Padding(padding: const EdgeInsets.all(24), child: Text('No students found.', style: AdminTypography.bodyMd())),
              for (final s in _pagedStudents) ...[
                _buildMobileStudentCard(s),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 4),
              AdminPagination(
                totalItems: _filteredStudents.length,
                page: _page,
                pageSize: _pageSize,
                itemLabel: 'student',
                onPageChanged: (p) => setState(() => _page = p),
                onPageSizeChanged: (s) => setState(() {
                  _pageSize = s;
                  _page = 1;
                }),
              ),
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
    return IntrinsicHeight(
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
              label: 'GRANTED CREDS',
              icon: Icons.verified,
              value: '$_totalCredentials',
              footerIcon: Icons.check_circle,
              footerText: 'Earned or revoked',
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
      controller: _searchController,
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
    final selected = _selected.contains(s.id);
    final courseMismatch = _courseMismatchStudentIds.contains(s.id);
    final cohortSuffix = s.cohort == null ? '' : ' (${s.cohort})';
    final profileLine = s.studentType == StudentType.external
        ? '${s.studentType.label} • ${s.programTrack ?? '—'}$cohortSuffix'
        : '${s.studentType.label} • ${s.department ?? '—'} / ${s.role ?? '—'}$cohortSuffix';
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
              Checkbox(
                value: selected,
                onChanged: (v) => setState(() => v == true ? _selected.add(s.id) : _selected.remove(s.id)),
                activeColor: AdminColors.primaryContainer,
              ),
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
                        if (courseMismatch)
                          Tooltip(
                            message: s.studentType == StudentType.external
                                ? 'One or more enrolled course is not mapped to this student\'s track'
                                : 'One or more enrolled course is not mapped to this student\'s role or department',
                            child: Icon(Icons.error, size: 16, color: AdminColors.error),
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
                          child: Text(s.studentCode, style: AdminTypography.labelSm()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(s.email, style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
                  ],
                ),
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
                  profileLine,
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
              onPressed: () => _openEnrolledCourses(s),
              icon: const Icon(Icons.menu_book, size: 18),
              label: const Text('Manage Enrolled Courses'),
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

}

// ---------------------------------------------------------------------------
// _BulkEnrollDialog — lets the admin pick a class (course_sections row) to
// enroll the selected students into. Pops the chosen CourseSection, or null
// if cancelled.
// ---------------------------------------------------------------------------
class _BulkEnrollDialog extends StatefulWidget {
  final int studentCount;
  final List<CourseSection> sections;
  final List<ProgramTrack> programTracks;
  final List<Department> departments;
  final List<Role> roles;
  final Map<String, Set<String>> courseIdsByTrackId;
  final Map<String, Set<String>> courseIdsByRoleId;
  final Map<String, Set<String>> courseIdsByDepartmentId;

  const _BulkEnrollDialog({
    required this.studentCount,
    required this.sections,
    required this.programTracks,
    required this.departments,
    required this.roles,
    required this.courseIdsByTrackId,
    required this.courseIdsByRoleId,
    required this.courseIdsByDepartmentId,
  });

  @override
  State<_BulkEnrollDialog> createState() => _BulkEnrollDialogState();
}

/// A profile-filter option in the combined Track/Department/Role dropdown —
/// picking one narrows the Class dropdown to classes whose course is mapped
/// to it (`track_courses` / `role_courses` / `department_courses`).
class _ProfileFilter {
  final String key;
  final String label;
  final Set<String> courseIds;
  const _ProfileFilter({required this.key, required this.label, required this.courseIds});
}

class _BulkEnrollDialogState extends State<_BulkEnrollDialog> {
  String? _selectedCohort;
  String? _selectedProfileFilterKey;
  String? _selectedSectionId;

  @override
  void initState() {
    super.initState();
    final cohortNames = _cohortNames;
    if (cohortNames.isNotEmpty) _selectedCohort = cohortNames.first;
  }

  List<String> get _cohortNames {
    final names = widget.sections.map((s) => s.cohort).whereType<String>().toSet().toList();
    names.sort();
    return names;
  }

  List<_ProfileFilter> get _profileFilters => [
        for (final t in widget.programTracks)
          _ProfileFilter(key: 'track:${t.id}', label: 'Track: ${t.name}', courseIds: widget.courseIdsByTrackId[t.id] ?? const {}),
        for (final d in widget.departments)
          _ProfileFilter(key: 'dept:${d.id}', label: 'Department: ${d.name}', courseIds: widget.courseIdsByDepartmentId[d.id] ?? const {}),
        for (final r in widget.roles)
          _ProfileFilter(key: 'role:${r.id}', label: 'Role: ${r.name}', courseIds: widget.courseIdsByRoleId[r.id] ?? const {}),
      ];

  List<CourseSection> get _sectionsForSelection {
    var sections = widget.sections.where((s) => s.cohort == _selectedCohort).toList();
    final filterKey = _selectedProfileFilterKey;
    if (filterKey != null) {
      final filter = _profileFilters.firstWhere((f) => f.key == filterKey);
      sections = sections.where((s) => filter.courseIds.contains(s.courseId)).toList();
    }
    sections.sort((a, b) => a.sectionCode.compareTo(b.sectionCode));
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.studentCount;
    final cohortNames = _cohortNames;
    final profileFilters = _profileFilters;
    final sections = _sectionsForSelection;
    return AlertDialog(
      title: Text('Enroll $count student${count == 1 ? '' : 's'}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a cohort, optionally narrow by track/department/role, then a class, to enroll ${count == 1 ? 'this student' : 'these students'} into.',
              style: AdminTypography.bodySm(),
            ),
            const SizedBox(height: 14),
            if (widget.sections.isEmpty)
              Text('No classes exist yet. Create one from Manage Assigned Courses first.', style: AdminTypography.bodySm(color: AdminColors.error))
            else ...[
              DropdownButtonFormField<String>(
                initialValue: cohortNames.contains(_selectedCohort) ? _selectedCohort : null,
                isExpanded: true,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AdminColors.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                hint: const Text('Select a cohort'),
                items: [for (final c in cohortNames) DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))],
                onChanged: (v) => setState(() {
                  _selectedCohort = v;
                  _selectedSectionId = null;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: profileFilters.any((f) => f.key == _selectedProfileFilterKey) ? _selectedProfileFilterKey : null,
                isExpanded: true,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AdminColors.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                hint: const Text('Track / Department / Role (optional)'),
                items: [for (final f in profileFilters) DropdownMenuItem(value: f.key, child: Text(f.label, overflow: TextOverflow.ellipsis))],
                onChanged: (v) => setState(() {
                  _selectedProfileFilterKey = v;
                  _selectedSectionId = null;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: sections.any((s) => s.id == _selectedSectionId) ? _selectedSectionId : null,
                isExpanded: true,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AdminColors.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                hint: Text(_selectedCohort == null ? 'Select a cohort first' : 'Select a class'),
                items: [
                  for (final s in sections)
                    DropdownMenuItem(
                      value: s.id,
                      child: Text('${s.sectionCode} • ${s.courseTitle}', overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: sections.isEmpty ? null : (v) => setState(() => _selectedSectionId = v),
              ),
            ],
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
