import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/domain/models/enrolled_course.dart';
import 'package:stitch_aiei_lms/domain/models/course_stats.dart';
import 'package:stitch_aiei_lms/domain/models/urgent_notice.dart';
import 'package:stitch_aiei_lms/presentation/screens/course_info/course_info_screen.dart';
import 'package:stitch_aiei_lms/presentation/screens/course_info/course_info_screen_2.dart';
import 'package:stitch_aiei_lms/presentation/screens/certifications_badges/certifications_badges_screen.dart';
import 'package:stitch_aiei_lms/presentation/screens/faculty_portal/my_assigned_courses_screen.dart';
import 'controllers/courses_controller.dart';
import 'controllers/courses_state.dart';
import 'widgets/portal_header.dart';
import 'widgets/portal_sidebar.dart';
import 'widgets/telemetry_banner.dart';
import 'widgets/course_filters_bar.dart';
import 'widgets/course_grid.dart';
import 'widgets/mobile_course_card.dart';
import 'package:stitch_aiei_lms/presentation/widgets/mobile_bottom_nav.dart';
import 'package:stitch_aiei_lms/presentation/widgets/mobile_top_bar.dart';

const double _kMobileBreakpoint = 700;

class EnrolledCoursesCatalogueScreen extends ConsumerStatefulWidget {
  const EnrolledCoursesCatalogueScreen({super.key});

  @override
  ConsumerState<EnrolledCoursesCatalogueScreen> createState() =>
      _EnrolledCoursesCatalogueScreenState();
}

