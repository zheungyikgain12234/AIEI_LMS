import 'package:stitch_aiei_lms/core/utils/refresh_on_return.dart';
import 'package:stitch_aiei_lms/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/presentation/widgets/skeleton.dart';
import 'package:stitch_aiei_lms/core/theme/ui_contrast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_badge_catalog_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_courses_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_badge_course_mapping_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/badge_catalog_item.dart';
import 'package:stitch_aiei_lms/domain/models/admin_course.dart';
import 'widgets/admin_no_results.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_mobile_top_bar.dart';
import 'widgets/admin_nav.dart';
import 'widgets/searchable_dropdown.dart';

// ---------------------------------------------------------------------------
// BadgeCourseMappingScreen — "which badges does a given course award on
// completion?" Pick a course, then check/uncheck badges; each toggle is saved
// immediately to `course_badges`.
// ---------------------------------------------------------------------------
class BadgeCourseMappingScreen extends StatefulWidget {
  const BadgeCourseMappingScreen({super.key});

  @override
  State<BadgeCourseMappingScreen> createState() => _BadgeCourseMappingScreenState();
}

class _BadgeCourseMappingScreenState extends State<BadgeCourseMappingScreen> with RefreshOnReturn<BadgeCourseMappingScreen> {
  @override
  void onReturnedTo() => _load();

  final _badgesRepository = SupabaseAdminBadgeCatalogRepositoryImpl(Supabase.instance.client);
  final _coursesRepository = SupabaseAdminCoursesRepositoryImpl(Supabase.instance.client);
  final _mappingRepository = SupabaseBadgeCourseMappingRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  bool _isLoadingMapping = false;
  List<BadgeCatalogItem> _badges = [];
  List<AdminCourse> _courses = [];
  String? _selectedCourseId;
  Set<String> _mappedBadgeIds = {};

