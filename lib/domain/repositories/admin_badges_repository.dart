import 'package:stitch_aiei_lms/domain/models/badge_award.dart';

/// Admin Portal CRUD for `badge_awards` — the Manage Badges screen.
abstract class AdminBadgesRepository {
  Future<List<BadgeAward>> getBadgeAwards();

  /// (id, title) for every row in `certifications` — the badge catalog the
  /// Manage Badges form picks from.
  Future<List<(String, String)>> getBadgeCatalog();

  Future<BadgeAward> createBadgeAward({
    required String studentId,
    required String courseId,
    required String badgeId,
    required int issueYear,
    required bool isRevoked,
  });

  Future<BadgeAward> updateBadgeAward(
    String id, {
    required String studentId,
    required String courseId,
    required String badgeId,
    required int issueYear,
    required bool isRevoked,
  });

  Future<void> deleteBadgeAwards(List<String> ids);
}
