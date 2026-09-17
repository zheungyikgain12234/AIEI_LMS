import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_master_data_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_courses_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_role_course_mapping_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/role.dart';
import 'package:stitch_aiei_lms/domain/models/admin_course.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_mobile_top_bar.dart';
import 'widgets/admin_nav.dart';

// ---------------------------------------------------------------------------
// RoleCourseMappingScreen — "which courses can a given job role study?"
// (e.g. IT Support Specialist -> PY-402, DATA-501, ...; HVAC / Aircon
// Installer -> OSHE-101, SAF-204). Pick a role, then check/uncheck courses;
// each toggle is saved immediately to `role_courses`.
// ---------------------------------------------------------------------------
class RoleCourseMappingScreen extends StatefulWidget {
  const RoleCourseMappingScreen({super.key});

  @override
  State<RoleCourseMappingScreen> createState() => _RoleCourseMappingScreenState();
}

class _RoleCourseMappingScreenState extends State<RoleCourseMappingScreen> {
  final _masterDataRepository = SupabaseAdminMasterDataRepositoryImpl(Supabase.instance.client);
  final _coursesRepository = SupabaseAdminCoursesRepositoryImpl(Supabase.instance.client);
  final _mappingRepository = SupabaseRoleCourseMappingRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  bool _isLoadingMapping = false;
  List<Role> _roles = [];
  List<AdminCourse> _courses = [];
  String? _selectedRoleId;
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
    final roles = await _masterDataRepository.getRoles();
    final courses = await _coursesRepository.getCourses();
    if (!mounted) return;
    setState(() {
      _roles = roles;
      _courses = courses;
      _selectedRoleId ??= roles.isEmpty ? null : roles.first.id;
      _isLoading = false;
    });
    if (_selectedRoleId != null) await _loadMapping(_selectedRoleId!);
  }

  Future<void> _loadMapping(String roleId) async {
    setState(() => _isLoadingMapping = true);
    final ids = await _mappingRepository.getCourseIdsForRole(roleId);
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

  Role? get _selectedRole {
    for (final r in _roles) {
      if (r.id == _selectedRoleId) return r;
    }
    return null;
  }

  void _handleNav(AdminNavDestination dest) => handleAdminNav(context, AdminNavDestination.roleCourseMapping, dest);

  Future<void> _toggleCourse(String courseId, bool allowed) async {
    final roleId = _selectedRoleId;
    if (roleId == null) return;
    setState(() => allowed ? _mappedCourseIds.add(courseId) : _mappedCourseIds.remove(courseId));
    try {
      await _mappingRepository.setCourseForRole(roleId, courseId, allowed);
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
      selected: AdminNavDestination.roleCourseMapping,
      onDestinationSelected: _handleNav,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 20),
          _buildRoleSelector(),
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
        Text('Role ↔ Course Mapping', style: AdminTypography.headlineLg()),
        const SizedBox(height: 2),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            'Assign courses to job roles — e.g. which courses an IT Support Specialist or an HVAC / Aircon Installer can study.',
            style: AdminTypography.bodyMd(),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    if (_roles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
        child: Text('No roles exist yet. Create one from Manage Roles first.', style: AdminTypography.bodyMd(color: AdminColors.error)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Role', style: AdminTypography.labelMd(color: AdminColors.onSurfaceVariant)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedRoleId,
                  isExpanded: true,
                  style: AdminTypography.bodyMd(color: AdminColors.onSurface),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: AdminColors.surfaceContainerLow,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  items: [for (final r in _roles) DropdownMenuItem(value: r.id, child: Text(r.name))],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _selectedRoleId = v);
                    _loadMapping(v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Role list retrieved from HRIQ system',
            style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant).copyWith(fontStyle: FontStyle.italic),
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
                '${_mappedCourseIds.length} of ${_courses.length} courses mapped to ${_selectedRole?.name ?? 'this role'}',
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
      appBar: const AdminMobileTopBar.detail(title: 'Role ↔ Course Mapping'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Assign courses to job roles — e.g. which courses an IT Support Specialist or an HVAC / Aircon Installer can study.',
                style: AdminTypography.bodyMd(),
              ),
              const SizedBox(height: 16),
              _buildRoleSelector(),
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
                '${_mappedCourseIds.length} of ${_courses.length} courses mapped to ${_selectedRole?.name ?? 'this role'}',
                style: AdminTypography.bodySm(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
