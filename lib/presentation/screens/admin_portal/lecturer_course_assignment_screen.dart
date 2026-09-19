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
import 'package:stitch_aiei_lms/data/repositories/supabase_specialization_course_mapping_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/lecturer.dart';
import 'package:stitch_aiei_lms/domain/models/admin_course.dart';
import 'package:stitch_aiei_lms/domain/models/cohort.dart';
import 'package:stitch_aiei_lms/domain/repositories/lecturers_repository.dart' show LecturerClassSlot;
import 'widgets/admin_field_label.dart';

// ---------------------------------------------------------------------------
// LecturerCourseAssignmentScreen — "Manage Assigned Courses" for a single
// lecturer. Shows the lecturer's info + credit capacity, lists courses
// (searchable, single-select via radio button — one course gets one new
// class section per assignment), keeps a live credit counter as a course is
// picked, and blocks assignment once the selection would exceed the
// lecturer's `credits_max`. Assigning a course
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
  final _specializationMappingRepository = SupabaseSpecializationCourseMappingRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  bool _isAssigning = false;
  bool _isUnassigning = false;
  Lecturer? _lecturer;
  List<AdminCourse> _availableCourses = [];
  List<Cohort> _cohortModels = [];
  Map<String, int> _creditsByCourseId = {};
  Map<String, AdminCourse> _courseById = {};
  Set<String> _specializationCourseIds = {};
  List<LecturerClassSlot> _assignedSchedules = [];
  int? _selectedYear;
  String? _selectedCourseId;
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
    final assignedSchedules = await _lecturersRepository.getAssignedSchedules(widget.lecturerId);
    final allCourses = await _coursesRepository.getCourses();
    final cohorts = await _masterDataRepository.getCohorts();

    // Courses "not related to lecturer's specialization" (Specialization ↔
    // Course Mapping) get a warning tag below — it never blocks assignment.
    final specializations = await _masterDataRepository.getSpecializations();
    Set<String> specializationCourseIds = {};
    for (final s in specializations) {
      if (s.name == lecturer.specialization) {
        specializationCourseIds = await _specializationMappingRepository.getCourseIdsForSpecialization(s.id);
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      _lecturer = lecturer;
      // Every course can be picked for assignment, including ones the
      // lecturer already teaches — that's how a second class/section is
      // created for the same course, even for the same cohort. Only a
      // genuine schedule clash (same course, same cohort, overlapping day
      // and time) is blocked, in _assign().
      _availableCourses = allCourses;
      _cohortModels = cohorts;
      _creditsByCourseId = {for (final c in allCourses) c.id: c.credits};
      _courseById = {for (final c in allCourses) c.id: c};
      _specializationCourseIds = specializationCourseIds;
      _assignedSchedules = assignedSchedules;
      // Keep the admin's current Year/Cohort selection across a reload
      // (e.g. right after assigning a class) instead of resetting it, so
      // they can keep adding classes to the same cohort in one sitting.
      final years = _allYears;
      if (_selectedYear == null || !years.contains(_selectedYear)) {
        final currentYear = DateTime.now().year;
        _selectedYear = years.contains(currentYear) ? currentYear : (years.isEmpty ? null : years.last);
      }
      final cohortNames = _selectedYear == null ? const <String>[] : _cohortNamesForYear(_selectedYear!);
      if (_selectedCohort == null || !cohortNames.contains(_selectedCohort)) {
        _selectedCohort = cohortNames.isEmpty ? null : cohortNames.first;
      }
      _selectedCourseId = null;
      _selectedToUnassign.clear();
      _isLoading = false;
    });
  }

  Map<String, int> get _cohortYearByName => {for (final c in _cohortModels) c.name: c.year};

  /// Every year with at least one cohort in the system — the source for the
  /// Year dropdown at the top of the page (not limited to years this
  /// lecturer already teaches in, since the admin needs to be able to pick
  /// any cohort to assign a first class into).
  List<int> get _allYears {
    final years = _cohortModels.map((c) => c.year).toSet().toList();
    years.sort();
    return years;
  }

  List<String> _cohortNamesForYear(int year) {
    final names = _cohortModels.where((c) => c.year == year).map((c) => c.name).toList();
    return names;
  }

  void _onYearChanged(int year) {
    setState(() {
      _selectedYear = year;
      final names = _cohortNamesForYear(year);
      _selectedCohort = names.isEmpty ? null : names.first;
    });
  }

  /// Per-cohort workload breakdown (class count + total credits), for
  /// cohorts in [_selectedYear] only — real teaching load computed from
  /// this lecturer's actual class sections, since the same course can now
  /// be assigned to them more than once (different cohorts and/or times).
  List<({String cohort, int classCount, int credits})> get _cohortWorkloads {
    final creditsByCohort = <String, int>{};
    final countByCohort = <String, int>{};
    for (final s in _assignedSchedules) {
      final cohort = s.cohort;
      if (cohort == null) continue;
      if (_selectedYear != null && _cohortYearByName[cohort] != _selectedYear) continue;
      final credits = _creditsByCourseId[s.courseId] ?? 0;
      creditsByCohort[cohort] = (creditsByCohort[cohort] ?? 0) + credits;
      countByCohort[cohort] = (countByCohort[cohort] ?? 0) + 1;
    }
    final names = creditsByCohort.keys.toList()..sort();
    return [for (final name in names) (cohort: name, classCount: countByCohort[name]!, credits: creditsByCohort[name]!)];
  }

  /// The lecturer's real total workload across every cohort/section (not
  /// just [_workloadYear]) — `lecturers.credits_used` is course-deduped (one
  /// row per (lecturer, course) regardless of how many cohorts/sections),
  /// so it can no longer be trusted as "credits used" now that a course may
  /// be assigned to the same lecturer more than once.
  int get _realCreditsUsed => _assignedSchedules.fold(0, (sum, s) => sum + (_creditsByCourseId[s.courseId] ?? 0));

  List<AdminCourse> get _filteredAvailable {
    if (_query.isEmpty) return _availableCourses;
    return _availableCourses.where((c) =>
        c.courseCode.toLowerCase().contains(_query) || c.courseTitle.toLowerCase().contains(_query)).toList();
  }

  int get _assignCredits =>
      _availableCourses.where((c) => c.id == _selectedCourseId).fold(0, (sum, c) => sum + c.credits);

  /// Unassigning is per section now, so this is just the sum of credits for
  /// the specific sections selected to unassign.
  int get _unassignCredits => _assignedSchedules
      .where((s) => _selectedToUnassign.contains(s.id))
      .fold(0, (sum, s) => sum + (_creditsByCourseId[s.courseId] ?? 0));

  /// Credits already used within [_selectedCohort] specifically —
  /// `credits_max` is a per-cohort cap, not a global one, so a lecturer at
  /// capacity in one cohort/term can still take on a full load in another.
  int get _selectedCohortCreditsUsed {
    if (_selectedCohort == null) return 0;
    return _assignedSchedules
        .where((s) => s.cohort == _selectedCohort)
        .fold(0, (sum, s) => sum + (_creditsByCourseId[s.courseId] ?? 0));
  }

  /// Of the sections selected to unassign, the credits that belong to
  /// [_selectedCohort] specifically — only those reduce *this* cohort's load.
  int get _selectedCohortUnassignCredits {
    if (_selectedCohort == null) return 0;
    return _assignedSchedules
        .where((s) => s.cohort == _selectedCohort && _selectedToUnassign.contains(s.id))
        .fold(0, (sum, s) => sum + (_creditsByCourseId[s.courseId] ?? 0));
  }

  int get _projectedCohortCreditsUsed => _selectedCohortCreditsUsed + _assignCredits - _selectedCohortUnassignCredits;

  bool get _overCapacity =>
      _lecturer != null && _selectedCohort != null && _projectedCohortCreditsUsed > _lecturer!.creditsMax;

  bool get _timeRangeValid => _startTime != null && _endTime != null && _toMinutes(_endTime!) > _toMinutes(_startTime!);

  bool get _canAssign =>
      _selectedCourseId != null &&
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

  /// Parses a Postgres `time` value (`"09:00:00"` or `"09:00"`) into minutes
  /// since midnight, for comparison against [_toMinutes].
  int? _parseMinutes(String? hms) {
    if (hms == null || hms.length < 5) return null;
    final hour = int.tryParse(hms.substring(0, 2));
    final minute = int.tryParse(hms.substring(3, 5));
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  String _trimSeconds(String hms) => hms.length >= 5 ? hms.substring(0, 5) : hms;

  /// The lecturer's existing classes for [courseId] and [cohort] whose
  /// day/time overlaps [dayOfWeek] + [start]–[end] — a genuine schedule
  /// clash. Same course/cohort at a non-overlapping time is allowed.
  List<LecturerClassSlot> _clashingSlots({
    required String courseId,
    required String cohort,
    required String dayOfWeek,
    required TimeOfDay start,
    required TimeOfDay end,
  }) {
    final startMin = _toMinutes(start);
    final endMin = _toMinutes(end);
    return _assignedSchedules.where((slot) {
      if (slot.courseId != courseId || slot.cohort != cohort || slot.dayOfWeek != dayOfWeek) return false;
      final slotStart = _parseMinutes(slot.startTime);
      final slotEnd = _parseMinutes(slot.endTime);
      if (slotStart == null || slotEnd == null) return false;
      return startMin < slotEnd && slotStart < endMin;
    }).toList();
  }

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
    final courses = _availableCourses.where((c) => c.id == _selectedCourseId).toList();

    // Same course + same cohort is fine as long as the day/time doesn't
    // overlap an existing class of this lecturer's — only a genuine
    // schedule clash is blocked.
    final clashes = <String>[];
    for (final course in courses) {
      final slots = _clashingSlots(
        courseId: course.id,
        cohort: _selectedCohort!,
        dayOfWeek: _dayOfWeek!,
        start: _startTime!,
        end: _endTime!,
      );
      for (final slot in slots) {
        clashes.add('${course.courseCode} (${slot.sectionCode} • ${slot.dayOfWeek} ${_trimSeconds(slot.startTime!)}–${_trimSeconds(slot.endTime!)})');
      }
    }
    if (clashes.isNotEmpty) {
      setState(() {
        _assignErrorMessage = '${_lecturer!.name} already has an overlapping class at that day/time: ${clashes.join(', ')}. '
            'Pick a different day or time to add another class for the same course and cohort.';
      });
      return;
    }

    setState(() {
      _isAssigning = true;
      _assignErrorMessage = null;
    });
    try {
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
      await _lecturersRepository.assignCoursesToLecturer(widget.lecturerId, [_selectedCourseId!]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${courses.length} course${courses.length == 1 ? '' : 's'} assigned to ${_lecturer!.name}.')),
      );
      _dayOfWeek = null;
      _startTime = null;
      _endTime = null;
      _deliveryMode = 'physical';
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
      for (final sectionId in _selectedToUnassign) {
        await _lecturersRepository.unassignSection(sectionId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count class${count == 1 ? '' : 'es'} unassigned from ${_lecturer!.name}.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unassign classes: $e'), backgroundColor: AdminColors.error),
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
                      _buildYearCohortCard(),
                      const SizedBox(height: 20),
                      if (_assignedSchedules.isNotEmpty) ...[
                        _buildWorkloadByCohortCard(),
                        const SizedBox(height: 20),
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

  Widget _buildYearCohortCard() {
    final years = _allYears;
    final cohortNames = _selectedYear == null ? const <String>[] : _cohortNamesForYear(_selectedYear!);
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
          Text('1. Select Year & Cohort', style: AdminTypography.titleSm()),
          const SizedBox(height: 2),
          Text(
            'Choose which cohort to assign a class into before picking courses. Credit capacity is checked per cohort.',
            style: AdminTypography.bodySm(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 160,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminFieldLabel('Year'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: years.contains(_selectedYear) ? _selectedYear : null,
                      isExpanded: true,
                      style: AdminTypography.bodyMd(color: AdminColors.onSurface),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: AdminColors.surfaceContainerLow,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      hint: Text('Select year', style: AdminTypography.bodySm(color: AdminColors.outline)),
                      items: [for (final y in years) DropdownMenuItem(value: y, child: Text('$y'))],
                      onChanged: (y) {
                        if (y != null) _onYearChanged(y);
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminFieldLabel('Cohort'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: cohortNames.contains(_selectedCohort) ? _selectedCohort : null,
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
                      items: [for (final c in cohortNames) DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))],
                      onChanged: (c) => setState(() => _selectedCohort = c),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
            children: _selectedCohort == null
                ? [
                    Text('$_realCreditsUsed Credits Used (All Cohorts)', style: AdminTypography.titleMd()),
                    const SizedBox(height: 2),
                    Text(
                      'Cap is ${l.creditsMax} credits per cohort — select a cohort below to check its capacity.',
                      style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant),
                      textAlign: TextAlign.end,
                    ),
                  ]
                : [
                    Text(
                      '$_projectedCohortCreditsUsed / ${l.creditsMax} Credits',
                      style: AdminTypography.titleMd(color: _overCapacity ? AdminColors.error : AdminColors.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedCohort!,
                      style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant),
                    ),
                    Text(
                      _selectedCourseId == null && _selectedToUnassign.isEmpty
                          ? 'Currently used: $_selectedCohortCreditsUsed'
                          : '$_selectedCohortCreditsUsed used'
                              '${_assignCredits > 0 ? ' + $_assignCredits selected' : ''}'
                              '${_selectedCohortUnassignCredits > 0 ? ' − $_selectedCohortUnassignCredits unassigning' : ''}',
                      style: AdminTypography.labelSm(color: _overCapacity ? AdminColors.error : AdminColors.onSurfaceVariant),
                    ),
                    if (_overCapacity) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Exceeds this cohort\'s capacity by ${_projectedCohortCreditsUsed - l.creditsMax}',
                        style: AdminTypography.labelSm(color: AdminColors.error).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkloadByCohortCard() {
    final workloads = _cohortWorkloads;
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
            children: [
              Expanded(child: Text('Workload by Cohort', style: AdminTypography.titleSm())),
              if (_selectedYear != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AdminColors.surfaceContainer, borderRadius: BorderRadius.circular(9999)),
                  child: Text('$_selectedYear', style: AdminTypography.labelSm()),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Real teaching load per cohort — the ${_lecturer?.creditsMax ?? '—'}-credit cap applies separately to each cohort, '
            'so being at capacity in one cohort doesn\'t block a full load in another.',
            style: AdminTypography.bodySm(),
          ),
          const SizedBox(height: 12),
          if (workloads.isEmpty)
            Text('No classes for this year.', style: AdminTypography.bodySm(color: AdminColors.onSurfaceVariant))
          else
            Column(children: [for (final w in workloads) _workloadRow(w)]),
        ],
      ),
    );
  }

  Widget _workloadRow(({String cohort, int classCount, int credits}) w) {
    final creditsMax = _lecturer?.creditsMax;
    final atCapacity = creditsMax != null && w.credits >= creditsMax;
    final isSelected = w.cohort == _selectedCohort;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: isSelected ? AdminColors.primaryContainer.withValues(alpha: 0.08) : null,
        border: const Border(bottom: BorderSide(color: AdminColors.surfaceContainer)),
      ),
      child: Row(
        children: [
          if (isSelected) ...[
            const Icon(Icons.arrow_right, size: 16, color: AdminColors.primary),
            const SizedBox(width: 2),
          ],
          Expanded(
            child: Text(
              w.cohort,
              style: AdminTypography.bodyMd(color: AdminColors.onSurface).copyWith(fontWeight: isSelected ? FontWeight.w700 : null),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text('${w.classCount} class${w.classCount == 1 ? '' : 'es'}', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: atCapacity ? AdminColors.errorContainer : AdminColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              creditsMax == null ? '${w.credits} cr' : '${w.credits} / $creditsMax cr',
              style: AdminTypography.labelSm(color: atCapacity ? AdminColors.onErrorContainer : AdminColors.onSurface)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedCard() {
    final schedules = _assignedSchedulesForSelectedCohort;
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
              child: Text(
                'Currently Assigned in ${_selectedCohort ?? 'this cohort'} (${schedules.length})',
                style: AdminTypography.titleSm(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Each class is unassigned individually by its class code — unassigning one class leaves the lecturer\'s '
              'other classes for the same course (different cohort or section) untouched.',
              style: AdminTypography.bodySm(),
            ),
          ),
          if (schedules.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text('No classes assigned in this cohort yet.', style: AdminTypography.bodySm(color: AdminColors.onSurfaceVariant)),
            )
          else
            Column(children: [for (final s in schedules) _assignedRow(s)]),
        ],
      ),
    );
  }

  /// The lecturer's classes for [_selectedCohort] only — the "Currently
  /// Assigned" list is scoped to the cohort picked at the top of the page,
  /// so it doesn't clutter the screen with every cohort's classes at once.
  List<LecturerClassSlot> get _assignedSchedulesForSelectedCohort {
    final filtered = _assignedSchedules.where((s) => s.cohort == _selectedCohort).toList();
    filtered.sort((a, b) => a.sectionCode.compareTo(b.sectionCode));
    return filtered;
  }

  Widget _assignedRow(LecturerClassSlot s) {
    final selected = _selectedToUnassign.contains(s.id);
    final course = _courseById[s.courseId];
    final credits = _creditsByCourseId[s.courseId] ?? 0;
    final timeLabel = s.dayOfWeek == null || s.startTime == null || s.endTime == null
        ? 'Schedule TBD'
        : '${s.dayOfWeek} ${_trimSeconds(s.startTime!)}–${_trimSeconds(s.endTime!)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AdminColors.surfaceContainer))),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: (v) => setState(() => v == true ? _selectedToUnassign.add(s.id) : _selectedToUnassign.remove(s.id)),
            activeColor: AdminColors.error,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(
                      course == null ? s.courseId : '${course.courseCode} • ${course.courseTitle}',
                      style: AdminTypography.titleSm(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AdminColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(4)),
                    child: Text(s.sectionCode, style: AdminTypography.labelSm(color: AdminColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
                  ),
                ]),
                Text('${s.cohort ?? 'No cohort'} • $timeLabel', style: AdminTypography.labelSm()),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(9999)),
            child: Text('$credits cr', style: AdminTypography.labelSm(color: AdminColors.onSurface)),
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
                ? 'Select classes above to unassign.'
                : '${_selectedToUnassign.length} class${_selectedToUnassign.length == 1 ? '' : 'es'} selected to unassign • $_unassignCredits credits',
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
              child: Text('No courses found.', style: AdminTypography.bodyMd()),
            )
          else
            Column(children: [for (final c in courses) _courseRow(c)]),
        ],
      ),
    );
  }

  Widget _courseRow(AdminCourse c) {
    final specializationMismatch = !_specializationCourseIds.contains(c.id);
    final existingSlots = _assignedSchedules.where((s) => s.courseId == c.id).toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AdminColors.surfaceContainer))),
      child: Row(
        children: [
          Radio<String>(
            value: c.id,
            groupValue: _selectedCourseId,
            onChanged: (v) => setState(() => _selectedCourseId = v),
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
          if (existingSlots.isNotEmpty) ...[
            Tooltip(
              message: 'Already assigned to this lecturer:\n'
                  '${existingSlots.map((s) => '${s.cohort ?? '—'} • ${s.dayOfWeek ?? '—'} ${s.startTime == null ? '' : _trimSeconds(s.startTime!)}–${s.endTime == null ? '' : _trimSeconds(s.endTime!)}').join('\n')}\n'
                  'Selecting it again is fine as long as the new class is a different cohort or a non-overlapping time.',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(9999)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.info_outline, size: 13, color: AdminColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'Already teaching (${existingSlots.length})',
                    style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (specializationMismatch) ...[
            Tooltip(
              message: "Not related to lecturer's specialization",
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFFFF3CD), borderRadius: BorderRadius.circular(9999)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.warning_amber_rounded, size: 13, color: Color(0xFF8A6D00)),
                  const SizedBox(width: 4),
                  Text('Not specialization', style: AdminTypography.labelSm(color: const Color(0xFF8A6D00))),
                ]),
              ),
            ),
            const SizedBox(width: 8),
          ],
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
            ],
          ),
          const SizedBox(height: 10),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.groups_outlined, size: 14, color: AdminColors.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              _selectedCohort == null ? 'No cohort selected above' : 'Assigning into: $_selectedCohort',
              style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant),
            ),
          ]),
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
            _selectedCohort == null
                ? 'Select a year and cohort at the top of the page.'
                : _selectedCourseId == null
                    ? 'Select a course to assign.'
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
                                        : '1 course selected • $_assignCredits credits',
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
