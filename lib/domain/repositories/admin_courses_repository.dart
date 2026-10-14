import 'dart:typed_data';
import 'package:stitch_aiei_lms/domain/models/admin_course.dart';

/// Admin Portal course catalogue CRUD — separate from [CoursesRepository]
/// (the read-only, student-facing catalogue view). Lecturer/section
/// assignment against these courses is built on top of this later.
///
/// Schedule and capacity are set per-class (see the Manage Assigned Courses
/// screen / `course_sections`), not here.
abstract class AdminCoursesRepository {
  Future<List<AdminCourse>> getCourses();

  Future<AdminCourse> getCourseById(String id);

  /// [tagIds] must be non-empty — at least one Course Tag is required per
  /// course. Badges awarded on completion are mapped separately (Badge ↔ Course Mapping); [badgeIds], when given, replaces them.
  Future<AdminCourse> createCourse({
    required String courseCode,
    required String courseTitle,
    required String courseDescription,
    required String category,
    String? imageUrl,
    required int credits,
    required List<String> tagIds,
    List<String>? badgeIds,
  });

  Future<AdminCourse> updateCourse(
    String id, {
    required String courseCode,
    required String courseTitle,
    required String courseDescription,
    required String category,
    String? imageUrl,
    required int credits,
    required List<String> tagIds,
    List<String>? badgeIds,
  });

  Future<void> deleteCourses(List<String> ids);

  /// Uploads a course banner image to the `course-content` storage bucket
  /// and returns its public URL (to be saved as `courses.image_url`).
  Future<String> uploadCourseBanner({required String fileName, required Uint8List bytes});
}
