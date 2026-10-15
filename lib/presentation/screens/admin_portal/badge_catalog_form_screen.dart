import 'package:stitch_aiei_lms/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/utils/input_formatters.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/session/app_session.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/core/utils/error_messages.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_badge_catalog_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/badge_catalog_item.dart';
import 'widgets/admin_field_error.dart';
import 'widgets/badge_contrast.dart';

// ---------------------------------------------------------------------------
// BadgeCatalogFormScreen — shared "Add New Badge" / "Edit Badge" popup for the
// Badges master data (open it with showDialog) (`certifications` table). Pass `badgeId` to edit an
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
  String? get _codeConflict => _errorMessage == codeConflictMessage ? _errorMessage : null;
  String? get _nameConflict => _errorMessage == nameConflictMessage ? _errorMessage : null;

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
      showSuccessSnackBar(context, widget.isEditing ? 'Badge updated.' : 'Badge created.');
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
    return Dialog(
      backgroundColor: AdminColors.surfaceContainerLowest,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: _isLoading
            ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Expanded(child: Text(title, style: AdminTypography.headlineSm(color: BadgeContrast.text))),
                        IconButton(
                          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: BadgeContrast.textSecondary),
                          tooltip: 'Close',
                        ),
                      ]),
                      const SizedBox(height: 4),
                          Text(
                            widget.isEditing
                                ? 'Update this badge\'s catalogue information.'
                                : 'Add a new badge to the catalogue. Courses can then be configured to award it on completion.',
                            style: AdminTypography.bodyMd(color: BadgeContrast.textSecondary),
                          ),
                          const SizedBox(height: 20),
                          if (_errorMessage != null && !isFieldConflictMessage(_errorMessage!)) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AdminColors.errorContainer, borderRadius: BorderRadius.circular(8)),
                              child: Text(_errorMessage!, style: AdminTypography.bodySm(color: AdminColors.onErrorContainer)),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (widget.isEditing)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text.rich(TextSpan(children: [
                                TextSpan(text: 'Badge Code: ', style: AdminTypography.bodySm(color: BadgeContrast.textSecondary).copyWith(fontWeight: FontWeight.w700)),
                                TextSpan(text: _codeController.text.trim().toUpperCase(), style: AdminTypography.titleSm(color: BadgeContrast.text)),
                              ])),
                            ),
                          if (!widget.isEditing) ...[
                            _field(controller: _codeController, label: 'Badge Code', hint: 'PYAUTO', inputFormatters: const [UpperCaseTextFormatter()]),
                            AdminFieldError(_codeConflict),
                            const SizedBox(height: 14),
                          ],
                          _field(controller: _titleController, label: 'Badge Name', hint: 'Python Automation Specialist'),
                          AdminFieldError(_nameConflict),
                          const SizedBox(height: 14),
                          _field(controller: _descriptionController, label: 'Description', hint: 'What this badge recognises...', maxLines: 4),
                          const SizedBox(height: 14),
                          _field(controller: _issuingBodyController, label: 'Issuing Party', hint: 'AIEI Enterprise Learning'),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: AdminColors.primaryContainer,
                                    side: BorderSide.none,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Cancel', textAlign: TextAlign.center),
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
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BadgeContrast.label(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          enabled: !readOnly,
          style: AdminTypography.bodyMd(color: BadgeContrast.text),
          decoration: BadgeContrast.fieldDecoration(hint: hint),
          validator: (value) => (value == null || value.trim().isEmpty) ? '$label is required' : null,
        ),
      ],
    );
  }
}
