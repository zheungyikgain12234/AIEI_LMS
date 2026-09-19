import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/core/utils/error_messages.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_badges_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_students_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_courses_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/badge_award.dart';
import 'widgets/admin_field_label.dart';

// ---------------------------------------------------------------------------
// BadgeAwardFormScreen — shared "Add Badge Award" / "Edit Badge Award" form
// for the Manage Badges screen. Pass `awardId` to edit an existing row;
// omit it to award a new badge. Saving pops back with the created/updated
// BadgeAward so the list can refresh.
// ---------------------------------------------------------------------------
class BadgeAwardFormScreen extends StatefulWidget {
  final BadgeAward? award;

  const BadgeAwardFormScreen({super.key, this.award});

  bool get isEditing => award != null;

  @override
  State<BadgeAwardFormScreen> createState() => _BadgeAwardFormScreenState();
}

class _BadgeAwardFormScreenState extends State<BadgeAwardFormScreen> {
  final _repository = SupabaseAdminBadgesRepositoryImpl(Supabase.instance.client);
  final _studentsRepository = SupabaseAdminStudentsRepositoryImpl(Supabase.instance.client);
  final _coursesRepository = SupabaseAdminCoursesRepositoryImpl(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();

  List<(String, String)> _students = [];
  List<(String, String)> _courses = [];
  List<(String, String)> _badges = [];
  String? _selectedStudentId;
  String? _selectedCourseId;
  String? _selectedBadgeId;
  DateTime? _issueDate;
  bool _isRevoked = false;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final students = await _studentsRepository.getStudents();
      final courses = await _coursesRepository.getCourses();
      final badges = await _repository.getBadgeCatalog();
      if (!mounted) return;
      final award = widget.award;
      setState(() {
        _students = [for (final s in students) (s.id, '${s.name} • ${s.studentCode}')];
        _courses = [for (final c in courses) (c.id, '${c.courseCode} • ${c.courseTitle}')];
        _badges = [for (final b in badges) (b.$1, '${b.$2} • ${b.$3}')];
        if (award != null) {
          _selectedStudentId = award.studentId;
          _selectedCourseId = award.courseId;
          _selectedBadgeId = award.badgeId;
          _issueDate = award.issueDate;
          _isRevoked = award.isRevoked;
        }
        _issueDate ??= DateTime.now();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null || _selectedCourseId == null || _selectedBadgeId == null) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final BadgeAward saved;
      if (widget.isEditing) {
        saved = await _repository.updateBadgeAward(
          widget.award!.id,
          studentId: _selectedStudentId!,
          courseId: _selectedCourseId!,
          badgeId: _selectedBadgeId!,
          issueDate: _issueDate!,
          isRevoked: _isRevoked,
        );
      } else {
        saved = await _repository.createBadgeAward(
          studentId: _selectedStudentId!,
          courseId: _selectedCourseId!,
          badgeId: _selectedBadgeId!,
          issueDate: _issueDate!,
          isRevoked: _isRevoked,
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
    final title = widget.isEditing ? 'Edit Badge Award' : 'Add Badge Award';
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
                                ? 'Update this badge award.'
                                : 'Award a badge to a student for a specific course.',
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
                          _dropdown(
                            label: 'Student',
                            hint: 'Select a student',
                            value: _selectedStudentId,
                            options: _students,
                            onChanged: (v) => setState(() => _selectedStudentId = v),
                          ),
                          const SizedBox(height: 14),
                          _dropdown(
                            label: 'Course',
                            hint: 'Select a course',
                            value: _selectedCourseId,
                            options: _courses,
                            onChanged: (v) => setState(() => _selectedCourseId = v),
                          ),
                          const SizedBox(height: 14),
                          _dropdown(
                            label: 'Badge',
                            hint: 'Select a badge',
                            value: _selectedBadgeId,
                            options: _badges,
                            onChanged: (v) => setState(() => _selectedBadgeId = v),
                          ),
                          const SizedBox(height: 14),
                          _datePicker(
                            label: 'Issue Date',
                            value: _issueDate,
                            onChanged: (v) => setState(() => _issueDate = v),
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: () => setState(() => _isRevoked = !_isRevoked),
                            borderRadius: BorderRadius.circular(10),
                            child: Row(
                              children: [
                                Checkbox(value: _isRevoked, onChanged: (v) => setState(() => _isRevoked = v ?? false), activeColor: AdminColors.error),
                                Text('Revoked', style: AdminTypography.bodyMd(color: AdminColors.onSurface)),
                              ],
                            ),
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
                                  onPressed: _isSaving
                                      ? null
                                      : (_selectedStudentId == null || _selectedCourseId == null || _selectedBadgeId == null)
                                          ? null
                                          : _save,
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
                                      : Text(widget.isEditing ? 'Save Changes' : 'Award Badge'),
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

  Widget _dropdown({
    required String label,
    required String hint,
    required String? value,
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
          hint: Text(hint, style: AdminTypography.bodySm(color: AdminColors.outline)),
          items: [for (final o in options) DropdownMenuItem(value: o.$1, child: Text(o.$2, overflow: TextOverflow.ellipsis))],
          onChanged: onChanged,
          validator: (v) => v == null || v.isEmpty ? '$label is required' : null,
        ),
      ],
    );
  }
}
