import 'package:stitch_aiei_lms/domain/models/admin_course.dart';

/// Admin Portal course catalogue CRUD — separate from [CoursesRepository]
/// (the read-only, student-facing catalogue view). Lecturer/section
/// assignment against these courses is built on top of this later.
abstract class AdminCoursesRepository {
  Future<List<AdminCourse>> getCourses();

  Future<AdminCourse> getCourseById(String id);

  Future<AdminCourse> createCourse({
    required String courseCode,
    required String courseTitle,
    required String courseDescription,
    required String category,
    String? imageUrl,
    required String scheduleText,
    required int capacity,
    required int credits,
  });

  Future<AdminCourse> updateCourse(
    String id, {
    required String courseCode,
    required String courseTitle,
    required String courseDescription,
    required String category,
    String? imageUrl,
    required String scheduleText,
    required int capacity,
    required int credits,
  });

  Future<void> deleteCourses(List<String> ids);
}
