import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch_aiei_lms/core/supabase/supabase_providers.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_master_data_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/repositories/admin_master_data_repository.dart';
import 'package:stitch_aiei_lms/domain/repositories/courses_repository.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_courses_repository_impl.dart';
import 'courses_state.dart';

final coursesRepositoryProvider = Provider<CoursesRepository>((ref) {
  return SupabaseCoursesRepositoryImpl(ref.watch(supabaseClientProvider));
});

final _masterDataRepositoryProvider = Provider<AdminMasterDataRepository>((ref) {
  return SupabaseAdminMasterDataRepositoryImpl(ref.watch(supabaseClientProvider));
});

class CoursesNotifier extends Notifier<CoursesState> {
  late final CoursesRepository _repository;
  late final AdminMasterDataRepository _masterDataRepository;

  @override
  CoursesState build() {
    _repository = ref.watch(coursesRepositoryProvider);
    _masterDataRepository = ref.watch(_masterDataRepositoryProvider);
    Future.microtask(() => loadInitialData());
    return const CoursesState();
  }

  /// Loads each part of the page independently and in parallel; every part
  /// shows as soon as it is ready (see the `...Ready` flags on the state).
  Future<void> loadInitialData() async {
    state = state.copyWith(errorMessage: null);
    final coursesFuture = _repository.getEnrolledCourses();
    final cohortsFuture = _masterDataRepository.getCohorts();
    await Future.wait([
      _loadPart(() async {
        final courses = await coursesFuture;
        final cohorts = await cohortsFuture;
        state = state.copyWith(allCourses: courses, cohorts: cohorts);
        _applyYearAndCohortSelection();
      }, () => state = state.copyWith(coursesReady: true)),
      _loadPart(() async {
        // Reuses the courses above instead of fetching them a second time.
        final stats = await _repository.getCourseStats(courses: await coursesFuture);
        state = state.copyWith(stats: stats);
      }, () => state = state.copyWith(statsReady: true)),
      _loadPart(() async {
        final actions = await _repository.getCriticalActions();
        state = state.copyWith(criticalActions: actions);
      }, () => state = state.copyWith(actionsReady: true)),
      _loadPart(() async {
        final compulsory = await _repository.getCompulsoryCourses();
        state = state.copyWith(compulsoryCourses: compulsory);
      }, () => state = state.copyWith(compulsoryReady: true)),
    ]);
  }

  /// Runs one part, then marks it ready — even on failure, so a placeholder
  /// never spins forever (the error is shown by the page).
  Future<void> _loadPart(Future<void> Function() part, void Function() markReady) async {
    try {
      await part();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
    markReady();
  }

  /// Keeps the student's existing Year/Cohort selection across a reload (this
  /// runs every time the screen re-mounts or data is refreshed, not just once)
  /// as long as it's still a valid option — only falls back to a default the
  /// first time, or if the previous choice no longer exists. Otherwise every
  /// reload would silently snap the picker back to "current year / first
  /// cohort", discarding whatever the student had deliberately selected.
  void _applyYearAndCohortSelection() {
    final years = state.availableYears;
    var selectedYear = state.selectedYear;
    if (selectedYear == null || !years.contains(selectedYear)) {
      final currentYear = DateTime.now().year;
      selectedYear = years.contains(currentYear) ? currentYear : (years.isEmpty ? null : years.last);
    }
    final cohortNames = selectedYear == null ? const <String>[] : state.cohortNamesForYear(selectedYear);
    var selectedCohort = state.selectedCohort;
    if (selectedCohort == null || !cohortNames.contains(selectedCohort)) {
      selectedCohort = cohortNames.isEmpty ? null : cohortNames.first;
    }
    state = state.copyWith(
      selectedYear: selectedYear,
      clearSelectedYear: selectedYear == null,
      selectedCohort: selectedCohort,
      clearSelectedCohort: selectedCohort == null,
    );
  }

  void selectTag(String? tag) {
    if (tag == null || state.selectedTag == tag) {
      state = state.copyWith(clearSelectedTag: true);
    } else {
      state = state.copyWith(selectedTag: tag);
    }
  }

  void selectCompulsoryTag(String? tag) {
    if (tag == null || state.selectedCompulsoryTag == tag) {
      state = state.copyWith(clearSelectedCompulsoryTag: true);
    } else {
      state = state.copyWith(selectedCompulsoryTag: tag);
    }
  }

  void selectProgramme(String? programme) {
    state = programme == null ? state.copyWith(clearSelectedProgramme: true) : state.copyWith(selectedProgramme: programme);
  }

  void selectCompulsoryProgramme(String? programme) {
    state = programme == null
        ? state.copyWith(clearSelectedCompulsoryProgramme: true)
        : state.copyWith(selectedCompulsoryProgramme: programme);
  }

  void setCompulsorySearchQuery(String query) {
    state = state.copyWith(compulsorySearchQuery: query);
  }

  void setCompulsorySortOption(CourseSortOption option) {
    state = state.copyWith(compulsorySortOption: option);
  }

  void selectCompulsoryYear(int year) {
    final names = state.compulsoryCohortNamesForYear(year);
    state = state.copyWith(
      selectedCompulsoryYear: year,
      selectedCompulsoryCohort: names.isEmpty ? null : names.first,
      clearSelectedCompulsoryCohort: names.isEmpty,
    );
  }

  void selectCompulsoryCohort(String cohort) {
    // Pin the year too, so the pair stays independent of the main selection.
    state = state.copyWith(
      selectedCompulsoryYear: state.effectiveCompulsoryYear,
      selectedCompulsoryCohort: cohort,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSortOption(CourseSortOption option) {
    state = state.copyWith(sortOption: option);
  }

  void selectYear(int year) {
    final cohortNames = state.cohortNamesForYear(year);
    state = state.copyWith(
      selectedYear: year,
      selectedCohort: cohortNames.isEmpty ? null : cohortNames.first,
      clearSelectedCohort: cohortNames.isEmpty,
    );
  }

  void selectCohort(String cohort) {
    state = state.copyWith(selectedCohort: cohort);
  }

  /// Enrolls the student into [courseId] via a class belonging to the
  /// cohort chosen in the "Compulsory for You" filters. Returns false (nothing changed) if the course
  /// has no such class yet; on success, reloads so the course moves out of
  /// "Compulsory for You" into the enrolled list.
  Future<bool> enrollInCompulsoryCourse(String courseId) async {
    final cohortId = [
      for (final c in state.cohorts)
        if (c.name == state.effectiveCompulsoryCohort && c.year == state.effectiveCompulsoryYear) c.id,
    ].firstOrNull;
    final enrolled = await _repository.enrollInCompulsoryCourse(courseId, cohortId: cohortId);
    if (enrolled) await loadInitialData();
    return enrolled;
  }
}

final coursesControllerProvider =
    NotifierProvider<CoursesNotifier, CoursesState>(CoursesNotifier.new);
