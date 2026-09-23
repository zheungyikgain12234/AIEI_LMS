import 'package:stitch_aiei_lms/domain/models/course_tag_option.dart';

/// Course Tags master data (`tags` table) — a single unique label per tag,
/// managed from the admin sidebar and selected (at least one required) when
/// creating/editing a course.
abstract class AdminCourseTagsRepository {
  Future<List<CourseTagOption>> getTags();
  Future<CourseTagOption> createTag(String label);
  Future<CourseTagOption> updateTag(String id, String label);
  Future<void> deleteTags(List<String> ids);
}
