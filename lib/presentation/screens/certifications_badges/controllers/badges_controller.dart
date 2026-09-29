import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/supabase/supabase_providers.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_students_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/repositories/admin_students_repository.dart';
import 'package:stitch_aiei_lms/domain/repositories/badges_repository.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_badges_repository_impl.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/controllers/courses_controller.dart';
import 'badges_state.dart';

final badgesRepositoryProvider = Provider<BadgesRepository>((ref) {
  return SupabaseBadgesRepositoryImpl(
    ref.watch(supabaseClientProvider),
    ref.watch(coursesRepositoryProvider),
  );
});

final _studentsRepositoryProvider = Provider<AdminStudentsRepository>((ref) {
  return SupabaseAdminStudentsRepositoryImpl(ref.watch(supabaseClientProvider));
});

class BadgesNotifier extends Notifier<BadgesState> {
  late final BadgesRepository _repository;
  late final AdminStudentsRepository _studentsRepository;

  @override
  BadgesState build() {
    _repository = ref.watch(badgesRepositoryProvider);
    _studentsRepository = ref.watch(_studentsRepositoryProvider);
    Future.microtask(() => loadInitialData());
    return const BadgesState(isLoading: true);
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final stats = await _repository.getBadgeStats();
      final earned = await _repository.getEarnedCredentials();
      final inProgress = await _repository.getInProgressBadges();
      final student = await _studentsRepository.getStudentById(DemoIdentity.studentId);

      state = state.copyWith(
        stats: stats,
        earnedCredentials: earned,
        inProgressBadges: inProgress,
        studentCode: student.studentCode,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

// autoDispose: a plain NotifierProvider only ever runs its build()/initial
// load once per app session, so re-entering this screen after a badge was
// awarded elsewhere (e.g. a course just completed) kept showing the stale
// list until a full page refresh. Disposing on navigate-away forces a fresh
// loadInitialData() every time the screen is opened.
final badgesControllerProvider =
    NotifierProvider.autoDispose<BadgesNotifier, BadgesState>(BadgesNotifier.new);