  /// badge id -> the course it is mapped to, across all courses. A badge can
  /// belong to only one course, so one mapped elsewhere can't be ticked here.
  Map<String, String> _courseByBadge = {};
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
    final badges = await _badgesRepository.getBadges();
    final courses = await _coursesRepository.getCourses();
    if (!mounted) return;
    setState(() {
      _badges = badges;
      _courses = courses;
      _selectedCourseId ??= courses.isEmpty ? null : courses.first.id;
      _isLoading = false;
    });
    if (_selectedCourseId != null) await _loadMapping(_selectedCourseId!);
  }

  Future<void> _loadMapping(String courseId) async {
    setState(() => _isLoadingMapping = true);
    final ids = await _mappingRepository.getBadgeIdsForCourse(courseId);
    final courseByBadge = await _mappingRepository.getCourseIdByBadge();
    if (!mounted) return;
    setState(() {
      _mappedBadgeIds = ids;
      _courseByBadge = courseByBadge;
      _isLoadingMapping = false;
    });
  }

  List<BadgeCatalogItem> get _filteredBadges {
    if (_query.isEmpty) return _badges;
    return _badges.where((b) => b.title.toLowerCase().contains(_query)).toList();
  }

  AdminCourse? get _selectedCourse {
    for (final c in _courses) {
      if (c.id == _selectedCourseId) return c;
    }
    return null;
  }

  void _handleNav(AdminNavDestination dest) =>
      handleAdminNav(context, AdminNavDestination.badgeCourseMapping, dest);

  Future<void> _toggleBadge(String badgeId, bool allowed) async {
    final courseId = _selectedCourseId;
    if (courseId == null) return;
    setState(() => allowed ? _mappedBadgeIds.add(badgeId) : _mappedBadgeIds.remove(badgeId));
    try {
      await _mappingRepository.setCourseForBadge(badgeId, courseId, allowed);
      if (mounted) {
        setState(() => allowed ? _courseByBadge[badgeId] = courseId : _courseByBadge.remove(badgeId));
        showSuccessSnackBar(context, 'Mapping updated.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => allowed ? _mappedBadgeIds.remove(badgeId) : _mappedBadgeIds.add(badgeId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update mapping: $e'), backgroundColor: AdminColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show the page frame straight away; only the content area is a placeholder.
      return MediaQuery.of(context).size.width <= 900 ? const SkeletonScaffold() : AdminScaffold(selected: AdminNavDestination.badgeCourseMapping, onDestinationSelected: _handleNav, body: const SkeletonPage());
    }
    if (MediaQuery.of(context).size.width <= 900) {
      return _buildMobileScaffold(context);
    }
    return AdminScaffold(
      selected: AdminNavDestination.badgeCourseMapping,
      onDestinationSelected: _handleNav,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 20),
          _buildCourseSelector(),
          const SizedBox(height: 20),
          _buildBadgesCard(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Badge ↔ Course Mapping', style: AdminTypography.headlineLg()),
        const SizedBox(height: 2),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            'Choose which badges each course can award (after admin approval). A badge can belong to only one course.',
            style: AdminTypography.bodyMd(),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseSelector() {
    if (_courses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
        child: Text('No courses exist yet.', style: AdminTypography.bodyMd(color: AdminColors.error)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: Row(
        children: [
          Text('Course', style: AdminTypography.labelMd(color: AdminColors.onSurfaceVariant)),
          const SizedBox(width: 12),
          Expanded(
            child: SearchableDropdownFormField<String>(
              initialValue: _selectedCourseId,
              isExpanded: true,
              style: AdminTypography.bodyMd(color: AdminColors.onSurface),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: [
                for (final c in _courses)
                  DropdownMenuItem(value: c.id, child: Text('${c.courseCode} — ${c.courseTitle}', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selectedCourseId = v);
                _loadMapping(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesCard() {
    final badges = _filteredBadges;
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
                hintText: 'Search badge by title...',
                prefixIcon: const Icon(Icons.search, size: 18, color: AdminColors.onSurfaceVariant),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_isLoadingMapping)
            const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())
          else if (badges.isEmpty)
            Padding(padding: const EdgeInsets.all(32), child: AdminNoResults(controller: _searchController, focusNode: _searchFocus))
          else
            Column(children: [for (final b in badges) _badgeRow(b)]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_mappedBadgeIds.length} of ${_badges.length} badges awarded by ${_selectedCourse?.courseTitle ?? 'this course'}',
                style: AdminTypography.bodySm(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeRow(BadgeCatalogItem b) {
    final allowed = _mappedBadgeIds.contains(b.id);
    final otherCourseId = _courseByBadge[b.id];
    final takenBy = otherCourseId != null && otherCourseId != _selectedCourseId
        ? _courses.where((c) => c.id == otherCourseId).map((c) => '${c.courseCode} — ${c.courseTitle}').firstOrNull
        : null;
    final locked = otherCourseId != null && otherCourseId != _selectedCourseId;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: UiContrast.divider))),
      child: Row(
        children: [
          Checkbox(
            value: allowed,
            onChanged: locked ? null : (v) => _toggleBadge(b.id, v ?? false),
            activeColor: AdminColors.primaryContainer,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.title, style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis),
                if (locked)
                  Text('Already assigned to ${takenBy ?? 'another course'}', style: AdminTypography.bodySm()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Mobile (≤ 900px) layout — a drill-in screen (back-arrow top bar, no
  // bottom nav; reached from the "More" menu).
  // ---------------------------------------------------------------------

  Widget _buildMobileScaffold(BuildContext context) {
    final badges = _filteredBadges;
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: const AdminMobileTopBar.detail(title: 'Badge ↔ Course Mapping'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(),
              const SizedBox(height: 16),
              _buildCourseSelector(),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                style: AdminTypography.bodySm(color: AdminColors.onSurface),
                decoration: InputDecoration(
                  isDense: true,
                  fillColor: AdminColors.surfaceContainerLowest,
                  hintText: 'Search badge by title...',
                  prefixIcon: const Icon(Icons.search, size: 18, color: AdminColors.onSurfaceVariant),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoadingMapping)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
              else if (badges.isEmpty)
                Padding(padding: const EdgeInsets.all(24), child: AdminNoResults(controller: _searchController, focusNode: _searchFocus))
              else
                Container(
                  decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [for (final b in badges) _badgeRow(b)]),
                ),
              const SizedBox(height: 12),
              Text(
                '${_mappedBadgeIds.length} of ${_badges.length} badges awarded by ${_selectedCourse?.courseTitle ?? 'this course'}',
                style: AdminTypography.bodySm(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
