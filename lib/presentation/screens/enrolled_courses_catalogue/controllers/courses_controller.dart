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
    return const CoursesState(isLoading: true);
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final courses = await _repository.getEnrolledCourses();
      final stats = await _repository.getCourseStats();
      final criticalActions = await _repository.getCriticalActions();
      final compulsoryCourses = await _repository.getCompulsoryCourses();
      final cohorts = await _masterDataRepository.getCohorts();

      state = state.copyWith(
        allCourses: courses,
        stats: stats,
        criticalActions: criticalActions,
        compulsoryCourses: compulsoryCourses,
        cohorts: cohorts,
        isLoading: false,
      );

      // Keep the student's existing Year/Cohort selection across a reload
      // (this runs every time the screen re-mounts or data is refreshed, not
      // just once) as long as it's still a valid option — only fall back to
      // a default the first time, or if the previous choice no longer
      // exists. Otherwise every reload silently snapped the picker back to
      // "current year / first cohort", discarding whatever the student had
      // deliberately selected.
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
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void selectTag(String? tag) {
    if (tag == null || state.selectedTag == tag) {
      state = state.copyWith(clearSelectedTag: true);
    } else {
      state = state.copyWith(selectedTag: tag);
    }
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

  /// Enrolls the student into [courseId] via any available class. Returns
  /// false (nothing changed) if the course has no class yet; on success,
  /// reloads so the course moves out of "Compulsory for You" into the
  /// enrolled list.
  Future<bool> enrollInCompulsoryCourse(String courseId) async {
    final enrolled = await _repository.enrollInCompulsoryCourse(courseId);
    if (enrolled) await loadInitialData();
    return enrolled;
  }
}

final coursesControllerProvider =
    NotifierProvider<CoursesNotifier, CoursesState>(CoursesNotifier.new);
