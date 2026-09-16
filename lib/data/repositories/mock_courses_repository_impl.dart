import '../../domain/models/enrolled_course.dart';
import '../../domain/models/course_stats.dart';
import '../../domain/models/module_material.dart';
import '../../domain/models/urgent_notice.dart';
import '../../domain/repositories/courses_repository.dart';
import '../datasources/mock_courses_data_source.dart';

/// Test-only fixture — production code uses [SupabaseCoursesRepositoryImpl].
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

  @override
  Future<List<(ModuleMaterial, String)>> getCourseLessons(String courseId) async {
    return const [];
  }
}