class _EnrolledCoursesCatalogueScreenState
    extends ConsumerState<EnrolledCoursesCatalogueScreen> {
  int _sidebarIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coursesControllerProvider);
    final notifier = ref.read(coursesControllerProvider.notifier);

    final isMobile = MediaQuery.of(context).size.width < _kMobileBreakpoint;
    if (isMobile) {
      return _buildMobileScaffold(context, state, notifier);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      // Fixed Desktop Portal Header
      appBar: PortalHeader(
        onSearch: (query) => notifier.setSearchQuery(query),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fixed Desktop Sidebar Navigation
          PortalSidebar(
            selectedIndex: _sidebarIndex,
            onDestinationSelected: (index) {
              if (index == 1) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const CertificationsBadgesScreen(),
                  ),
                );
                return;
              }
              setState(() => _sidebarIndex = index);
            },
            onOpenFacultyPortal: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyAssignedCoursesScreen()),
              );
            },
          ),

          // Scrollable Main Content Container
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondary,
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1440),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Section 1: Top Stat Telemetry & Urgent Action
                            TelemetryBanner(
                              stats: state.stats,
                              urgentNotice: state.urgentNotice,
                            ),

                            const SizedBox(height: 32),

                            // Section 2: Filter Tabs, Live Search & Sort Options
                            CourseFiltersBar(
                              selectedCategory: state.selectedCategory,
                              onSelectCategory: notifier.selectCategory,
                              onSearchChanged: notifier.setSearchQuery,
                              selectedSort: state.sortOption,
                              onSortChanged: notifier.setSortOption,
                              countForCategory: state.getCountForCategory,
                            ),

                            const SizedBox(height: 24),

                            // Section 3: Course Grid (Interactive Cards)
                            CourseGrid(
                              courses: state.filteredAndSortedCourses,
                              onCourseAction: (course) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => course.id == 'c2-oshe'
                                        ? CourseInfoScreen2(course: course)
                                        : CourseInfoScreen(course: course),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Mobile layout ─────────────────────────────────────────────────────────
  void _openCourse(BuildContext context, EnrolledCourse course) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => course.id == 'c2-oshe'
            ? CourseInfoScreen2(course: course)
            : CourseInfoScreen(course: course),
      ),
    );
  }

  IconData _categoryIcon(CourseCategory category) {
    switch (category) {
      case CourseCategory.all:
        return Icons.apps;
      case CourseCategory.compliance:
        return Icons.shield_outlined;
      case CourseCategory.techData:
        return Icons.code;
      case CourseCategory.aiTools:
        return Icons.smart_toy_outlined;
      case CourseCategory.productivity:
        return Icons.groups_outlined;
    }
  }

  Widget _buildMobileScaffold(BuildContext context, CoursesState state, CoursesNotifier notifier) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MobileTopBar(),
      bottomNavigationBar: MobileBottomNav(
        selectedIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CertificationsBadgesScreen()),
            );
          }
        },
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
          : SafeArea(
              top: false,
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 40,
                      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)]),
                      child: TextField(
                        onChanged: notifier.setSearchQuery,
                        style: AppTypography.bodyMd(color: AppColors.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Search courses, lessons and certifications',
                          hintStyle: AppTypography.bodyMd(color: AppColors.outline),
                          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.outline),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Text('My Enrolled Courses', style: AppTypography.headlineLg(color: AppColors.primary).copyWith(fontSize: 22))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(9999)),
                          child: Text('ACTIVE TERM', style: AppTypography.labelSm(color: AppColors.secondary).copyWith(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (state.stats != null) _buildMobileTelemetryChips(state.stats!),
                    const SizedBox(height: 16),
                    if (state.urgentNotice != null) ...[
                      _buildMobilePriorityCard(context, state.urgentNotice!),
                      const SizedBox(height: 16),
                    ],
                    _buildMobileFilterPills(state, notifier),
                    const SizedBox(height: 16),
                    for (final course in state.filteredAndSortedCourses) ...[
                      MobileCourseCard(course: course, onAction: () => _openCourse(context, course)),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
    );
  }


  Widget _buildMobileTelemetryChips(CourseStats stats) {
    Widget chip(Color dotColor, String label, String value, {IconData? icon}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: 14, color: AppColors.outline)
            else
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: AppTypography.labelSm(color: AppColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            Text(value, style: AppTypography.labelMd(color: AppColors.primary).copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          chip(AppColors.secondary, 'ENROLLED', '${stats.enrolledCourses}'),
          chip(AppColors.secondaryContainer, 'IN PROGRESS', '${stats.inProgressCourses}'),
          chip(AppColors.onTertiaryContainer, 'COMPLETED', '${stats.completedCourses}'),
          chip(Colors.transparent, 'LESSONS', '${stats.completedLessons}/${stats.totalLessons}', icon: Icons.menu_book_outlined),
          chip(Colors.transparent, 'BADGES', '${stats.badgesEarned}', icon: Icons.military_tech_outlined),
        ],
      ),
    );
  }

  Widget _buildMobilePriorityCard(BuildContext context, UrgentNotice notice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 12, offset: Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(9999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 13, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(notice.badgeText.toUpperCase(), style: AppTypography.labelSm(color: Colors.white).copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Text('REQUIRED COMPLIANCE', style: AppTypography.labelSm(color: const Color(0xFFBCC7DE))),
            ],
          ),
          const SizedBox(height: 10),
          Text(notice.title, style: AppTypography.headlineMd(color: Colors.white)),
          const SizedBox(height: 4),
          Text(notice.subtitle, style: AppTypography.bodySm(color: const Color(0xFFBCC7DE))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primaryContainer.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text('Module Completion', style: AppTypography.labelSm(color: const Color(0xFFBCC7DE))),
                    Text('${notice.progressPercentage}% Complete', style: AppTypography.labelSm(color: const Color(0xFF6FFBBE)).copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: LinearProgressIndicator(
                    value: notice.progressPercentage / 100,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6FFBBE)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(notice.dueText, style: AppTypography.labelSm(color: const Color(0xFFBCC7DE)), overflow: TextOverflow.ellipsis),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: Text(notice.ctaLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.onSecondary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilterPills(CoursesState state, CoursesNotifier notifier) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final category in CourseCategory.values) ...[
            _mobileFilterPill(
              icon: _categoryIcon(category),
              label: category.label,
              count: state.getCountForCategory(category),
              active: state.selectedCategory == category,
              onTap: () => notifier.selectCategory(category),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _mobileFilterPill({required IconData icon, required String label, required int count, required bool active, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.secondary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTypography.labelMd(color: active ? AppColors.onSecondary : AppColors.onSurfaceVariant)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: active ? Colors.white.withValues(alpha: 0.25) : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text('$count', style: AppTypography.labelSm(color: active ? AppColors.onSecondary : AppColors.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }
}
