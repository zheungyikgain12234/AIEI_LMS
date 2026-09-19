import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/session/app_session.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/core/utils/error_messages.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_students_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_master_data_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/student.dart';
import 'widgets/admin_field_label.dart';

// ---------------------------------------------------------------------------
// StudentFormScreen — shared "Register New Student" / "Edit Student" form.
// Pass `studentId` to edit an existing row (prefilled from the database by
// its primary key); omit it to register a new student. Saving pops back to
// the caller with the created/updated Student so the table can refresh.
//
// Department / Program Track / Cohort are selected from the admin-managed
// master data lists (Manage Departments / Manage Program Tracks / Manage
// Cohorts) rather than freely typed, so the values always satisfy the
// `students` table's foreign keys. GPA is not editable here — it defaults
// to 0 in the database and is updated elsewhere as the student progresses.
// ---------------------------------------------------------------------------
class StudentFormScreen extends ConsumerStatefulWidget {
  final String? studentId;

  const StudentFormScreen({super.key, this.studentId});

  bool get isEditing => studentId != null;

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _repository = SupabaseAdminStudentsRepositoryImpl(Supabase.instance.client);
  final _masterDataRepository = SupabaseAdminMasterDataRepositoryImpl(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _studentCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _titleController = TextEditingController();

  List<String> _departments = [];
  List<String> _programTracks = [];
  List<String> _cohorts = [];
  List<String> _roles = [];
  String? _selectedDepartment;
  String? _selectedProgramTrack;
  String? _selectedCohort;
  String? _selectedRole;
  DateTime? _registrationDate;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  /// Every code is stored tenant-prefixed (`TN01-EMP-88219`) to keep it
  /// unique across tenants, but the admin only ever types/sees the suffix.
  String _tenantPrefix() => '${ref.read(appSessionProvider).tenantId}-';

  String _stripTenantPrefix(String code) {
    final prefix = _tenantPrefix();
    return code.startsWith(prefix) ? code.substring(prefix.length) : code;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final departments = await _masterDataRepository.getDepartments();
      final programTracks = await _masterDataRepository.getProgramTracks();
      final cohorts = await _masterDataRepository.getCohorts();
      final roles = await _masterDataRepository.getRoles();
      Student? student;
      if (widget.isEditing) {
        student = await _repository.getStudentById(widget.studentId!);
      }
      if (!mounted) return;
      setState(() {
        _departments = [for (final d in departments) d.name];
        _programTracks = [for (final t in programTracks) t.name];
        _cohorts = [for (final c in cohorts) c.name];
        _roles = [for (final r in roles) r.name];
        if (student != null) {
          _nameController.text = student.name;
          _studentCodeController.text = _stripTenantPrefix(student.studentCode);
          _emailController.text = student.email;
          _titleController.text = student.title ?? '';
          _selectedDepartment = _departments.contains(student.department) ? student.department : null;
          _selectedProgramTrack = _programTracks.contains(student.programTrack) ? student.programTrack : null;
          _selectedCohort = _cohorts.contains(student.cohort) ? student.cohort : null;
          _selectedRole = _roles.contains(student.role) ? student.role : null;
          _registrationDate = student.registrationDate;
        }
        _registrationDate ??= DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load form: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentCodeController.dispose();
    _emailController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final title = _titleController.text.trim();
      final Student saved;
      if (widget.isEditing) {
        saved = await _repository.updateStudent(
          widget.studentId!,
          name: _nameController.text.trim(),
          studentCode: '${_tenantPrefix()}${_studentCodeController.text.trim().toUpperCase()}',
          email: _emailController.text.trim(),
          department: _selectedDepartment!,
          title: title.isEmpty ? null : title,
          programTrack: _selectedProgramTrack!,
          cohort: _selectedCohort!,
          role: _selectedRole!,
          registrationDate: _registrationDate!,
        );
      } else {
        saved = await _repository.createStudent(
          name: _nameController.text.trim(),
          studentCode: '${_tenantPrefix()}${_studentCodeController.text.trim().toUpperCase()}',
          email: _emailController.text.trim(),
          department: _selectedDepartment!,
          title: title.isEmpty ? null : title,
          programTrack: _selectedProgramTrack!,
          cohort: _selectedCohort!,
          role: _selectedRole!,
          registrationDate: _registrationDate!,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = friendlyErrorMessage(e);
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Edit Student' : 'Register New Student';
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: AdminColors.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AdminColors.onSurface,
        title: Text(title, style: AdminTypography.headlineSm()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AdminColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.isEditing
                                ? 'Update this learner\'s registry information.'
                                : 'Add a new learner to the institutional registry.',
                            style: AdminTypography.bodyMd(),
                          ),
                          const SizedBox(height: 20),
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AdminColors.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_errorMessage!, style: AdminTypography.bodySm(color: AdminColors.onErrorContainer)),
                            ),
                            const SizedBox(height: 16),
                          ],
                          _field(controller: _nameController, label: 'Full Name', hint: 'Alex Chen'),
                          const SizedBox(height: 14),
                          _field(controller: _studentCodeController, label: 'Student Code', hint: 'EMP-88219'),
                          const SizedBox(height: 14),
                          _field(controller: _emailController, label: 'Email', hint: 'alex.chen@enterprise.com', keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 14),
                          _dropdown(
                            label: 'Department',
                            hint: 'Select a department',
                            value: _selectedDepartment,
                            options: _departments,
                            onChanged: (v) => setState(() => _selectedDepartment = v),
                          ),
                          const SizedBox(height: 14),
                          _field(controller: _titleController, label: 'Title (optional)', hint: 'Product Analyst • Operations', required: false),
                          const SizedBox(height: 14),
                          _dropdown(
                            label: 'Program Track',
                            hint: 'Select a program track',
                            value: _selectedProgramTrack,
                            options: _programTracks,
                            onChanged: (v) => setState(() => _selectedProgramTrack = v),
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
                          _dropdown(
                            label: 'Role',
                            hint: 'Select a role',
                            value: _selectedRole,
                            options: _roles,
                            onChanged: (v) => setState(() => _selectedRole = v),
                          ),
                          const SizedBox(height: 14),
                          _datePicker(
                            label: 'Registration Date',
                            value: _registrationDate,
                            onChanged: (v) => setState(() => _registrationDate = v),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AdminColors.onSurface,
                                    backgroundColor: AdminColors.surfaceContainerLow,
                                    side: BorderSide.none,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AdminColors.primaryContainer,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : Text(widget.isEditing ? 'Save Changes' : 'Register Student'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool required = true,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFieldLabel(label, required: required),
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
            prefixText: prefixText,
            prefixStyle: AdminTypography.bodyMd(color: AdminColors.onSurfaceVariant),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          validator: validator ?? (required ? (value) => (value == null || value.trim().isEmpty) ? '$label is required' : null : null),
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
          validator: (v) => v == null || v.isEmpty ? '$label is required' : null,
        ),
      ],
    );
  }

  Widget _datePicker({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFieldLabel(label),
        const SizedBox(height: 6),
        FormField<DateTime>(
          initialValue: value,
          validator: (v) => v == null ? '$label is required' : null,
          builder: (state) => InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                onChanged(picked);
                state.didChange(picked);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AdminColors.surfaceContainerLow,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                errorText: state.errorText,
                suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: AdminColors.onSurfaceVariant),
              ),
              child: Text(
                value == null ? 'Select a date' : '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
                style: AdminTypography.bodyMd(color: value == null ? AdminColors.outline : AdminColors.onSurface),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
