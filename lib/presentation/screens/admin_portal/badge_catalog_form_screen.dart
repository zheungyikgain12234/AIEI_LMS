import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/session/app_session.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/core/utils/error_messages.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_badge_catalog_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/badge_catalog_item.dart';
import 'widgets/admin_field_label.dart';

// ---------------------------------------------------------------------------
// BadgeCatalogFormScreen — shared "Add New Badge" / "Edit Badge" form for the
// Badges master data (`certifications` table). Pass `badgeId` to edit an
// existing row; omit it to create a new one.
// ---------------------------------------------------------------------------
class BadgeCatalogFormScreen extends ConsumerStatefulWidget {
  final String? badgeId;

  const BadgeCatalogFormScreen({super.key, this.badgeId});

  bool get isEditing => badgeId != null;

  @override
  ConsumerState<BadgeCatalogFormScreen> createState() => _BadgeCatalogFormScreenState();
}

class _BadgeCatalogFormScreenState extends ConsumerState<BadgeCatalogFormScreen> {
  final _repository = SupabaseAdminBadgeCatalogRepositoryImpl(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _issuingBodyController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  /// Every code is stored tenant-prefixed (`TN01-CERT-PYAUTO`) to keep it
  /// unique across tenants, but the admin only ever types/sees the suffix.
  String _tenantPrefix() => '${ref.read(appSessionProvider).tenantId}-';

  String _stripTenantPrefix(String code) {
    final prefix = _tenantPrefix();
    return code.startsWith(prefix) ? code.substring(prefix.length) : code;
  }

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final badge = await _repository.getBadgeById(widget.badgeId!);
      if (!mounted) return;
      _codeController.text = _stripTenantPrefix(badge.code);
      _titleController.text = badge.title;
      _descriptionController.text = badge.description;
      _issuingBodyController.text = badge.issuingBody;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load badge: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _issuingBodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final code = '${_tenantPrefix()}${_codeController.text.trim().toUpperCase()}';
      final BadgeCatalogItem saved;
      if (widget.isEditing) {
        saved = await _repository.updateBadge(
          widget.badgeId!,
          code: code,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          issuingBody: _issuingBodyController.text.trim(),
        );
      } else {
        saved = await _repository.createBadge(
          code: code,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          issuingBody: _issuingBodyController.text.trim(),
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
    final title = widget.isEditing ? 'Edit Badge' : 'Add New Badge';
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
                                ? 'Update this badge\'s catalog information.'
                                : 'Add a new badge to the catalog. Courses can then be configured to award it on completion.',
                            style: AdminTypography.bodyMd(),
                          ),
                          const SizedBox(height: 20),
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AdminColors.errorContainer, borderRadius: BorderRadius.circular(8)),
                              child: Text(_errorMessage!, style: AdminTypography.bodySm(color: AdminColors.onErrorContainer)),
                            ),
                            const SizedBox(height: 16),
                          ],
                          _field(controller: _codeController, label: 'Badge Code', hint: 'PYAUTO'),
                          const SizedBox(height: 14),
                          _field(controller: _titleController, label: 'Badge Name', hint: 'Python Automation Specialist'),
                          const SizedBox(height: 14),
                          _field(controller: _descriptionController, label: 'Description', hint: 'What this badge recognizes...', maxLines: 4),
                          const SizedBox(height: 14),
                          _field(controller: _issuingBodyController, label: 'Issuing Party', hint: 'AIEI Enterprise Learning'),
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
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : Text(widget.isEditing ? 'Save Changes' : 'Add Badge'),
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
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFieldLabel(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
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
          validator: (value) => (value == null || value.trim().isEmpty) ? '$label is required' : null,
        ),
      ],
    );
  }
}
