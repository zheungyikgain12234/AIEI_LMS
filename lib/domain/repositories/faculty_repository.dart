import 'package:stitch_aiei_lms/domain/models/assigned_course.dart';
import 'package:stitch_aiei_lms/domain/models/course_module.dart';
import 'package:stitch_aiei_lms/domain/models/module_material.dart';

abstract class FacultyRepository {
  Future<List<AssignedCourse>> getAssignedCourses(String lecturerId);

  /// module_materials for a class, joined through course_modules, ordered
  /// by module then material sorting — used by the Curriculum Manager and
  /// as the source list for Grade Quiz / Grade Assignment.
  Future<List<ModuleMaterial>> getCourseMaterials(String sectionId);

  /// course_modules for a class, ordered by sorting — used by the
  /// Curriculum Manager to render one card per module.
  Future<List<CourseModule>> getCourseModules(String sectionId);

  /// The `course_sections.id` of one class teaching [courseId] — for the
  /// couple of legacy demo screens that were built around a course id
  /// before module content became class-scoped, and just need any one
  /// section to resolve it through. Null if the course has no class yet.
  Future<String?> getPrimarySectionIdForCourse(String courseId);
}
