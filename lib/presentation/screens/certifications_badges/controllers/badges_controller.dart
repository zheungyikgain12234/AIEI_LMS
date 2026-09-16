import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch_aiei_lms/core/supabase/supabase_providers.dart';
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

class BadgesNotifier extends Notifier<BadgesState> {
  late final BadgesRepository _repository;

  @override
  BadgesState build() {
    _repository = ref.watch(badgesRepositoryProvider);
    Future.microtask(() => loadInitialData());
    return const BadgesState(isLoading: true);
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final stats = await _repository.getBadgeStats();
      final earned = await _repository.getEarnedCredentials();
      final inProgress = await _repository.getInProgressBadges();

      state = state.copyWith(
        stats: stats,
        earnedCredentials: earned,
        inProgressBadges: inProgress,
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

final badgesControllerProvider =
    NotifierProvider<BadgesNotifier, BadgesState>(BadgesNotifier.new);
