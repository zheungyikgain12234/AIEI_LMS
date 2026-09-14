import 'package:stitch_aiei_lms/domain/models/enrolled_course.dart';
import 'package:stitch_aiei_lms/domain/models/course_stats.dart';
import 'package:stitch_aiei_lms/domain/models/urgent_notice.dart';

enum CourseSortOption {
  progressDesc('progress-desc', 'Sort: Highest Progress'),
  deadline('deadline', 'Sort: Urgent Deadline'),
  name('name', 'Sort: Course Title'),
  estTime('est-time', 'Sort: Estimated Time');

  final String key;
  final String label;
  const CourseSortOption(this.key, this.label);
}

class CoursesState {
  final List<EnrolledCourse> allCourses;
  final CourseStats? stats;
  final UrgentNotice? urgentNotice;
  final CourseCategory selectedCategory;
  final String searchQuery;
  final CourseSortOption sortOption;
  final bool isLoading;
  final String? errorMessage;

  const CoursesState({
    this.allCourses = const [],
    this.stats,
    this.urgentNotice,
    this.selectedCategory = CourseCategory.all,
    this.searchQuery = '',
    this.sortOption = CourseSortOption.progressDesc,
    this.isLoading = false,
    this.errorMessage,
  });

  CoursesState copyWith({
    List<EnrolledCourse>? allCourses,
    CourseStats? stats,
    UrgentNotice? urgentNotice,
    CourseCategory? selectedCategory,
    String? searchQuery,
    CourseSortOption? sortOption,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CoursesState(
      allCourses: allCourses ?? this.allCourses,
      stats: stats ?? this.stats,
      urgentNotice: urgentNotice ?? this.urgentNotice,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  List<EnrolledCourse> get filteredAndSortedCourses {
    var filtered = allCourses.where((course) {
      final matchesCategory = selectedCategory == CourseCategory.all ||
          course.category == selectedCategory;

      final query = searchQuery.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          course.title.toLowerCase().contains(query) ||
          course.instructorOrBoard.toLowerCase().contains(query) ||
          course.tags.any((t) => t.label.toLowerCase().contains(query)) ||
          course.unlockBadgeTitle.toLowerCase().contains(query);

      return matchesCategory && matchesQuery;
    }).toList();

    filtered.sort((a, b) {
      switch (sortOption) {
        case CourseSortOption.progressDesc:
          return b.progressPercentage.compareTo(a.progressPercentage);
        case CourseSortOption.deadline:
          return a.deadlineDays.compareTo(b.deadlineDays);
        case CourseSortOption.name:
          return a.title.compareTo(b.title);
        case CourseSortOption.estTime:
          final aTime = _extractHours(a.durationText);
          final bTime = _extractHours(b.durationText);
          return bTime.compareTo(aTime);
      }
    });

    return filtered;
  }

  double _extractHours(String? text) {
    if (text == null) return 0.0;
    final match = RegExp(r'([\d\.]+)').firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '0') ?? 0.0;
    }
    return 0.0;
  }

  int getCountForCategory(CourseCategory category) {
    if (category == CourseCategory.all) return allCourses.length;
    return allCourses.where((c) => c.category == category).length;
  }
}
