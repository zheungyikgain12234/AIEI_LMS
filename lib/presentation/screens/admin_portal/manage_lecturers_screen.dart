import 'package:stitch_aiei_lms/core/utils/refresh_on_return.dart';
import 'package:stitch_aiei_lms/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/presentation/widgets/skeleton.dart';
import 'package:stitch_aiei_lms/core/theme/ui_contrast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturers_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/lecturer.dart';
import 'widgets/admin_no_results.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_mobile_top_bar.dart';
import 'widgets/admin_mobile_bottom_nav.dart';
import 'widgets/admin_nav.dart';
import 'widgets/admin_more_menu.dart';
import 'widgets/admin_mobile_selection_bar.dart';
import 'widgets/admin_pagination.dart';
import 'lecturer_form_screen.dart';
import 'lecturer_course_assignment_screen.dart';
import 'reassign_orphaned_classes_screen.dart';

// ---------------------------------------------------------------------------
// ManageLecturersScreen – Stitch "Manage Lecturers" faithful Flutter
// conversion.
// ---------------------------------------------------------------------------
class ManageLecturersScreen extends StatefulWidget {
  const ManageLecturersScreen({super.key});

  @override
  State<ManageLecturersScreen> createState() => _ManageLecturersScreenState();
}

enum _SortColumn { code, name, department, status }

class _ManageLecturersScreenState extends State<ManageLecturersScreen> with RefreshOnReturn<ManageLecturersScreen> {
  @override
  void onReturnedTo() => _load();

  final _repository = SupabaseLecturersRepositoryImpl(Supabase.instance.client);
  bool _isLoading = true;
  List<Lecturer> _lecturers = [];
  Map<String, List<String>> _courseCodesByLecturer = {};
  final Set<String> _selected = {};
  _SortColumn _sortColumn = _SortColumn.name;
  bool _sortAscending = true;
  int _page = 1;
  int _pageSize = adminPageSizeOptions.first;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  List<Lecturer> get _filteredLecturers {
    if (_query.isEmpty) return _lecturers;
    return _lecturers.where((l) =>
        l.name.toLowerCase().contains(_query) ||
        l.lecturerCode.toLowerCase().contains(_query) ||
        l.email.toLowerCase().contains(_query) ||
        l.department.toLowerCase().contains(_query)).toList();
  }

