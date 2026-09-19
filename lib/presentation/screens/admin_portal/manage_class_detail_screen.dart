import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/core/utils/error_messages.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturers_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_students_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_master_data_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/course_section.dart';
import 'package:stitch_aiei_lms/domain/models/roster_student.dart';
import 'widgets/admin_field_label.dart';

// ---------------------------------------------------------------------------
// ManageClassDetailScreen — "Manage" detail/edit page for a single class
// section, reached from the Manage Classes table by its primary key
// (`sectionId`). Lets the admin view/edit the class's date, schedule,
// capacity, delivery mode, cohort, and status, and lists every student
// currently enrolled in this section with a pre-checked box each — unchecking
// one unenrolls that student immediately (same pattern as the student-side
// "Manage Enrolled Courses" screen, inverted to be class-centric).
// ---------------------------------------------------------------------------
class ManageClassDetailScreen extends StatefulWidget {
  final String sectionId;

  const ManageClassDetailScreen({super.key, required this.sectionId});

  @override
  State<ManageClassDetailScreen> createState() => _ManageClassDetailScreenState();
}

class _ManageClassDetailScreenState extends State<ManageClassDetailScreen> {
  final _lecturersRepository = SupabaseLecturersRepositoryImpl(Supabase.instance.client);
  final _studentsRepository = SupabaseAdminStudentsRepositoryImpl(Supabase.instance.client);
  final _masterDataRepository = SupabaseAdminMasterDataRepositoryImpl(Supabase.instance.client);
  final _locationController = TextEditingController();
  final _capacityController = TextEditingController();

  static const _dayOptions = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _deliveryModeOptions = [('physical', 'Physical'), ('online', 'Online')];
  static const _statusOptions = [
    ('scheduled', 'Scheduled'),
    ('in_progress', 'In Progress'),
    ('completed', 'Completed'),
    ('cancelled', 'Cancelled'),
  ];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  CourseSection? _section;
  List<RosterStudent> _roster = [];
  List<String> _cohorts = [];
  final Set<String> _unenrolling = {};

