import 'package:stitch_aiei_lms/core/utils/input_formatters.dart';
import 'package:stitch_aiei_lms/core/utils/refresh_on_return.dart';
import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/presentation/widgets/skeleton.dart';
import 'package:stitch_aiei_lms/core/theme/ui_contrast.dart';
import 'widgets/admin_form_dialog.dart';
import 'widgets/admin_row_action.dart';
import 'widgets/admin_field_error.dart';
import 'widgets/admin_fixed_code.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch_aiei_lms/core/session/app_session.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/core/utils/error_messages.dart';
import 'widgets/admin_no_results.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_mobile_top_bar.dart';
import 'widgets/admin_nav.dart';
import 'widgets/admin_field_label.dart';
import 'widgets/admin_relational_delete.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_relational_delete.dart';

/// A single row of master data: id + tenant-prefixed unique code + display
/// name + free-text remarks (never shown on the table, only in the edit
/// form) + an optional year (only used when [MasterDataScreen.showYear]).
class MasterDataRow {
  final String id;
  final String code;
  final String name;
  final String remarks;
  final int? year;

  const MasterDataRow({required this.id, required this.code, required this.name, this.remarks = '', this.year});
}

enum _SortColumn { code, name, year }

/// Generic CRUD screen for simple admin-managed lookup lists (departments,
/// program tracks, semesters, ...) backing the Student Registration dropdowns.
class MasterDataScreen extends ConsumerStatefulWidget {
  final String title;
  final String description;
  final String itemLabel;
  final AdminNavDestination navDestination;
  final Future<List<MasterDataRow>> Function() load;
  final Future<void> Function(String code, String name, String remarks, int? year) create;
  final Future<void> Function(String id, String code, String name, String remarks, int? year) update;
  final MasterKind masterKind;

  /// Adds a required numeric "Year" field to the form and table (Semester only).
  final bool showYear;

  /// Optional italicized note shown under the description (e.g. a note
  /// about where this list is sourced from).
  final String? note;

  /// Optional label overrides (e.g. Programme ID / Programme Name / Description)
  /// and a table column for the remarks text.
  final String? codeLabel;
  final String? nameLabel;
  final String? remarksLabel;
  final bool showRemarksColumn;

  const MasterDataScreen({
    super.key,
    required this.title,
    required this.description,
    required this.itemLabel,
    required this.navDestination,
    required this.load,
    required this.create,
    required this.update,
    required this.masterKind,
    this.showYear = false,
    this.note,
    this.codeLabel,
    this.nameLabel,
    this.remarksLabel,
    this.showRemarksColumn = false,
  });

  @override
  ConsumerState<MasterDataScreen> createState() => _MasterDataScreenState();
}

class _MasterDataScreenState extends ConsumerState<MasterDataScreen> with RefreshOnReturn<MasterDataScreen> {
  @override
  void onReturnedTo() => _load();

