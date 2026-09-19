/// Backs the Track ↔ Course Mapping screen — which courses a given program
/// track is associated with, stored in `track_courses`.
abstract class TrackCourseMappingRepository {
  /// Course ids currently mapped to [trackId].
  Future<Set<String>> getCourseIdsForTrack(String trackId);

  /// Adds or removes the (track, course) mapping depending on [allowed].
  Future<void> setCourseForTrack(String trackId, String courseId, bool allowed);
}
