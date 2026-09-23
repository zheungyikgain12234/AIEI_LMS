import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/session/app_session.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/core/utils/error_messages.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_badge_catalog_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_course_tags_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_courses_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/admin_course.dart';
import 'package:stitch_aiei_lms/domain/models/badge_catalog_item.dart';
import 'package:stitch_aiei_lms/domain/models/course_tag_option.dart';
import 'widgets/admin_field_label.dart';

// ---------------------------------------------------------------------------
// CourseFormScreen — shared "Add New Course" / "Edit Course" form. Pass
// `courseId` to edit an existing row (prefilled from the database by its
// primary key); omit it to create a new course. Saving pops back to the
// caller with the created/updated AdminCourse so the catalogue can refresh.
// ---------------------------------------------------------------------------
class CourseFormScreen extends ConsumerStatefulWidget {
  final String? courseId;

  const CourseFormScreen({super.key, this.courseId});

  bool get isEditing => courseId != null;

  @override
  ConsumerState<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends ConsumerState<CourseFormScreen> {
  final _repository = SupabaseAdminCoursesRepositoryImpl(Supabase.instance.client);
  final _tagsRepository = SupabaseAdminCourseTagsRepositoryImpl(Supabase.instance.client);
  final _badgesRepository = SupabaseAdminBadgeCatalogRepositoryImpl(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();

  final _courseCodeController = TextEditingController();
  final _courseTitleController = TextEditingController();
  final _courseDescriptionController = TextEditingController();
  final _creditsController = TextEditingController(text: '3');

  static const _categoryOptions = [
    ('techData', 'Technical & Data'),
    ('compliance', 'Compliance'),
    ('aiTools', 'AI & Tools'),
    ('productivity', 'Productivity & Soft Skills'),
  ];
  String _category = 'techData';

  List<CourseTagOption> _availableTags = [];
  List<BadgeCatalogItem> _availableBadges = [];
  final Set<String> _selectedTagIds = {};
  final Set<String> _selectedBadgeIds = {};

  String? _bannerImageUrl;
  bool _uploadingBanner = false;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  /// Every code is stored tenant-prefixed (`TN01-PY-402`) to keep it unique
  /// across tenants, but the admin only ever types/sees the suffix.
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
      final tags = await _tagsRepository.getTags();
      final badges = await _badgesRepository.getBadges();
      AdminCourse? course;
      if (widget.isEditing) {
        course = await _repository.getCourseById(widget.courseId!);
      }
      if (!mounted) return;
      setState(() {
        _availableTags = tags;
        _availableBadges = badges;
        if (course != null) {
          _courseCodeController.text = _stripTenantPrefix(course.courseCode);
          _courseTitleController.text = course.courseTitle;
          _courseDescriptionController.text = course.courseDescription;
          _creditsController.text = course.credits.toString();
          _bannerImageUrl = course.imageUrl;
          _category = _categoryOptions.any((c) => c.$1 == course!.category) ? course.category : 'techData';
          _selectedTagIds
            ..clear()
            ..addAll(course.tagIds);
          _selectedBadgeIds
            ..clear()
            ..addAll(course.badgeIds);
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load course: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _courseCodeController.dispose();
    _courseTitleController.dispose();
    _courseDescriptionController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadBanner() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final Uint8List? bytes = file.bytes;
    if (bytes == null) return;
    setState(() => _uploadingBanner = true);
    try {
      final url = await _repository.uploadCourseBanner(fileName: file.name, bytes: bytes);
      if (!mounted) return;
      setState(() {
        _bannerImageUrl = url;
        _uploadingBanner = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Banner upload failed: $e';
        _uploadingBanner = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTagIds.isEmpty) {
      setState(() => _errorMessage = 'Select at least one Course Tag.');
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final credits = int.parse(_creditsController.text.trim());
      final AdminCourse saved;
      if (widget.isEditing) {
        saved = await _repository.updateCourse(
          widget.courseId!,
          courseCode: '${_tenantPrefix()}${_courseCodeController.text.trim().toUpperCase()}',
          courseTitle: _courseTitleController.text.trim(),
          courseDescription: _courseDescriptionController.text.trim(),
          category: _category,
          imageUrl: _bannerImageUrl,
          credits: credits,
          tagIds: _selectedTagIds.toList(),
          badgeIds: _selectedBadgeIds.toList(),
        );
      } else {
        saved = await _repository.createCourse(
          courseCode: '${_tenantPrefix()}${_courseCodeController.text.trim().toUpperCase()}',
          courseTitle: _courseTitleController.text.trim(),
          courseDescription: _courseDescriptionController.text.trim(),
          category: _category,
          imageUrl: _bannerImageUrl,
          credits: credits,
          tagIds: _selectedTagIds.toList(),
          badgeIds: _selectedBadgeIds.toList(),
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
    final title = widget.isEditing ? 'Edit Course' : 'Add New Course';
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
                                ? 'Update this course\'s catalogue information.'
                                : 'Add a new course to the institutional catalogue. Lecturer and section assignment can be done afterward.',
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
                          _bannerField(),
                          const SizedBox(height: 14),
                          _field(controller: _courseCodeController, label: 'Course Code', hint: 'PY-402'),
                          const SizedBox(height: 14),
                          _field(controller: _courseTitleController, label: 'Course Title', hint: 'Python for Enterprise Data Analysis'),
                          const SizedBox(height: 14),
                          _field(controller: _courseDescriptionController, label: 'Description', hint: 'What this course covers...', maxLines: 4),
                          const SizedBox(height: 14),
                          _dropdown(
                            label: 'Category',
                            value: _category,
                            options: _categoryOptions,
                            onChanged: (v) => setState(() => _category = v!),
                          ),
                          const SizedBox(height: 14),
                          _field(
                            controller: _creditsController,
                            label: 'Credits',
                            hint: '3',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final trimmed = value?.trim() ?? '';
                              if (trimmed.isEmpty) return 'Credits is required';
                              final parsed = int.tryParse(trimmed);
                              if (parsed == null || parsed <= 0) return 'Enter a positive whole number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _multiSelect(
                            label: 'Course Tags',
                            required: true,
                            hint: 'Select at least one tag',
                            options: [for (final t in _availableTags) (id: t.id, label: t.label)],
                            selectedIds: _selectedTagIds,
                          ),
                          const SizedBox(height: 14),
                          _multiSelect(
                            label: 'Badges Awarded on Completion',
                            required: false,
                            hint: 'Select badges students unlock (optional)',
                            options: [for (final b in _availableBadges) (id: b.id, label: b.title)],
                            selectedIds: _selectedBadgeIds,
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
                                      : Text(widget.isEditing ? 'Save Changes' : 'Add Course'),
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

  Widget _bannerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminFieldLabel('Course Banner Image', required: false),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 140,
            width: double.infinity,
            color: AdminColors.surfaceContainerLow,
            child: _bannerImageUrl == null || _bannerImageUrl!.isEmpty
                ? const Center(child: Icon(Icons.image_outlined, size: 36, color: AdminColors.outline))
                : Image.network(
                    _bannerImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.broken_image_outlined, size: 36, color: AdminColors.outline)),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _uploadingBanner ? null : _pickAndUploadBanner,
              icon: _uploadingBanner
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload_outlined, size: 16),
              label: Text(_bannerImageUrl == null || _bannerImageUrl!.isEmpty ? 'Upload Banner Image' : 'Replace Banner Image'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AdminColors.primary,
                backgroundColor: AdminColors.surfaceContainer,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            if (_bannerImageUrl != null && _bannerImageUrl!.isNotEmpty) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: _uploadingBanner ? null : () => setState(() => _bannerImageUrl = null),
                child: const Text('Remove'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _multiSelect({
    required String label,
    required bool required,
    required String hint,
    required List<({String id, String label})> options,
    required Set<String> selectedIds,
  }) {
    final selectedOptions = options.where((o) => selectedIds.contains(o.id)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFieldLabel(label, required: required),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _openMultiSelectPicker(label: label, options: options, selectedIds: selectedIds),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
            child: selectedOptions.isEmpty
                ? Row(
                    children: [
                      Expanded(child: Text(hint, style: AdminTypography.bodySm(color: AdminColors.outline))),
                      const Icon(Icons.expand_more, size: 18, color: AdminColors.onSurfaceVariant),
                    ],
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final o in selectedOptions)
                        Chip(
                          label: Text(o.label, style: AdminTypography.labelSm(color: AdminColors.onSurface)),
                          backgroundColor: AdminColors.surfaceContainer,
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => setState(() => selectedIds.remove(o.id)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _openMultiSelectPicker({
    required String label,
    required List<({String id, String label})> options,
    required Set<String> selectedIds,
  }) async {
    final searchController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final query = searchController.text.trim().toLowerCase();
          final filtered = query.isEmpty ? options : options.where((o) => o.label.toLowerCase().contains(query)).toList();
          return AlertDialog(
            title: Text('Select $label'),
            content: SizedBox(
              width: 400,
              height: 420,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 18), hintText: 'Search...', isDense: true),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(child: Text('No matches.', style: AdminTypography.bodySm()))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final option = filtered[index];
                              final checked = selectedIds.contains(option.id);
                              return CheckboxListTile(
                                value: checked,
                                dense: true,
                                controlAffinity: ListTileControlAffinity.leading,
                                title: Text(option.label),
                                onChanged: (v) => setDialogState(() {
                                  setState(() => v == true ? selectedIds.add(option.id) : selectedIds.remove(option.id));
                                }),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Done')),
            ],
          );
        },
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool required = true,
    int maxLines = 1,
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
          maxLines: maxLines,
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
          items: [for (final o in options) DropdownMenuItem(value: o.$1, child: Text(o.$2, overflow: TextOverflow.ellipsis))],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
