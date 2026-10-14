import 'package:stitch_aiei_lms/core/utils/date_format.dart';
import 'package:stitch_aiei_lms/core/utils/refresh_on_return.dart';
import 'package:stitch_aiei_lms/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_badges_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/badge_award.dart';
import 'widgets/admin_field_label.dart';
import 'widgets/admin_no_results.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_mobile_top_bar.dart';
import 'widgets/admin_nav.dart';
import 'widgets/admin_pagination.dart';

// ---------------------------------------------------------------------------
// ManageBadgesScreen – CRUD for badge_awards: which student earned (or had
// revoked) which badge for which course.
// ---------------------------------------------------------------------------
class ManageBadgesScreen extends StatefulWidget {
  const ManageBadgesScreen({super.key});

  @override
  State<ManageBadgesScreen> createState() => _ManageBadgesScreenState();
}

enum _SortColumn { student, course, badge, date }

String _formatDate(DateTime d) => formatDate(d);

class _ManageBadgesScreenState extends State<ManageBadgesScreen> with RefreshOnReturn<ManageBadgesScreen> {
  @override
  void onReturnedTo() => _load();

  final _repository = SupabaseAdminBadgesRepositoryImpl(Supabase.instance.client);
  bool _isLoading = true;
  List<BadgeAward> _awards = [];
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  _SortColumn _sortColumn = _SortColumn.student;
  bool _sortAscending = true;
  int _page = 1;
  int _pageSize = adminPageSizeOptions.first;

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
    final awards = await _repository.getBadgeAwards();
    if (!mounted) return;
    setState(() {
      _awards = awards;
      _isLoading = false;
    });
  }

  List<BadgeAward> get _filtered {
    final awards = _query.isEmpty
        ? _awards
        : _awards.where((a) =>
            a.studentName.toLowerCase().contains(_query) ||
            a.courseCode.toLowerCase().contains(_query) ||
            a.courseTitle.toLowerCase().contains(_query) ||
            a.badgeTitle.toLowerCase().contains(_query)).toList();
    final sorted = [...awards];
    sorted.sort((a, b) {
      final int cmp;
      switch (_sortColumn) {
        case _SortColumn.student:
          cmp = a.studentName.toLowerCase().compareTo(b.studentName.toLowerCase());
        case _SortColumn.course:
          cmp = a.courseTitle.toLowerCase().compareTo(b.courseTitle.toLowerCase());
        case _SortColumn.badge:
          cmp = a.badgeTitle.toLowerCase().compareTo(b.badgeTitle.toLowerCase());
        case _SortColumn.date:
          cmp = a.issueDate.compareTo(b.issueDate);
      }
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  List<BadgeAward> _paged(List<BadgeAward> items) {
    final pageCount = items.isEmpty ? 1 : (items.length / _pageSize).ceil();
    if (_page > pageCount) _page = pageCount;
    final start = ((_page - 1) * _pageSize).clamp(0, items.length);
    final end = (start + _pageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }

  void _handleNav(AdminNavDestination dest) => handleAdminNav(context, AdminNavDestination.manageBadges, dest);

  Future<void> _setRevoked(BadgeAward award, bool revoke) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(revoke ? 'Revoke badge?' : 'Unrevoke badge?'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(revoke
                  ? 'Revoke "${award.badgeTitle}" from ${award.studentName}?'
                  : 'Restore "${award.badgeTitle}" for ${award.studentName}?'),
              if (revoke) ...[
                const SizedBox(height: 12),
                const AdminFieldLabel('Reason for Revoking'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: reasonController,
                  autofocus: true,
                  maxLines: 3,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. Safety infraction found during site audit'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'A reason is required to revoke a badge.' : null,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.of(ctx).pop(true);
            },
            style: revoke ? FilledButton.styleFrom(backgroundColor: AdminColors.error) : null,
            child: Text(revoke ? 'Revoke' : 'Unrevoke'),
          ),
        ],
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (confirmed != true || !mounted) return;
    await _repository.setBadgeAwardRevoked(award.id, revoked: revoke, reason: reason);
    if (!mounted) return;
    showSuccessSnackBar(context, revoke ? 'Badge revoked.' : 'Badge unrevoked.');
    await _load();
  }

  Widget _revokeButton(BadgeAward a) {
    return ElevatedButton(
      onPressed: () => _setRevoked(a, !a.isRevoked),
      style: ElevatedButton.styleFrom(
        backgroundColor: a.isRevoked ? AdminColors.primaryContainer : AdminColors.error,
        foregroundColor: Colors.white,
        elevation: 0,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(a.isRevoked ? 'Unrevoke' : 'Revoke'),
    );
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

  // ---------------------------------------------------------------------
  // Mobile (<700px) layout — a drill-in screen (back-arrow top bar, no
  // bottom nav; reached from the "More" menu), card list instead of the
  // desktop table's fixed-width columns.
  // ---------------------------------------------------------------------

  Widget _buildMobileScaffold(BuildContext context) {
    final awards = _filtered;
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: const AdminMobileTopBar.detail(title: 'Manage Badge Award'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                style: AdminTypography.bodySm(color: AdminColors.onSurface),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AdminColors.surfaceContainerLowest,
                  hintText: 'Search by student, course, or badge...',
                  hintStyle: AdminTypography.bodySm(color: AdminColors.hint).copyWith(fontStyle: FontStyle.italic),
                  prefixIcon: const Icon(Icons.search, size: 18, color: AdminColors.onSurfaceVariant),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              if (awards.isEmpty)
                Padding(padding: const EdgeInsets.all(24), child: AdminNoResults(controller: _searchController, focusNode: _searchFocus))
              else ...[
                for (final a in _paged(awards)) ...[
                  _mobileAwardCard(a),
                  const SizedBox(height: 12),
                ],
                AdminPagination(
                  totalItems: awards.length,
                  page: _page,
                  pageSize: _pageSize,
                  itemLabel: 'badge award',
                  onPageChanged: (p) => setState(() => _page = p),
                  onPageSizeChanged: (s) => setState(() {
                    _pageSize = s;
                    _page = 1;
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileAwardCard(BadgeAward a) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: a.isRevoked ? AdminColors.errorContainer.withValues(alpha: 0.12) : AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(a.studentName, style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: a.isRevoked ? AdminColors.errorContainer : AdminColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      a.isRevoked ? 'Revoked' : 'Active',
                      style: AdminTypography.labelSm(color: a.isRevoked ? AdminColors.error : AdminColors.onSurface).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ]),
                Text('${a.courseTitle} (${a.courseCode})', style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
                Text('${a.badgeTitle} • ${_formatDate(a.issueDate)}', style: AdminTypography.labelSm()),
              ],
            ),
          ),
          _revokeButton(a),
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
            Text('Manage Badge Award', style: AdminTypography.headlineLg()),
            const SizedBox(height: 2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Text('Per-course badge awards — which student earned or had revoked which badge.', style: AdminTypography.bodyMd()),
            ),
          ],
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
              focusNode: _searchFocus,
              style: AdminTypography.bodySm(color: AdminColors.onSurface),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AdminColors.surfaceContainerLow,
                hintText: 'Search by student, course, or badge...',
                hintStyle: AdminTypography.bodySm(color: AdminColors.hint).copyWith(fontStyle: FontStyle.italic),
                prefixIcon: const Icon(Icons.search, size: 18, color: AdminColors.onSurfaceVariant),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (awards.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: AdminNoResults(controller: _searchController, focusNode: _searchFocus),
            )
          else
            _headerRow(),
            Column(children: [for (final a in _paged(awards)) _row(a)]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AdminPagination(
              totalItems: awards.length,
              page: _page,
              pageSize: _pageSize,
              itemLabel: 'badge award',
              onPageChanged: (p) => setState(() => _page = p),
              onPageSizeChanged: (s) => setState(() {
                _pageSize = s;
                _page = 1;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AdminColors.surfaceContainer))),
      child: Row(
        children: [
          Expanded(flex: 3, child: _sortHeader('Student', _SortColumn.student)),
          Expanded(flex: 3, child: _sortHeader('Course', _SortColumn.course)),
          Expanded(flex: 3, child: _sortHeader('Badge', _SortColumn.badge)),
          Expanded(flex: 2, child: _sortHeader('Issue Date', _SortColumn.date)),
          SizedBox(width: 90, child: Text('Status', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant))),
          SizedBox(
            width: 100,
            child: Text('Action', textAlign: TextAlign.right, style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  Widget _row(BadgeAward a) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: a.isRevoked ? AdminColors.errorContainer.withValues(alpha: 0.12) : null,
        border: const Border(bottom: BorderSide(color: AdminColors.surfaceContainer)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(a.studentName, style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis),
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
            flex: 2,
            child: Text(_formatDate(a.issueDate), style: AdminTypography.labelSm()),
          ),
          SizedBox(
            width: 90,
            child: Align(
              alignment: Alignment.centerLeft,
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
          SizedBox(
            width: 100,
            child: Align(alignment: Alignment.centerRight, child: _revokeButton(a)),
          ),
        ],
      ),
    );
  }
}
