import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/main.dart' show routeObserver;
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/domain/models/enrolled_course.dart';
import 'package:stitch_aiei_lms/domain/models/course_stats.dart';
import 'package:stitch_aiei_lms/domain/models/critical_action_item.dart';
import 'package:stitch_aiei_lms/presentation/screens/course_info/course_content_screen.dart';
import 'package:stitch_aiei_lms/presentation/screens/certifications_badges/certifications_badges_screen.dart';
import 'controllers/courses_controller.dart';
import 'controllers/courses_state.dart';
import 'widgets/portal_header.dart';
import 'widgets/portal_sidebar.dart';
import 'widgets/telemetry_banner.dart';
import 'widgets/course_filters_bar.dart';
import 'widgets/tags_filter_row.dart';
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
    extends ConsumerState<EnrolledCoursesCatalogueScreen> with RouteAware {
  int _sidebarIndex = 0;

  @override
  void initState() {
    super.initState();
    // Progress/badges/tags are admin- or lecturer-editable elsewhere in the
    // app, so always reload fresh from the DB whenever this screen is
    // (re)created rather than trusting whatever the provider last cached.
    Future.microtask(() => ref.read(coursesControllerProvider.notifier).loadInitialData());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // A pushed screen (e.g. viewing course content) popped back to this
    // one — progress/badges may have changed server-side since this
    // screen's provider state was last loaded, so refresh it.
    ref.read(coursesControllerProvider.notifier).loadInitialData();
  }

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
      appBar: const PortalHeader(),
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
                            // Section 1: Top Stat Telemetry & Critical Action
                            TelemetryBanner(
                              stats: state.stats,
                              criticalActions: state.criticalActions,
                              onOpenAction: (action) => _openCriticalAction(context, action),
                            ),

                            const SizedBox(height: 24),

                            // Section 2: Tags (horizontally scrollable, click to
                            // filter) + Search & Sort, sharing one row.
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: TagsFilterRow(
                                    tags: state.availableTags,
                                    selectedTag: state.selectedTag,
                                    onSelectTag: notifier.selectTag,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                CourseFiltersBar(
                                  onSearchChanged: notifier.setSearchQuery,
                                  selectedSort: state.sortOption,
                                  onSortChanged: notifier.setSortOption,
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Section 4: Course Grid (Interactive Cards)
                            CourseGrid(
                              courses: state.filteredAndSortedCourses,
                              onCourseAction: (course) => _openCourse(context, course),
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

  void _openCourse(BuildContext context, EnrolledCourse course) {
    final sectionId = course.sectionId;
    if (sectionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You haven\'t been assigned to a class for this course yet.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CourseContentScreen(sectionId: sectionId, courseTitle: course.title)),
    );
  }

  void _openCriticalAction(BuildContext context, CriticalActionItem action) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseContentScreen(sectionId: action.sectionId, courseTitle: action.courseTitle),
      ),
    );
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
                    Text('My Enrolled Courses', style: AppTypography.headlineLg(color: AppColors.primary).copyWith(fontSize: 22)),
                    const SizedBox(height: 8),
                    if (state.stats != null) _buildMobileTelemetryChips(state.stats!),
                    const SizedBox(height: 16),
                    if (state.criticalActions.isNotEmpty) ...[
                      _buildMobileCriticalActionsCard(context, state.criticalActions),
                      const SizedBox(height: 16),
                    ],
                    TagsFilterRow(
                      tags: state.availableTags,
                      selectedTag: state.selectedTag,
                      onSelectTag: notifier.selectTag,
                    ),
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
          chip(Colors.transparent, 'BADGES', '${stats.badgesEarned}', icon: Icons.military_tech_outlined),
        ],
      ),
    );
  }

  Widget _buildMobileCriticalActionsCard(BuildContext context, List<CriticalActionItem> actions) {
    String dueText(CriticalActionItem item) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final due = DateTime(item.dueDate.year, item.dueDate.month, item.dueDate.day);
      final diff = due.difference(today).inDays;
      if (diff < 0) return 'Overdue by ${-diff}d';
      if (diff == 0) return 'Due Today';
      return 'Due in ${diff}d';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 12, offset: Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('CRITICAL ACTION', style: AppTypography.labelSm(color: AppColors.errorContainer)),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            InkWell(
              onTap: () => _openCriticalAction(context, actions[i]),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(actions[i].type == 'exam' ? Icons.quiz_outlined : Icons.assignment_outlined, size: 16, color: const Color(0xFF6FFBBE)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(actions[i].title, style: AppTypography.bodySm(color: Colors.white).copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(actions[i].courseTitle, style: AppTypography.labelSm(color: const Color(0xFFBCC7DE)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Text(dueText(actions[i]), style: AppTypography.labelSm(color: const Color(0xFFBCC7DE)).copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

}
