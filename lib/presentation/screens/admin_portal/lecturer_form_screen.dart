import 'package:stitch_aiei_lms/core/utils/date_format.dart';
import 'package:stitch_aiei_lms/core/utils/input_formatters.dart';
import 'package:stitch_aiei_lms/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/presentation/widgets/skeleton.dart';

import 'widgets/admin_fixed_code.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/session/app_session.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/core/utils/error_messages.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturers_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_master_data_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/lecturer.dart';

import 'widgets/admin_field_error.dart';
import 'widgets/admin_field_label.dart';
import 'widgets/admin_form_dialog.dart';
import 'widgets/searchable_dropdown.dart';

// ---------------------------------------------------------------------------
// LecturerFormScreen — shared "Add New Lecturer" / "Edit Lecturer" form.
// Pass `lecturerId` to edit an existing row (prefilled from the database by
// its primary key); omit it to onboard a new lecturer. Saving pops back to
// the caller with the created/updated Lecturer so the directory can refresh.
// ---------------------------------------------------------------------------
class LecturerFormScreen extends ConsumerStatefulWidget {
  final String? lecturerId;

  const LecturerFormScreen({super.key, this.lecturerId});

  bool get isEditing => lecturerId != null;

  @override
  ConsumerState<LecturerFormScreen> createState() => _LecturerFormScreenState();
}

class _LecturerFormScreenState extends ConsumerState<LecturerFormScreen> {
  final _repository = SupabaseLecturersRepositoryImpl(Supabase.instance.client);
  final _masterDataRepository = SupabaseAdminMasterDataRepositoryImpl(
    Supabase.instance.client,
  );
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _lecturerCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _creditsMaxController = TextEditingController(text: '15');

  static const _statusOptions = ['Active', 'Contract', 'Sabbatical'];
  String _status = 'Active';
  bool _accredited = false;

  List<String> _departments = [];
  List<String> _specializations = [];
  String? _selectedDepartment;
  final Set<String> _selectedCompetencies = {};
  String? _competenciesError;
  DateTime? _joinDate;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? get _codeConflict =>
      _errorMessage == codeConflictMessage ? _errorMessage : null;

