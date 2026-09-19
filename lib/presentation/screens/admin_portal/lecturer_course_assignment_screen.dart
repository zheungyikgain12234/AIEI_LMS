import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/session/app_session.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/core/utils/error_messages.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturers_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_courses_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_master_data_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/lecturer.dart';
import 'package:stitch_aiei_lms/domain/models/admin_course.dart';
import 'widgets/admin_field_label.dart';

// ---------------------------------------------------------------------------
// LecturerCourseAssignmentScreen — "Manage Assigned Courses" for a single
// lecturer. Shows the lecturer's info + credit capacity, lists courses not
// yet assigned to them (searchable, checkbox-selectable), keeps a live
// credit counter as courses are checked, and blocks assignment once the
// selection would exceed the lecturer's `credits_max`. Assigning a course
// creates a new class section identified by an admin-entered, tenant-prefixed
// unique Class Code (e.g. `TN01-CLS-OSHE101-A01`) taught by this lecturer;
// already-assigned courses can be unassigned, which frees up their sections.
// ---------------------------------------------------------------------------
class LecturerCourseAssignmentScreen extends ConsumerStatefulWidget {
  final String lecturerId;

  const LecturerCourseAssignmentScreen({super.key, required this.lecturerId});

  @override
  ConsumerState<LecturerCourseAssignmentScreen> createState() => _LecturerCourseAssignmentScreenState();
}

