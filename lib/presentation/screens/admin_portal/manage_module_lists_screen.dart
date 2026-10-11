import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/core/utils/error_messages.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_module_lists_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/module_list.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_mobile_top_bar.dart';
import 'widgets/admin_nav.dart';
import 'widgets/module_names_editor.dart';

// ---------------------------------------------------------------------------
// ManageModuleListsScreen — Module Lists master data: named, reusable lists
// of module names (`module_lists` / `module_list_items`) that an admin can
// import while creating a class (Manage Assigned Courses → Modules).
// ---------------------------------------------------------------------------
class ManageModuleListsScreen extends StatefulWidget {
  const ManageModuleListsScreen({super.key});

  @override
  State<ManageModuleListsScreen> createState() => _ManageModuleListsScreenState();
}

class _ManageModuleListsScreenState extends State<ManageModuleListsScreen> {
  final _repository = SupabaseAdminModuleListsRepositoryImpl(Supabase.instance.client);
  bool _isLoading = true;
  List<ModuleList> _lists = [];
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
    final lists = await _repository.getModuleLists();
    if (!mounted) return;
    setState(() {
      _lists = lists;
      _isLoading = false;
    });
  }

  List<ModuleList> get _filtered {
    if (_query.isEmpty) return _lists;
    return _lists.where((l) => l.name.toLowerCase().contains(_query) || l.moduleNames.any((m) => m.toLowerCase().contains(_query))).toList();
  }

  void _handleNav(AdminNavDestination dest) => handleAdminNav(context, AdminNavDestination.manageModuleLists, dest);

  Future<void> _openForm({ModuleList? list}) async {
    final nameController = TextEditingController(text: list?.name ?? '');
    final modules = ModuleNamesController();
    if (list != null) modules.setNames(list.moduleNames);
    String? errorMessage;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(list == null ? 'Add Module List' : 'Edit Module List'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AdminColors.errorContainer, borderRadius: BorderRadius.circular(8)),
                      child: Text(errorMessage!, style: AdminTypography.bodySm(color: AdminColors.onErrorContainer)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'List name', hintText: 'e.g. Standard 4-Module Course'),
                  ),
                  const SizedBox(height: 16),
                  Text('Modules', style: AdminTypography.titleSm()),
                  const SizedBox(height: 8),
                  ModuleNamesEditor(controller: modules),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final names = modules.names;
                if (name.isEmpty) {
                  setDialogState(() => errorMessage = 'List name is required.');
                  return;
                }
                if (names.isEmpty) {
                  setDialogState(() => errorMessage = 'Add at least one module.');
                  return;
                }
                try {
                  if (list == null) {
                    await _repository.createModuleList(name, names);
                  } else {
                    await _repository.updateModuleList(list.id, name, names);
                  }
                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                } catch (e) {
                  setDialogState(() => errorMessage = friendlyErrorMessage(e));
                }
              },
              child: Text(list == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    modules.dispose();
    if (saved == true) _load();
  }

  Future<void> _deleteSelected() async {
    final count = _selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete module lists?'),
        content: Text('This will permanently delete $count module list${count == 1 ? '' : 's'}. Classes already created from them keep their modules. This cannot be undone.'),
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
    await _repository.deleteModuleLists(_selected.toList());
    if (!mounted) return;
    setState(_selected.clear);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (MediaQuery.of(context).size.width < 700) {
      return Scaffold(
        backgroundColor: AdminColors.background,
        appBar: const AdminMobileTopBar.detail(title: 'Manage Module Lists'),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_buildHeader(), const SizedBox(height: 16), _buildListCard()]),
          ),
        ),
      );
    }
    return AdminScaffold(
      selected: AdminNavDestination.manageModuleLists,
      onDestinationSelected: _handleNav,
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildHeader(), const SizedBox(height: 20), _buildListCard()]),
    );
  }

  Widget _buildHeader() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage Module Lists', style: AdminTypography.headlineLg()),
            const SizedBox(height: 2),
            Text('Reusable module lists an admin can import when creating a class.', style: AdminTypography.bodyMd()),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Module List'),
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
    final lists = _filtered;
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
                hintText: 'Search module lists...',
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
                  Text('${_selected.length} selected', style: AdminTypography.titleSm()),
                  OutlinedButton.icon(
                    onPressed: _deleteSelected,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminColors.error,
                      backgroundColor: AdminColors.errorContainer,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          if (lists.isEmpty)
            Padding(padding: const EdgeInsets.all(32), child: Text('No module lists found.', style: AdminTypography.bodyMd()))
          else
            Column(children: [for (final l in lists) _row(l)]),
        ],
      ),
    );
  }

  Widget _row(ModuleList l) {
    final selected = _selected.contains(l.id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AdminColors.surfaceContainer))),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: (v) => setState(() => v == true ? _selected.add(l.id) : _selected.remove(l.id)),
            activeColor: AdminColors.primaryContainer,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${l.name} (${l.moduleNames.length})', style: AdminTypography.bodyMd(color: AdminColors.onSurface).copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(l.moduleNames.join(' • '), style: AdminTypography.bodySm(), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openForm(list: l),
            icon: const Icon(Icons.edit_outlined, size: 18, color: AdminColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
