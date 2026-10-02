import 'package:stitch_aiei_lms/domain/models/student.dart';
import 'package:stitch_aiei_lms/domain/models/roster_student.dart';
import 'package:stitch_aiei_lms/domain/models/enrollment_candidate.dart';
import 'package:stitch_aiei_lms/domain/models/enrolled_class.dart';

abstract class AdminStudentsRepository {
  Future<List<Student>> getStudents();

  Future<Student> getStudentById(String id);

  /// Looks up a student by their tenant-prefixed `student_code` (case
  /// -insensitive on the user-entered suffix) — used by the exam editor's
  /// "reset a student's attempt" control, which lecturers key in by code
  /// rather than picking from a roster. Returns null if no student matches.
  Future<Student?> getStudentByCode(String code);

  /// Inserts a new student row (the `id` is auto-assigned by the database's
  /// identity column) and returns it. GPA is not settable at registration —
  /// it defaults to 0 in the database. [department]/[role] are required for
  /// [StudentType.internal] and must be omitted for [StudentType.external],
  /// which requires [programTrack] instead — matching the `students` table's
  /// `students_type_fields_check` constraint.
  Future<Student> createStudent({
    required String name,
    required String studentCode,
    required String email,
    required StudentType studentType,
    String? department,
    String? title,
    String? programTrack,
    String? role,
    required DateTime registrationDate,
  });

  /// [gpa] is left unchanged when omitted. See [createStudent] for the
  /// department/role vs. programTrack requirements per [studentType].
  Future<Student> updateStudent(
    String id, {
    required String name,
    required String studentCode,
    required String email,
    required StudentType studentType,
    String? department,
    String? title,
    String? programTrack,
    String? role,
    required DateTime registrationDate,
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

  Future<void> deleteStudents(List<String> ids);

  Future<List<RosterStudent>> getCourseRoster(String courseId);
  Future<List<EnrollmentCandidate>> getEnrollmentCandidates(String courseId);

  /// Enrolls each student into [courseId] via the class [sectionId]. A student
  /// can be in only one class of a course per cohort (classes in different
  /// cohorts are fine), so students who are already
  /// enrolled in this course — in this class or in another one of the same
  /// cohort — are NOT
  /// touched (nothing is overwritten or moved); they are reported back so the
  /// caller can tell the admin. A section's enrolled count is always derived
  /// from `student_courses`, never stored, so nothing else needs updating.
  Future<EnrollOutcome> enrollStudentsInSection(
    List<String> studentIds, {
    required String sectionId,
    required String courseId,
  });

  /// The classes [studentId] is currently enrolled in — Manage Enrolled
  /// Courses screen.
  Future<List<EnrolledClass>> getEnrolledClasses(String studentId);

  /// Removes the student_courses row for (studentId, courseId) — only the one in
  /// [sectionId] when given, since a student can be in several classes of a
  /// course (in different cohorts). A section's
  /// enrolled count is always derived from `student_courses`, never stored.
  Future<void> unenrollStudentFromCourse(String studentId, String courseId, {String? sectionId});

  /// Students currently enrolled in one class section (from
  /// `student_courses`, filtered to `sectionId`) — the "Manage Classes"
  /// detail screen's enrollment checklist.
  Future<List<RosterStudent>> getSectionRoster(String sectionId);

  /// Persists a lecturer's manual moderation adjustment for one student's
  /// `student_courses` row (Course Dashboard's Student Directory table).
  Future<void> updateModeratedScore(String studentId, String courseId, double moderatedScore, {String? sectionId});
}

/// Result of [AdminStudentsRepository.enrollStudentsInSection], as student ids.
/// [inOtherClass] maps a student already in a different class of the course to
/// that class's code (same cohort only).
typedef EnrollOutcome = ({List<String> enrolled, List<String> alreadyInThisClass, Map<String, String> inOtherClass});
