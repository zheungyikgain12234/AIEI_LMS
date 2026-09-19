/// Backs the Department ↔ Course Mapping screen — which courses a given
/// department is associated with, stored in `department_courses`.
abstract class DepartmentCourseMappingRepository {
  /// Course ids currently mapped to [departmentId].
  Future<Set<String>> getCourseIdsForDepartment(String departmentId);

  /// Adds or removes the (department, course) mapping depending on [allowed].
  Future<void> setCourseForDepartment(String departmentId, String courseId, bool allowed);
}
