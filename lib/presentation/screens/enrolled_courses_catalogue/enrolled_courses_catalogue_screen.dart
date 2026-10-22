import 'package:stitch_aiei_lms/core/utils/busy_overlay.dart';
import 'package:stitch_aiei_lms/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/domain/repositories/courses_repository.dart' show EnrollableClass;
import 'package:stitch_aiei_lms/domain/repositories/lecturers_repository.dart' show ScheduleConflictException;
import 'package:stitch_aiei_lms/presentation/widgets/skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/domain/models/enrolled_course.dart';
import 'package:stitch_aiei_lms/domain/models/critical_action_item.dart';
import 'package:stitch_aiei_lms/presentation/screens/course_info/course_content_screen.dart';
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
import 'package:stitch_aiei_lms/presentation/widgets/student_navigation.dart';

const double _kMobileBreakpoint = 900;

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
  /// pushed route), which was wiping the student's Year/Semester selection
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

    final isMobile = MediaQuery.of(context).size.width <= _kMobileBreakpoint;
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
              if (index != 0) {
                navigateStudentTab(context, index, current: 0);
                return;
              }
              setState(() => _sidebarIndex = index);
            },
          ),

          // Scrollable Main Content Container
          Expanded(
            child: SingleChildScrollView(
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
 statsReady: state.statsReady,
 actionsReady: state.actionsReady,
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
                                    programmeNames: state.availableProgrammes,
                                    selectedProgramme: state.selectedProgramme,
                                    onProgrammeChanged: notifier.selectProgramme,
                                    onSearchChanged: notifier.setSearchQuery,
                                    selectedSort: state.sortOption,
                                    onSortChanged: notifier.setSortOption,
                                    availableYears: state.availableYears,
                                    selectedYear: state.selectedYear,
                                    onYearChanged: notifier.selectYear,
                                    semesterNames: state.selectedYear == null ? const [] : state.semesterNamesForYear(state.selectedYear!),
                                    selectedSemester: state.selectedSemester,
                                    onSemesterChanged: notifier.selectSemester,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Section 4: Course Grid (Interactive Cards)
                            state.coursesReady ? CourseGrid(
                              courses: state.filteredAndSortedCourses,
                              onCourseAction: (course) => _openCourse(context, course),
                            ) : const SkeletonCourseGrid(),

                            if (!state.compulsoryReady) ...const [SizedBox(height: 40), Skeleton(width: 220, height: 26), SizedBox(height: 16), SkeletonCourseGrid(count: 3)] else if (state.compulsoryCourses.isNotEmpty) ...[
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
                                      showYearSemester: false,
                                      programmeNames: state.availableCompulsoryProgrammes,
                                      selectedProgramme: state.selectedCompulsoryProgramme,
                                      onProgrammeChanged: notifier.selectCompulsoryProgramme,
                                      onSearchChanged: notifier.setCompulsorySearchQuery,
                                      selectedSort: state.compulsorySortOption,
                                      onSortChanged: notifier.setCompulsorySortOption,
                                      availableYears: const [],
                                      selectedYear: null,
                                      onYearChanged: (_) {},
                                      semesterNames: const [],
                                      selectedSemester: null,
                                      onSemesterChanged: (_) {},
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
    final notifier = ref.read(coursesControllerProvider.notifier);
    final classes = await runWithBusy(context, 'Finding classes…', () => notifier.enrollableClasses(course.id));
    if (!context.mounted) return;
    if (classes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No class available for the selected semester that fits your schedule, please try again later.'),
          duration: Duration(seconds: 6),
        ),
      );
      return;
    }
    final chosen = await showDialog<EnrollableClass>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Enroll in ${course.title}'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('These classes don\'t clash with your schedule. Pick one to enroll.', style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final c in classes)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(c.sectionCode),
                        subtitle: Text([c.scheduleText, if (c.semesterName != null) c.semesterName!, if (c.location != null && c.location!.isNotEmpty) c.location!].join(' · ')),
                        trailing: FilledButton(onPressed: () => Navigator.of(ctx).pop(c), child: const Text('Enroll')),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel'))],
      ),
    );
    if (chosen == null || !context.mounted) return;
    try {
      await runWithBusy(context, 'Enrolling…', () => notifier.enrollInSection(course.id, chosen.sectionId));
    } on ScheduleConflictException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), duration: const Duration(seconds: 8)));
      return;
    }
    if (!context.mounted) return;
    showSuccessSnackBar(context, 'Enrolled in ${course.title} (${chosen.sectionCode}).');
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

  // Mobile (≤ 900px) layout — the same sections as desktop (telemetry banner +
  // critical actions, tag/search/sort/year/semester filters, the course grid and
  // the "Compulsory for You" block). Each desktop widget is already
  // responsive, so they are reused as-is; only the shell (compact top bar and
  // bottom nav instead of header + sidebar) differs.
  Widget _buildMobileScaffold(BuildContext context, CoursesState state, CoursesNotifier notifier) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MobileTopBar(),
      bottomNavigationBar: MobileBottomNav(
        selectedIndex: 0,
        onTap: (index) => navigateStudentTab(context, index, current: 0),
      ),
      body: SafeArea(
              top: false,
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TelemetryBanner(
 statsReady: state.statsReady,
 actionsReady: state.actionsReady,
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
                      programmeNames: state.availableProgrammes,
                                    selectedProgramme: state.selectedProgramme,
                                    onProgrammeChanged: notifier.selectProgramme,
                                    onSearchChanged: notifier.setSearchQuery,
                      selectedSort: state.sortOption,
                      onSortChanged: notifier.setSortOption,
                      availableYears: state.availableYears,
                      selectedYear: state.selectedYear,
                      onYearChanged: notifier.selectYear,
                      semesterNames: state.selectedYear == null ? const [] : state.semesterNamesForYear(state.selectedYear!),
                      selectedSemester: state.selectedSemester,
                      onSemesterChanged: notifier.selectSemester,
                    ),
                    const SizedBox(height: 24),
                    state.coursesReady ? CourseGrid(
                      courses: state.filteredAndSortedCourses,
                      onCourseAction: (course) => _openCourse(context, course),
                    ) : const SkeletonCourseGrid(),
                    if (!state.compulsoryReady) ...const [SizedBox(height: 40), Skeleton(width: 220, height: 26), SizedBox(height: 16), SkeletonCourseGrid(count: 3)] else if (state.compulsoryCourses.isNotEmpty) ...[
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
                        showYearSemester: false,
                        alignment: WrapAlignment.start,
                        programmeNames: state.availableCompulsoryProgrammes,
                                      selectedProgramme: state.selectedCompulsoryProgramme,
                                      onProgrammeChanged: notifier.selectCompulsoryProgramme,
                                      onSearchChanged: notifier.setCompulsorySearchQuery,
                        selectedSort: state.compulsorySortOption,
                        onSortChanged: notifier.setCompulsorySortOption,
                        availableYears: const [],
                        selectedYear: null,
                        onYearChanged: (_) {},
                        semesterNames: const [],
                        selectedSemester: null,
                        onSemesterChanged: (_) {},
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
      semesterNames: year == null ? const [] : state.compulsorySemesterNamesForYear(year),
      selectedSemester: state.effectiveCompulsorySemester,
      onSemesterChanged: notifier.selectCompulsorySemester,
    );
  }
}
