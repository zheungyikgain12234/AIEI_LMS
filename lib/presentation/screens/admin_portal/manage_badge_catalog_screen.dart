import 'package:stitch_aiei_lms/core/utils/refresh_on_return.dart';
import 'package:stitch_aiei_lms/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_badge_catalog_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/badge_award.dart';
import 'package:stitch_aiei_lms/domain/models/badge_catalog_item.dart';
import 'widgets/admin_no_results.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_searchable_dropdown.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_mobile_top_bar.dart';
import 'widgets/admin_nav.dart';
import 'badge_catalog_form_screen.dart';

// ---------------------------------------------------------------------------
// ManageBadgeCatalogScreen — Badges master data: code, name, description,
// issuing party (`certifications` table). Courses select any number of
// these (see CourseFormScreen) as the badges students unlock on completion.
// ---------------------------------------------------------------------------
class ManageBadgeCatalogScreen extends StatefulWidget {
  const ManageBadgeCatalogScreen({super.key});

  @override
  State<ManageBadgeCatalogScreen> createState() => _ManageBadgeCatalogScreenState();
}

class _ManageBadgeCatalogScreenState extends State<ManageBadgeCatalogScreen> with RefreshOnReturn<ManageBadgeCatalogScreen> {
  @override
  void onReturnedTo() => _load();

