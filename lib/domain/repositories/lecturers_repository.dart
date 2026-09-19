import 'package:stitch_aiei_lms/domain/models/lecturer.dart';
import 'package:stitch_aiei_lms/domain/models/course_section.dart';

abstract class LecturersRepository {
  Future<List<Lecturer>> getLecturers();

  Future<Lecturer> getLecturerById(String id);

  /// Course codes each lecturer teaches (from `lecturer_courses`), e.g.
  /// `{lecturerId: ['PY-402', 'DATA-501', 'AI-301']}` — drives the chip
  /// lists on the Manage Lecturers screen.
  Future<Map<String, List<String>>> getLecturerCourseCodes();

  /// All course sections with lecturer + course joined — the Lecturer
  /// Allocation screen's assigned/unassigned/available views all filter
  /// this same list.
  Future<List<CourseSection>> getAllSections();

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
  });

  Future<void> deleteLecturers(List<String> ids);

  /// Course ids already assigned to this lecturer (from `lecturer_courses`)
  /// — drives the Manage Assigned Courses screen's "already assigned" filter.
  Future<List<String>> getAssignedCourseIds(String lecturerId);

  /// Adds rows to `lecturer_courses` for each course id. `credits_used` is
  /// not touched here — a database trigger recomputes it from
  /// `lecturer_courses` (the assignation table) whenever it changes.
  Future<void> assignCoursesToLecturer(String lecturerId, List<String> courseIds);

  /// Removes the `lecturer_courses` rows for these course ids and unassigns
  /// the lecturer from any `course_sections` (classes) built for them.
  /// `credits_used` is recomputed automatically by a database trigger.
  Future<void> unassignCoursesFromLecturer(String lecturerId, List<String> courseIds);

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
  });

  Future<void> deleteSections(List<String> sectionIds);
}
