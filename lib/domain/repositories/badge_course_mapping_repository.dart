/// Backs the Course ↔ Badge Mapping screen — which courses award a given
/// badge on completion, stored in `course_badges`.
abstract class BadgeCourseMappingRepository {
  /// Course ids currently mapped to [badgeId].
  Future<Set<String>> getCourseIdsForBadge(String badgeId);

  /// Adds or removes the (course, badge) mapping depending on [allowed].
  Future<void> setCourseForBadge(String badgeId, String courseId, bool allowed);
}