  final _repository = SupabaseAdminBadgeCatalogRepositoryImpl(Supabase.instance.client);
  bool _isLoading = true;
  List<BadgeCatalogItem> _badges = [];
  final Set<String> _selected = {};
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
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
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final badges = await _repository.getBadges();
    if (!mounted) return;
    setState(() {
      _badges = badges;
      _isLoading = false;
    });
  }

  List<BadgeCatalogItem> get _filtered {
    if (_query.isEmpty) return _badges;
    return _badges.where((b) => b.code.toLowerCase().contains(_query) || b.title.toLowerCase().contains(_query)).toList();
  }

  void _handleNav(AdminNavDestination dest) => handleAdminNav(context, AdminNavDestination.manageBadgeCatalog, dest);

  Future<void> _openAdd() async {
    final saved = await Navigator.of(context).push<BadgeCatalogItem>(
      MaterialPageRoute(builder: (_) => const BadgeCatalogFormScreen()),
    );
    if (saved != null) _load();
  }

  Future<void> _openEdit(BadgeCatalogItem b) async {
    final saved = await Navigator.of(context).push<BadgeCatalogItem>(
      MaterialPageRoute(builder: (_) => BadgeCatalogFormScreen(badgeId: b.id)),
    );
    if (saved != null) _load();
  }

  Future<void> _deleteSelected() async {
    final ids = _selected.toList();
    final awards = await _repository.getAwardsForBadges(ids);
    if (!mounted) return;
    final replacements = _badges.where((b) => !_selected.contains(b.id)).toList();
    final reassignments = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => _DeleteBadgesDialog(badgeCount: ids.length, awards: awards, replacements: replacements),
    );
    if (reassignments == null || !mounted) return;
    if (awards.isNotEmpty) {
      final moved = reassignments.length;
      final removed = awards.length - moved;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm deletion'),
          content: Text(
            'You are about to delete ${ids.length} badge${ids.length == 1 ? '' : 's'}.\n'
            '• $moved award${moved == 1 ? '' : 's'} will be reassigned\n'
            '• $removed award${removed == 1 ? '' : 's'} will be deleted\n\n'
            'This cannot be undone.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Back')),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AdminColors.error),
              child: const Text('Confirm & delete'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    await _repository.deleteBadges(ids, reassignments: reassignments);
    if (!mounted) return;
    setState(_selected.clear);
    showSuccessSnackBar(context, '${ids.length} badge${ids.length == 1 ? '' : 's'} deleted');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // Only rows still visible (after a search or filter) can stay selected, so
    // the "N selected" count and bulk actions never include hidden records.
    final visibleIds = {for (final r in _filtered) r.id};
    _selected.retainWhere(visibleIds.contains);
    if (MediaQuery.of(context).size.width < 700) {
      return _buildMobileScaffold(context);
    }
    return AdminScaffold(
      selected: AdminNavDestination.manageBadgeCatalog,
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
            Text('Manage Badges', style: AdminTypography.headlineLg()),
            const SizedBox(height: 2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Text('The badge catalogue courses can be configured to award on completion.', style: AdminTypography.bodyMd()),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _openAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('+ Add New Badge'),
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
    final badges = _filtered;
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
                filled: true,
                fillColor: AdminColors.surfaceContainerLow,
                hintText: 'Search badge by code or name...',
                hintStyle: AdminTypography.bodySm(color: AdminColors.hint).copyWith(fontStyle: FontStyle.italic),
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
          if (badges.isEmpty)
            Padding(padding: const EdgeInsets.all(32), child: AdminNoResults(controller: _searchController, focusNode: _searchFocus))
          else
            Column(children: [for (final b in badges) _row(b)]),
        ],
      ),
    );
  }

  Widget _row(BadgeCatalogItem b) {
    final selected = _selected.contains(b.id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AdminColors.surfaceContainer))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: selected,
            onChanged: (v) => setState(() => v == true ? _selected.add(b.id) : _selected.remove(b.id)),
            activeColor: AdminColors.primaryContainer,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(child: Text(b.title, style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _openEdit(b),
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(padding: EdgeInsets.all(2), child: Icon(Icons.edit_outlined, size: 14, color: AdminColors.onSurfaceVariant)),
                  ),
                ]),
                Text('${b.code} • ${b.issuingBody}', style: AdminTypography.labelSm(), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileScaffold(BuildContext context) {
    // Same content as desktop (header + list card); the rows are already
    // single-column, so they are reused as-is.
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: const AdminMobileTopBar.detail(title: 'Manage Badges'),
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
}

// Confirms a badge delete. Awards still on the badges are listed one by one;
// each needs its own decision: move to another badge, or delete the award.
// Pops a map of award id -> new badge id (awards left out are deleted).
class _DeleteBadgesDialog extends StatefulWidget {
  const _DeleteBadgesDialog({required this.badgeCount, required this.awards, required this.replacements});

  final int badgeCount;
  final List<BadgeAward> awards;
  final List<BadgeCatalogItem> replacements;

  @override
  State<_DeleteBadgesDialog> createState() => _DeleteBadgesDialogState();
}

class _DeleteBadgesDialogState extends State<_DeleteBadgesDialog> {
  static const _deleteAward = '__delete__';

  // award id -> badge id, or [_deleteAward]. Missing = not decided yet.
  final Map<String, String> _choices = {};

  @override
  Widget build(BuildContext context) {
    final noun = widget.badgeCount == 1 ? 'badge' : 'badges';
    final awards = widget.awards;
    final undecided = awards.where((a) => !_choices.containsKey(a.id)).length;
    return AlertDialog(
      title: Text('Delete $noun?'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(awards.isEmpty
                  ? 'This will permanently delete ${widget.badgeCount} $noun from the catalogue and any course that awards it. This cannot be undone.'
                  : '${awards.length} award${awards.length == 1 ? ' is' : 's are'} still linked to the selected $noun. Choose what happens to each one. Courses that award the $noun will stop awarding it.'),
              for (final a in awards) ...[
                const SizedBox(height: 12),
                Text('${a.studentName} • ${a.courseCode}', style: AdminTypography.titleSm()),
                Text('Currently: ${a.badgeCode} ${a.badgeTitle}', style: AdminTypography.labelSm()),
                const SizedBox(height: 4),
                AdminSearchableDropdown(
                  key: ValueKey(a.id),
                  initialValue: _choices[a.id],
                  hint: 'Choose action',
                  filled: false,
                  options: [
                    (_deleteAward, 'Delete this award'),
                    for (final b in widget.replacements) (b.id, 'Reassign to ${b.code} • ${b.title}'),
                  ],
                  onChanged: (v) => setState(() => _choices[a.id] = v!),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: undecided == 0
              ? () => Navigator.of(context).pop({
                    for (final e in _choices.entries)
                      if (e.value != _deleteAward) e.key: e.value,
                  })
              : null,
          style: FilledButton.styleFrom(backgroundColor: AdminColors.error),
          child: Text(undecided == 0 ? 'Delete $noun' : '$undecided left to decide'),
        ),
      ],
    );
  }
}
