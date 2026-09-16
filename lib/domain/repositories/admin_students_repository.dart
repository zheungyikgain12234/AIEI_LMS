import 'package:stitch_aiei_lms/domain/models/student.dart';
import 'package:stitch_aiei_lms/domain/models/roster_student.dart';
import 'package:stitch_aiei_lms/domain/models/enrollment_candidate.dart';

abstract class AdminStudentsRepository {
  Future<List<Student>> getStudents();

  /// Course count + credentials earned per student (from `student_courses`
  /// and `student_certifications`), keyed by student id.
  Future<Map<String, int>> getEnrollmentCounts();
  Future<Map<String, List<String>>> getEarnedCredentialTitles();

  /// (trackName, studentCount) grouped from `students.program_track`.
  Future<List<(String, int)>> getProgramTracks();

  /// (monthLabel, newEnrollments) from `enrollment_monthly_stats`.
  Future<List<(String, int)>> getEnrollmentTrend();

  Future<List<RosterStudent>> getCourseRoster(String courseId);
  Future<List<EnrollmentCandidate>> getEnrollmentCandidates(String courseId);
}
