/// Backs the Role ↔ Course Mapping screen — which courses a given job role
/// (e.g. "IT Support Specialist", "HVAC / Aircon Installer") is allowed to
/// study, stored in `role_courses`.
abstract class RoleCourseMappingRepository {
  /// Course ids currently mapped to [roleId].
  Future<Set<String>> getCourseIdsForRole(String roleId);

  /// Adds or removes the (role, course) mapping depending on [allowed].
  Future<void> setCourseForRole(String roleId, String courseId, bool allowed);
}
