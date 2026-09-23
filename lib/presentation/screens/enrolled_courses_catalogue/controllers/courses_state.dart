import 'package:stitch_aiei_lms/domain/models/enrolled_course.dart';
import 'package:stitch_aiei_lms/domain/models/course_stats.dart';
import 'package:stitch_aiei_lms/domain/models/critical_action_item.dart';

enum CourseSortOption {
  progressDesc('progress-desc', 'Sort: Highest Progress'),
  name('name', 'Sort: Course Title'),
  estTime('est-time', 'Sort: Estimated Time');

  final String key;
  final String label;
  const CourseSortOption(this.key, this.label);
}

class CoursesState {
  final List<EnrolledCourse> allCourses;
  final CourseStats? stats;
  final List<CriticalActionItem> criticalActions;

  /// Selected Course Tag ("All Courses" chip = null) — the real, admin-
  /// managed filter, replacing the old fixed-category filter pills.
  final String? selectedTag;
  final String searchQuery;
  final CourseSortOption sortOption;
  final bool isLoading;
  final String? errorMessage;

  const CoursesState({
    this.allCourses = const [],
    this.stats,
    this.criticalActions = const [],
    this.selectedTag,
    this.searchQuery = '',
    this.sortOption = CourseSortOption.progressDesc,
    this.isLoading = false,
    this.errorMessage,
  });

  CoursesState copyWith({
    List<EnrolledCourse>? allCourses,
    CourseStats? stats,
    List<CriticalActionItem>? criticalActions,
    String? selectedTag,
    bool clearSelectedTag = false,
    String? searchQuery,
    CourseSortOption? sortOption,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CoursesState(
      allCourses: allCourses ?? this.allCourses,
      stats: stats ?? this.stats,
      criticalActions: criticalActions ?? this.criticalActions,
      selectedTag: clearSelectedTag ? null : (selectedTag ?? this.selectedTag),
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
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

      final query = searchQuery.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          course.title.toLowerCase().contains(query) ||
          course.instructorOrBoard.toLowerCase().contains(query) ||
          course.tags.any((t) => t.label.toLowerCase().contains(query));

      return matchesTag && matchesQuery;
    }).toList();

    filtered.sort((a, b) {
      switch (sortOption) {
        case CourseSortOption.progressDesc:
          return b.progressPercentage.compareTo(a.progressPercentage);
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
}
