import 'package:stitch_aiei_lms/domain/models/badge_stats.dart';
import 'package:stitch_aiei_lms/domain/models/earned_credential.dart';
import 'package:stitch_aiei_lms/domain/models/in_progress_badge.dart';

abstract class BadgesRepository {
  Future<BadgeStats> getBadgeStats();
  Future<List<EarnedCredential>> getEarnedCredentials();
  Future<List<InProgressBadge>> getInProgressBadges();
}
