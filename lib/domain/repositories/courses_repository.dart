import '../models/enrolled_course.dart';
import '../models/course_stats.dart';
import '../models/urgent_notice.dart';

abstract class CoursesRepository {
  Future<List<EnrolledCourse>> getEnrolledCourses();
  Future<CourseStats> getCourseStats();
  Future<UrgentNotice?> getUrgentNotice();
}
