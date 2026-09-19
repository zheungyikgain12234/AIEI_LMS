import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturers_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/course_section.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_mobile_top_bar.dart';
import 'widgets/admin_nav.dart';
import 'widgets/admin_mobile_selection_bar.dart';
import 'widgets/admin_pagination.dart';
import 'manage_class_detail_screen.dart';

// ---------------------------------------------------------------------------
// ManageClassesScreen – lists every class section (course_sections) created
// when a lecturer is assigned to a course from the Manage Assigned Courses
// screen, e.g. `OSHE-101-01`. Search/bulk-delete, plus a per-row "Manage"
// button that opens ManageClassDetailScreen to view/edit the class's date
// and other info and manage its enrolled students. New sections are still
// only created from a lecturer's Manage Assigned Courses screen.
// ---------------------------------------------------------------------------
class ManageClassesScreen extends StatefulWidget {
  const ManageClassesScreen({super.key});

  @override
  State<ManageClassesScreen> createState() => _ManageClassesScreenState();
}

enum _SortColumn { section, course, lecturer, cohort, year, enrolled }

class _ManageClassesScreenState extends State<ManageClassesScreen> {
  final _repository = SupabaseLecturersRepositoryImpl(Supabase.instance.client);
  bool _isLoading = true;
  List<CourseSection> _sections = [];
  final Set<String> _selected = {};
  final _searchController = TextEditingController();
  String _query = '';
  _SortColumn _sortColumn = _SortColumn.section;
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
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final sections = await _repository.getAllSections();
    if (!mounted) return;
    setState(() {
      _sections = sections;
      _isLoading = false;
    });
  }

  List<CourseSection> get _filtered {
    final sections = _query.isEmpty
        ? _sections
        : _sections.where((s) =>
            s.sectionCode.toLowerCase().contains(_query) ||
            s.courseCode.toLowerCase().contains(_query) ||
            s.courseTitle.toLowerCase().contains(_query) ||
            (s.lecturerName ?? '').toLowerCase().contains(_query) ||
            (s.cohort ?? '').toLowerCase().contains(_query)).toList();
    final sorted = [...sections];
    sorted.sort((a, b) {
      final int cmp;
      switch (_sortColumn) {
        case _SortColumn.section:
          cmp = a.sectionCode.toLowerCase().compareTo(b.sectionCode.toLowerCase());
        case _SortColumn.course:
          cmp = a.courseTitle.toLowerCase().compareTo(b.courseTitle.toLowerCase());
        case _SortColumn.lecturer:
          cmp = (a.lecturerName ?? '').toLowerCase().compareTo((b.lecturerName ?? '').toLowerCase());
        case _SortColumn.cohort:
          cmp = (a.cohort ?? '').toLowerCase().compareTo((b.cohort ?? '').toLowerCase());
        case _SortColumn.year:
          cmp = (a.cohortYear ?? 0).compareTo(b.cohortYear ?? 0);
        case _SortColumn.enrolled:
          cmp = a.enrolledCount.compareTo(b.enrolledCount);
      }
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  List<CourseSection> _paged(List<CourseSection> items) {
    final pageCount = items.isEmpty ? 1 : (items.length / _pageSize).ceil();
    if (_page > pageCount) _page = pageCount;
    final start = ((_page - 1) * _pageSize).clamp(0, items.length);
    final end = (start + _pageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }

  void _handleNav(AdminNavDestination dest) => handleAdminNav(context, AdminNavDestination.manageClasses, dest);

  Future<void> _openManageClass(CourseSection s) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ManageClassDetailScreen(sectionId: s.id)),
    );
    _load();
  }

  Future<void> _deleteSelected() async {
    final count = _selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete classes?'),
        content: Text('This will permanently delete $count class${count == 1 ? '' : 'es'}. This cannot be undone.'),
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
    await _repository.deleteSections(_selected.toList());
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
      return _buildMobileScaffold(context);
    }
    return AdminScaffold(
      selected: AdminNavDestination.manageClasses,
      onDestinationSelected: _handleNav,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 20),
          _buildClassesCard(),
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
    final sections = _filtered;
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: const AdminMobileTopBar.detail(title: 'Manage Classes'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Class sections created when a lecturer is assigned to a course, from Manage Assigned Courses.',
                style: AdminTypography.bodyMd(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                style: AdminTypography.bodySm(color: AdminColors.onSurface),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AdminColors.surfaceContainerLowest,
                  hintText: 'Search by section, course, or lecturer...',
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
                  itemLabel: 'class',
                  onDeselectAll: () => setState(_selected.clear),
                  onDelete: _deleteSelected,
                ),
              ],
              const SizedBox(height: 16),
              if (sections.isEmpty)
                Padding(padding: const EdgeInsets.all(24), child: Text('No classes found.', style: AdminTypography.bodyMd()))
              else ...[
                for (final s in _paged(sections)) ...[
                  _mobileSectionCard(s),
                  const SizedBox(height: 12),
                ],
                AdminPagination(
                  totalItems: sections.length,
                  page: _page,
                  pageSize: _pageSize,
                  itemLabel: 'class',
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

  Widget _mobileSectionCard(CourseSection s) {
    final selected = _selected.contains(s.id);
    final unassigned = s.lecturerId == null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: selected,
            onChanged: (v) => setState(() => v == true ? _selected.add(s.id) : _selected.remove(s.id)),
            activeColor: AdminColors.primaryContainer,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.sectionCode, style: AdminTypography.titleSm()),
                Text(s.courseTitle, style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
                Text(s.courseCode, style: AdminTypography.labelSm()),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      unassigned ? 'Unassigned' : (s.lecturerName ?? '—'),
                      style: AdminTypography.labelSm(color: unassigned ? AdminColors.onSurfaceVariant : AdminColors.onSurface),
                    ),
                    Text(s.scheduleText, style: AdminTypography.labelSm()),
                    if (s.cohort != null)
                      Text('${s.cohortCode ?? '—'} - ${s.cohort}${s.cohortYear == null ? '' : ' (${s.cohortYear})'}', style: AdminTypography.labelSm()),
                    Text('${s.enrolledCount} / ${s.capacity}', style: AdminTypography.labelSm()),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: () => _openManageClass(s),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminColors.primary,
                      backgroundColor: AdminColors.surfaceContainerLow,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: AdminTypography.labelSm(),
                    ),
                    child: const Text('Manage'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Manage Classes', style: AdminTypography.headlineLg()),
        const SizedBox(height: 2),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            'Class sections created when a lecturer is assigned to a course, from Manage Assigned Courses.',
            style: AdminTypography.bodyMd(),
          ),
        ),
      ],
    );
  }

  Widget _buildClassesCard() {
    final sections = _filtered;
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
                hintText: 'Search class by section code, course, or lecturer...',
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
                    Text('${_selected.length} class${_selected.length == 1 ? '' : 'es'} selected', style: AdminTypography.titleSm()),
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
          if (sections.isNotEmpty) _headerRow(),
          if (sections.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text('No classes found.', style: AdminTypography.bodyMd()),
            )
          else
            Column(children: [for (final s in _paged(sections)) _sectionRow(s)]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AdminPagination(
              totalItems: sections.length,
              page: _page,
              pageSize: _pageSize,
              itemLabel: 'class',
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
          const SizedBox(width: 48),
          Expanded(flex: 3, child: _sortHeader('Section', _SortColumn.section)),
          Expanded(flex: 4, child: _sortHeader('Course', _SortColumn.course)),
          Expanded(flex: 3, child: _sortHeader('Lecturer', _SortColumn.lecturer)),
          const Expanded(flex: 3, child: SizedBox()),
          Expanded(flex: 3, child: _sortHeader('Cohort', _SortColumn.cohort)),
          Expanded(flex: 1, child: _sortHeader('Year', _SortColumn.year)),
          Expanded(flex: 2, child: _sortHeader('Enrolled', _SortColumn.enrolled)),
          const SizedBox(width: 110),
        ],
      ),
    );
  }

  Widget _sectionRow(CourseSection s) {
    final selected = _selected.contains(s.id);
    final unassigned = s.lecturerId == null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AdminColors.surfaceContainer))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: selected,
            onChanged: (v) => setState(() => v == true ? _selected.add(s.id) : _selected.remove(s.id)),
            activeColor: AdminColors.primaryContainer,
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(s.sectionCode, style: AdminTypography.titleSm()),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.courseTitle, style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis),
                  Text(s.courseCode, style: AdminTypography.labelSm()),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: unassigned
                  ? Text('Unassigned', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant))
                  : Text(s.lecturerName ?? '—', style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(s.scheduleText, style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                s.cohort == null ? '—' : '${s.cohortCode ?? '—'} - ${s.cohort}',
                style: AdminTypography.bodySm(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(s.cohortYear == null ? '—' : '${s.cohortYear}', style: AdminTypography.bodySm()),
          ),
          Expanded(
            flex: 2,
            child: Text('${s.enrolledCount} / ${s.capacity}', style: AdminTypography.labelSm()),
          ),
          SizedBox(
            width: 110,
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => _openManageClass(s),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminColors.primary,
                  backgroundColor: AdminColors.surfaceContainerLow,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: AdminTypography.labelSm(),
                ),
                child: const Text('Manage'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
