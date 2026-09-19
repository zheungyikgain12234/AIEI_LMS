/// Backs the Specialization ↔ Course Mapping screen — which courses are
/// relevant to a given lecturer specialization, stored in
/// `specialization_courses`. Also used to flag courses assigned to a
/// lecturer that don't fit their specialization (Manage Assigned Courses).
abstract class SpecializationCourseMappingRepository {
  /// Course ids currently mapped to [specializationId].
  Future<Set<String>> getCourseIdsForSpecialization(String specializationId);

  /// Adds or removes the (specialization, course) mapping depending on [allowed].
  Future<void> setCourseForSpecialization(String specializationId, String courseId, bool allowed);
}
