import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/domain/models/enrolled_course.dart';
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
import 'widgets/enroll_target_picker.dart';
import 'widgets/course_grid.dart';
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
  void initState() {
    super.initState();
    // Progress/badges/tags are admin- or lecturer-editable elsewhere in the
    // app, so always reload fresh from the DB whenever this screen is
    // (re)created rather than trusting whatever the provider last cached.
    Future.microtask(() => ref.read(coursesControllerProvider.notifier).loadInitialData());
  }

  /// Reloads after returning from a screen that may have changed
  /// progress/badges server-side (e.g. viewing course content). Deliberately
  /// NOT done via RouteObserver.didPopNext — that also fires when a
  /// same-screen popup route pops (a DropdownButton's menu is itself a
  /// pushed route), which was wiping the student's Year/Cohort selection
  /// back to its default every time they picked a dropdown value.
  Future<void> _pushAndReload(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
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
                                TagsFilterRow(
                                  tags: state.availableTags,
                                  selectedTag: state.selectedTag,
                                  onSelectTag: notifier.selectTag,
                                ),
                                const SizedBox(width: 16),
                                Flexible(
                                  child: CourseFiltersBar(
                                    onSearchChanged: notifier.setSearchQuery,
                                    selectedSort: state.sortOption,
                                    onSortChanged: notifier.setSortOption,
                                    availableYears: state.availableYears,
                                    selectedYear: state.selectedYear,
                                    onYearChanged: notifier.selectYear,
                                    cohortNames: state.selectedYear == null ? const [] : state.cohortNamesForYear(state.selectedYear!),
                                    selectedCohort: state.selectedCohort,
                                    onCohortChanged: notifier.selectCohort,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Section 4: Course Grid (Interactive Cards)
                            CourseGrid(
                              courses: state.filteredAndSortedCourses,
                              onCourseAction: (course) => _openCourse(context, course),
                            ),

                            if (state.compulsoryCourses.isNotEmpty) ...[
                              const SizedBox(height: 40),
                              Text('Compulsory for You', style: AppTypography.headlineLg(color: AppColors.primary).copyWith(fontSize: 22)),
                              const SizedBox(height: 4),
                              Text(
                                'Required for your role — not yet on your enrolled list.',
                                style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  TagsFilterRow(
                                    tags: state.availableCompulsoryTags,
                                    selectedTag: state.selectedCompulsoryTag,
                                    onSelectTag: notifier.selectCompulsoryTag,
                                  ),
                                  const SizedBox(width: 16),
                                  Flexible(
                                    child: CourseFiltersBar(
                                      showYearCohort: false,
                                      onSearchChanged: notifier.setCompulsorySearchQuery,
                                      selectedSort: state.compulsorySortOption,
                                      onSortChanged: notifier.setCompulsorySortOption,
                                      availableYears: const [],
                                      selectedYear: null,
                                      onYearChanged: (_) {},
                                      cohortNames: const [],
                                      selectedCohort: null,
                                      onCohortChanged: (_) {},
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Align(alignment: Alignment.centerLeft, child: _enrollTargetPicker(state, notifier)),
                              const SizedBox(height: 24),
                              CourseGrid(
                                courses: state.filteredCompulsoryCourses,
                                onCourseAction: (course) => _enrollInCompulsoryCourse(context, course),
                              ),
                            ],

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

  Future<void> _enrollInCompulsoryCourse(BuildContext context, EnrolledCourse course) async {
    final enrolled = await ref.read(coursesControllerProvider.notifier).enrollInCompulsoryCourse(course.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enrolled ? 'Enrolled in ${course.title}.' : 'No class available for the selected cohort as of now, please try again later.',
        ),
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
    _pushAndReload(CourseContentScreen(sectionId: sectionId, courseTitle: course.title));
  }

  void _openCriticalAction(BuildContext context, CriticalActionItem action) {
    _pushAndReload(CourseContentScreen(sectionId: action.sectionId, courseTitle: action.courseTitle));
  }

  // Mobile (< 700px) layout — the same sections as desktop (telemetry banner +
  // critical actions, tag/search/sort/year/cohort filters, the course grid and
  // the "Compulsory for You" block). Each desktop widget is already
  // responsive, so they are reused as-is; only the shell (compact top bar and
  // bottom nav instead of header + sidebar) differs.
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
                    TelemetryBanner(
                      stats: state.stats,
                      criticalActions: state.criticalActions,
                      onOpenAction: (action) => _openCriticalAction(context, action),
                    ),
                    const SizedBox(height: 24),
                    TagsFilterRow(
                      tags: state.availableTags,
                      selectedTag: state.selectedTag,
                      onSelectTag: notifier.selectTag,
                      expand: true,
                    ),
                    const SizedBox(height: 12),
                    CourseFiltersBar(
                      alignment: WrapAlignment.start,
                      onSearchChanged: notifier.setSearchQuery,
                      selectedSort: state.sortOption,
                      onSortChanged: notifier.setSortOption,
                      availableYears: state.availableYears,
                      selectedYear: state.selectedYear,
                      onYearChanged: notifier.selectYear,
                      cohortNames: state.selectedYear == null ? const [] : state.cohortNamesForYear(state.selectedYear!),
                      selectedCohort: state.selectedCohort,
                      onCohortChanged: notifier.selectCohort,
                    ),
                    const SizedBox(height: 24),
                    CourseGrid(
                      courses: state.filteredAndSortedCourses,
                      onCourseAction: (course) => _openCourse(context, course),
                    ),
                    if (state.compulsoryCourses.isNotEmpty) ...[
                      const SizedBox(height: 40),
                      Text('Compulsory for You', style: AppTypography.headlineLg(color: AppColors.primary).copyWith(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(
                        'Required for your role — not yet on your enrolled list.',
                        style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      TagsFilterRow(
                        tags: state.availableCompulsoryTags,
                        selectedTag: state.selectedCompulsoryTag,
                        onSelectTag: notifier.selectCompulsoryTag,
                        expand: true,
                      ),
                      const SizedBox(height: 12),
                      CourseFiltersBar(
                        showYearCohort: false,
                        alignment: WrapAlignment.start,
                        onSearchChanged: notifier.setCompulsorySearchQuery,
                        selectedSort: state.compulsorySortOption,
                        onSortChanged: notifier.setCompulsorySortOption,
                        availableYears: const [],
                        selectedYear: null,
                        onYearChanged: (_) {},
                        cohortNames: const [],
                        selectedCohort: null,
                        onCohortChanged: (_) {},
                      ),
                      const SizedBox(height: 12),
                      Align(alignment: Alignment.centerLeft, child: _enrollTargetPicker(state, notifier)),
                      const SizedBox(height: 24),
                      CourseGrid(
                        courses: state.filteredCompulsoryCourses,
                        onCourseAction: (course) => _enrollInCompulsoryCourse(context, course),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _enrollTargetPicker(CoursesState state, CoursesNotifier notifier) {
    final year = state.effectiveCompulsoryYear;
    return EnrollTargetPicker(
      years: state.availableCompulsoryYears,
      selectedYear: year,
      onYearChanged: notifier.selectCompulsoryYear,
      cohortNames: year == null ? const [] : state.compulsoryCohortNamesForYear(year),
      selectedCohort: state.effectiveCompulsoryCohort,
      onCohortChanged: notifier.selectCompulsoryCohort,
    );
  }
}
