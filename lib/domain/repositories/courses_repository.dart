import '../models/enrolled_course.dart';
import '../models/course_stats.dart';
import '../models/critical_action_item.dart';
import '../models/module_material.dart';

abstract class CoursesRepository {
  Future<List<EnrolledCourse>> getEnrolledCourses();
  Future<CourseStats> getCourseStats();

  /// The 2 real assignments/quizzes (across every enrolled course) nearest
  /// their due date that the student hasn't submitted yet.
  Future<List<CriticalActionItem>> getCriticalActions({int limit = 2});

  /// A course's materials in module order, each paired with the demo
  /// student's completion status — the lesson/module list shown on the
  /// Course Info screens.
  Future<List<(ModuleMaterial, String)>> getCourseLessons(String courseId);

  /// Courses mapped to the demo student's department (`department_courses`)
  /// that they aren't enrolled in yet. Empty for External students (they
  /// have no department) — powers the catalogue's "Compulsory for You"
  /// section.
  Future<List<EnrolledCourse>> getCompulsoryCourses();
}
