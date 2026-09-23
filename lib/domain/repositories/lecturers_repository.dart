import 'package:stitch_aiei_lms/domain/models/lecturer.dart';
import 'package:stitch_aiei_lms/domain/models/course_section.dart';

/// One of a lecturer's existing classes — just enough (course, cohort, day,
/// time) to detect a genuine schedule clash when assigning them to another
/// class. A lecturer may teach the same course for the same cohort more than
/// once (e.g. two sections), as long as the day/time don't overlap.
typedef LecturerClassSlot = ({
  String id,
  String courseId,
  String? cohort,
  String sectionCode,
  String? dayOfWeek,
  String? startTime,
  String? endTime,
});

abstract class LecturersRepository {
  Future<List<Lecturer>> getLecturers();

  Future<Lecturer> getLecturerById(String id);

  /// Course codes each lecturer teaches (from `lecturer_courses`), e.g.
  /// `{lecturerId: ['PY-402', 'DATA-501', 'AI-301']}` — drives the chip
  /// lists on the Manage Lecturers screen.
  Future<Map<String, List<String>>> getLecturerCourseCodes();

  /// All course sections with lecturer + course joined — the Lecturer
  /// Allocation screen's assigned/unassigned/available views all filter
  /// this same list. `enrolledCount` on each is computed from
  /// `student_courses`, not stored.
  Future<List<CourseSection>> getAllSections();

  /// A single class section by its primary key — the Manage Classes screen's
  /// "Manage" detail/edit page.
  Future<CourseSection> getSectionById(String id);

  /// Updates a class section's schedule/capacity/status fields. `dayOfWeek`,
  /// `startTime`, `endTime`, and `location` are combined into a fresh
  /// `schedule_text` display string, the same way [createSectionForCourse]
  /// builds its initial one.
  Future<CourseSection> updateSection(
    String id, {
    DateTime? startDate,
    DateTime? endDate,
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    String? location,
    required int capacity,
    required String deliveryMode,
    required String cohort,
    required String status,
  });

  Future<void> assignLecturerToSection(String sectionId, String lecturerId);

  /// Inserts a new lecturer row and returns it. `creditsUsed` defaults to 0
  /// and `manageable` defaults to true — neither is settable at onboarding.
  Future<Lecturer> createLecturer({
    required String name,
    required String title,
    required String lecturerCode,
    required String email,
    required String department,
    required String specialization,
    required int creditsMax,
    required String status,
    required bool accredited,
    required DateTime joinDate,
  });

  Future<Lecturer> updateLecturer(
    String id, {
    required String name,
    required String title,
    required String lecturerCode,
    required String email,
    required String department,
    required String specialization,
    required int creditsMax,
    required String status,
    required bool accredited,
    required DateTime joinDate,
  });

  Future<void> deleteLecturers(List<String> ids);

  /// Course ids already assigned to this lecturer (from `lecturer_courses`)
  /// — drives the Manage Assigned Courses screen's "already assigned" filter.
  Future<List<String>> getAssignedCourseIds(String lecturerId);

  /// This lecturer's existing classes (from `course_sections`) — the Manage
  /// Assigned Courses screen checks each against a new assignment's
  /// course/cohort/day/time to block only a genuine schedule clash (same
  /// course, same cohort, overlapping time), and uses it to show which
  /// cohorts a course is already being taught in.
  Future<List<LecturerClassSlot>> getAssignedSchedules(String lecturerId);

  /// Adds rows to `lecturer_courses` for each course id. A course already
  /// assigned to this lecturer (e.g. being re-assigned for a new cohort) is
  /// left untouched rather than erroring. `credits_used` is not touched
  /// here — a database trigger recomputes it from `lecturer_courses` (the
  /// assignation table) whenever it changes.
  Future<void> assignCoursesToLecturer(String lecturerId, List<String> courseIds);

  /// Removes the `lecturer_courses` rows for these course ids and unassigns
  /// the lecturer from any `course_sections` (classes) built for them.
  /// `credits_used` is recomputed automatically by a database trigger.
  Future<void> unassignCoursesFromLecturer(String lecturerId, List<String> courseIds);

  /// Unassigns the lecturer from a single class section (clears its
  /// `lecturer_id`, resets status to `scheduled`) rather than every section
  /// of that course — so a lecturer teaching PY-402 in two different
  /// cohorts (or twice in the same cohort at different times) can have just
  /// one of those classes unassigned while the other stays intact. If this
  /// was the lecturer's last section for that course, the `lecturer_courses`
  /// row is removed too; otherwise it's left in place.
  Future<void> unassignSection(String sectionId);

  /// Creates a new class section for [courseId] taught by [lecturerId].
  /// [classCode] is the admin-entered, tenant-prefixed unique code for this
  /// class (e.g. `TN01-CLS-OSHE101-01`) — see the "Class Code" field on the
  /// Manage Assigned Courses screen. [startTime] and [endTime] are `HH:mm`
  /// 24-hour strings; [dayOfWeek] is a full day name (e.g. `Monday`).
  Future<CourseSection> createSectionForCourse({
    required String courseId,
    required String classCode,
    required String lecturerId,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    required String location,
    required int capacity,
    required String deliveryMode,
    required String cohort,
    DateTime? courseStartDate,
    DateTime? courseEndDate,
  });

  Future<void> deleteSections(List<String> sectionIds);
}
