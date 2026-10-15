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
    return const BadgesState();
  }

  /// Loads the stats, the earned badges and the student's ID in parallel; each
  /// appears as soon as it is ready.
  Future<void> loadInitialData() async {
    state = state.copyWith(errorMessage: null);
    await Future.wait([
      _loadPart(() async {
        final stats = await _repository.getBadgeStats();
        state = state.copyWith(stats: stats);
      }, () => state = state.copyWith(statsReady: true)),
      _loadPart(() async {
        final earned = await _repository.getEarnedCredentials();
        final inProgress = await _repository.getInProgressBadges();
        state = state.copyWith(earnedCredentials: earned, inProgressBadges: inProgress);
      }, () => state = state.copyWith(earnedReady: true)),
      _loadPart(() async {
        final student = await _studentsRepository.getStudentById(DemoIdentity.studentId);
        state = state.copyWith(studentCode: student.studentCode);
      }, () {}),
    ]);
  }

  /// Runs one part, then marks it ready even on failure so a placeholder never
  /// spins forever.
  Future<void> _loadPart(Future<void> Function() part, void Function() markReady) async {
    try {
      await part();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
    markReady();
  }
}

// autoDispose: a plain NotifierProvider only ever runs its build()/initial
// load once per app session, so re-entering this screen after a badge was
// awarded elsewhere (e.g. a course just completed) kept showing the stale
// list until a full page refresh. Disposing on navigate-away forces a fresh
// loadInitialData() every time the screen is opened.
final badgesControllerProvider =
    NotifierProvider.autoDispose<BadgesNotifier, BadgesState>(BadgesNotifier.new);
