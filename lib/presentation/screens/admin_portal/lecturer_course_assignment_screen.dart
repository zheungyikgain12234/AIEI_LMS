import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturers_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_courses_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/lecturer.dart';
import 'package:stitch_aiei_lms/domain/models/admin_course.dart';

// ---------------------------------------------------------------------------
// LecturerCourseAssignmentScreen — "Manage Assigned Courses" for a single
// lecturer. Shows the lecturer's info + credit capacity, lists courses not
// yet assigned to them (searchable, checkbox-selectable), keeps a live
// credit counter as courses are checked, and blocks assignment once the
// selection would exceed the lecturer's `credits_max`.
// ---------------------------------------------------------------------------
class LecturerCourseAssignmentScreen extends StatefulWidget {
  final String lecturerId;

  const LecturerCourseAssignmentScreen({super.key, required this.lecturerId});

  @override
  State<LecturerCourseAssignmentScreen> createState() => _LecturerCourseAssignmentScreenState();
}

class _LecturerCourseAssignmentScreenState extends State<LecturerCourseAssignmentScreen> {
  final _lecturersRepository = SupabaseLecturersRepositoryImpl(Supabase.instance.client);
  final _coursesRepository = SupabaseAdminCoursesRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  bool _isAssigning = false;
  Lecturer? _lecturer;
  List<AdminCourse> _availableCourses = [];
  List<AdminCourse> _assignedCourses = [];
  final Set<String> _selected = {};
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
    final lecturer = await _lecturersRepository.getLecturerById(widget.lecturerId);
    final assignedIds = (await _lecturersRepository.getAssignedCourseIds(widget.lecturerId)).toSet();
    final allCourses = await _coursesRepository.getCourses();
    if (!mounted) return;
    setState(() {
      _lecturer = lecturer;
      _assignedCourses = allCourses.where((c) => assignedIds.contains(c.id)).toList();
      _availableCourses = allCourses.where((c) => !assignedIds.contains(c.id)).toList();
      _selected.clear();
      _isLoading = false;
    });
  }

  List<AdminCourse> get _filteredAvailable {
    if (_query.isEmpty) return _availableCourses;
    return _availableCourses.where((c) =>
        c.courseCode.toLowerCase().contains(_query) || c.courseTitle.toLowerCase().contains(_query)).toList();
  }

  int get _selectedCredits => _availableCourses.where((c) => _selected.contains(c.id)).fold(0, (sum, c) => sum + c.credits);

  int get _projectedCreditsUsed => (_lecturer?.creditsUsed ?? 0) + _selectedCredits;

  bool get _overCapacity => _lecturer != null && _projectedCreditsUsed > _lecturer!.creditsMax;

  Future<void> _assign() async {
    if (_selected.isEmpty || _overCapacity || _lecturer == null) return;
    setState(() => _isAssigning = true);
    try {
      await _lecturersRepository.assignCoursesToLecturer(widget.lecturerId, _selected.toList());
      await _lecturersRepository.setCreditsUsed(widget.lecturerId, _projectedCreditsUsed);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_selected.length} course${_selected.length == 1 ? '' : 's'} assigned to ${_lecturer!.name}.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign courses: $e'), backgroundColor: AdminColors.error),
      );
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: AdminColors.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AdminColors.onSurface,
        title: Text('Manage Assigned Courses', style: AdminTypography.headlineSm()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildLecturerCard(),
                      const SizedBox(height: 20),
                      if (_assignedCourses.isNotEmpty) ...[
                        _buildAssignedCard(),
                        const SizedBox(height: 20),
                      ],
                      _buildAvailableCoursesCard(),
                      const SizedBox(height: 16),
                      _buildAssignBar(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLecturerCard() {
    final l = _lecturer!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: AdminColors.surfaceContainerHigh, shape: BoxShape.circle),
            child: const Icon(Icons.person, color: AdminColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.name, style: AdminTypography.titleMd()),
                Text(l.title, style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
                Text('${l.department} • ${l.employeeId}', style: AdminTypography.labelSm(), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_projectedCreditsUsed / ${l.creditsMax} Credits',
                style: AdminTypography.titleMd(color: _overCapacity ? AdminColors.error : AdminColors.onSurface),
              ),
              const SizedBox(height: 2),
              Text(
                _selected.isEmpty
                    ? 'Currently used: ${l.creditsUsed}'
                    : '${l.creditsUsed} used + $_selectedCredits selected',
                style: AdminTypography.labelSm(color: _overCapacity ? AdminColors.error : AdminColors.onSurfaceVariant),
              ),
              if (_overCapacity) ...[
                const SizedBox(height: 4),
                Text(
                  'Exceeds capacity by ${_projectedCreditsUsed - l.creditsMax}',
                  style: AdminTypography.labelSm(color: AdminColors.error).copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedCard() {
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
          Text('Currently Assigned (${_assignedCourses.length})', style: AdminTypography.titleSm()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _assignedCourses.map((c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(6)),
              child: Text('${c.courseCode} • ${c.credits} cr', style: AdminTypography.labelSm(color: AdminColors.onSurface)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableCoursesCard() {
    final courses = _filteredAvailable;
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
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
          if (courses.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                _availableCourses.isEmpty ? 'All courses are already assigned to this lecturer.' : 'No courses found.',
                style: AdminTypography.bodyMd(),
              ),
            )
          else
            Column(children: [for (final c in courses) _courseRow(c)]),
        ],
      ),
    );
  }

  Widget _courseRow(AdminCourse c) {
    final selected = _selected.contains(c.id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AdminColors.surfaceContainer))),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: (v) => setState(() => v == true ? _selected.add(c.id) : _selected.remove(c.id)),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(9999)),
            child: Text('${c.credits} cr', style: AdminTypography.labelSm(color: AdminColors.onSurface)),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignBar() {
    final disabled = _selected.isEmpty || _overCapacity || _isAssigning;
    return Row(
      children: [
        Expanded(
          child: Text(
            _selected.isEmpty
                ? 'Select courses to assign.'
                : '${_selected.length} course${_selected.length == 1 ? '' : 's'} selected • $_selectedCredits credits',
            style: AdminTypography.bodySm(color: AdminColors.onSurfaceVariant),
          ),
        ),
        ElevatedButton(
          onPressed: disabled ? null : _assign,
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.primaryContainer,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isAssigning
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Assign to Lecturer'),
        ),
      ],
    );
  }
}
