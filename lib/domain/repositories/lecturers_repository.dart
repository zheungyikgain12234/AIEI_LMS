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
    required String employeeId,
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
    required String employeeId,
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

  /// Adds rows to `lecturer_courses` for each course id. Does not touch
  /// `credits_used` — call [setCreditsUsed] separately once the caller has
  /// computed the new total.
  Future<void> assignCoursesToLecturer(String lecturerId, List<String> courseIds);

  Future<void> setCreditsUsed(String lecturerId, int creditsUsed);
}
