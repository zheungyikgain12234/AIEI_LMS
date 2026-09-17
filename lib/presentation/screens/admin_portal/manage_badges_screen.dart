import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_badges_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/badge_award.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_nav.dart';
import 'badge_award_form_screen.dart';

// ---------------------------------------------------------------------------
// ManageBadgesScreen – CRUD for badge_awards: which student earned (or had
// revoked) which badge for which course.
// ---------------------------------------------------------------------------
class ManageBadgesScreen extends StatefulWidget {
  const ManageBadgesScreen({super.key});

  @override
  State<ManageBadgesScreen> createState() => _ManageBadgesScreenState();
}

class _ManageBadgesScreenState extends State<ManageBadgesScreen> {
  final _repository = SupabaseAdminBadgesRepositoryImpl(Supabase.instance.client);
  bool _isLoading = true;
  List<BadgeAward> _awards = [];
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
    final awards = await _repository.getBadgeAwards();
    if (!mounted) return;
    setState(() {
      _awards = awards;
      _isLoading = false;
    });
  }

  List<BadgeAward> get _filtered {
    if (_query.isEmpty) return _awards;
    return _awards.where((a) =>
        a.studentName.toLowerCase().contains(_query) ||
        a.courseCode.toLowerCase().contains(_query) ||
        a.courseTitle.toLowerCase().contains(_query) ||
        a.badgeTitle.toLowerCase().contains(_query)).toList();
  }

  void _handleNav(AdminNavDestination dest) => handleAdminNav(context, AdminNavDestination.manageBadges, dest);

  Future<void> _openAdd() async {
    final saved = await Navigator.of(context).push<BadgeAward>(
      MaterialPageRoute(builder: (_) => const BadgeAwardFormScreen()),
    );
    if (saved != null) _load();
  }

  Future<void> _openEdit(BadgeAward award) async {
    final saved = await Navigator.of(context).push<BadgeAward>(
      MaterialPageRoute(builder: (_) => BadgeAwardFormScreen(award: award)),
    );
    if (saved != null) _load();
  }

  Future<void> _deleteSelected() async {
    final count = _selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete badge awards?'),
        content: Text('This will permanently delete $count badge award${count == 1 ? '' : 's'}. This cannot be undone.'),
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
    await _repository.deleteBadgeAwards(_selected.toList());
    if (!mounted) return;
    setState(_selected.clear);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return AdminScaffold(
      selected: AdminNavDestination.manageBadges,
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
              child: Text('Per-course badge awards — which student earned or had revoked which badge.', style: AdminTypography.bodyMd()),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _openAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('+ Add Badge Award'),
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
    final awards = _filtered;
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
                hintText: 'Search by student, course, or badge...',
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
                    onPressed: _deleteSelected,
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
          if (awards.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text('No badge awards found.', style: AdminTypography.bodyMd()),
            )
          else
            Column(children: [for (final a in awards) _row(a)]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${awards.length} badge award${awards.length == 1 ? '' : 's'}', style: AdminTypography.bodySm()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BadgeAward a) {
    final selected = _selected.contains(a.id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: a.isRevoked ? AdminColors.errorContainer.withValues(alpha: 0.12) : null,
        border: const Border(bottom: BorderSide(color: AdminColors.surfaceContainer)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: selected,
            onChanged: (v) => setState(() => v == true ? _selected.add(a.id) : _selected.remove(a.id)),
            activeColor: AdminColors.primaryContainer,
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                children: [
                  Flexible(child: Text(a.studentName, style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _openEdit(a),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(Icons.edit_outlined, size: 14, color: AdminColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.courseTitle, style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
                  Text(a.courseCode, style: AdminTypography.labelSm()),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(a.badgeTitle, style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text('${a.issueYear}', style: AdminTypography.labelSm()),
          ),
          SizedBox(
            width: 110,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: a.isRevoked ? AdminColors.errorContainer : AdminColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  a.isRevoked ? 'Revoked' : 'Active',
                  style: AdminTypography.labelSm(color: a.isRevoked ? AdminColors.error : AdminColors.onSurface).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
