import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_mobile_top_bar.dart';
import 'widgets/admin_nav.dart';
import 'widgets/admin_mobile_selection_bar.dart';

/// A single row of master data: (id, display name).
typedef MasterDataRow = (String id, String name);

/// Generic CRUD screen for simple admin-managed lookup lists (departments,
/// program tracks, cohorts, ...) backing the Student Registration dropdowns.
/// Each row is just an id + a name.
class MasterDataScreen extends StatefulWidget {
  final String title;
  final String description;
  final String itemLabel;
  final AdminNavDestination navDestination;
  final Future<List<MasterDataRow>> Function() load;
  final Future<void> Function(String name) create;
  final Future<void> Function(String id, String name) update;
  final Future<void> Function(List<String> ids) delete;

  /// Optional italicized note shown under the description (e.g. a note
  /// about where this list is sourced from).
  final String? note;

  const MasterDataScreen({
    super.key,
    required this.title,
    required this.description,
    required this.itemLabel,
    required this.navDestination,
    required this.load,
    required this.create,
    required this.update,
    required this.delete,
    this.note,
  });

  @override
  State<MasterDataScreen> createState() => _MasterDataScreenState();
}

class _MasterDataScreenState extends State<MasterDataScreen> {
  bool _isLoading = true;
  List<MasterDataRow> _rows = [];
  final Set<String> _selected = {};
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _query = _searchController.text.trim().toLowerCase()));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
    if (_query.isEmpty) return _rows;
    return _rows.where((r) => r.$2.toLowerCase().contains(_query)).toList();
  }

  void _handleNav(AdminNavDestination dest) => handleAdminNav(context, widget.navDestination, dest);

  Future<void> _openForm({String? id, String? name}) async {
    final controller = TextEditingController(text: name ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(id == null ? 'Add ${widget.itemLabel}' : 'Edit ${widget.itemLabel}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: widget.itemLabel, border: const OutlineInputBorder()),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return;
    if (id == null) {
      await widget.create(result);
    } else {
      await widget.update(id, result);
    }
    await _load();
  }

  Future<void> _confirmAndDelete(List<String> ids) async {
    final count = ids.length;
    final label = widget.itemLabel.toLowerCase();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $label${count == 1 ? '' : 's'}?'),
        content: Text('This will permanently delete $count $label${count == 1 ? '' : 's'}. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AdminColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.delete(ids);
    if (!mounted) return;
    setState(() => _selected.removeAll(ids));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (MediaQuery.of(context).size.width < 700) {
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
  // Mobile (<700px) layout — a drill-in screen (back-arrow top bar, no
  // bottom nav; reached from the "More" menu).
  // ---------------------------------------------------------------------

  Widget _buildMobileScaffold(BuildContext context) {
    final rows = _filtered;
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AdminMobileTopBar.detail(title: widget.title),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.description, style: AdminTypography.bodyMd()),
              if (widget.note != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.note!,
                  style: AdminTypography.bodySm(color: AdminColors.onSurfaceVariant).copyWith(fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add, size: 20),
                  label: Text('Add ${widget.itemLabel}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primaryContainer,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                style: AdminTypography.bodySm(color: AdminColors.onSurface),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AdminColors.surfaceContainerLowest,
                  hintText: 'Search ${widget.itemLabel.toLowerCase()}s...',
                  hintStyle: AdminTypography.bodySm(color: AdminColors.outline),
                  prefixIcon: const Icon(Icons.search, size: 18, color: AdminColors.onSurfaceVariant),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              if (_selected.isNotEmpty) ...[
                const SizedBox(height: 12),
                adminMobileSelectionBar(
                  count: _selected.length,
                  itemLabel: widget.itemLabel.toLowerCase(),
                  onDeselectAll: () => setState(_selected.clear),
                  onDelete: () => _confirmAndDelete(_selected.toList()),
                ),
              ],
              const SizedBox(height: 12),
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No ${widget.itemLabel.toLowerCase()}s found.', style: AdminTypography.bodyMd()),
                )
              else
                Container(
                  decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [for (final r in rows) _row(r)]),
                ),
            ],
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
          label: Text('Add ${widget.itemLabel}'),
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
              style: AdminTypography.bodySm(color: AdminColors.onSurface),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AdminColors.surfaceContainerLow,
                hintText: 'Search ${widget.itemLabel.toLowerCase()}s...',
                hintStyle: AdminTypography.bodySm(color: AdminColors.outline),
                prefixIcon: const Icon(Icons.search, size: 18, color: AdminColors.onSurfaceVariant),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
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
                    label: const Text('Delete'),
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
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text('No ${widget.itemLabel.toLowerCase()}s found.', style: AdminTypography.bodyMd()),
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

  Widget _row(MasterDataRow row) {
    final (id, name) = row;
    final selected = _selected.contains(id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AdminColors.surfaceContainer))),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: (v) => setState(() => v == true ? _selected.add(id) : _selected.remove(id)),
            activeColor: AdminColors.primaryContainer,
          ),
          Expanded(child: Text(name, style: AdminTypography.titleSm(color: AdminColors.onSurface))),
          IconButton(
            onPressed: () => _openForm(id: id, name: name),
            icon: const Icon(Icons.edit_outlined, size: 18, color: AdminColors.onSurfaceVariant),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: () => _confirmAndDelete([id]),
            icon: const Icon(Icons.delete_outline, size: 18, color: AdminColors.error),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}
