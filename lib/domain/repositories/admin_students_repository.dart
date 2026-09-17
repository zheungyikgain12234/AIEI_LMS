import 'package:stitch_aiei_lms/domain/models/student.dart';
import 'package:stitch_aiei_lms/domain/models/roster_student.dart';
import 'package:stitch_aiei_lms/domain/models/enrollment_candidate.dart';
import 'package:stitch_aiei_lms/domain/models/enrolled_class.dart';

abstract class AdminStudentsRepository {
  Future<List<Student>> getStudents();

  Future<Student> getStudentById(String id);

  /// Inserts a new student row (the `id` is auto-assigned by the database's
  /// identity column) and returns it. GPA is not settable at registration —
  /// it defaults to 0 in the database.
  Future<Student> createStudent({
    required String name,
    required String studentId,
    required String email,
    required String department,
    String? title,
    required String programTrack,
    required String cohort,
    required String role,
  });

  /// [gpa] is left unchanged when omitted.
  Future<Student> updateStudent(
    String id, {
    required String name,
    required String studentId,
    required String email,
    required String department,
    String? title,
    required String programTrack,
    required String cohort,
    required String role,
    double? gpa,
  });

  /// Course count + credentials earned per student (from `student_courses`
  /// and `student_certifications`), keyed by student id.
  Future<Map<String, int>> getEnrollmentCounts();
  Future<Map<String, List<String>>> getEarnedCredentialTitles();

  /// Enrolled course ids per student (from `student_courses`), keyed by
  /// student id — used to flag enrollments that don't fit the student's role
  /// (see `role_courses` / Role ↔ Course Mapping).
  Future<Map<String, List<String>>> getEnrolledCourseIdsByStudent();

  /// (trackName, studentCount) grouped from `students.program_track`.
  Future<List<(String, int)>> getProgramTracks();

  /// (monthLabel, newEnrollments) from `enrollment_monthly_stats`.
  Future<List<(String, int)>> getEnrollmentTrend();

  Future<void> deleteStudents(List<String> ids);

  Future<List<RosterStudent>> getCourseRoster(String courseId);
  Future<List<EnrollmentCandidate>> getEnrollmentCandidates(String courseId);

  /// Enrolls each student into [courseId] via the class [sectionId] (an
  /// upsert — re-enrolling an already-enrolled student just moves them to
  /// this section), then refreshes that section's `enrolled_count`.
  Future<void> enrollStudentsInSection(
    List<String> studentIds, {
    required String sectionId,
    required String courseId,
  });

  /// The classes [studentId] is currently enrolled in — Manage Enrolled
  /// Courses screen.
  Future<List<EnrolledClass>> getEnrolledClasses(String studentId);

  /// Removes the student_courses row for (studentId, courseId) and, if it
  /// was tied to a section, refreshes that section's `enrolled_count`.
  Future<void> unenrollStudentFromCourse(String studentId, String courseId);
}
