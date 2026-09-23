import 'package:stitch_aiei_lms/domain/models/assigned_course.dart';
import 'package:stitch_aiei_lms/domain/models/course_module.dart';
import 'package:stitch_aiei_lms/domain/models/module_material.dart';

/// Real per-section assessment stats, sourced from `content_block_submissions`
/// (the same data `CourseDashboardScreen` reads) rather than the legacy
/// `module_materials`/`student_materials` tables or the denormalized
/// `student_courses.progress_percentage` column (which isn't scoped to a
/// single section and can drift from actual submissions).
/// - [pendingAssignments]/[pendingQuizzes]: assignment/exam
///   `content_block_submissions` with status `submitted` (awaiting grading).
/// - [avgProgress]: average, over students enrolled in this section, of
///   (graded assessments / total assessments) — 0 if the section has no
///   assessments or no enrolled students.
typedef SectionAssessmentStats = ({int pendingAssignments, int pendingQuizzes, int avgProgress});

abstract class FacultyRepository {
  Future<List<AssignedCourse>> getAssignedCourses(String lecturerId);

  /// module_materials for a class, joined through course_modules, ordered
  /// by module then material sorting — used by the Curriculum Manager and
  /// as the source list for Grade Quiz / Grade Assignment.
  Future<List<ModuleMaterial>> getCourseMaterials(String sectionId);

  /// course_modules for a class, ordered by sorting — used by the
  /// Curriculum Manager to render one card per module.
  Future<List<CourseModule>> getCourseModules(String sectionId);

  /// The `course_sections.id` of one class teaching [courseId] — for the
  /// couple of legacy demo screens that were built around a course id
  /// before module content became class-scoped, and just need any one
  /// section to resolve it through. Null if the course has no class yet.
  Future<String?> getPrimarySectionIdForCourse(String courseId);

  /// Batched real assessment stats for every section in [sectionIds], keyed
  /// by `sectionId`, in one round trip. A section with no assessments/no
  /// enrolled students is present in the map with zero values, not absent.
  Future<Map<String, SectionAssessmentStats>> getSectionAssessmentStats(List<String> sectionIds);
}
