import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_master_data_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_courses_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_department_course_mapping_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/department.dart';
import 'package:stitch_aiei_lms/domain/models/admin_course.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_mobile_top_bar.dart';
import 'widgets/admin_nav.dart';

// ---------------------------------------------------------------------------
// DepartmentCourseMappingScreen — "which courses belong to a given
// department?" Pick a department, then check/uncheck courses; each toggle
// is saved immediately to `department_courses`.
// ---------------------------------------------------------------------------
class DepartmentCourseMappingScreen extends StatefulWidget {
  const DepartmentCourseMappingScreen({super.key});

  @override
  State<DepartmentCourseMappingScreen> createState() => _DepartmentCourseMappingScreenState();
}

class _DepartmentCourseMappingScreenState extends State<DepartmentCourseMappingScreen> {
  final _masterDataRepository = SupabaseAdminMasterDataRepositoryImpl(Supabase.instance.client);
  final _coursesRepository = SupabaseAdminCoursesRepositoryImpl(Supabase.instance.client);
  final _mappingRepository = SupabaseDepartmentCourseMappingRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  bool _isLoadingMapping = false;
  List<Department> _departments = [];
  List<AdminCourse> _courses = [];
  String? _selectedDepartmentId;
  Set<String> _mappedCourseIds = {};
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _query = _searchController.text.trim().toLowerCase()));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final departments = await _masterDataRepository.getDepartments();
    final courses = await _coursesRepository.getCourses();
    if (!mounted) return;
    setState(() {
      _departments = departments;
      _courses = courses;
      _selectedDepartmentId ??= departments.isEmpty ? null : departments.first.id;
      _isLoading = false;
    });
    if (_selectedDepartmentId != null) await _loadMapping(_selectedDepartmentId!);
  }

  Future<void> _loadMapping(String departmentId) async {
    setState(() => _isLoadingMapping = true);
    final ids = await _mappingRepository.getCourseIdsForDepartment(departmentId);
    if (!mounted) return;
    setState(() {
      _mappedCourseIds = ids;
      _isLoadingMapping = false;
    });
  }

  List<AdminCourse> get _filteredCourses {
    if (_query.isEmpty) return _courses;
    return _courses.where((c) =>
        c.courseCode.toLowerCase().contains(_query) || c.courseTitle.toLowerCase().contains(_query)).toList();
  }

  Department? get _selectedDepartment {
    for (final d in _departments) {
      if (d.id == _selectedDepartmentId) return d;
    }
    return null;
  }

  void _handleNav(AdminNavDestination dest) =>
      handleAdminNav(context, AdminNavDestination.departmentCourseMapping, dest);

  Future<void> _toggleCourse(String courseId, bool allowed) async {
    final departmentId = _selectedDepartmentId;
    if (departmentId == null) return;
    setState(() => allowed ? _mappedCourseIds.add(courseId) : _mappedCourseIds.remove(courseId));
    try {
      await _mappingRepository.setCourseForDepartment(departmentId, courseId, allowed);
    } catch (e) {
      if (!mounted) return;
      setState(() => allowed ? _mappedCourseIds.remove(courseId) : _mappedCourseIds.add(courseId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update mapping: $e'), backgroundColor: AdminColors.error),
      );
    }
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
      selected: AdminNavDestination.departmentCourseMapping,
      onDestinationSelected: _handleNav,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 20),
          _buildDepartmentSelector(),
          const SizedBox(height: 20),
          _buildCoursesCard(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Department ↔ Course Mapping', style: AdminTypography.headlineLg()),
        const SizedBox(height: 2),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            'Assign courses to departments — e.g. which courses belong under Information Technology or Engineering.',
            style: AdminTypography.bodyMd(),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentSelector() {
    if (_departments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
        child: Text('No departments exist yet. Create one from Manage Departments first.', style: AdminTypography.bodyMd(color: AdminColors.error)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: Row(
        children: [
          Text('Department', style: AdminTypography.labelMd(color: AdminColors.onSurfaceVariant)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedDepartmentId,
              isExpanded: true,
              style: AdminTypography.bodyMd(color: AdminColors.onSurface),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AdminColors.surfaceContainerLow,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: [for (final d in _departments) DropdownMenuItem(value: d.id, child: Text(d.name))],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selectedDepartmentId = v);
                _loadMapping(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesCard() {
    final courses = _filteredCourses;
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
                hintText: 'Search course by code or title...',
                hintStyle: AdminTypography.bodySm(color: AdminColors.outline),
                prefixIcon: const Icon(Icons.search, size: 18, color: AdminColors.onSurfaceVariant),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_isLoadingMapping)
            const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())
          else if (courses.isEmpty)
            Padding(padding: const EdgeInsets.all(32), child: Text('No courses found.', style: AdminTypography.bodyMd()))
          else
            Column(children: [for (final c in courses) _courseRow(c)]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_mappedCourseIds.length} of ${_courses.length} courses mapped to ${_selectedDepartment?.name ?? 'this department'}',
                style: AdminTypography.bodySm(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _courseRow(AdminCourse c) {
    final allowed = _mappedCourseIds.contains(c.id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AdminColors.surfaceContainer))),
      child: Row(
        children: [
          Checkbox(
            value: allowed,
            onChanged: (v) => _toggleCourse(c.id, v ?? false),
            activeColor: AdminColors.primaryContainer,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.courseTitle, style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis),
                Text(c.courseCode, style: AdminTypography.labelSm()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Mobile (<700px) layout — a drill-in screen (back-arrow top bar, no
  // bottom nav; reached from the "More" menu).
  // ---------------------------------------------------------------------

  Widget _buildMobileScaffold(BuildContext context) {
    final courses = _filteredCourses;
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: const AdminMobileTopBar.detail(title: 'Department ↔ Course Mapping'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Assign courses to departments — e.g. which courses belong under Information Technology or Engineering.',
                style: AdminTypography.bodyMd(),
              ),
              const SizedBox(height: 16),
              _buildDepartmentSelector(),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                style: AdminTypography.bodySm(color: AdminColors.onSurface),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AdminColors.surfaceContainerLowest,
                  hintText: 'Search course by code or title...',
                  hintStyle: AdminTypography.bodySm(color: AdminColors.outline),
                  prefixIcon: const Icon(Icons.search, size: 18, color: AdminColors.onSurfaceVariant),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoadingMapping)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
              else if (courses.isEmpty)
                Padding(padding: const EdgeInsets.all(24), child: Text('No courses found.', style: AdminTypography.bodyMd()))
              else
                Container(
                  decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [for (final c in courses) _courseRow(c)]),
                ),
              const SizedBox(height: 12),
              Text(
                '${_mappedCourseIds.length} of ${_courses.length} courses mapped to ${_selectedDepartment?.name ?? 'this department'}',
                style: AdminTypography.bodySm(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
