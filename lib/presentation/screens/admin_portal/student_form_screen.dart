import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_students_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/student.dart';

// ---------------------------------------------------------------------------
// StudentFormScreen — shared "Register New Student" / "Edit Student" form.
// Pass `studentId` to edit an existing row (prefilled from the database by
// its primary key); omit it to register a new student. Saving pops back to
// the caller with the created/updated Student so the table can refresh.
// ---------------------------------------------------------------------------
class StudentFormScreen extends StatefulWidget {
  final String? studentId;

  const StudentFormScreen({super.key, this.studentId});

  bool get isEditing => studentId != null;

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _repository = SupabaseAdminStudentsRepositoryImpl(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  final _titleController = TextEditingController();
  final _programTrackController = TextEditingController();
  final _cohortController = TextEditingController();
  final _gpaController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final student = await _repository.getStudentById(widget.studentId!);
      if (!mounted) return;
      _nameController.text = student.name;
      _studentIdController.text = student.studentId;
      _emailController.text = student.email;
      _departmentController.text = student.department;
      _titleController.text = student.title ?? '';
      _programTrackController.text = student.programTrack;
      _cohortController.text = student.cohort;
      _gpaController.text = student.gpa.toString();
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load student: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _titleController.dispose();
    _programTrackController.dispose();
    _cohortController.dispose();
    _gpaController.dispose();
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
          studentId: _studentIdController.text.trim(),
          email: _emailController.text.trim(),
          department: _departmentController.text.trim(),
          title: title.isEmpty ? null : title,
          programTrack: _programTrackController.text.trim(),
          cohort: _cohortController.text.trim(),
          gpa: double.parse(_gpaController.text.trim()),
        );
      } else {
        saved = await _repository.createStudent(
          name: _nameController.text.trim(),
          studentId: _studentIdController.text.trim(),
          email: _emailController.text.trim(),
          department: _departmentController.text.trim(),
          title: title.isEmpty ? null : title,
          programTrack: _programTrackController.text.trim(),
          cohort: _cohortController.text.trim(),
          gpa: double.parse(_gpaController.text.trim()),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to save student: $e';
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
                          _field(controller: _studentIdController, label: 'Student ID', hint: 'EMP-88219'),
                          const SizedBox(height: 14),
                          _field(controller: _emailController, label: 'Email', hint: 'alex.chen@enterprise.com', keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 14),
                          _field(controller: _departmentController, label: 'Department', hint: 'Operations'),
                          const SizedBox(height: 14),
                          _field(controller: _titleController, label: 'Title (optional)', hint: 'Product Analyst • Operations', required: false),
                          const SizedBox(height: 14),
                          _field(controller: _programTrackController, label: 'Program Track', hint: 'Data Architecture Specialist'),
                          const SizedBox(height: 14),
                          _field(controller: _cohortController, label: 'Cohort', hint: 'Fall 2025 Cohort'),
                          const SizedBox(height: 14),
                          _field(
                            controller: _gpaController,
                            label: 'GPA',
                            hint: '3.76',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              final trimmed = value?.trim() ?? '';
                              if (trimmed.isEmpty) return 'GPA is required';
                              final parsed = double.tryParse(trimmed);
                              if (parsed == null) return 'Enter a valid number';
                              if (parsed < 0 || parsed > 4) return 'GPA must be between 0 and 4';
                              return null;
                            },
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
          validator: validator ?? (required ? (value) => (value == null || value.trim().isEmpty) ? '$label is required' : null : null),
        ),
      ],
    );
  }
}