class _LecturerCourseAssignmentScreenState extends ConsumerState<LecturerCourseAssignmentScreen> {
  final _lecturersRepository = SupabaseLecturersRepositoryImpl(Supabase.instance.client);
  final _coursesRepository = SupabaseAdminCoursesRepositoryImpl(Supabase.instance.client);
  final _masterDataRepository = SupabaseAdminMasterDataRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  bool _isAssigning = false;
  bool _isUnassigning = false;
  Lecturer? _lecturer;
  List<AdminCourse> _availableCourses = [];
  List<AdminCourse> _assignedCourses = [];
  List<String> _cohorts = [];
  final Set<String> _selectedToAssign = {};
  final Set<String> _selectedToUnassign = {};
  final _searchController = TextEditingController();
  final _locationController = TextEditingController();
  final _classCodeController = TextEditingController();
  final _capacityController = TextEditingController();
  String _query = '';
  static const _dayOptions = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _deliveryModeOptions = [('physical', 'Physical'), ('online', 'Online')];
  String? _dayOfWeek;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _deliveryMode = 'physical';
  String? _selectedCohort;
  String? _assignErrorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _query = _searchController.text.trim().toLowerCase()));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    _classCodeController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final lecturer = await _lecturersRepository.getLecturerById(widget.lecturerId);
    final assignedIds = (await _lecturersRepository.getAssignedCourseIds(widget.lecturerId)).toSet();
    final allCourses = await _coursesRepository.getCourses();
    final cohorts = await _masterDataRepository.getCohorts();
    if (!mounted) return;
    setState(() {
      _lecturer = lecturer;
      _assignedCourses = allCourses.where((c) => assignedIds.contains(c.id)).toList();
      _availableCourses = allCourses.where((c) => !assignedIds.contains(c.id)).toList();
      _cohorts = [for (final c in cohorts) c.name];
      _selectedToAssign.clear();
      _selectedToUnassign.clear();
      _isLoading = false;
    });
  }

  List<AdminCourse> get _filteredAvailable {
    if (_query.isEmpty) return _availableCourses;
    return _availableCourses.where((c) =>
        c.courseCode.toLowerCase().contains(_query) || c.courseTitle.toLowerCase().contains(_query)).toList();
  }

  int get _assignCredits => _availableCourses.where((c) => _selectedToAssign.contains(c.id)).fold(0, (sum, c) => sum + c.credits);

  int get _unassignCredits => _assignedCourses.where((c) => _selectedToUnassign.contains(c.id)).fold(0, (sum, c) => sum + c.credits);

  int get _projectedCreditsUsed => (_lecturer?.creditsUsed ?? 0) + _assignCredits - _unassignCredits;

  bool get _overCapacity => _lecturer != null && _projectedCreditsUsed > _lecturer!.creditsMax;

  bool get _timeRangeValid => _startTime != null && _endTime != null && _toMinutes(_endTime!) > _toMinutes(_startTime!);

  bool get _canAssign =>
      _selectedToAssign.isNotEmpty &&
      !_overCapacity &&
      _dayOfWeek != null &&
      _timeRangeValid &&
      _locationController.text.trim().isNotEmpty &&
      _classCodeController.text.trim().isNotEmpty &&
      _classCapacity != null &&
      _classCapacity! > 0 &&
      _selectedCohort != null;

  int? get _classCapacity => int.tryParse(_capacityController.text.trim());

  /// Every code is stored tenant-prefixed (`TN01-CLS-...`) to keep it unique
  /// across tenants, but the admin only ever types/sees the suffix. When
  /// more than one course is assigned at once, the course code is folded in
  /// too so the same suffix (e.g. `A01`) stays unique per course.
  String _classCodeFor(AdminCourse course) {
    final courseSuffix = _stripTenantPrefix(course.courseCode).replaceAll('-', '');
    final suffix = _classCodeController.text.trim();
    return '${_tenantPrefix()}CLS-$courseSuffix-$suffix';
  }

  String _tenantPrefix() => '${ref.read(appSessionProvider).tenantId}-';

  String _stripTenantPrefix(String code) {
    final prefix = _tenantPrefix();
    return code.startsWith(prefix) ? code.substring(prefix.length) : code;
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  String _formatTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;
    setState(() => isStart ? _startTime = picked : _endTime = picked);
  }

  Future<void> _assign() async {
    if (!_canAssign || _lecturer == null) return;
    setState(() {
      _isAssigning = true;
      _assignErrorMessage = null;
    });
    try {
      final courses = _availableCourses.where((c) => _selectedToAssign.contains(c.id)).toList();
      final startTime = _formatTime(_startTime!);
      final endTime = _formatTime(_endTime!);
      final location = _locationController.text.trim();
      final capacity = _classCapacity!;
      for (final course in courses) {
        await _lecturersRepository.createSectionForCourse(
          courseId: course.id,
          classCode: _classCodeFor(course),
          lecturerId: widget.lecturerId,
          dayOfWeek: _dayOfWeek!,
          startTime: startTime,
          endTime: endTime,
          location: location,
          capacity: capacity,
          deliveryMode: _deliveryMode,
          cohort: _selectedCohort!,
        );
      }
      await _lecturersRepository.assignCoursesToLecturer(widget.lecturerId, _selectedToAssign.toList());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${courses.length} course${courses.length == 1 ? '' : 's'} assigned to ${_lecturer!.name}.')),
      );
      _dayOfWeek = null;
      _startTime = null;
      _endTime = null;
      _deliveryMode = 'physical';
      _selectedCohort = null;
      _locationController.clear();
      _classCodeController.clear();
      _capacityController.clear();
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _assignErrorMessage = friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  Future<void> _unassign() async {
    if (_selectedToUnassign.isEmpty || _lecturer == null) return;
    setState(() => _isUnassigning = true);
    try {
      final count = _selectedToUnassign.length;
      await _lecturersRepository.unassignCoursesFromLecturer(widget.lecturerId, _selectedToUnassign.toList());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count course${count == 1 ? '' : 's'} unassigned from ${_lecturer!.name}.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unassign courses: $e'), backgroundColor: AdminColors.error),
      );
    } finally {
      if (mounted) setState(() => _isUnassigning = false);
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
                        const SizedBox(height: 16),
                        _buildUnassignBar(),
                        const SizedBox(height: 20),
                      ],
                      _buildAvailableCoursesCard(),
                      const SizedBox(height: 16),
                      _buildClassDetailsCard(),
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
                Text('${l.department} • ${l.lecturerCode}', style: AdminTypography.labelSm(), overflow: TextOverflow.ellipsis),
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
                _selectedToAssign.isEmpty && _selectedToUnassign.isEmpty
                    ? 'Currently used: ${l.creditsUsed}'
                    : '${l.creditsUsed} used'
                        '${_assignCredits > 0 ? ' + $_assignCredits selected' : ''}'
                        '${_unassignCredits > 0 ? ' − $_unassignCredits unassigning' : ''}',
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
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Currently Assigned (${_assignedCourses.length})', style: AdminTypography.titleSm()),
            ),
          ),
          Column(children: [for (final c in _assignedCourses) _assignedRow(c)]),
        ],
      ),
    );
  }

  Widget _assignedRow(AdminCourse c) {
    final selected = _selectedToUnassign.contains(c.id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AdminColors.surfaceContainer))),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: (v) => setState(() => v == true ? _selectedToUnassign.add(c.id) : _selectedToUnassign.remove(c.id)),
            activeColor: AdminColors.error,
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

  Widget _buildUnassignBar() {
    final disabled = _selectedToUnassign.isEmpty || _isUnassigning;
    return Row(
      children: [
        Expanded(
          child: Text(
            _selectedToUnassign.isEmpty
                ? 'Select assigned courses above to unassign.'
                : '${_selectedToUnassign.length} course${_selectedToUnassign.length == 1 ? '' : 's'} selected to unassign • $_unassignCredits credits',
            style: AdminTypography.bodySm(color: AdminColors.onSurfaceVariant),
          ),
        ),
        OutlinedButton.icon(
          onPressed: disabled ? null : _unassign,
          icon: _isUnassigning
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AdminColors.error))
              : const Icon(Icons.link_off, size: 16),
          label: const Text('Unassign Selected'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AdminColors.error,
            backgroundColor: AdminColors.errorContainer,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: AdminTypography.labelSm(),
          ),
        ),
      ],
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
    final selected = _selectedToAssign.contains(c.id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AdminColors.surfaceContainer))),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: (v) => setState(() => v == true ? _selectedToAssign.add(c.id) : _selectedToAssign.remove(c.id)),
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

  Widget _buildClassDetailsCard() {
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
          Text('Class Details', style: AdminTypography.titleSm()),
          const SizedBox(height: 2),
          Text('Applied to every class section created by this assignment.', style: AdminTypography.bodySm()),
          const SizedBox(height: 12),
          if (_assignErrorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AdminColors.errorContainer, borderRadius: BorderRadius.circular(8)),
              child: Text(_assignErrorMessage!, style: AdminTypography.bodySm(color: AdminColors.onErrorContainer)),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 160,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminFieldLabel('Day'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _dayOfWeek,
                      isExpanded: true,
                      style: AdminTypography.bodyMd(color: AdminColors.onSurface),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: AdminColors.surfaceContainerLow,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      hint: Text('Select day', style: AdminTypography.bodySm(color: AdminColors.outline)),
                      items: [for (final d in _dayOptions) DropdownMenuItem(value: d, child: Text(d))],
                      onChanged: (v) => setState(() => _dayOfWeek = v),
                    ),
                  ],
                ),
              ),
              _timeField(label: 'Start Time', value: _startTime, onTap: () => _pickTime(isStart: true)),
              _timeField(label: 'End Time', value: _endTime, onTap: () => _pickTime(isStart: false)),
              SizedBox(
                width: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminFieldLabel('Location'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _locationController,
                      onChanged: (_) => setState(() {}),
                      style: AdminTypography.bodyMd(color: AdminColors.onSurface),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: AdminColors.surfaceContainerLow,
                        hintText: 'Room 204',
                        hintStyle: AdminTypography.bodySm(color: AdminColors.outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminFieldLabel('Class Code'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _classCodeController,
                      onChanged: (_) => setState(() {}),
                      style: AdminTypography.bodyMd(color: AdminColors.onSurface),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: AdminColors.surfaceContainerLow,
                        hintText: 'A01',
                        hintStyle: AdminTypography.bodySm(color: AdminColors.outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminFieldLabel('Capacity'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _capacityController,
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.number,
                      style: AdminTypography.bodyMd(color: AdminColors.onSurface),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: AdminColors.surfaceContainerLow,
                        hintText: '30',
                        hintStyle: AdminTypography.bodySm(color: AdminColors.outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 160,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminFieldLabel('Delivery Mode'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _deliveryMode,
                      isExpanded: true,
                      style: AdminTypography.bodyMd(color: AdminColors.onSurface),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: AdminColors.surfaceContainerLow,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: [for (final m in _deliveryModeOptions) DropdownMenuItem(value: m.$1, child: Text(m.$2))],
                      onChanged: (v) => setState(() => _deliveryMode = v!),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminFieldLabel('Cohort'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCohort,
                      isExpanded: true,
                      style: AdminTypography.bodyMd(color: AdminColors.onSurface),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: AdminColors.surfaceContainerLow,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      hint: Text('Select cohort', style: AdminTypography.bodySm(color: AdminColors.outline)),
                      items: [for (final c in _cohorts) DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))],
                      onChanged: (v) => setState(() => _selectedCohort = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_startTime != null && _endTime != null && !_timeRangeValid) ...[
            const SizedBox(height: 8),
            Text('End time must be after start time.', style: AdminTypography.labelSm(color: AdminColors.error)),
          ],
        ],
      ),
    );
  }

  Widget _timeField({required String label, required TimeOfDay? value, required VoidCallback onTap}) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminFieldLabel(label),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: AdminColors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    value == null ? 'Select time' : _formatTime(value),
                    style: AdminTypography.bodyMd(color: value == null ? AdminColors.outline : AdminColors.onSurface),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignBar() {
    final disabled = !_canAssign || _isAssigning;
    return Row(
      children: [
        Expanded(
          child: Text(
            _selectedToAssign.isEmpty
                ? 'Select courses to assign.'
                : _dayOfWeek == null
                    ? 'Set a day above.'
                    : !_timeRangeValid
                        ? 'Set a valid start/end time above.'
                        : _locationController.text.trim().isEmpty
                            ? 'Set a location above.'
                            : _classCodeController.text.trim().isEmpty
                                ? 'Set a class code above.'
                                : _classCapacity == null || _classCapacity! <= 0
                                    ? 'Set a valid capacity above.'
                                    : _selectedCohort == null
                                        ? 'Select a cohort above.'
                                        : '${_selectedToAssign.length} course${_selectedToAssign.length == 1 ? '' : 's'} selected • $_assignCredits credits',
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
