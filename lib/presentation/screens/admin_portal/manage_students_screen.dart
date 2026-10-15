import 'package:stitch_aiei_lms/core/utils/refresh_on_return.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/ui_contrast.dart';
import 'package:stitch_aiei_lms/core/utils/app_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/session/app_session.dart';
import 'package:stitch_aiei_lms/core/utils/file_download.dart';
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
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_relational_delete.dart';
import 'widgets/admin_field_error.dart';
import 'widgets/admin_form_dialog.dart';
import 'widgets/admin_no_results.dart';
import 'widgets/admin_relational_delete.dart';
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
import 'widgets/searchable_dropdown.dart';

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

class _ManageStudentsScreenState extends State<ManageStudentsScreen> with RefreshOnReturn<ManageStudentsScreen> {
  @override
  void onReturnedTo() => _load();

  final _client = Supabase.instance.client;
  final _repository = SupabaseAdminStudentsRepositoryImpl(Supabase.instance.client);
  final _badgesRepository = SupabaseAdminBadgesRepositoryImpl(Supabase.instance.client);
  final _lecturersRepository = SupabaseLecturersRepositoryImpl(Supabase.instance.client);
  final _masterDataRepository = SupabaseAdminMasterDataRepositoryImpl(Supabase.instance.client);
  bool _isLoading = true;
  String? _errorMessage;
  List<Student> _students = [];
  Map<String, List<String>> _credentialTitles = {};
  List<(String, int)> _tracks = [];
  List<(String, int)> _trend = [];
  Set<String> _courseMismatchStudentIds = {};
  _SortColumn _sortColumn = _SortColumn.name;
  bool _sortAscending = true;
  int _page = 1;
  int _pageSize = adminPageSizeOptions.first;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  final Set<String> _selected = {};

  // '' means "All" (SearchableDropdownButton ignores null picks).
  String _trackFilter = '';
  String _departmentFilter = '';
  String _roleFilter = '';
  List<String> _trackOptions = [];
  List<String> _departmentOptions = [];
  List<String> _roleOptions = [];

  bool get _hasActiveFilters => _trackFilter.isNotEmpty || _departmentFilter.isNotEmpty || _roleFilter.isNotEmpty;

  List<Student> get _filteredStudents {
    return _students.where((s) {
      if (_trackFilter.isNotEmpty && s.programTrack != _trackFilter) return false;
      if (_departmentFilter.isNotEmpty && s.department != _departmentFilter) return false;
      if (_roleFilter.isNotEmpty && s.role != _roleFilter) return false;
      if (_query.isEmpty) return true;
      return s.name.toLowerCase().contains(_query) ||
          s.studentCode.toLowerCase().contains(_query) ||
          s.email.toLowerCase().contains(_query) ||
          (s.department ?? '').toLowerCase().contains(_query) ||
          (s.role ?? '').toLowerCase().contains(_query) ||
          (s.programTrack ?? '').toLowerCase().contains(_query);
    }).toList();
  }

  void _resetFilters() => setState(() {
        _trackFilter = '';
        _departmentFilter = '';
        _roleFilter = '';
        _page = 1;
      });

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 170, maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: SearchableDropdownButton<String>(
        isDense: true,
        value: value,
        style: AdminTypography.bodySm(color: AdminColors.onSurface),
        items: [
          DropdownMenuItem(value: '', child: Text('All $label', overflow: TextOverflow.ellipsis)),
          for (final o in options) DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (v) => setState(() {
          onChanged(v ?? '');
          _page = 1;
        }),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _filterDropdown(label: 'Tracks', value: _trackFilter, options: _trackOptions, onChanged: (v) => _trackFilter = v),
        _filterDropdown(label: 'Departments', value: _departmentFilter, options: _departmentOptions, onChanged: (v) => _departmentFilter = v),
        _filterDropdown(label: 'Roles', value: _roleFilter, options: _roleOptions, onChanged: (v) => _roleFilter = v),
        if (_hasActiveFilters)
          TextButton.icon(
            onPressed: _resetFilters,
            icon: const Icon(Icons.restart_alt, size: 16),
            label: const Text('Reset', textAlign: TextAlign.center),
            style: TextButton.styleFrom(foregroundColor: AdminColors.primaryContainer),
          ),
      ],
    );
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
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final students = await _repository.getStudents();
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
        _credentialTitles = credentials;
        _tracks = tracks;
        _trend = trend;
        _courseMismatchStudentIds = mismatches;
        _trackOptions = programTracks.map((t) => t.name).toList()..sort();
        _departmentOptions = departments.map((d) => d.name).toList()..sort();
        _roleOptions = roles.map((r) => r.name).toList()..sort();
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

