import 'package:stitch_aiei_lms/domain/models/assigned_course.dart';
import 'package:stitch_aiei_lms/domain/models/course_module.dart';
import 'package:stitch_aiei_lms/domain/models/module_material.dart';

abstract class FacultyRepository {
  Future<List<AssignedCourse>> getAssignedCourses(String lecturerId);

  /// module_materials for a course, joined through course_modules, ordered
  /// by module then material sorting — used by the Curriculum Manager and
  /// as the source list for Grade Quiz / Grade Assignment.
  Future<List<ModuleMaterial>> getCourseMaterials(String courseId);

  /// course_modules for a course, ordered by sorting — used by the
  /// Curriculum Manager to render one card per module.
  Future<List<CourseModule>> getCourseModules(String courseId);
}