  bool _isLoading = true;
  List<MasterDataRow> _rows = [];
  final Set<String> _selected = {};
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  _SortColumn _sortColumn = _SortColumn.code;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _query = _searchController.text.trim().toLowerCase()));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final rows = await widget.load();
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _isLoading = false;
    });
  }

  List<MasterDataRow> get _filtered {
    final rows = _query.isEmpty
        ? _rows
        : _rows.where((r) => r.name.toLowerCase().contains(_query) || r.code.toLowerCase().contains(_query)).toList();
    final sorted = [...rows];
    sorted.sort((a, b) {
      final int cmp;
      switch (_sortColumn) {
        case _SortColumn.code:
          cmp = a.code.toLowerCase().compareTo(b.code.toLowerCase());
        case _SortColumn.name:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case _SortColumn.year:
          cmp = (a.year ?? 0).compareTo(b.year ?? 0);
      }
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  void _toggleSort(_SortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  void _handleNav(AdminNavDestination dest) => handleAdminNav(context, widget.navDestination, dest);

  /// Every code is stored tenant-prefixed (`TN01-OPS`) and upper-cased to
  /// keep uniqueness checks case-insensitive; the admin only ever
  /// types/sees the plain suffix.
  String _tenantPrefix() => '${ref.read(appSessionProvider).tenantId}-';

  String _stripTenantPrefix(String code) {
    final prefix = _tenantPrefix();
    return code.startsWith(prefix) ? code.substring(prefix.length) : code;
  }

  Future<void> _openForm({String? id, String? code, String? name, String? remarks, int? year}) async {
    final codeController = TextEditingController(text: code != null ? _stripTenantPrefix(code) : '');
    final nameController = TextEditingController(text: name ?? '');
    final remarksController = TextEditingController(text: remarks ?? '');
    final yearController = TextEditingController(text: (year ?? DateTime.now().year).toString());
    final formKey = GlobalKey<FormState>();
    var isSaving = false;
    String? errorMessage;
    var saved = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AdminFormDialog(
          title: id == null ? 'Add ${widget.itemLabel}' : 'Edit ${widget.itemLabel}',
          maxWidth: 520,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (errorMessage != null && !isFieldConflictMessage(errorMessage!)) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AdminColors.errorContainer, borderRadius: BorderRadius.circular(8)),
                    child: Text(errorMessage!, style: AdminTypography.bodySm(color: AdminColors.onErrorContainer)),
                  ),
                  const SizedBox(height: 12),
                ],
                if (id != null)
                  AdminFixedCode(label: widget.codeLabel ?? '${widget.itemLabel} Code', value: codeController.text.trim().toUpperCase())
                else ...[
                  AdminFieldLabel(widget.codeLabel ?? '${widget.itemLabel} Code'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: codeController,
                    autofocus: id == null,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: const [UpperCaseTextFormatter()],
                    style: AdminTypography.bodyMd(color: AdminColors.onSurface),
                    decoration: adminFormDecoration(),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Code is required' : null,
                  ),
                  AdminFieldError(errorMessage == codeConflictMessage ? errorMessage : null),
                  const SizedBox(height: 14),
                ],
                AdminFieldLabel(widget.nameLabel ?? widget.itemLabel),
                const SizedBox(height: 6),
                TextFormField(
                  controller: nameController,
                  style: AdminTypography.bodyMd(color: AdminColors.onSurface),
                  decoration: adminFormDecoration(),
                  validator: (v) => (v == null || v.trim().isEmpty) ? '${widget.itemLabel} is required' : null,
                ),
                AdminFieldError(errorMessage == nameConflictMessage ? errorMessage : null),
                if (widget.showYear) ...[
                  const SizedBox(height: 14),
                  const AdminFieldLabel('Year'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: yearController,
                    keyboardType: TextInputType.number,
                    inputFormatters: digitsOnly,
                    style: AdminTypography.bodyMd(color: AdminColors.onSurface),
                    decoration: adminFormDecoration(),
                    validator: (v) {
                      final parsed = int.tryParse(v?.trim() ?? '');
                      if (parsed == null) return 'Enter a valid year';
                      if (parsed < 1990 || parsed > 2100) return 'Enter a year between 1990 and 2100';
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 14),
                AdminFieldLabel(widget.remarksLabel ?? 'Remarks', required: false),
                const SizedBox(height: 6),
                TextFormField(
                  controller: remarksController,
                  minLines: 3,
                  maxLines: 6,
                  keyboardType: TextInputType.multiline,
                  style: AdminTypography.bodyMd(color: AdminColors.onSurface),
                  decoration: adminFormDecoration(),
                ),
              ],
            ),
          ),
          onCancel: isSaving ? null : () => Navigator.of(ctx).pop(),
          submitChild: isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(id == null ? 'Add ${widget.itemLabel}' : 'Save Changes'),
          onSubmit: isSaving
              ? null
              : () async {
                  if (!formKey.currentState!.validate()) return;
                  setDialogState(() {
                    isSaving = true;
                    errorMessage = null;
                  });
                  try {
                    final savedCode = '${_tenantPrefix()}${codeController.text.trim().toUpperCase()}';
                    final savedName = nameController.text.trim();
                    final savedRemarks = remarksController.text.trim();
                    final savedYear = widget.showYear ? int.parse(yearController.text.trim()) : null;
                    if (id == null) {
                      await widget.create(savedCode, savedName, savedRemarks, savedYear);
                    } else {
                      await widget.update(id, savedCode, savedName, savedRemarks, savedYear);
                    }
                    saved = true;
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  } catch (e) {
                    setDialogState(() {
                      isSaving = false;
                      errorMessage = friendlyErrorMessage(e);
                    });
                  }
                },
        ),
      ),
    );
    // showDialog's Future resolves as soon as Navigator.pop() is called,
    // before the dialog's exit transition finishes — the TextFields using
    // these controllers are still mounted/animating at that point, so
    // disposing them synchronously here corrupts the element tree. Defer to
    // next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      codeController.dispose();
      nameController.dispose();
      remarksController.dispose();
      yearController.dispose();
    });
    if (saved) await _load();
  }

  Future<void> _confirmAndDelete(List<String> ids) async {
    final service = SupabaseAdminRelationalDelete(Supabase.instance.client);
    if (widget.masterKind == MasterKind.semester) {
      final impact = await service.semesterImpact(ids);
      if (!mounted) return;
      final names = [for (final r in _rows) if (ids.contains(r.id)) r.name];
      final done = await runTypedNameDelete(
        context,
        noun: 'semester',
        names: names,
        warning:
            'All classes and enrolments under ${ids.length == 1 ? 'this semester' : 'these semesters'} will be deleted: ${impact.classes} class${impact.classes == 1 ? '' : 'es'} and ${impact.enrolments} enrolment${impact.enrolments == 1 ? '' : 's'}. This cannot be undone.',
        perform: () => service.deleteSemesters(ids),
      );
      if (!done || !mounted) return;
      setState(() => _selected.removeAll(ids));
      await _load();
      return;
    }
    final dependents = await service.masterDependents(widget.masterKind, ids);
    if (!mounted) return;
    final done = await runRelationalDelete(
      context,
      noun: widget.itemLabel.toLowerCase(),
      count: ids.length,
      dependents: dependents,
      perform: (decisions) => service.deleteMaster(widget.masterKind, ids, decisions),
    );
    if (!done || !mounted) return;
    setState(() => _selected.removeAll(ids));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show the page frame straight away; only the content area is a placeholder.
      return MediaQuery.of(context).size.width <= 900 ? const SkeletonScaffold() : AdminScaffold(selected: widget.navDestination, onDestinationSelected: _handleNav, body: const SkeletonPage());
    }
    // Only rows still visible (after a search or filter) can stay selected, so
    // the "N selected" count and bulk actions never include hidden records.
    final visibleIds = {for (final r in _filtered) r.id};
    _selected.retainWhere(visibleIds.contains);
    if (MediaQuery.of(context).size.width <= 900) {
      return _buildMobileScaffold(context);
    }
    return AdminScaffold(
      selected: widget.navDestination,
      onDestinationSelected: _handleNav,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 20),
          _buildListCard(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Mobile (≤ 900px) layout — a drill-in screen (back-arrow top bar, no
  // bottom nav; reached from the "More" menu). Same content as desktop: the
  // header and the list card are reused as-is.
  // ---------------------------------------------------------------------

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AdminMobileTopBar.detail(title: widget.title),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_buildTopBar(), const SizedBox(height: 16), _buildListCard()],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: AdminTypography.headlineLg()),
            const SizedBox(height: 2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Text(widget.description, style: AdminTypography.bodyMd()),
            ),
            if (widget.note != null) ...[
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Text(
                  widget.note!,
                  style: AdminTypography.bodySm(color: AdminColors.onSurfaceVariant).copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add, size: 18),
          label: Text('Add ${widget.itemLabel}', textAlign: TextAlign.center),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.primaryContainer,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildListCard() {
    final rows = _filtered;
    return Container(
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              style: AdminTypography.bodySm(color: AdminColors.onSurface),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search ${widget.itemLabel.toLowerCase()}s...',
                prefixIcon: const Icon(Icons.search, size: 18, color: AdminColors.onSurfaceVariant),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_selected.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_box, size: 18, color: AdminColors.secondary),
                    const SizedBox(width: 6),
                    Text('${_selected.length} selected', style: AdminTypography.titleSm()),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(_selected.clear),
                      child: Text('Deselect all', style: AdminTypography.labelMd(color: AdminColors.secondary)),
                    ),
                  ]),
                  OutlinedButton.icon(
                    onPressed: () => _confirmAndDelete(_selected.toList()),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete', textAlign: TextAlign.center),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminColors.error,
                      backgroundColor: AdminColors.errorContainer,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: AdminTypography.labelSm(),
                    ),
                  ),
                ],
              ),
            ),
          if (rows.isNotEmpty) _headerRow(),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: AdminNoResults(controller: _searchController, focusNode: _searchFocus),
            )
          else
            Column(children: [for (final r in rows) _row(r)]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${rows.length} ${widget.itemLabel.toLowerCase()}${rows.length == 1 ? '' : 's'}', style: AdminTypography.bodySm()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: UiContrast.divider))),
      child: Row(
        children: [
          const SizedBox(width: 40),
          Expanded(flex: 2, child: _sortHeader(widget.codeLabel ?? 'Code', _SortColumn.code)),
          Expanded(flex: 3, child: _sortHeader(widget.nameLabel ?? widget.itemLabel, _SortColumn.name)),
          if (widget.showRemarksColumn) Expanded(flex: 4, child: Text(widget.remarksLabel ?? 'Remarks', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant))),
          if (widget.showYear) SizedBox(width: 90, child: _sortHeader('Year', _SortColumn.year)),
          adminActionHeader(),
        ],
      ),
    );
  }

  Widget _sortHeader(String label, _SortColumn column) {
    final active = _sortColumn == column;
    return InkWell(
      onTap: () => _toggleSort(column),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AdminTypography.labelSm(color: active ? AdminColors.onSurface : AdminColors.onSurfaceVariant)),
          const SizedBox(width: 2),
          Icon(
            active && !_sortAscending ? Icons.arrow_downward : Icons.arrow_upward,
            size: 12,
            color: active ? AdminColors.onSurface : AdminColors.outline,
          ),
        ],
      ),
    );
  }

  Widget _row(MasterDataRow row) {
    final selected = _selected.contains(row.id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: UiContrast.divider))),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: (v) => setState(() => v == true ? _selected.add(row.id) : _selected.remove(row.id)),
            activeColor: AdminColors.primaryContainer,
          ),
          Expanded(flex: 2, child: Text(row.code, style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant))),
          Expanded(flex: 3, child: Text(row.name, style: AdminTypography.titleSm(color: AdminColors.onSurface))),
          if (widget.showRemarksColumn) Expanded(flex: 4, child: Padding(padding: const EdgeInsets.only(right: 12), child: Text(row.remarks, style: AdminTypography.bodySm(), maxLines: 2, overflow: TextOverflow.ellipsis))),
          if (widget.showYear) SizedBox(width: 90, child: Text('${row.year}', style: AdminTypography.bodySm())),
          adminEditAction(() => _openForm(id: row.id, code: row.code, name: row.name, remarks: row.remarks, year: row.year)),
        ],
      ),
    );
  }
}
