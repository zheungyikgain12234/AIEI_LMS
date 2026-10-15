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

  /// Separate tag filter for the "Compulsory for You" section.
  final String? selectedCompulsoryTag;

  /// Programme filter (null = all programmes), one for each course list.
  final String? selectedProgramme;
  final String? selectedCompulsoryProgramme;

  /// Own search / sort / Year / Cohort for "Compulsory for You". Year/Cohort
  /// choose which cohort's class a course is enrolled into; when unset they
  /// fall back to the enrolled-courses selection above.
  final String compulsorySearchQuery;
  final CourseSortOption compulsorySortOption;
  final int? selectedCompulsoryYear;
  final String? selectedCompulsoryCohort;
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

  /// Which parts of the page have loaded. Each part appears as soon as its
  /// own data is ready (placeholders until then), instead of the whole page
  /// waiting for the slowest query.
  final bool coursesReady;
  final bool statsReady;
  final bool actionsReady;
  final bool compulsoryReady;

  /// The top banner needs both the stats and the critical actions.
  bool get bannerReady => statsReady && actionsReady;

  const CoursesState({
    this.allCourses = const [],
    this.stats,
    this.criticalActions = const [],
    this.compulsoryCourses = const [],
    this.selectedTag,
    this.selectedCompulsoryTag,
    this.selectedProgramme,
    this.selectedCompulsoryProgramme,
    this.compulsorySearchQuery = '',
    this.compulsorySortOption = CourseSortOption.name,
    this.selectedCompulsoryYear,
    this.selectedCompulsoryCohort,
    this.searchQuery = '',
    this.sortOption = CourseSortOption.progressDesc,
    this.cohorts = const [],
    this.selectedYear,
    this.selectedCohort,
    this.isLoading = false,
    this.coursesReady = false,
    this.statsReady = false,
    this.actionsReady = false,
    this.compulsoryReady = false,
    this.errorMessage,
  });

  CoursesState copyWith({
    List<EnrolledCourse>? allCourses,
    CourseStats? stats,
    List<CriticalActionItem>? criticalActions,
    List<EnrolledCourse>? compulsoryCourses,
    String? selectedTag,
    bool clearSelectedTag = false,
    String? selectedCompulsoryTag,
    bool clearSelectedCompulsoryTag = false,
    String? selectedProgramme,
    bool clearSelectedProgramme = false,
    String? selectedCompulsoryProgramme,
    bool clearSelectedCompulsoryProgramme = false,
    String? compulsorySearchQuery,
    CourseSortOption? compulsorySortOption,
    int? selectedCompulsoryYear,
    String? selectedCompulsoryCohort,
    bool clearSelectedCompulsoryCohort = false,
    String? searchQuery,
    CourseSortOption? sortOption,
    List<Cohort>? cohorts,
    int? selectedYear,
    bool clearSelectedYear = false,
    String? selectedCohort,
    bool clearSelectedCohort = false,
    bool? isLoading,
    bool? coursesReady,
    bool? statsReady,
    bool? actionsReady,
    bool? compulsoryReady,
    String? errorMessage,
  }) {
    return CoursesState(
      allCourses: allCourses ?? this.allCourses,
      stats: stats ?? this.stats,
      criticalActions: criticalActions ?? this.criticalActions,
      compulsoryCourses: compulsoryCourses ?? this.compulsoryCourses,
      selectedTag: clearSelectedTag ? null : (selectedTag ?? this.selectedTag),
      selectedCompulsoryTag: clearSelectedCompulsoryTag ? null : (selectedCompulsoryTag ?? this.selectedCompulsoryTag),
      selectedProgramme: clearSelectedProgramme ? null : (selectedProgramme ?? this.selectedProgramme),
      selectedCompulsoryProgramme:
          clearSelectedCompulsoryProgramme ? null : (selectedCompulsoryProgramme ?? this.selectedCompulsoryProgramme),
      compulsorySearchQuery: compulsorySearchQuery ?? this.compulsorySearchQuery,
      compulsorySortOption: compulsorySortOption ?? this.compulsorySortOption,
      selectedCompulsoryYear: selectedCompulsoryYear ?? this.selectedCompulsoryYear,
      selectedCompulsoryCohort: clearSelectedCompulsoryCohort ? null : (selectedCompulsoryCohort ?? this.selectedCompulsoryCohort),
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
      cohorts: cohorts ?? this.cohorts,
      selectedYear: clearSelectedYear ? null : (selectedYear ?? this.selectedYear),
      selectedCohort: clearSelectedCohort ? null : (selectedCohort ?? this.selectedCohort),
      isLoading: isLoading ?? this.isLoading,
      coursesReady: coursesReady ?? this.coursesReady,
      statsReady: statsReady ?? this.statsReady,
      actionsReady: actionsReady ?? this.actionsReady,
      compulsoryReady: compulsoryReady ?? this.compulsoryReady,
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

  /// Programmes any enrolled course is mapped to, sorted by name.
  List<String> get availableProgrammes => ({for (final c in allCourses) ...c.programmeNames}.toList()..sort());

  /// Programmes any compulsory course is mapped to, sorted by name.
  List<String> get availableCompulsoryProgrammes => ({for (final c in compulsoryCourses) ...c.programmeNames}.toList()..sort());

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

  /// Distinct tag labels across the compulsory courses, in first-seen order.
  List<String> get availableCompulsoryTags {
    final seen = <String>{};
    final labels = <String>[];
    for (final course in compulsoryCourses) {
      for (final tag in course.tags) {
        if (seen.add(tag.label)) labels.add(tag.label);
      }
    }
    return labels;
  }

  /// Every cohort year (not just enrolled ones) — the student may enroll
  /// into a cohort they have no class in yet.
  List<int> get availableCompulsoryYears => ({for (final c in cohorts) c.year}.toList()..sort());

  List<String> compulsoryCohortNamesForYear(int year) => [
        for (final c in cohorts)
          if (c.year == year) c.name,
      ];

  int? get effectiveCompulsoryYear => selectedCompulsoryYear ?? selectedYear;

  String? get effectiveCompulsoryCohort =>
      selectedCompulsoryYear == null ? (selectedCompulsoryCohort ?? selectedCohort) : selectedCompulsoryCohort;

  List<EnrolledCourse> get filteredCompulsoryCourses {
    final query = compulsorySearchQuery.trim().toLowerCase();
    final filtered = compulsoryCourses.where((course) {
      final matchesTag = selectedCompulsoryTag == null || course.tags.any((t) => t.label == selectedCompulsoryTag);
      final matchesProgramme = selectedCompulsoryProgramme == null || course.programmeNames.contains(selectedCompulsoryProgramme);
      final matchesQuery = query.isEmpty ||
          course.title.toLowerCase().contains(query) ||
          course.tags.any((t) => t.label.toLowerCase().contains(query));
      return matchesTag && matchesProgramme && matchesQuery;
    }).toList();
    filtered.sort((a, b) => switch (compulsorySortOption) {
          CourseSortOption.progressDesc => b.progressPercentage.compareTo(a.progressPercentage),
          CourseSortOption.name => a.title.compareTo(b.title),
        });
    return filtered;
  }

  List<EnrolledCourse> get filteredAndSortedCourses {
    var filtered = allCourses.where((course) {
      final matchesTag = selectedTag == null || course.tags.any((t) => t.label == selectedTag);
      final matchesProgramme = selectedProgramme == null || course.programmeNames.contains(selectedProgramme);
      final matchesCohort = selectedCohort == null || course.cohort == selectedCohort;

      final query = searchQuery.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          course.title.toLowerCase().contains(query) ||
          course.instructorOrBoard.toLowerCase().contains(query) ||
          course.tags.any((t) => t.label.toLowerCase().contains(query));

      return matchesTag && matchesProgramme && matchesCohort && matchesQuery;
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