  /// Every code is stored tenant-prefixed (`TN01-EMP-7721`) to keep it
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
      final departments = await _masterDataRepository.getLecturerDepartments();
      final specializations = await _masterDataRepository.getSpecializations();
      Lecturer? lecturer;
      if (widget.isEditing) {
        lecturer = await _repository.getLecturerById(widget.lecturerId!);
      }
      if (!mounted) return;
      setState(() {
        _departments = [for (final d in departments) d.name];
        _specializations = [for (final s in specializations) s.name]
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        if (lecturer != null) {
          _nameController.text = lecturer.name;
          _titleController.text = lecturer.title;
          _lecturerCodeController.text = _stripTenantPrefix(
            lecturer.lecturerCode,
          );
          _emailController.text = lecturer.email;
          _creditsMaxController.text = lecturer.creditsMax.toString();
          _status = _statusOptions.contains(lecturer.status)
              ? lecturer.status
              : 'Active';
          _accredited = lecturer.accredited;
          _selectedDepartment = _departments.contains(lecturer.department)
              ? lecturer.department
              : null;
          _selectedCompetencies.addAll(
            lecturer.competencies.where(_specializations.contains),
          );
          _joinDate = lecturer.joinDate;
        }
        _joinDate ??= DateTime.now();
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
    _lecturerCodeController.dispose();
    _emailController.dispose();
    _creditsMaxController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    if (_selectedCompetencies.isEmpty) {
      setState(
        () => _competenciesError = 'Select at least one teaching competency',
      );
      return;
    }
    if (!valid) return;
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
          lecturerCode:
              '${_tenantPrefix()}${_lecturerCodeController.text.trim().toUpperCase()}',
          email: _emailController.text.trim(),
          department: _selectedDepartment!,
          competencies: _selectedCompetencies.toList(),
          creditsMax: creditsMax,
          status: _status,
          accredited: _accredited,
          joinDate: _joinDate!,
        );
      } else {
        saved = await _repository.createLecturer(
          name: _nameController.text.trim(),
          title: _titleController.text.trim(),
          lecturerCode:
              '${_tenantPrefix()}${_lecturerCodeController.text.trim().toUpperCase()}',
          email: _emailController.text.trim(),
          department: _selectedDepartment!,
          competencies: _selectedCompetencies.toList(),
          creditsMax: creditsMax,
          status: _status,
          accredited: _accredited,
          joinDate: _joinDate!,
        );
      }
      if (!mounted) return;
      showSuccessSnackBar(
        context,
        widget.isEditing ? 'Lecturer updated.' : 'Lecturer created.',
      );
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
    final title = widget.isEditing ? 'Edit Lecturer' : 'Add New Lecturer';
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: AdminColors.navSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AdminColors.onSurface,
        title: Text(title, style: AdminTypography.headlineSm()),
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const SkeletonBody()
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
                        boxShadow: const [
                          BoxShadow(color: Color(0x0D000000), blurRadius: 6),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              widget.isEditing
                                  ? 'Update this lecturer\'s directory information.'
                                  : 'Onboard a new lecturer.',
                              style: AdminTypography.bodyMd(),
                            ),
                            const SizedBox(height: 20),
                            if (_errorMessage != null &&
                                !isFieldConflictMessage(_errorMessage!)) ...[
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
                              const SizedBox(height: 16),
                            ],
                            if (widget.isEditing)
                              AdminFixedCode(
                                label: 'Lecturer Code',
                                value: _lecturerCodeController.text
                                    .trim()
                                    .toUpperCase(),
                              ),
                            _field(
                              controller: _nameController,
                              label: 'Full Name',
                              hint: 'Dr. Sarah Lin',
                            ),
                            const SizedBox(height: 14),
                            _field(
                              controller: _titleController,
                              label: 'Title',
                              hint: 'Lead Data Architect',
                            ),
                            const SizedBox(height: 14),
                            if (!widget.isEditing) ...[
                              _field(
                                controller: _lecturerCodeController,
                                label: 'Lecturer Code',
                                hint: 'EMP-7721',
                                inputFormatters: const [
                                  UpperCaseTextFormatter(),
                                ],
                              ),
                              AdminFieldError(_codeConflict),
                              const SizedBox(height: 14),
                            ],
                            _field(
                              controller: _emailController,
                              label: 'Email',
                              hint: 'sarah.lin@aiei.edu',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),
                            _dropdown(
                              label: 'Department',
                              hint: 'Select a department',
                              value: _selectedDepartment,
                              options: _departments,
                              onChanged: (v) =>
                                  setState(() => _selectedDepartment = v),
                              required: true,
                            ),
                            const SizedBox(height: 14),
                            _competenciesField(),
                            const SizedBox(height: 14),
                            _field(
                              controller: _creditsMaxController,
                              label: 'Credits Max',
                              hint: '15',
                              keyboardType: TextInputType.number,
                              inputFormatters: digitsOnly,
                              validator: (value) {
                                final trimmed = value?.trim() ?? '';
                                if (trimmed.isEmpty)
                                  return 'Credits Max is required';
                                final parsed = int.tryParse(trimmed);
                                if (parsed == null || parsed < 0)
                                  return 'Enter a valid whole number';
                                if (parsed > maxLecturerCredits)
                                  return 'Credits Max cannot exceed $maxLecturerCredits';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _dropdown(
                              label: 'Status',
                              value: _status,
                              options: _statusOptions,
                              onChanged: (v) => setState(() => _status = v!),
                              required: true,
                            ),
                            const SizedBox(height: 14),
                            _datePicker(
                              label: 'Join Date',
                              value: _joinDate,
                              onChanged: (v) => setState(() => _joinDate = v),
                            ),
                            const SizedBox(height: 14),
                            _checkbox(
                              label: 'Accredited',
                              value: _accredited,
                              onChanged: (v) => setState(() => _accredited = v),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isSaving
                                        ? null
                                        : () => Navigator.of(context).pop(),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor:
                                          AdminColors.primaryContainer,
                                      side: BorderSide.none,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : _save,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AdminColors.primaryContainer,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
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
                                        : Text(
                                            widget.isEditing
                                                ? 'Save Changes'
                                                : 'Add Lecturer',
                                          ),
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
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    String? prefixText,
    bool required = true,
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
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          enabled: !readOnly,
          style: AdminTypography.bodyMd(color: AdminColors.onSurface),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            prefixText: prefixText,
            prefixStyle: AdminTypography.bodyMd(
              color: AdminColors.onSurfaceVariant,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          validator:
              validator ??
              (required
                  ? (value) => (value == null || value.trim().isEmpty)
                        ? '$label is required'
                        : null
                  : null),
        ),
      ],
    );
  }