  List<Lecturer> get _sortedLecturers {
    final sorted = [..._filteredLecturers];
    sorted.sort((a, b) {
      final int cmp;
      switch (_sortColumn) {
        case _SortColumn.code:
          cmp = a.lecturerCode.toLowerCase().compareTo(b.lecturerCode.toLowerCase());
        case _SortColumn.name:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case _SortColumn.department:
          cmp = a.department.toLowerCase().compareTo(b.department.toLowerCase());
        case _SortColumn.status:
          cmp = a.status.toLowerCase().compareTo(b.status.toLowerCase());
      }
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  List<Lecturer> get _pagedLecturers {
    final sorted = _sortedLecturers;
    final pageCount = sorted.isEmpty ? 1 : (sorted.length / _pageSize).ceil();
    if (_page > pageCount) _page = pageCount;
    final start = ((_page - 1) * _pageSize).clamp(0, sorted.length);
    final end = (start + _pageSize).clamp(0, sorted.length);
    return sorted.sublist(start, end);
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {
          _query = _searchController.text.trim().toLowerCase();
          _page = 1;
        }));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final lecturers = await _repository.getLecturers();
    final codes = await _repository.getLecturerCourseCodes();
    if (!mounted) return;
    setState(() {
      _lecturers = lecturers;
      _courseCodesByLecturer = codes;
      _isLoading = false;
    });
  }

  void _handleNav(AdminNavDestination dest) =>
      handleAdminNav(context, AdminNavDestination.manageLecturers, dest);

  Future<void> _openAssignedCourses(Lecturer l) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LecturerCourseAssignmentScreen(lecturerId: l.id)),
    );
    _load();
  }

  Future<void> _openAddLecturer() async {
    final saved = await Navigator.of(context).push<Lecturer>(
      MaterialPageRoute(builder: (_) => const LecturerFormScreen()),
    );
    if (saved != null) _load();
  }

  Future<void> _openEditLecturer(Lecturer l) async {
    final saved = await Navigator.of(context).push<Lecturer>(
      MaterialPageRoute(builder: (_) => LecturerFormScreen(lecturerId: l.id)),
    );
    if (saved != null) _load();
  }

  Future<void> _deleteSelected() async {
    final count = _selected.length;
    final orphaned = await _repository.getSectionsForLecturers(_selected.toList());
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete lecturers?'),
        content: Text(
          'This will permanently delete $count lecturer${count == 1 ? '' : 's'}. This cannot be undone.'
          '${orphaned.isEmpty ? '' : '\n\nThey still teach ${orphaned.length} class${orphaned.length == 1 ? '' : 'es'}, '
              'which you will be asked to reassign first. Nobody is deleted until every class has a new lecturer.'}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel', textAlign: TextAlign.center)),
          // With classes to reassign, nothing is deleted yet: this only opens the
          // reassignment review. With none, this is the final confirmation.
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: orphaned.isEmpty ? FilledButton.styleFrom(backgroundColor: AdminColors.error) : null,
            child: Text(orphaned.isEmpty ? 'Delete' : 'Review', textAlign: TextAlign.center),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (orphaned.isNotEmpty) {
      final deleted = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ReassignOrphanedClassesScreen(
            lecturersToDelete: _lecturers.where((l) => _selected.contains(l.id)).toList(),
          ),
        ),
      );
      if (!mounted) return;
      // Reassigned classes change regardless of whether the delete finished.
      if (deleted != true) {
        await _load();
        return;
      }
    } else {
      await _repository.deleteLecturers(_selected.toList());
      if (!mounted) return;
    }
    showSuccessSnackBar(context, 'Lecturer(s) deleted.');
    setState(_selected.clear);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show the page frame straight away; only the content area is a placeholder.
      return MediaQuery.of(context).size.width <= 900 ? const SkeletonScaffold() : AdminScaffold(selected: AdminNavDestination.manageLecturers, onDestinationSelected: _handleNav, body: const SkeletonPage());
    }
    // Only rows still visible (after a search or filter) can stay selected, so
    // the "N selected" count and bulk actions never include hidden records.
    final visibleIds = {for (final r in _filteredLecturers) r.id};
    _selected.retainWhere(visibleIds.contains);
    if (MediaQuery.of(context).size.width <= 900) {
      return _buildMobileScaffold(context);
    }
    return AdminScaffold(
      selected: AdminNavDestination.manageLecturers,
      onDestinationSelected: _handleNav,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 16),
          _buildInstructionBanner(),
          const SizedBox(height: 20),
          _buildMetrics(),
          const SizedBox(height: 20),
          _buildDirectoryCard(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 16,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage and Assign Lecturers', style: AdminTypography.headlineLg()),
            const SizedBox(height: 2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Text('Add lecturers, set their login details and department, and assign them to the courses they teach.', style: AdminTypography.bodyMd()),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _openAddLecturer,
          icon: const Icon(Icons.person_add_outlined, size: 18),
          label: const Text('Add New Lecturer', textAlign: TextAlign.center),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.primaryContainer,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AdminColors.primaryFixed,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: AdminColors.primary, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.check_box_outlined, color: AdminColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AdminTypography.bodySm(color: AdminColors.onPrimaryFixed),
                children: [
                  TextSpan(text: 'Tip: ', style: AdminTypography.titleSm(color: AdminColors.onPrimaryFixed)),
                  const TextSpan(text: 'Check the boxes next to lecturer rows to select them for bulk actions. To assign courses to a lecturer, click '),
                  TextSpan(text: 'Manage Assigned Courses', style: AdminTypography.bodySm(color: AdminColors.onPrimaryFixed).copyWith(fontWeight: FontWeight.w700)),
                  const TextSpan(text: ' on that lecturer\'s row.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int get _activeFacultyCount => _lecturers.where((l) => l.status == 'Active').length;

  int get _totalAssignedCourses => _courseCodesByLecturer.values.fold(0, (sum, courses) => sum + courses.length);

  Widget _buildMetrics() {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 700 ? 2 : 1;
      final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
      final total = _lecturers.length;
      final activeProgress = total == 0 ? 0.0 : _activeFacultyCount / total;
      final assignedProgress = total == 0 ? 0.0 : (_courseCodesByLecturer.values.where((c) => c.isNotEmpty).length / total);
      final cards = [
        _metricCard('TOTAL LECTURERS', '$_activeFacultyCount Active', Icons.groups_outlined, 'of $total total lecturers', activeProgress),
        _metricCard('ASSIGNED COURSES', '$_totalAssignedCourses Assigned', Icons.menu_book_outlined,
            '${(assignedProgress * 100).round()}% of lecturers have an assignment', assignedProgress),
      ];
      return Wrap(spacing: 16, runSpacing: 16, children: cards.map((c) => SizedBox(width: width, child: c)).toList());
    });
  }

  Widget _metricCard(String label, String value, IconData icon, String footer, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(label, style: AdminTypography.labelMd().copyWith(fontWeight: FontWeight.w600))),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: AdminColors.primary, size: 18),
            ),
          ]),
          const SizedBox(height: 8),
          Text(value, style: AdminTypography.dataMetric()),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(child: Text(footer, style: AdminTypography.labelSm())),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(value: progress, minHeight: 4, backgroundColor: AdminColors.surfaceContainerLow, valueColor: const AlwaysStoppedAnimation<Color>(AdminColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryCard() {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AdminColors.surfaceContainerLow,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              style: AdminTypography.bodySm(color: AdminColors.onSurface),
              decoration: InputDecoration(
                isDense: true,
                fillColor: AdminColors.surfaceContainerLowest,
                hintText: 'Search by lecturer name, employee ID, email, or department...',
                prefixIcon: const Icon(Icons.search, size: 18, color: AdminColors.onSurfaceVariant),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                    Text('${_selected.length} lecturer${_selected.length == 1 ? '' : 's'} selected', style: AdminTypography.titleSm()),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(_selected.clear),
                      child: Text('Deselect all', style: AdminTypography.labelMd(color: AdminColors.secondary)),
                    ),
                  ]),
                  OutlinedButton.icon(
                    onPressed: _deleteSelected,
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
          if (_filteredLecturers.isNotEmpty) _headerRow(),
          if (_lecturers.isNotEmpty && _filteredLecturers.isEmpty)
            Padding(padding: const EdgeInsets.all(32), child: AdminNoResults(controller: _searchController, focusNode: _searchFocus)),
          Column(children: [for (final l in _pagedLecturers) _lecturerRow(l)]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AdminPagination(
              totalItems: _filteredLecturers.length,
              page: _page,
              pageSize: _pageSize,
              itemLabel: 'lecturer',
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
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: UiContrast.divider))),
      child: Row(
        children: [
          const SizedBox(width: 48),
          Expanded(flex: 2, child: _sortHeader('Code', _SortColumn.code)),
          Expanded(flex: 4, child: _sortHeader('Lecturer', _SortColumn.name)),
          Expanded(flex: 3, child: _sortHeader('Department', _SortColumn.department)),
          Expanded(flex: 2, child: _sortHeader('Status', _SortColumn.status)),
          const SizedBox(width: 170),
        ],
      ),
    );
  }

  Widget _lecturerRow(Lecturer l) {
    final selected = _selected.contains(l.id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: UiContrast.divider))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: selected,
            onChanged: (v) => setState(() => v == true ? _selected.add(l.id) : _selected.remove(l.id)),
            activeColor: AdminColors.primaryContainer,
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(l.lecturerCode, style: AdminTypography.labelSm(), overflow: TextOverflow.ellipsis),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(color: AdminColors.surfaceContainerHigh, shape: BoxShape.circle),
                    child: const Icon(Icons.person, color: AdminColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(l.name, style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis)),
                            if (l.accredited) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.verified, size: 14, color: AdminColors.secondary)),
                            const SizedBox(width: 2),
                            InkWell(
                              onTap: () => _openEditLecturer(l),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(Icons.edit_outlined, size: 14, color: AdminColors.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                        Text(l.title, style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
                        Text(l.email, style: AdminTypography.labelSm(), overflow: TextOverflow.ellipsis),
                      ],
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
                  Text(l.department, style: AdminTypography.titleSm()),
                  _CompetenciesList(competencies: l.competencies),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: l.status == 'Active' ? AdminColors.surfaceContainerLow : AdminColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: l.status == 'Active' ? AdminColors.primary : AdminColors.onSurfaceVariant, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l.status,
                      overflow: TextOverflow.ellipsis,
                      style: AdminTypography.labelSm(color: l.status == 'Active' ? AdminColors.primary : AdminColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ]),
              ),
            ),
          ),
          SizedBox(
            width: 170,
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => _openAssignedCourses(l),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AdminColors.primaryContainer,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: AdminTypography.labelSm(),
                ),
                child: const Text('Manage Assigned Courses', textAlign: TextAlign.center),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Mobile (≤ 900px) layout — the same content as desktop (title, tip,
  // metrics, search, bulk-select, directory, pagination); only the table
  // becomes one card per lecturer carrying the same fields as a table row.
  // ---------------------------------------------------------------------

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: const AdminMobileTopBar.root(title: 'Manage and Assign Lecturers'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(),
              const SizedBox(height: 16),
              _buildInstructionBanner(),
              const SizedBox(height: 16),
              _buildMetrics(),
              const SizedBox(height: 16),
              _mobileSearchField(),
              if (_selected.isNotEmpty) ...[
                const SizedBox(height: 12),
                adminMobileSelectionBar(
                  count: _selected.length,
                  itemLabel: 'lecturer',
                  onDeselectAll: () => setState(_selected.clear),
                  onDelete: _deleteSelected,
                ),
              ],
              const SizedBox(height: 16),
              if (_lecturers.isNotEmpty && _filteredLecturers.isEmpty)
                Padding(padding: const EdgeInsets.all(24), child: AdminNoResults(controller: _searchController, focusNode: _searchFocus)),
              for (final l in _pagedLecturers) ...[
                _mobileLecturerCard(l),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 4),
              AdminPagination(
                totalItems: _filteredLecturers.length,
                page: _page,
                pageSize: _pageSize,
                itemLabel: 'lecturer',
                onPageChanged: (p) => setState(() => _page = p),
                onPageSizeChanged: (s) => setState(() {
                  _pageSize = s;
                  _page = 1;
                }),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AdminMobileBottomNav(
        selected: AdminMobileTab.lecturers,
        onTap: (tab) => handleAdminMobileTab(context, AdminMobileTab.lecturers, tab),
        onMore: () => showAdminMoreMenu(context),
      ),
    );
  }

  Widget _mobileSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocus,
      style: AdminTypography.bodySm(color: AdminColors.onSurface),
      decoration: InputDecoration(
        isDense: true,
        fillColor: AdminColors.surfaceContainerLowest,
        hintText: 'Search by lecturer name, employee ID, email, or department...',
        prefixIcon: const Icon(Icons.search, size: 20, color: AdminColors.outline),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _mobileLecturerCard(Lecturer l) {
    final selected = _selected.contains(l.id);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: selected,
                onChanged: (v) => setState(() => v == true ? _selected.add(l.id) : _selected.remove(l.id)),
                activeColor: AdminColors.primaryContainer,
              ),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AdminColors.surfaceContainerHigh, shape: BoxShape.circle),
                child: const Icon(Icons.person, color: AdminColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.lecturerCode, style: AdminTypography.labelSm()),
                    Row(children: [
                      Flexible(child: Text(l.name, style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis)),
                      if (l.accredited) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.verified, size: 14, color: AdminColors.secondary)),
                    ]),
                    Text(l.title, style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
                    Text(l.email, style: AdminTypography.labelSm(), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(l.department, style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis),
                    _CompetenciesList(competencies: l.competencies),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _openEditLecturer(l),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.edit_outlined, size: 18, color: AdminColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: _mobileStatusPill(l)),
              const SizedBox(width: 8),
              _mobileCardActionButton(l),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileStatusPill(Lecturer l) {
    final active = l.status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AdminColors.surfaceContainerLow : AdminColors.surfaceContainer,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: active ? AdminColors.primary : AdminColors.onSurfaceVariant, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            l.status,
            overflow: TextOverflow.ellipsis,
            style: AdminTypography.labelSm(color: active ? AdminColors.primary : AdminColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ]),
    );
  }

  Widget _mobileCardActionButton(Lecturer l) {
    return OutlinedButton(
      onPressed: () => _openAssignedCourses(l),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AdminColors.primaryContainer,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: AdminTypography.labelSm(),
      ),
      child: const Text('Manage Assigned Courses', textAlign: TextAlign.center),
    );
  }
}

/// A lecturer's teaching competencies, one per line. Collapsed it shows just
/// the first one on a single line (so the row keeps its usual height) with a
/// down arrow, when there are more, that unfolds the rest.
class _CompetenciesList extends StatefulWidget {
  final List<String> competencies;

  const _CompetenciesList({required this.competencies});

  @override
  State<_CompetenciesList> createState() => _CompetenciesListState();
}

class _CompetenciesListState extends State<_CompetenciesList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final items = widget.competencies;
    if (items.isEmpty) return Text('—', style: AdminTypography.bodySm());
    final style = AdminTypography.bodySm();
    final more = items.length > 1;
    final shown = _expanded ? items : [items.first];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < shown.length; i++)
          Row(
            children: [
              Expanded(child: Text(shown[i], style: style, maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (i == 0 && more)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Tooltip(
                    message: _expanded ? 'Show fewer' : 'Show all ${items.length} teaching competencies',
                    child: Material(
                      color: const Color(0xFF0B3D91),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => setState(() => _expanded = !_expanded),
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
