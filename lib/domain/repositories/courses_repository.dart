import '../models/enrolled_course.dart';
import '../models/course_stats.dart';
import '../models/critical_action_item.dart';
import '../models/module_material.dart';

/// A class of a course the student can join without clashing with their schedule.
class EnrollableClass {
  final String sectionId;
  final String sectionCode;
  final String? semesterName;
  final String scheduleText;
  final String? location;

  const EnrollableClass({
    required this.sectionId,
    required this.sectionCode,
    required this.scheduleText,
    this.semesterName,
    this.location,
  });
}

abstract class CoursesRepository {
  Future<List<EnrolledCourse>> getEnrolledCourses();
  /// Pass [courses] (already loaded) to skip fetching them a second time.
  Future<CourseStats> getCourseStats({List<EnrolledCourse>? courses});

  /// The 2 real assignments/quizzes (across every enrolled course) nearest
  /// their due date that the student hasn't submitted yet.
  Future<List<CriticalActionItem>> getCriticalActions({int limit = 2});

  /// A course's materials in module order, each paired with the demo
  /// student's completion status — the lesson/module list shown on the
  /// Course Info screens.
  Future<List<(ModuleMaterial, String)>> getCourseLessons(String courseId);

  /// Courses mapped to the demo student's role (`role_courses`) that they
  /// aren't enrolled in yet. Empty for External students (they have no
  /// role) — powers the catalogue's "Compulsory for You" section.
  Future<List<EnrolledCourse>> getCompulsoryCourses();

  /// Enrolls the demo student into [courseId] via one of its existing
  /// classes (`course_sections`) — used when they click "Enroll" on a
  /// compulsory-but-not-enrolled course. Returns false (no write performed)
  /// if the course has no class yet (in [semesterId], when given).
  Future<bool> enrollInCompulsoryCourse(String courseId, {String? semesterId});

  /// Classes of [courseId] (in [semesterId], when given) the demo student can
  /// join: none of them clash with a class they already attend. Empty when
  /// they already have a class of the course in that semester.
  Future<List<EnrollableClass>> getEnrollableClasses(String courseId, {String? semesterId});

  /// Enrolls the demo student into the chosen class of [courseId]. Throws
  /// [ScheduleConflictException] if it now clashes with one they attend.
  Future<void> enrollInSection(String courseId, String sectionId);
}
