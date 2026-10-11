import 'package:stitch_aiei_lms/domain/models/badge_award.dart';
import 'package:stitch_aiei_lms/domain/models/badge_catalog_item.dart';

/// Badges master data (`certifications` table) — the catalog of badges a
/// course can be configured to award on completion (see `course_badges`).
/// Distinct from [AdminBadgesRepository]/`badge_awards`, which is the
/// actual per-student award record.
abstract class AdminBadgeCatalogRepository {
  Future<List<BadgeCatalogItem>> getBadges();
  Future<BadgeCatalogItem> getBadgeById(String id);

  Future<BadgeCatalogItem> createBadge({
    required String code,
    required String title,
    required String description,
    required String issuingBody,
  });

  Future<BadgeCatalogItem> updateBadge(
    String id, {
    required String code,
    required String title,
    required String description,
    required String issuingBody,
  });

  /// The `badge_awards` that reference any of [ids].
  Future<List<BadgeAward>> getAwardsForBadges(List<String> ids);

  /// Deletes the badges. [reassignments] maps award id -> the badge that
  /// award moves to first; any other award on a deleted badge is deleted
  /// with it.
  Future<void> deleteBadges(List<String> ids, {Map<String, String> reassignments = const {}});
}
