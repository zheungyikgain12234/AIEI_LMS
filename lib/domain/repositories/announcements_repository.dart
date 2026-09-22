import 'package:stitch_aiei_lms/domain/models/course_announcement.dart';

abstract class AnnouncementsRepository {
  /// Announcements for a class, newest first — read by both the lecturer's
  /// Course Dashboard and the student's Course Content right sidebar.
  Future<List<CourseAnnouncement>> getAnnouncementsForSection(String sectionId);

  /// Posted by the lecturer assigned to [sectionId] (`course_sections.
  /// lecturer_id`) — the only lecturer who can access that class's
  /// dashboard in the first place.
  Future<void> postAnnouncement({
    required String sectionId,
    required String lecturerId,
    required String title,
    required String body,
  });
}
