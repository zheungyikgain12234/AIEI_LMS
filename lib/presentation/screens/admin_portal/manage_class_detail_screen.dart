import 'package:stitch_aiei_lms/core/utils/date_format.dart';
import 'package:stitch_aiei_lms/core/utils/input_formatters.dart';
import 'package:stitch_aiei_lms/core/utils/busy_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stitch_aiei_lms/core/utils/app_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/core/utils/error_messages.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturers_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_students_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_master_data_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/course_section.dart';
import 'package:stitch_aiei_lms/domain/models/roster_student.dart';

import 'widgets/admin_no_results.dart';
import 'widgets/admin_date_time_field.dart';
import 'widgets/admin_field_error.dart';
import 'widgets/admin_fixed_code.dart';
import 'widgets/admin_field_label.dart';
import 'widgets/searchable_dropdown.dart';

// ---------------------------------------------------------------------------
// ManageClassDetailScreen — "Manage" detail/edit page for a single class
// section, reached from the Manage Classes table by its primary key
// (`sectionId`). Lets the admin view/edit the class's date, schedule,
// capacity, delivery mode, cohort, and status, and lists every student
// currently enrolled in this section with an unchecked box each — tick the
// students to remove and press the red "Unenroll Selected" button (after a
// confirmation dialog they are unenrolled in one go).
// ---------------------------------------------------------------------------
enum _RosterSort { code, name }

class ManageClassDetailScreen extends StatefulWidget {
  final String sectionId;

  const ManageClassDetailScreen({super.key, required this.sectionId});

  @override
  State<ManageClassDetailScreen> createState() =>
      _ManageClassDetailScreenState();
}

class _ManageClassDetailScreenState extends State<ManageClassDetailScreen> {
  final _lecturersRepository = SupabaseLecturersRepositoryImpl(
    Supabase.instance.client,
  );
  final _studentsRepository = SupabaseAdminStudentsRepositoryImpl(
    Supabase.instance.client,
  );
  final _masterDataRepository = SupabaseAdminMasterDataRepositoryImpl(
    Supabase.instance.client,
  );
  final _locationController = TextEditingController();
  final _capacityController = TextEditingController();
  final _overrideCodeController = TextEditingController();
  DateTime? _editStartAt;
  DateTime? _editEndAt;

  static const _dayOptions = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _deliveryModeOptions = [
    ('physical', 'Physical'),
    ('online', 'Online'),
  ];
  static const _statusOptions = [
    ('scheduled', 'Scheduled'),
    ('in_progress', 'In Progress'),
    ('completed', 'Completed'),
    ('cancelled', 'Cancelled'),
  ];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  final Map<String, String> _fieldErrors = {};
  CourseSection? _section;
  List<RosterStudent> _roster = [];
  List<String> _cohorts = [];
  final Set<String> _unenrolling = {};
  final Set<String> _selected = {};
  final _rosterSearchController = TextEditingController();
  final _rosterSearchFocus = FocusNode();
  String _rosterQuery = '';
  _RosterSort _rosterSort = _RosterSort.name;
  bool _rosterAscending = true;

