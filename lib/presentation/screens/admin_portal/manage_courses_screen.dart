import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_courses_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/admin_course.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_mobile_top_bar.dart';
import 'widgets/admin_mobile_bottom_nav.dart';
import 'widgets/admin_nav.dart';
import 'widgets/admin_more_menu.dart';
import 'widgets/admin_mobile_selection_bar.dart';
import 'widgets/admin_pagination.dart';
import 'course_form_screen.dart';

// ---------------------------------------------------------------------------
// ManageCoursesScreen – course catalogue master data. Lecturer/section
// assignment against these courses (already modeled by course_sections /
// lecturer_courses) is built on top of this later.
// ---------------------------------------------------------------------------
class ManageCoursesScreen extends StatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

enum _SortColumn { code, title, category, credits }

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  final _repository = SupabaseAdminCoursesRepositoryImpl(Supabase.instance.client);
  bool _isLoading = true;
  List<AdminCourse> _courses = [];
  final Set<String> _selected = {};
  final _searchController = TextEditingController();
  String _query = '';
  _SortColumn _sortColumn = _SortColumn.code;
  bool _sortAscending = true;
  int _page = 1;
  int _pageSize = adminPageSizeOptions.first;

  static const _categoryLabels = {
    'techData': 'Technical & Data',
    'compliance': 'Compliance',
    'aiTools': 'AI & Tools',
    'productivity': 'Productivity & Soft Skills',
  };

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
    final courses = await _repository.getCourses();
    if (!mounted) return;
    setState(() {
      _courses = courses;
      _isLoading = false;
    });
  }

  List<AdminCourse> get _filtered {
    final courses = _query.isEmpty
        ? _courses
        : _courses.where((c) => c.courseCode.toLowerCase().contains(_query) || c.courseTitle.toLowerCase().contains(_query)).toList();
    final sorted = [...courses];
    sorted.sort((a, b) {
      final int cmp;
      switch (_sortColumn) {
        case _SortColumn.code:
          cmp = a.courseCode.toLowerCase().compareTo(b.courseCode.toLowerCase());
        case _SortColumn.title:
          cmp = a.courseTitle.toLowerCase().compareTo(b.courseTitle.toLowerCase());
        case _SortColumn.category:
          cmp = (_categoryLabels[a.category] ?? a.category).toLowerCase().compareTo((_categoryLabels[b.category] ?? b.category).toLowerCase());
        case _SortColumn.credits:
          cmp = a.credits.compareTo(b.credits);
      }
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  List<AdminCourse> _paged(List<AdminCourse> items) {
    final pageCount = items.isEmpty ? 1 : (items.length / _pageSize).ceil();
    if (_page > pageCount) _page = pageCount;
    final start = ((_page - 1) * _pageSize).clamp(0, items.length);
    final end = (start + _pageSize).clamp(0, items.length);
    return items.sublist(start, end);
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

  void _handleNav(AdminNavDestination dest) => handleAdminNav(context, AdminNavDestination.manageCourses, dest);

  Future<void> _openAddCourse() async {
    final saved = await Navigator.of(context).push<AdminCourse>(
      MaterialPageRoute(builder: (_) => const CourseFormScreen()),
    );
    if (saved != null) _load();
  }

  Future<void> _openEditCourse(AdminCourse c) async {
    final saved = await Navigator.of(context).push<AdminCourse>(
      MaterialPageRoute(builder: (_) => CourseFormScreen(courseId: c.id)),
    );
    if (saved != null) _load();
  }

  Future<void> _deleteSelected() async {
    final count = _selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete courses?'),
        content: Text('This will permanently delete $count course${count == 1 ? '' : 's'}, including any modules and materials under them. This cannot be undone.'),
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
    await _repository.deleteCourses(_selected.toList());
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
      selected: AdminNavDestination.manageCourses,
      onDestinationSelected: _handleNav,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 20),
          _buildCatalogueCard(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Mobile (<700px) layout — root bottom-nav tab, card list instead of the
  // desktop table's fixed-width columns.
  // ---------------------------------------------------------------------

  Widget _buildMobileScaffold(BuildContext context) {
    final courses = _filtered;
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: const AdminMobileTopBar.root(title: 'Courses'),
      bottomNavigationBar: AdminMobileBottomNav(
        selected: AdminMobileTab.courses,
        onTap: (tab) => handleAdminMobileTab(context, AdminMobileTab.courses, tab),
        onMore: () => showAdminMoreMenu(context),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Institutional course catalogue. Lecturer and section assignment can be done afterward.', style: AdminTypography.bodyMd()),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _openAddCourse,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add New Course'),
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
                  hintText: 'Search course by code or title...',
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
                  itemLabel: 'course',
                  onDeselectAll: () => setState(_selected.clear),
                  onDelete: _deleteSelected,
                ),
              ],
              const SizedBox(height: 16),
              if (courses.isEmpty)
                Padding(padding: const EdgeInsets.all(24), child: Text('No courses found.', style: AdminTypography.bodyMd()))
              else ...[
                for (final c in _paged(courses)) ...[
                  _mobileCourseCard(c),
                  const SizedBox(height: 12),
                ],
                AdminPagination(
                  totalItems: courses.length,
                  page: _page,
                  pageSize: _pageSize,
                  itemLabel: 'course',
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

  Widget _mobileCourseCard(AdminCourse c) {
    final selected = _selected.contains(c.id);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: selected,
                onChanged: (v) => setState(() => v == true ? _selected.add(c.id) : _selected.remove(c.id)),
                activeColor: AdminColors.primaryContainer,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.courseTitle, style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis),
                    Text(c.courseCode, style: AdminTypography.labelSm()),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _openEditCourse(c),
                icon: const Icon(Icons.edit_outlined, size: 18, color: AdminColors.onSurfaceVariant),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(9999)),
                child: Text(_categoryLabels[c.category] ?? c.category, style: AdminTypography.labelSm(color: AdminColors.onSurface)),
              ),
              Text('${c.credits} cr', style: AdminTypography.labelSm()),
            ],
          ),
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
            Text('Manage Courses', style: AdminTypography.headlineLg()),
            const SizedBox(height: 2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Text('Institutional course catalogue. Lecturer and section assignment can be done afterward.', style: AdminTypography.bodyMd()),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _openAddCourse,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('+ Add New Course'),
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

  Widget _buildCatalogueCard() {
    final courses = _filtered;
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
                hintText: 'Search course by code or title...',
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
                    Text('${_selected.length} course${_selected.length == 1 ? '' : 's'} selected', style: AdminTypography.titleSm()),
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
          if (courses.isNotEmpty) _headerRow(),
          if (courses.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text('No courses found.', style: AdminTypography.bodyMd()),
            )
          else
            Column(children: [for (final c in _paged(courses)) _courseRow(c)]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AdminPagination(
              totalItems: courses.length,
              page: _page,
              pageSize: _pageSize,
              itemLabel: 'course',
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 40),
          Expanded(flex: 2, child: _sortHeader('Code', _SortColumn.code)),
          Expanded(flex: 5, child: _sortHeader('Course', _SortColumn.title)),
          Expanded(flex: 3, child: _sortHeader('Category', _SortColumn.category)),
          Expanded(flex: 2, child: _sortHeader('Credits', _SortColumn.credits)),
        ],
      ),
    );
  }

  Widget _courseRow(AdminCourse c) {
    final selected = _selected.contains(c.id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AdminColors.surfaceContainer))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: selected,
            onChanged: (v) => setState(() => v == true ? _selected.add(c.id) : _selected.remove(c.id)),
            activeColor: AdminColors.primaryContainer,
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(c.courseCode, style: AdminTypography.labelSm(), overflow: TextOverflow.ellipsis),
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                children: [
                  Flexible(child: Text(c.courseTitle, style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _openEditCourse(c),
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(9999)),
                child: Text(
                  _categoryLabels[c.category] ?? c.category,
                  style: AdminTypography.labelSm(color: AdminColors.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('${c.credits} cr', style: AdminTypography.labelSm()),
          ),
        ],
      ),
    );
  }
}
