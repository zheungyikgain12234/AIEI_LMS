import 'package:stitch_aiei_lms/domain/models/enrolled_course.dart';
import 'package:stitch_aiei_lms/domain/models/course_stats.dart';
import 'package:stitch_aiei_lms/domain/models/critical_action_item.dart';
import 'package:stitch_aiei_lms/domain/models/cohort.dart';

enum CourseSortOption {
  progressDesc('progress-desc', 'Sort: Highest Progress'),
  name('name', 'Sort: Course Title');

  final String key;
  final String label;
  const CourseSortOption(this.key, this.label);
}

class CoursesState {
  final List<EnrolledCourse> allCourses;
  final CourseStats? stats;
  final List<CriticalActionItem> criticalActions;

  /// Courses mapped to an Internal student's role (`role_courses`) that
  /// they aren't enrolled in yet — shown in a separate "Compulsory for
  /// You" section on the catalogue, distinct from [allCourses].
  final List<EnrolledCourse> compulsoryCourses;

  /// Selected Course Tag ("All Courses" chip = null) — the real, admin-
  /// managed filter, replacing the old fixed-category filter pills.
  final String? selectedTag;
  final String searchQuery;
  final CourseSortOption sortOption;

  // ── Year / Cohort filter — mirrors the Faculty "My Assigned Courses"
  // screen's pattern: the master `cohorts` list (for year lookups + the
  // year dropdown's options) and the currently selected year/cohort.
  final List<Cohort> cohorts;
  final int? selectedYear;
  final String? selectedCohort;

  final bool isLoading;
  final String? errorMessage;

  const CoursesState({
    this.allCourses = const [],
    this.stats,
    this.criticalActions = const [],
    this.compulsoryCourses = const [],
    this.selectedTag,
    this.searchQuery = '',
    this.sortOption = CourseSortOption.progressDesc,
    this.cohorts = const [],
    this.selectedYear,
    this.selectedCohort,
    this.isLoading = false,
    this.errorMessage,
  });

  CoursesState copyWith({
    List<EnrolledCourse>? allCourses,
    CourseStats? stats,
    List<CriticalActionItem>? criticalActions,
    List<EnrolledCourse>? compulsoryCourses,
    String? selectedTag,
    bool clearSelectedTag = false,
    String? searchQuery,
    CourseSortOption? sortOption,
    List<Cohort>? cohorts,
    int? selectedYear,
    bool clearSelectedYear = false,
    String? selectedCohort,
    bool clearSelectedCohort = false,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CoursesState(
      allCourses: allCourses ?? this.allCourses,
      stats: stats ?? this.stats,
      criticalActions: criticalActions ?? this.criticalActions,
      compulsoryCourses: compulsoryCourses ?? this.compulsoryCourses,
      selectedTag: clearSelectedTag ? null : (selectedTag ?? this.selectedTag),
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
      cohorts: cohorts ?? this.cohorts,
      selectedYear: clearSelectedYear ? null : (selectedYear ?? this.selectedYear),
      selectedCohort: clearSelectedCohort ? null : (selectedCohort ?? this.selectedCohort),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  Map<String, int> get _cohortYearByName => {for (final c in cohorts) c.name: c.year};

  /// Years the student actually has enrolled classes in, sorted ascending.
  List<int> get availableYears {
    final years = <int>{};
    for (final c in allCourses) {
      final year = _cohortYearByName[c.cohort];
      if (year != null) years.add(year);
    }
    return years.toList()..sort();
  }

  /// Cohort names (within [year]) the student has enrolled classes in, in
  /// the same order as the master `cohorts` list.
  List<String> cohortNamesForYear(int year) {
    final enrolledNames = allCourses.map((c) => c.cohort).whereType<String>().toSet();
    return [
      for (final c in cohorts)
        if (c.year == year && enrolledNames.contains(c.name)) c.name,
    ];
  }

  /// Distinct tag labels across every enrolled course, in first-seen order —
  /// the horizontally scrollable filter row above the course grid.
  List<String> get availableTags {
    final seen = <String>{};
    final labels = <String>[];
    for (final course in allCourses) {
      for (final tag in course.tags) {
        if (seen.add(tag.label)) labels.add(tag.label);
      }
    }
    return labels;
  }

  List<EnrolledCourse> get filteredAndSortedCourses {
    var filtered = allCourses.where((course) {
      final matchesTag = selectedTag == null || course.tags.any((t) => t.label == selectedTag);
      final matchesCohort = selectedCohort == null || course.cohort == selectedCohort;

      final query = searchQuery.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          course.title.toLowerCase().contains(query) ||
          course.instructorOrBoard.toLowerCase().contains(query) ||
          course.tags.any((t) => t.label.toLowerCase().contains(query));

      return matchesTag && matchesCohort && matchesQuery;
    }).toList();

    filtered.sort((a, b) {
      switch (sortOption) {
        case CourseSortOption.progressDesc:
          return b.progressPercentage.compareTo(a.progressPercentage);
        case CourseSortOption.name:
          return a.title.compareTo(b.title);
      }
    });

    return filtered;
  }
}