  DateTime? _startDate;
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
    super.dispose();
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final section = await _lecturersRepository.getSectionById(widget.sectionId);
      final roster = await _studentsRepository.getSectionRoster(widget.sectionId);
      final cohorts = await _masterDataRepository.getCohorts();
      if (!mounted) return;
      setState(() {
        _section = section;
        _roster = roster;
        _cohorts = [for (final c in cohorts) c.name];
        _startDate = section.startDate;
        _dayOfWeek = section.dayOfWeek;
        _startTime = _parseTime(section.startTime);
        _endTime = _parseTime(section.endTime);
        _locationController.text = section.location ?? '';
        _capacityController.text = section.capacity.toString();
        _deliveryMode = section.deliveryMode;
        _selectedCohort = _cohorts.contains(section.cohort) ? section.cohort : null;
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() => isStart ? _startTime = picked : _endTime = picked);
    }
  }

  Future<void> _save() async {
    final capacity = int.tryParse(_capacityController.text.trim());
    if (capacity == null || capacity <= 0) {
      setState(() => _errorMessage = 'Capacity must be a positive number.');
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final saved = await _lecturersRepository.updateSection(
        widget.sectionId,
        startDate: _startDate,
        dayOfWeek: _dayOfWeek,
        startTime: _startTime == null ? null : _formatTime(_startTime!),
        endTime: _endTime == null ? null : _formatTime(_endTime!),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        capacity: capacity,
        deliveryMode: _deliveryMode,
        cohort: _selectedCohort ?? _section!.cohort ?? '',
        status: _status,
      );
      if (!mounted) return;
      setState(() {
        _section = saved;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class updated.')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = friendlyErrorMessage(e);
        _isSaving = false;
      });
    }
  }

  Future<void> _unenroll(RosterStudent s) async {
    final courseId = _section!.courseId;
    setState(() => _unenrolling.add(s.studentId));
    try {
      await _studentsRepository.unenrollStudentFromCourse(s.studentId, courseId);
      if (!mounted) return;
      setState(() {
        _roster.removeWhere((r) => r.studentId == s.studentId);
        _unenrolling.remove(s.studentId);
        _section = CourseSection(
          id: _section!.id,
          courseId: _section!.courseId,
          courseCode: _section!.courseCode,
          courseTitle: _section!.courseTitle,
          sectionCode: _section!.sectionCode,
          roleLabel: _section!.roleLabel,
          term: _section!.term,
          scheduleText: _section!.scheduleText,
          dayOfWeek: _section!.dayOfWeek,
          startTime: _section!.startTime,
          endTime: _section!.endTime,
          location: _section!.location,
          lecturerId: _section!.lecturerId,
          lecturerName: _section!.lecturerName,
          capacity: _section!.capacity,
          deliveryMode: _section!.deliveryMode,
          cohortId: _section!.cohortId,
          cohort: _section!.cohort,
          cohortCode: _section!.cohortCode,
          cohortYear: _section!.cohortYear,
          enrolledCount: _roster.length,
          status: _section!.status,
          startDate: _section!.startDate,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unenrolled ${s.name}.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _unenrolling.remove(s.studentId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unenroll: $e'), backgroundColor: AdminColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final section = _section;
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: AdminColors.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AdminColors.onSurface,
        title: Text(section == null ? 'Manage Class' : 'Manage ${section.sectionCode}', style: AdminTypography.headlineSm()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : section == null
              ? Center(child: Text(_errorMessage ?? 'Class not found.', style: AdminTypography.bodyMd()))
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
          Text('${section.courseCode} • ${section.sectionCode}', style: AdminTypography.labelSm()),
          const SizedBox(height: 8),
          Text(
            section.lecturerName == null ? 'Unassigned lecturer' : 'Taught by ${section.lecturerName}',
            style: AdminTypography.bodySm(color: AdminColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

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
              decoration: BoxDecoration(color: AdminColors.errorContainer, borderRadius: BorderRadius.circular(8)),
              child: Text(_errorMessage!, style: AdminTypography.bodySm(color: AdminColors.onErrorContainer)),
            ),
            const SizedBox(height: 14),
          ],
          _dateField(label: 'Start Date', value: _startDate, onTap: _pickDate),
          const SizedBox(height: 14),
          _dropdown(
            label: 'Day of Week',
            hint: 'Select a day',
            value: _dayOfWeek,
            options: _dayOptions,
            onChanged: (v) => setState(() => _dayOfWeek = v),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _timeField(label: 'Start Time', value: _startTime, onTap: () => _pickTime(isStart: true))),
              const SizedBox(width: 12),
              Expanded(child: _timeField(label: 'End Time', value: _endTime, onTap: () => _pickTime(isStart: false))),
            ],
          ),
          const SizedBox(height: 14),
          _textField(label: 'Location', controller: _locationController, hint: 'Innovation Hall 204'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _textField(label: 'Capacity', controller: _capacityController, hint: '50', keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(
                child: _labeledDropdown(
                  label: 'Delivery Mode',
                  value: _deliveryMode,
                  options: _deliveryModeOptions,
                  onChanged: (v) => setState(() => _deliveryMode = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _dropdown(
            label: 'Cohort',
            hint: 'Select a cohort',
            value: _selectedCohort,
            options: _cohorts,
            onChanged: (v) => setState(() => _selectedCohort = v),
          ),
          const SizedBox(height: 14),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
                Text('Enrolled Students (${_roster.length})', style: AdminTypography.titleSm()),
                Text(
                  'Uncheck to unenroll.',
                  style: AdminTypography.bodySm(color: AdminColors.onSurfaceVariant).copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          if (_roster.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('No students enrolled in this class.', style: AdminTypography.bodyMd()),
            )
          else
            Column(children: [for (final s in _roster) _rosterRow(s)]),
        ],
      ),
    );
  }

  Widget _rosterRow(RosterStudent s) {
    final busy = _unenrolling.contains(s.studentId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AdminColors.surfaceContainer))),
      child: Row(
        children: [
          busy
              ? const SizedBox(width: 24, height: 24, child: Padding(padding: EdgeInsets.all(2), child: CircularProgressIndicator(strokeWidth: 2)))
              : Checkbox(
                  value: true,
                  onChanged: (v) {
                    if (v == false) _unenroll(s);
                  },
                  activeColor: AdminColors.primaryContainer,
                ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name, style: AdminTypography.titleSm()),
                Text(s.studentCode, style: AdminTypography.labelSm()),
              ],
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFieldLabel(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: AdminTypography.bodyMd(color: AdminColors.onSurface),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AdminColors.surfaceContainerLow,
            hintText: hint,
            hintStyle: AdminTypography.bodySm(color: AdminColors.outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _dateField({required String label, required DateTime? value, required VoidCallback onTap}) {
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: AdminColors.onSurfaceVariant),
            ),
            child: Text(
              value == null ? 'Select a date' : '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
              style: AdminTypography.bodyMd(color: value == null ? AdminColors.outline : AdminColors.onSurface),
            ),
          ),
        ),
      ],
    );
  }

  Widget _timeField({required String label, required TimeOfDay? value, required VoidCallback onTap}) {
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              suffixIcon: const Icon(Icons.access_time, size: 18, color: AdminColors.onSurfaceVariant),
            ),
            child: Text(
              value == null ? 'Select a time' : _formatTime(value),
              style: AdminTypography.bodyMd(color: value == null ? AdminColors.outline : AdminColors.onSurface),
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
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          style: AdminTypography.bodyMd(color: AdminColors.onSurface),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AdminColors.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          hint: Text(hint, style: AdminTypography.bodySm(color: AdminColors.outline)),
          items: [for (final o in options) DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis))],
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
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          style: AdminTypography.bodyMd(color: AdminColors.onSurface),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AdminColors.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          items: [for (final o in options) DropdownMenuItem(value: o.$1, child: Text(o.$2))],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
