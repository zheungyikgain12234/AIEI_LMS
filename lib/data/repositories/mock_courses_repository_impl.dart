import '../../domain/models/enrolled_course.dart';
import '../../domain/models/course_stats.dart';
import '../../domain/models/urgent_notice.dart';
import '../../domain/repositories/courses_repository.dart';
import '../datasources/mock_courses_data_source.dart';

class MockCoursesRepositoryImpl implements CoursesRepository {
  @override
  Future<List<EnrolledCourse>> getEnrolledCourses() async {
    // Return mock courses
    return MockCoursesDataSource.courses;
  }

  @override
  Future<CourseStats> getCourseStats() async {
    return MockCoursesDataSource.stats;
  }

  @override
  Future<UrgentNotice?> getUrgentNotice() async {
    return MockCoursesDataSource.urgentNotice;
  }
}
