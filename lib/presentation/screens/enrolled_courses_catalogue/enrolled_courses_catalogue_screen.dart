import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/presentation/screens/course_info/course_info_screen.dart';
import 'package:stitch_aiei_lms/presentation/screens/course_info/course_info_screen_2.dart';
import 'package:stitch_aiei_lms/presentation/screens/certifications_badges/certifications_badges_screen.dart';
import 'package:stitch_aiei_lms/presentation/screens/faculty_portal/my_assigned_courses_screen.dart';
import 'controllers/courses_controller.dart';
import 'widgets/portal_header.dart';
import 'widgets/portal_sidebar.dart';
import 'widgets/telemetry_banner.dart';
import 'widgets/course_filters_bar.dart';
import 'widgets/course_grid.dart';

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
}
