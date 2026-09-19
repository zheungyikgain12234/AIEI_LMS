import 'package:stitch_aiei_lms/domain/models/badge_award.dart';

/// Admin Portal CRUD for `badge_awards` — the Badge Award Management screen.
abstract class AdminBadgesRepository {
  Future<List<BadgeAward>> getBadgeAwards();

  /// (id, code, title) for every row in `certifications` — the badge
  /// catalog the Badge Award Management form picks from.
  Future<List<(String, String, String)>> getBadgeCatalog();

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
