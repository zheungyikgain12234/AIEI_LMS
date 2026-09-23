import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch_aiei_lms/core/supabase/supabase_providers.dart';
import 'package:stitch_aiei_lms/domain/repositories/courses_repository.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_courses_repository_impl.dart';
import 'courses_state.dart';

final coursesRepositoryProvider = Provider<CoursesRepository>((ref) {
  return SupabaseCoursesRepositoryImpl(ref.watch(supabaseClientProvider));
});

class CoursesNotifier extends Notifier<CoursesState> {
  late final CoursesRepository _repository;

  @override
  CoursesState build() {
    _repository = ref.watch(coursesRepositoryProvider);
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

      state = state.copyWith(
        allCourses: courses,
        stats: stats,
        criticalActions: criticalActions,
        compulsoryCourses: compulsoryCourses,
        isLoading: false,
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