  DateTime? _startDate;
  DateTime? _endDate;
  String? _dayOfWeek;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _deliveryMode = 'physical';
  String? _selectedCohort;
  String _status = 'scheduled';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _capacityController.dispose();
    _overrideCodeController.dispose();
    _rosterSearchController.dispose();
    _rosterSearchFocus.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final section = await _lecturersRepository.getSectionById(
        widget.sectionId,
      );
      final roster = await _studentsRepository.getSectionRoster(
        widget.sectionId,
      );
      final cohorts = await _masterDataRepository.getCohorts();
      if (!mounted) return;
      setState(() {
        _section = section;
        _roster = roster;
        _cohorts = [for (final c in cohorts) c.name];
        _startDate = section.startDate;
        _endDate = section.endDate;
        _dayOfWeek = section.dayOfWeek;
        _startTime = _parseTime(section.startTime);
        _endTime = _parseTime(section.endTime);
        // An online class has no location, so nothing is pre-filled for it.
        _locationController.text = section.deliveryMode == 'online' ? '' : (section.location ?? '');
        _capacityController.text = section.capacity.toString();
        _editStartAt = section.editStartAt;
        _editEndAt = section.editEndAt;
        _overrideCodeController.text = section.editOverrideLecturerCode ?? '';
        _deliveryMode = section.deliveryMode;
        _selectedCohort = _cohorts.contains(section.cohort)
            ? section.cohort
            : null;
        _status = section.status;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load class: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null)
      setState(() => isStart ? _startDate = picked : _endDate = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          (isStart ? _startTime : _endTime) ??
          const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() => isStart ? _startTime = picked : _endTime = picked);
    }
  }

  Future<void> _save() async {
    // Every field marked with a red asterisk is compulsory. Each problem is
    // reported in a red box directly beneath its own field.
    final errors = <String, String>{};
    if (_startDate == null) errors['startDate'] = 'Start Date is required.';
    if (_endDate == null) errors['endDate'] = 'End Date is required.';
    if (_startDate != null && _endDate != null && !_endDate!.isAfter(_startDate!)) {
      errors['endDate'] = 'End Date must be after Start Date.';
    }
    if (_dayOfWeek == null) errors['dayOfWeek'] = 'Day of Week is required.';
    if (_startTime == null) errors['startTime'] = 'Start Time is required.';
    if (_endTime == null) errors['endTime'] = 'End Time is required.';
    if (_startTime != null &&
        _endTime != null &&
        _endTime!.hour * 60 + _endTime!.minute <= _startTime!.hour * 60 + _startTime!.minute) {
      errors['endTime'] = 'End Time must be after Start Time.';
    }
    if (_deliveryMode != 'online' && _locationController.text.trim().isEmpty) {
      errors['location'] = 'Location is required.';
    }
    final capacity = int.tryParse(_capacityController.text.trim());
    if (capacity == null || capacity <= 0) {
      errors['capacity'] = 'Capacity must be a positive number.';
    } else if (capacity > maxClassCapacity) {
      errors['capacity'] = 'Capacity cannot exceed $maxClassCapacity.';
    }
    if (_editStartAt == null || _editEndAt == null) {
      errors['editPeriod'] = 'Set a syllabus edit period — both start and end are required.';
    } else if (!_editEndAt!.isAfter(_editStartAt!)) {
      errors['editPeriod'] = 'Edit end must be after edit start.';
    }
    if (errors.isNotEmpty) {
      setState(() {
        _fieldErrors
          ..clear()
          ..addAll(errors);
        _errorMessage = null;
      });
      return;
    }
    _fieldErrors.clear();
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final saved = await _lecturersRepository.updateSection(
        widget.sectionId,
        startDate: _startDate,
        endDate: _endDate,
        dayOfWeek: _dayOfWeek,
        startTime: _startTime == null ? null : _formatTime(_startTime!),
        endTime: _endTime == null ? null : _formatTime(_endTime!),
        location: _deliveryMode == 'online' || _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        capacity: capacity!,
        deliveryMode: _deliveryMode,
        cohort: _selectedCohort!,
        status: _status,
        editStartAt: _editStartAt!,
        editEndAt: _editEndAt!,
        editOverrideLecturerCode: _overrideCodeController.text,
      );
      if (!mounted) return;
      setState(() {
        _section = saved;
        _isSaving = false;
      });
      showSuccessSnackBar(context, 'Class updated.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e is StateError ? e.message : friendlyErrorMessage(e);
        _isSaving = false;
      });
    }
  }

  Future<void> _unenrollSelected() async {
    final targets = _roster
        .where((r) => _selected.contains(r.studentId))
        .toList();
    if (targets.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unenroll students?'),
        content: Text(
          targets.length == 1
              ? 'Unenroll ${targets.first.name} from this class?'
              : 'Unenroll ${targets.length} selected students from this class?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', textAlign: TextAlign.center),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unenroll', textAlign: TextAlign.center),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final courseId = _section!.courseId;
    setState(() => _unenrolling.addAll(targets.map((t) => t.studentId)));
    final removed = <String>{};
    Object? failure;
    await runWithBusy(context, 'Unenrolling students…', () async {
      for (final s in targets) {
        try {
          await _studentsRepository.unenrollStudentFromCourse(
            s.studentId,
            courseId,
            sectionId: widget.sectionId,
          );
          removed.add(s.studentId);
        } catch (e) {
          failure = e;
        }
      }
    });
    if (!mounted) return;
    setState(() {
      _roster.removeWhere((r) => removed.contains(r.studentId));
      _selected.removeAll(removed);
      _unenrolling.clear();
      final s = _section!;
      _section = CourseSection(
        id: s.id,
        courseId: s.courseId,
        courseCode: s.courseCode,
        courseTitle: s.courseTitle,
        sectionCode: s.sectionCode,
        roleLabel: s.roleLabel,
        term: s.term,
        scheduleText: s.scheduleText,
        dayOfWeek: s.dayOfWeek,
        startTime: s.startTime,
        endTime: s.endTime,
        location: s.location,
        lecturerId: s.lecturerId,
        lecturerName: s.lecturerName,
        capacity: s.capacity,
        deliveryMode: s.deliveryMode,
        cohortId: s.cohortId,
        cohort: s.cohort,
        cohortCode: s.cohortCode,
        cohortYear: s.cohortYear,
        enrolledCount: _roster.length,
        status: s.status,
        startDate: s.startDate,
        endDate: s.endDate,
        editStartAt: s.editStartAt,
        editEndAt: s.editEndAt,
        editOverrideLecturerCode: s.editOverrideLecturerCode,
        syllabusStatus: s.syllabusStatus,
      );
    });
    if (removed.isNotEmpty) {
      showSuccessSnackBar(
        context,
        removed.length == 1
            ? 'Unenrolled successfully.'
            : 'Unenrolled ${removed.length} students successfully.',
      );
    }
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unenroll some students: $failure'),
          backgroundColor: AdminColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final section = _section;
    // Only students still visible after a search can stay selected.
    final visibleIds = {for (final r in _visibleRoster) r.studentId};
    _selected.retainWhere(visibleIds.contains);
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: AdminColors.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AdminColors.onSurface,
        title: Text(
          section == null ? 'Manage Class' : 'Manage ${section.sectionCode}',
          style: AdminTypography.headlineSm(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : section == null
          ? Center(
              child: Text(
                _errorMessage ?? 'Class not found.',
                style: AdminTypography.bodyMd(),
              ),
            )
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _infoCard(section),
                      const SizedBox(height: 16),
                      _editCard(),
                      const SizedBox(height: 16),
                      _rosterCard(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _codeLabel(String label, String value) => Text.rich(
        TextSpan(children: [
          TextSpan(text: '$label: ', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant)),
          TextSpan(text: value, style: AdminTypography.labelMd(color: AdminColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _infoCard(CourseSection section) {
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
          Text(section.courseTitle, style: AdminTypography.titleMd()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 20,
            runSpacing: 4,
            children: [
              _codeLabel('Course Code', section.courseCode),
              _codeLabel('Class Code', section.sectionCode),
              _codeLabel('Cohort Code', section.cohortCode ?? '—'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            section.lecturerName == null
                ? 'Unassigned lecturer'
                : 'Taught by ${section.lecturerName}',
            style: AdminTypography.bodySm(color: AdminColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// Appends the red validation box for [key] directly beneath [field].
  Widget _err(String key, Widget field) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [field, AdminFieldError(_fieldErrors[key])]);

  Widget _editCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Class Information', style: AdminTypography.titleSm()),
          const SizedBox(height: 14),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminColors.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: AdminTypography.bodySm(
                  color: AdminColors.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Expanded(
                child: _err('startDate', _dateField(
                  label: 'Start Date',
                  value: _startDate,
                  onTap: () => _pickDate(isStart: true),
                )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _err('endDate', _dateField(
                  label: 'End Date',
                  value: _endDate,
                  onTap: () => _pickDate(isStart: false),
                )),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _err('dayOfWeek', _dropdown(
            label: 'Day of Week',
            hint: 'Select a day',
            value: _dayOfWeek,
            options: _dayOptions,
            onChanged: (v) => setState(() => _dayOfWeek = v),
          )),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _err('startTime', _timeField(
                  label: 'Start Time',
                  value: _startTime,
                  onTap: () => _pickTime(isStart: true),
                )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _err('endTime', _timeField(
                  label: 'End Time',
                  value: _endTime,
                  onTap: () => _pickTime(isStart: false),
                )),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _labeledDropdown(
            label: 'Delivery Mode',
            value: _deliveryMode,
            options: _deliveryModeOptions,
            onChanged: (v) => setState(() {
              _deliveryMode = v!;
              _locationController.clear();
            }),
          ),
          if (_deliveryMode != 'online') ...[
            const SizedBox(height: 14),
            _err('location', _textField(
              label: 'Location',
              controller: _locationController,
              hint: 'Innovation Hall 204',
            )),
          ],
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Text('Syllabus Edit Period *', style: AdminTypography.titleSm()),
          const SizedBox(height: 2),
          Text(
            'The lecturer can add, edit and delete sessions and contents only between these two moments. Outside it their syllabus is read-only.',
            style: AdminTypography.bodySm(),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AdminDateTimeField(
                  label: 'Edit Start',
                  value: _editStartAt,
                  onChanged: (v) => setState(() => _editStartAt = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminDateTimeField(
                  label: 'Edit End',
                  value: _editEndAt,
                  defaultHour: 23,
                  onChanged: (v) => setState(() => _editEndAt = v),
                ),
              ),
            ],
          ),
          AdminFieldError(_fieldErrors['editPeriod']),
          const SizedBox(height: 14),
          _textField(
            label: 'Edit Override — Lecturer Code (optional)',
            controller: _overrideCodeController,
            hint: 'e.g. LEC-0042',
            required: false,
          ),
          const SizedBox(height: 4),
          Text(
            'Type a lecturer\'s unique code to let that lecturer edit this syllabus at any time, inside or outside the period. Leave blank for none.',
            style: AdminTypography.bodySm(),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _err('capacity', _textField(
                  label: 'Capacity',
                  controller: _capacityController,
                  hint: '50',
                  keyboardType: TextInputType.number,
                  inputFormatters: digitsOnly,
                )),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // A class's cohort is fixed once created: its enrolled students and the
          // lecturer's per-cohort credit load both depend on it.
          AdminFixedCode(label: 'Cohort', value: _selectedCohort ?? '—'),
          _labeledDropdown(
            label: 'Status',
            value: _status,
            options: _statusOptions,
            onChanged: (v) => setState(() => _status = v!),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.primaryContainer,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rosterCard() {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Enrolled Students (${_roster.length})',
                        style: AdminTypography.titleSm(),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _selected.isEmpty || _unenrolling.isNotEmpty
                          ? null
                          : _unenrollSelected,
                      icon: const Icon(Icons.person_remove_outlined, size: 18),
                      label: Text(
                        _selected.isEmpty
                            ? 'Unenroll Selected'
                            : 'Unenroll Selected (${_selected.length})', textAlign: TextAlign.center),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.error,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AdminColors.error.withValues(
                          alpha: 0.35,
                        ),
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Tick students, then click Unenroll Selected.',
                  style: AdminTypography.bodySm(
                    color: AdminColors.onSurfaceVariant,
                  ).copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          if (_roster.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: TextField(
                controller: _rosterSearchController,
                focusNode: _rosterSearchFocus,
                onChanged: (v) =>
                    setState(() => _rosterQuery = v.trim().toLowerCase()),
                style: AdminTypography.bodySm(color: AdminColors.onSurface),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AdminColors.surfaceContainerLow,
                  hintText: 'Search by student code or name...',
                  hintStyle: AdminTypography.bodySm(color: AdminColors.hint).copyWith(fontStyle: FontStyle.italic),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: AdminColors.onSurfaceVariant,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AdminColors.surfaceContainer),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    flex: 2,
                    child: _rosterSortHeader('Code', _RosterSort.code),
                  ),
                  Expanded(
                    flex: 4,
                    child: _rosterSortHeader('Name', _RosterSort.name),
                  ),
                ],
              ),
            ),
          ],
          if (_roster.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No students enrolled in this class.',
                style: AdminTypography.bodyMd(),
              ),
            )
          else if (_visibleRoster.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: AdminNoResults(
                controller: _rosterSearchController,
                focusNode: _rosterSearchFocus,
              ),
            )
          else
            Column(children: [for (final s in _visibleRoster) _rosterRow(s)]),
        ],
      ),
    );
  }

  List<RosterStudent> get _visibleRoster {
    final filtered = _rosterQuery.isEmpty
        ? [..._roster]
        : _roster
              .where(
                (s) =>
                    s.name.toLowerCase().contains(_rosterQuery) ||
                    s.studentCode.toLowerCase().contains(_rosterQuery),
              )
              .toList();
    filtered.sort((a, b) {
      final cmp = _rosterSort == _RosterSort.code
          ? a.studentCode.toLowerCase().compareTo(b.studentCode.toLowerCase())
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return _rosterAscending ? cmp : -cmp;
    });
    return filtered;
  }

  Widget _rosterSortHeader(String label, _RosterSort column) {
    final active = _rosterSort == column;
    return InkWell(
      onTap: () => setState(() {
        if (active) {
          _rosterAscending = !_rosterAscending;
        } else {
          _rosterSort = column;
          _rosterAscending = true;
        }
      }),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AdminTypography.labelSm(
              color: active
                  ? AdminColors.onSurface
                  : AdminColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            active && !_rosterAscending
                ? Icons.arrow_downward
                : Icons.arrow_upward,
            size: 12,
            color: active ? AdminColors.onSurface : AdminColors.outline,
          ),
        ],
      ),
    );
  }

  Widget _rosterRow(RosterStudent s) {
    final busy = _unenrolling.contains(s.studentId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AdminColors.surfaceContainer)),
      ),
      child: Row(
        children: [
          busy
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: Padding(
                    padding: EdgeInsets.all(2),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Checkbox(
                  value: _selected.contains(s.studentId),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selected.add(s.studentId);
                    } else {
                      _selected.remove(s.studentId);
                    }
                  }),
                  activeColor: AdminColors.primaryContainer,
                ),
          Expanded(
            flex: 2,
            child: Text(
              s.studentCode,
              style: AdminTypography.labelSm(),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              s.name,
              style: AdminTypography.titleSm(),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFieldLabel(label, required: required),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: AdminTypography.bodyMd(color: AdminColors.onSurface),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AdminColors.surfaceContainerLow,
            hintText: hint,
            hintStyle: AdminTypography.bodySm(color: AdminColors.hint).copyWith(fontStyle: FontStyle.italic),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFieldLabel(label),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: InputDecorator(
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AdminColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              suffixIcon: const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AdminColors.onSurfaceVariant,
              ),
            ),
            child: Text(
              value == null
                  ? 'Select a date'
                  : formatDate(value),
              style: AdminTypography.bodyMd(
                color: value == null
                    ? AdminColors.outline
                    : AdminColors.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _timeField({
    required String label,
    required TimeOfDay? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFieldLabel(label),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: InputDecorator(
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AdminColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              suffixIcon: const Icon(
                Icons.access_time,
                size: 18,
                color: AdminColors.onSurfaceVariant,
              ),
            ),
            child: Text(
              value == null ? 'Select a time' : _formatTime(value),
              style: AdminTypography.bodyMd(
                color: value == null
                    ? AdminColors.outline
                    : AdminColors.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFieldLabel(label),
        const SizedBox(height: 6),
        SearchableDropdownFormField<String>(
          initialValue: value,
          isExpanded: true,
          style: AdminTypography.bodyMd(color: AdminColors.onSurface),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AdminColors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          hint: Text(
            hint,
            style: AdminTypography.bodySm(color: AdminColors.outline),
          ),
          items: [
            for (final o in options)
              DropdownMenuItem(
                value: o,
                child: Text(o, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _labeledDropdown({
    required String label,
    required String value,
    required List<(String, String)> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFieldLabel(label),
        const SizedBox(height: 6),
        SearchableDropdownFormField<String>(
          initialValue: value,
          isExpanded: true,
          style: AdminTypography.bodyMd(color: AdminColors.onSurface),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AdminColors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          items: [
            for (final o in options)
              DropdownMenuItem(value: o.$1, child: Text(o.$2)),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