  /// A lecturer can have several teaching competencies: chips for the chosen
  /// ones, tap to open the picker.
  Widget _competenciesField() {
    final selected = _specializations
        .where(_selectedCompetencies.contains)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminFieldLabel('Teaching Competencies', required: true),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _openCompetenciesPicker,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AdminColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: selected.isEmpty
                ? Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select teaching competencies',
                          style: AdminTypography.bodySm(
                            color: AdminColors.outline,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.expand_more,
                        size: 18,
                        color: AdminColors.onSurfaceVariant,
                      ),
                    ],
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final name in selected)
                        Chip(
                          label: Text(
                            name,
                            style: AdminTypography.labelSm(
                              color: AdminColors.onSurface,
                            ),
                          ),
                          backgroundColor: AdminColors.surfaceContainer,
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => setState(
                            () => _selectedCompetencies.remove(name),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
          ),
        ),
        AdminFieldError(_competenciesError),
      ],
    );
  }

  Future<void> _openCompetenciesPicker() async {
    final searchController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final query = searchController.text.trim().toLowerCase();
          final filtered = query.isEmpty
              ? _specializations
              : _specializations
                    .where((o) => o.toLowerCase().contains(query))
                    .toList();
          return AdminFormDialog(
            title: 'Select Teaching Competencies',
            maxWidth: 480,
            showCancel: false,
            submitChild: const Text('Done'),
            onSubmit: () => Navigator.of(ctx).pop(),
            child: SizedBox(
              height: 380,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    onChanged: (_) => setDialogState(() {}),
                    style: AdminTypography.bodyMd(color: AdminColors.onSurface),
                    decoration: adminFormDecoration(
                      hint: 'Search...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No matches.',
                              style: AdminTypography.bodySm(),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final name = filtered[index];
                              return CheckboxListTile(
                                value: _selectedCompetencies.contains(name),
                                dense: true,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(name),
                                onChanged: (v) => setDialogState(() {
                                  setState(() {
                                    v == true
                                        ? _selectedCompetencies.add(name)
                                        : _selectedCompetencies.remove(name);
                                    _competenciesError = null;
                                  });
                                }),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    searchController.dispose();
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
        AdminFieldLabel(label, required: required),
        const SizedBox(height: 6),
        SearchableDropdownFormField<String>(
          initialValue: value,
          isExpanded: true,
          style: AdminTypography.bodyMd(color: AdminColors.onSurface),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          hint: hint == null
              ? null
              : Text(
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
          validator: required
              ? (v) => v == null || v.isEmpty ? '$label is required' : null
              : null,
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                errorText: state.errorText,
                suffixIcon: const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: AdminColors.onSurfaceVariant,
                ),
              ),
              child: Text(
                value == null ? 'Select a date' : formatDate(value),
                style: AdminTypography.bodyMd(
                  color: value == null
                      ? AdminColors.outline
                      : AdminColors.onSurface,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _checkbox({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: AdminColors.primaryContainer,
            ),
            Text(
              label,
              style: AdminTypography.bodyMd(color: AdminColors.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
