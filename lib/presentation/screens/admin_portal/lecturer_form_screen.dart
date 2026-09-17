import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturers_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_master_data_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/lecturer.dart';

// ---------------------------------------------------------------------------
// LecturerFormScreen — shared "Add New Lecturer" / "Edit Lecturer" form.
// Pass `lecturerId` to edit an existing row (prefilled from the database by
// its primary key); omit it to onboard a new lecturer. Saving pops back to
// the caller with the created/updated Lecturer so the directory can refresh.
// ---------------------------------------------------------------------------
class LecturerFormScreen extends StatefulWidget {
  final String? lecturerId;

  const LecturerFormScreen({super.key, this.lecturerId});

  bool get isEditing => lecturerId != null;

  @override
  State<LecturerFormScreen> createState() => _LecturerFormScreenState();
}

class _LecturerFormScreenState extends State<LecturerFormScreen> {
  final _repository = SupabaseLecturersRepositoryImpl(Supabase.instance.client);
  final _masterDataRepository = SupabaseAdminMasterDataRepositoryImpl(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _creditsMaxController = TextEditingController(text: '15');

  static const _statusOptions = ['Active', 'Contract', 'Sabbatical'];
  String _status = 'Active';
  bool _accredited = false;

  List<String> _departments = [];
  List<String> _specializations = [];
  String? _selectedDepartment;
  String? _selectedSpecialization;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final departments = await _masterDataRepository.getLecturerDepartments();
      final specializations = await _masterDataRepository.getSpecializations();
      Lecturer? lecturer;
      if (widget.isEditing) {
        lecturer = await _repository.getLecturerById(widget.lecturerId!);
      }
      if (!mounted) return;
      setState(() {
        _departments = [for (final d in departments) d.name];
        _specializations = [for (final s in specializations) s.name];
        if (lecturer != null) {
          _nameController.text = lecturer.name;
          _titleController.text = lecturer.title;
          _employeeIdController.text = lecturer.employeeId;
          _emailController.text = lecturer.email;
          _creditsMaxController.text = lecturer.creditsMax.toString();
          _status = _statusOptions.contains(lecturer.status) ? lecturer.status : 'Active';
          _accredited = lecturer.accredited;
          _selectedDepartment = _departments.contains(lecturer.department) ? lecturer.department : null;
          _selectedSpecialization = _specializations.contains(lecturer.specialization) ? lecturer.specialization : null;
        }
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
    _titleController.dispose();
    _employeeIdController.dispose();
    _emailController.dispose();
    _creditsMaxController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final creditsMax = int.parse(_creditsMaxController.text.trim());
      final Lecturer saved;
      if (widget.isEditing) {
        saved = await _repository.updateLecturer(
          widget.lecturerId!,
          name: _nameController.text.trim(),
          title: _titleController.text.trim(),
          employeeId: _employeeIdController.text.trim(),
          email: _emailController.text.trim(),
          department: _selectedDepartment!,
          specialization: _selectedSpecialization!,
          creditsMax: creditsMax,
          status: _status,
          accredited: _accredited,
        );
      } else {
        saved = await _repository.createLecturer(
          name: _nameController.text.trim(),
          title: _titleController.text.trim(),
          employeeId: _employeeIdController.text.trim(),
          email: _emailController.text.trim(),
          department: _selectedDepartment!,
          specialization: _selectedSpecialization!,
          creditsMax: creditsMax,
          status: _status,
          accredited: _accredited,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to save lecturer: $e';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Edit Lecturer' : 'Add New Lecturer';
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
                                ? 'Update this faculty member\'s directory information.'
                                : 'Onboard a new faculty member to the institutional roster.',
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
                          _field(controller: _nameController, label: 'Full Name', hint: 'Dr. Sarah Lin'),
                          const SizedBox(height: 14),
                          _field(controller: _titleController, label: 'Title', hint: 'Lead Data Architect'),
                          const SizedBox(height: 14),
                          _field(controller: _employeeIdController, label: 'Employee ID', hint: 'EMP-7721'),
                          const SizedBox(height: 14),
                          _field(controller: _emailController, label: 'Email', hint: 'sarah.lin@aiei.edu', keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 14),
                          _dropdown(
                            label: 'Department',
                            hint: 'Select a department',
                            value: _selectedDepartment,
                            options: _departments,
                            onChanged: (v) => setState(() => _selectedDepartment = v),
                            required: true,
                          ),
                          const SizedBox(height: 14),
                          _dropdown(
                            label: 'Specialization',
                            hint: 'Select a specialization',
                            value: _selectedSpecialization,
                            options: _specializations,
                            onChanged: (v) => setState(() => _selectedSpecialization = v),
                            required: true,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            controller: _creditsMaxController,
                            label: 'Credits Max',
                            hint: '15',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final trimmed = value?.trim() ?? '';
                              if (trimmed.isEmpty) return 'Credits Max is required';
                              final parsed = int.tryParse(trimmed);
                              if (parsed == null || parsed < 0) return 'Enter a valid whole number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _dropdown(
                            label: 'Status',
                            value: _status,
                            options: _statusOptions,
                            onChanged: (v) => setState(() => _status = v!),
                          ),
                          const SizedBox(height: 14),
                          _checkbox(label: 'Accredited', value: _accredited, onChanged: (v) => setState(() => _accredited = v)),
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
                                      : Text(widget.isEditing ? 'Save Changes' : 'Add Lecturer'),
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
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AdminTypography.labelMd(color: AdminColors.onSurfaceVariant)),
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
          validator: validator ?? (value) => (value == null || value.trim().isEmpty) ? '$label is required' : null,
        ),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    String? hint,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AdminTypography.labelMd(color: AdminColors.onSurfaceVariant)),
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
          hint: hint == null ? null : Text(hint, style: AdminTypography.bodySm(color: AdminColors.outline)),
          items: [for (final o in options) DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis))],
          onChanged: onChanged,
          validator: required ? (v) => v == null || v.isEmpty ? '$label is required' : null : null,
        ),
      ],
    );
  }

  Widget _checkbox({required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Checkbox(value: value, onChanged: (v) => onChanged(v ?? false), activeColor: AdminColors.primaryContainer),
            Text(label, style: AdminTypography.bodyMd(color: AdminColors.onSurface)),
          ],
        ),
      ),
    );
  }
}
