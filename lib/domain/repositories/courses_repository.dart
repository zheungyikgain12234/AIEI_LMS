import '../models/enrolled_course.dart';
import '../models/course_stats.dart';
import '../models/urgent_notice.dart';
import '../models/module_material.dart';

abstract class CoursesRepository {
  Future<List<EnrolledCourse>> getEnrolledCourses();
  Future<CourseStats> getCourseStats();
  Future<UrgentNotice?> getUrgentNotice();

  /// A course's materials in module order, each paired with the demo
  /// student's completion status — the lesson/module list shown on the
  /// Course Info screens.
  Future<List<(ModuleMaterial, String)>> getCourseLessons(String courseId);
}
