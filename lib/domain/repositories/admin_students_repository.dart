import 'package:stitch_aiei_lms/domain/models/student.dart';
import 'package:stitch_aiei_lms/domain/models/roster_student.dart';
import 'package:stitch_aiei_lms/domain/models/enrollment_candidate.dart';

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
    double? gpa,
  });

  /// Course count + credentials earned per student (from `student_courses`
  /// and `student_certifications`), keyed by student id.
  Future<Map<String, int>> getEnrollmentCounts();
  Future<Map<String, List<String>>> getEarnedCredentialTitles();

  /// (trackName, studentCount) grouped from `students.program_track`.
  Future<List<(String, int)>> getProgramTracks();

  /// (monthLabel, newEnrollments) from `enrollment_monthly_stats`.
  Future<List<(String, int)>> getEnrollmentTrend();

  Future<void> deleteStudents(List<String> ids);

  Future<List<RosterStudent>> getCourseRoster(String courseId);
  Future<List<EnrollmentCandidate>> getEnrollmentCandidates(String courseId);
}
