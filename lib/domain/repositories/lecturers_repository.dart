import 'package:stitch_aiei_lms/domain/models/lecturer.dart';
import 'package:stitch_aiei_lms/domain/models/course_section.dart';

abstract class LecturersRepository {
  Future<List<Lecturer>> getLecturers();

  /// Course codes each lecturer teaches (from `lecturer_courses`), e.g.
  /// `{lecturerId: ['PY-402', 'DATA-501', 'AI-301']}` — drives the chip
  /// lists on the Manage Lecturers screen.
  Future<Map<String, List<String>>> getLecturerCourseCodes();

  /// All course sections with lecturer + course joined — the Lecturer
  /// Allocation screen's assigned/unassigned/available views all filter
  /// this same list.
  Future<List<CourseSection>> getAllSections();

  Future<void> assignLecturerToSection(String sectionId, String lecturerId);
}