  Future<void> _openRegisterStudent() async {
    final saved = await Navigator.of(context).push<Student>(
      MaterialPageRoute(builder: (_) => const StudentFormScreen()),
    );
    if (saved != null) _load();
  }

  static const _csvColumns = ['name', 'studentCode', 'email', 'studentType', 'department', 'title', 'programTrack', 'role', 'registrationDate'];

  Future<void> _downloadCsvTemplate() async {
    final header = _csvColumns.join(',');
    const staffExample = 'Jane Doe,EMP-90001,jane.doe@enterprise.com,Staff,Operations,Product Analyst,,Data Analyst,2025-01-15';
    const publicExample = 'John Smith,EMP-90002,john.smith@enterprise.com,Public,,,AI Engineering Track,,2025-01-15';
    const notes = [
      '# Lines starting with # are instructions and are ignored on import. You may delete them.',
      '# Required: name, studentCode, email, studentType, registrationDate.',
      '# registrationDate format: YYYY-MM-DD (e.g. 2025-01-15).',
      '# studentType: Staff or Public. department, title and role apply to Staff only; programTrack applies to Public only.',
      '# Example rows below - replace them with your own students.',
    ];
    final csv = '${notes.join('\n')}\n$header\n$staffExample\n$publicExample\n';
    final bytes = Uint8List.fromList(utf8.encode(csv));
    try {
      if (supportsBrowserDownload) {
        downloadBytes('student_import_template.csv', bytes);
        if (!mounted) return;
        showSuccessSnackBar(context, 'Template downloaded.');
        return;
      }
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save student import template',
        fileName: 'student_import_template.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes,
      );
      if (path == null) return;
      // On desktop, file_picker only returns the chosen path; it doesn't write the bytes.
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        await File(path.toLowerCase().endsWith('.csv') ? path : '$path.csv').writeAsBytes(bytes);
      }
      if (!mounted) return;
      showSuccessSnackBar(context, 'Template saved.');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save template: $e')));
    }
  }

  List<List<String>> _parseCsv(String content) {
    final rows = <List<String>>[];
    var row = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < content.length; i++) {
      final char = content[i];
      if (inQuotes) {
        if (char == '"') {
          if (i + 1 < content.length && content[i + 1] == '"') {
            buffer.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          buffer.write(char);
        }
      } else if (char == '"') {
        inQuotes = true;
      } else if (char == ',') {
        row.add(buffer.toString());
        buffer.clear();
      } else if (char == '\n' || char == '\r') {
        if (char == '\r' && i + 1 < content.length && content[i + 1] == '\n') i++;
        row.add(buffer.toString());
        buffer.clear();
        rows.add(row);
        row = [];
      } else {
        buffer.write(char);
      }
    }
    if (buffer.isNotEmpty || row.isNotEmpty) {
      row.add(buffer.toString());
      rows.add(row);
    }
    return rows.where((r) => r.any((c) => c.trim().isNotEmpty)).toList();
  }

  Future<void> _importFromCsv() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv'], withData: true);
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) return;

    final rows = _parseCsv(utf8.decode(bytes)).where((r) => !r.first.trimLeft().startsWith('#')).toList();
    if (rows.length < 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV has no data rows.')));
      return;
    }

    final header = rows.first.map((h) => h.trim().toLowerCase()).toList();
    int colIndex(String name) => header.indexOf(name.toLowerCase());
    final iName = colIndex('name');
    final iCode = colIndex('studentCode');
    final iEmail = colIndex('email');
    final iType = colIndex('studentType');
    final iDept = colIndex('department');
    final iTitle = colIndex('title');
    final iTrack = colIndex('programTrack');
    final iRole = colIndex('role');
    final iRegDate = colIndex('registrationDate');
    if ([iName, iCode, iEmail, iType, iRegDate].any((i) => i == -1)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV is missing required columns (name, studentCode, email, studentType, registrationDate).')),
      );
      return;
    }

    var succeeded = 0;
    final errors = <String>[];
    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      String cell(int i) => (i >= 0 && i < row.length) ? row[i].trim() : '';
      final name = cell(iName);
      final codeSuffix = cell(iCode);
      final email = cell(iEmail);
      final typeLabel = cell(iType);
      final registrationDateStr = cell(iRegDate);
      if (name.isEmpty && codeSuffix.isEmpty && email.isEmpty) continue; // blank row
      if (name.isEmpty || codeSuffix.isEmpty || email.isEmpty || registrationDateStr.isEmpty) {
        errors.add('Row ${r + 1}: missing required field(s).');
        continue;
      }
      final matchingType = StudentType.values.where((t) => t.label.toLowerCase() == typeLabel.toLowerCase());
      if (matchingType.isEmpty) {
        errors.add('Row ${r + 1}: unknown studentType "$typeLabel" (expected Staff or Public).');
        continue;
      }
      final studentType = matchingType.first;
      final registrationDate = DateTime.tryParse(registrationDateStr);
      if (registrationDate == null) {
        errors.add('Row ${r + 1}: invalid registrationDate "$registrationDateStr" (expected YYYY-MM-DD).');
        continue;
      }
      final department = cell(iDept);
      final title = cell(iTitle);
      final programTrack = cell(iTrack);
      final role = cell(iRole);
      try {
        await _repository.createStudent(
          name: name,
          studentCode: '${tenantPrefix()}${codeSuffix.toUpperCase()}',
          email: email,
          studentType: studentType,
          department: studentType == StudentType.internal && department.isNotEmpty ? department : null,
          title: studentType == StudentType.internal && title.isNotEmpty ? title : null,
          programTrack: studentType == StudentType.external && programTrack.isNotEmpty ? programTrack : null,
          role: studentType == StudentType.internal && role.isNotEmpty ? role : null,
          registrationDate: registrationDate,
        );
        succeeded++;
      } catch (e) {
        errors.add('Row ${r + 1}: $e');
      }
    }

    if (!mounted) return;
    await _load();
    if (!mounted) return;
    final summary =
        '$succeeded student${succeeded == 1 ? '' : 's'} imported.${errors.isEmpty ? '' : ' ${errors.length} row${errors.length == 1 ? '' : 's'} failed.'}';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import complete'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(summary),
                if (errors.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final e in errors) Text(e, style: AdminTypography.bodySm(color: AdminColors.error)),
                ],
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close', textAlign: TextAlign.center))],
      ),
    );
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
    final ids = _selected.toList();
    final service = SupabaseAdminRelationalDelete(Supabase.instance.client);
    final note = await service.studentCascadeNote(ids);
    if (!mounted) return;
    final done = await runRelationalDelete(
      context,
      noun: 'student',
      count: ids.length,
      dependents: const [],
      note: note,
      perform: (_) => _repository.deleteStudents(ids),
    );
    if (!done || !mounted) return;
    setState(_selected.clear);
    await _load();
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
    final outcome = await _repository.enrollStudentsInSection(studentIds, sectionId: chosen.id, courseId: chosen.courseId);
    if (!mounted) return;
    setState(_selected.clear);
    await _load();
    if (!mounted) return;
    String nameOf(String id) => _students.where((s) => s.id == id).map((s) => s.name).firstOrNull ?? 'Student $id';
    final n = outcome.enrolled.length;
    final lines = <String>[
      if (n > 0) '$n student${n == 1 ? '' : 's'} successfully enrolled in ${chosen.sectionCode}.',
      if (outcome.alreadyInThisClass.isNotEmpty)
        'Already enrolled in ${chosen.sectionCode}: ${outcome.alreadyInThisClass.map(nameOf).join(', ')}.',
      if (outcome.inOtherClass.isNotEmpty)
        'Already enrolled in another class of this course in the same cohort (not changed — unenroll them first to move): '
            '${outcome.inOtherClass.entries.map((e) => '${nameOf(e.key)} (${e.value})').join(', ')}.',
    ];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(lines.join('\n')), duration: Duration(seconds: lines.length > 1 ? 10 : 4)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // Only rows still visible (after a search or filter) can stay selected, so
    // the "N selected" count and bulk actions never include hidden records.
    final visibleIds = {for (final r in _filteredStudents) r.id};
    _selected.retainWhere(visibleIds.contains);
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
                ElevatedButton(onPressed: _load, child: const Text('Retry', textAlign: TextAlign.center)),
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
          _buildChartsGrid(),
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
            Text('Manage and Enrol Students', style: AdminTypography.headlineLg()),
            const SizedBox(height: 2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Text('The register of all students. Add students, place them in a cohort, department or track, and enrol them into courses.', style: AdminTypography.bodyMd()),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _downloadCsvTemplate,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Download CSV Template', textAlign: TextAlign.center),
              style: OutlinedButton.styleFrom(
                foregroundColor: AdminColors.primaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _importFromCsv,
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: const Text('Import from CSV', textAlign: TextAlign.center),
              style: OutlinedButton.styleFrom(
                foregroundColor: AdminColors.primaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _openRegisterStudent,
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('Register New Student', textAlign: TextAlign.center),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.primaryContainer,
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
                  TextSpan(text: 'Bulk Enrol', style: AdminTypography.bodySm(color: AdminColors.onPrimaryFixed).copyWith(fontWeight: FontWeight.w700)),
                  const TextSpan(text: ' to enrol them into a class.'),
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
              focusNode: _searchFocus,
              style: AdminTypography.bodySm(color: AdminColors.onSurface),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search student by name, student ID, email, or company...',
                prefixIcon: const Icon(Icons.search, size: 18, color: AdminColors.onSurfaceVariant),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(alignment: Alignment.centerLeft, child: _buildFilterRow()),
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
                    OutlinedButton(onPressed: _openBulkEnroll, style: _pillButtonStyle(), child: const Text('Bulk Enrol', textAlign: TextAlign.center)),
                    OutlinedButton.icon(
                      onPressed: _deleteSelected,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete', textAlign: TextAlign.center),
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
            Padding(padding: const EdgeInsets.all(32), child: AdminNoResults(controller: _searchController, focusNode: _searchFocus)),
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
        foregroundColor: Colors.white,
        backgroundColor: AdminColors.primaryContainer,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: AdminTypography.labelSm(),
      );

  Widget _headerRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: UiContrast.divider))),
      child: Row(
        children: [
          const SizedBox(width: 48),
          Expanded(flex: 2, child: _sortHeader('Code', _SortColumn.code)),
          Expanded(flex: 4, child: _sortHeader('Student', _SortColumn.name)),
          Expanded(flex: 2, child: Text('Student Type', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant))),
          Expanded(flex: 2, child: _sortHeader('Track', _SortColumn.track)),
          Expanded(flex: 3, child: _sortHeader('Department / Role', _SortColumn.department)),
          Expanded(flex: 3, child: Text('Badges', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant))),
          const SizedBox(width: 190),
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
        color: null,
        border: const Border(bottom: BorderSide(color: UiContrast.divider)),
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
                        child: Text(s.name, style: AdminTypography.titleSm(color: AdminColors.onSurface), overflow: TextOverflow.ellipsis),
                      ),
                      if (courseMismatch) ...[
                        const SizedBox(width: 4),
                        Tooltip(
                          message: s.studentType == StudentType.external
                              ? 'One or more enrolled course is not mapped to this student\'s track. Please click on the Manage Enrolled Courses button for more info.'
                              : 'One or more enrolled course is not mapped to this student\'s role or department. Please click on the Manage Enrolled Courses button for more info.',
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
              child: Text(s.studentType.label, style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis),
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
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.workspace_premium_outlined, size: 14, color: flagged ? AdminColors.error : AdminColors.onSurface),
                      const SizedBox(width: 4),
                      Text('${credentials.length} Badge${credentials.length == 1 ? '' : 's'}', style: AdminTypography.titleSm(color: flagged ? AdminColors.error : AdminColors.onSurface)),
                    ]),
                  ),
          ),
          SizedBox(
            width: 190,
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => _openEnrolledCourses(s),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AdminColors.primaryContainer,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: AdminTypography.labelSm(),
                ),
                child: const Text('Manage Enrolled Courses', textAlign: TextAlign.center),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int get _publicStudentCount => _students.where((s) => s.studentType == StudentType.external).length;
  int get _staffStudentCount => _students.where((s) => s.studentType == StudentType.internal).length;

  /// Counts of staff (internal) students per value of [pick], largest first;
  /// students without a value are grouped under "Unassigned".
  List<(String, int)> _staffCountsBy(String? Function(Student) pick) {
    final counts = <String, int>{};
    for (final s in _students) {
      if (s.studentType != StudentType.internal) continue;
      final key = pick(s) ?? 'Unassigned';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return [for (final e in counts.entries) (e.key, e.value)]..sort((a, b) => b.$2.compareTo(a.$2));
  }

  Widget _buildTracksCard() => _buildDistributionCard(
        title: 'Public Students by Track',
        subtitle: 'Total public students: $_publicStudentCount',
        entries: _tracks,
        total: _publicStudentCount,
      );

  Widget _buildDepartmentCard() => _buildDistributionCard(
        title: 'Staff Students by Department',
        subtitle: 'Total staff students: $_staffStudentCount',
        entries: _staffCountsBy((s) => s.department),
        total: _staffStudentCount,
      );

  Widget _buildRoleCard() => _buildDistributionCard(
        title: 'Staff Students by Role',
        subtitle: 'Total staff students: $_staffStudentCount',
        entries: _staffCountsBy((s) => s.role),
        total: _staffStudentCount,
      );

  Widget _buildDistributionCard({
    required String title,
    required String subtitle,
    required List<(String, int)> entries,
    required int total,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AdminTypography.titleMd()),
          const SizedBox(height: 4),
          Text(subtitle, style: AdminTypography.bodySm()),
          const SizedBox(height: 12),
          if (entries.isEmpty) Text('No students yet.', style: AdminTypography.bodySm(color: AdminColors.onSurfaceVariant)),
          for (final t in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(t.$1, style: AdminTypography.labelMd(color: AdminColors.onSurface))),
                    const SizedBox(width: 8),
                    Text('${t.$2} Students (${total == 0 ? 0 : (t.$2 * 100 / total).round()}%)', style: AdminTypography.labelSm()),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: LinearProgressIndicator(value: total == 0 ? 0 : t.$2 / total, minHeight: 6, backgroundColor: AdminColors.surfaceContainerLow, valueColor: const AlwaysStoppedAnimation<Color>(AdminColors.secondaryContainer)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// The four summary charts in an aligned 2×2 grid on wide screens (equal
  /// column widths, equal heights per row), stacked on narrow ones.
  Widget _buildChartsGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final charts = [_buildTracksCard(), _buildDepartmentCard(), _buildRoleCard(), _buildCredentialTrendCard()];
      if (constraints.maxWidth < 900) {
        return Column(children: [
          for (var i = 0; i < charts.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            charts[i],
          ],
        ]);
      }
      Widget pair(Widget a, Widget b) => IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: a),
              const SizedBox(width: 16),
              Expanded(child: b),
            ]),
          );
      return Column(children: [
        pair(charts[0], charts[1]),
        const SizedBox(height: 16),
        pair(charts[2], charts[3]),
      ]);
    });
  }

  /// Round-number y-axis step (1, 2, 5 × 10^k, never below 1) giving about
  /// four intervals, so the scale adapts to the data but always reads cleanly.
  static int _niceStep(int maxValue) {
    if (maxValue <= 4) return 1;
    final raw = maxValue / 4;
    var magnitude = 1;
    while (magnitude * 10 <= raw) {
      magnitude *= 10;
    }
    for (final m in const [1, 2, 5, 10]) {
      if (m * magnitude >= raw) return m * magnitude;
    }
    return 10 * magnitude;
  }

  Widget _buildCredentialTrendCard() {
    final months = _trend;
    final maxValue = months.isEmpty ? 0 : months.map((m) => m.$2).reduce((a, b) => a > b ? a : b);
    const intervals = 4;
    final step = _niceStep(maxValue);
    final axisMax = step * intervals;
    const plotHeight = 140.0;
    final axisLine = BorderSide(color: AdminColors.onSurfaceVariant, width: 1.5);
    final gridLine = BorderSide(color: UiContrast.divider);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text('Monthly Badge Grant Rate', style: AdminTypography.titleMd())),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AdminColors.surfaceContainer, borderRadius: BorderRadius.circular(6)),
              child: Text('Last 6 Months', style: AdminTypography.labelSm()),
            ),
          ]),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Y-axis tick labels, evenly spaced over the plot height.
              SizedBox(
                width: 30,
                height: plotHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i <= intervals; i++)
                      Positioned(
                        right: 6,
                        bottom: plotHeight * i / intervals - 7,
                        child: Text('${step * i}', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant)),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: plotHeight,
                      decoration: BoxDecoration(border: Border(left: axisLine, bottom: axisLine)),
                      child: Stack(
                        children: [
                          for (var i = 1; i <= intervals; i++)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: plotHeight * i / intervals - 1,
                              child: Container(height: 1, decoration: BoxDecoration(border: Border(top: gridLine))),
                            ),
                          Positioned.fill(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (final m in months)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Tooltip(
                                        message: '${m.$1}: ${m.$2} badge${m.$2 == 1 ? '' : 's'}',
                                        child: Container(
                                          height: (m.$2 / axisMax) * (plotHeight - 1.5),
                                          decoration: BoxDecoration(
                                            color: m == months.last ? AdminColors.secondaryContainer : AdminColors.surfaceContainerHigh,
                                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        for (final m in months)
                          Expanded(
                            child: Center(
                              child: Text(m.$1, style: AdminTypography.labelSm(color: m == months.last ? AdminColors.secondary : AdminColors.onSurfaceVariant)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
  // Mobile (<700px) layout — the same content as desktop (title + actions,
  // tip, metrics, search, filters, bulk-select, directory, pagination and the
  // two analytics cards); only the table becomes one card per student with
  // the same fields as a table row.
  // -------------------------------------------------------------------------
  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: const AdminMobileTopBar.root(title: 'Manage and Enrol Students'),
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
              _buildTopBar(),
              const SizedBox(height: 16),
              _buildInstructionBanner(),
              const SizedBox(height: 16),
              _buildMetrics(),
              const SizedBox(height: 20),
              _buildMobileSearchBar(),
              const SizedBox(height: 12),
              _buildFilterRow(),
              if (_selected.isNotEmpty) ...[
                const SizedBox(height: 12),
                adminMobileSelectionBar(
                  count: _selected.length,
                  itemLabel: 'student',
                  onDeselectAll: () => setState(_selected.clear),
                  onDelete: _deleteSelected,
                  extraActions: [
                    OutlinedButton(onPressed: _openBulkEnroll, style: _pillButtonStyle(), child: const Text('Bulk Enrol', textAlign: TextAlign.center)),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (_students.isNotEmpty && _filteredStudents.isEmpty)
                Padding(padding: const EdgeInsets.all(24), child: AdminNoResults(controller: _searchController, focusNode: _searchFocus)),
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
              _buildDepartmentCard(),
              const SizedBox(height: 16),
              _buildRoleCard(),
              const SizedBox(height: 16),
              _buildCredentialTrendCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSearchBar() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocus,
      style: AdminTypography.bodySm(color: AdminColors.onSurface),
      decoration: InputDecoration(
        isDense: true,
        fillColor: AdminColors.surfaceContainerLowest,
        hintText: 'Search student by name, student ID, email, or company...',
        prefixIcon: const Icon(Icons.search, size: 20, color: AdminColors.outline),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildMobileStudentCard(Student s) {
    final credentials = _credentialTitles[s.id] ?? const [];
    final selected = _selected.contains(s.id);
    final courseMismatch = _courseMismatchStudentIds.contains(s.id);
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
              Checkbox(
                value: selected,
                onChanged: (v) => setState(() => v == true ? _selected.add(s.id) : _selected.remove(s.id)),
                activeColor: AdminColors.primaryContainer,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.studentCode, style: AdminTypography.labelSm()),
                    Row(
                      children: [
                        Flexible(child: Text(s.name, style: AdminTypography.titleSm(color: AdminColors.onSurface), overflow: TextOverflow.ellipsis)),
                        if (courseMismatch) ...[
                          const SizedBox(width: 4),
                          Tooltip(
                            message: s.studentType == StudentType.external
                                ? 'One or more enrolled course is not mapped to this student\'s track. Please click on the Manage Enrolled Courses button for more info.'
                                : 'One or more enrolled course is not mapped to this student\'s role or department. Please click on the Manage Enrolled Courses button for more info.',
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
              Text(s.studentType.label, style: AdminTypography.labelSm(color: AdminColors.onSurface)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _mobileLabeled('Track', s.programTrack ?? '—')),
              const SizedBox(width: 12),
              Expanded(child: _mobileLabeled('Department / Role', s.department ?? '—', second: s.role ?? '—')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: credentials.isEmpty
                    ? Text('No badges', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant))
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Tooltip(
                          message: credentials.join('\n'),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.workspace_premium_outlined, size: 14, color: AdminColors.onSurface),
                            const SizedBox(width: 4),
                            Text('${credentials.length} Badge${credentials.length == 1 ? '' : 's'}', style: AdminTypography.labelSm(color: AdminColors.onSurface)),
                          ]),
                        ),
                      ),
              ),
              OutlinedButton(
                onPressed: () => _openEnrolledCourses(s),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AdminColors.primaryContainer,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: AdminTypography.labelSm(),
                ),
                child: const Text('Manage Enrolled Courses', textAlign: TextAlign.center),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileLabeled(String label, String value, {String? second}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant)),
        Text(value, style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis),
        if (second != null) Text(second, style: AdminTypography.labelSm(), overflow: TextOverflow.ellipsis),
      ],
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
  String? _sectionError;

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
    return AdminFormDialog(
      title: 'Enrol $count student${count == 1 ? '' : 's'}',
      submitChild: const Text('Enrol'),
      onSubmit: () {
        final id = _selectedSectionId;
        if (id == null) {
          setState(() => _sectionError = 'Select a class to enrol into.');
          return;
        }
        Navigator.of(context).pop(widget.sections.firstWhere((s) => s.id == id));
      },
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a cohort, optionally narrow by track/department/role, then a class, to enrol ${count == 1 ? 'this student' : 'these students'} into.',
              style: AdminTypography.bodySm(),
            ),
            const SizedBox(height: 14),
            if (widget.sections.isEmpty)
              Text('No classes exist yet. Create one from Manage Assigned Courses first.', style: AdminTypography.bodySm(color: AdminColors.error))
            else ...[
              SearchableDropdownFormField<String>(
                initialValue: cohortNames.contains(_selectedCohort) ? _selectedCohort : null,
                isExpanded: true,
                decoration: InputDecoration(
                  isDense: true,
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
              SearchableDropdownFormField<String>(
                initialValue: profileFilters.any((f) => f.key == _selectedProfileFilterKey) ? _selectedProfileFilterKey : null,
                isExpanded: true,
                decoration: InputDecoration(
                  isDense: true,
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
              SearchableDropdownFormField<String>(
                initialValue: sections.any((s) => s.id == _selectedSectionId) ? _selectedSectionId : null,
                isExpanded: true,
                decoration: InputDecoration(
                  isDense: true,
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
                onChanged: sections.isEmpty ? null : (v) => setState(() {
                  _selectedSectionId = v;
                  _sectionError = null;
                }),
              ),
              AdminFieldError(_sectionError),
            ],
          ],
        ),
    );
  }
}
