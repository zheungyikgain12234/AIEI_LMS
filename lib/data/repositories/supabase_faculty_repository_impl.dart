import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/assigned_course.dart';
import 'package:stitch_aiei_lms/domain/models/course_module.dart';
import 'package:stitch_aiei_lms/domain/models/module_material.dart';
import 'package:stitch_aiei_lms/domain/repositories/faculty_repository.dart';

class SupabaseFacultyRepositoryImpl implements FacultyRepository {
  SupabaseFacultyRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AssignedCourse>> getAssignedCourses(String lecturerId) async {
    final rows = await _client
        .from('course_sections')
        .select('*, courses(*), cohorts(name)')
        .eq('lecturer_id', lecturerId)
        .order('section_code');
    final sectionIds = [for (final row in rows as List) row['id'] as String];
    final enrolled = sectionIds.isEmpty
        ? const []
        : await _client.from('student_courses').select('section_id').inFilter('section_id', sectionIds);
    final counts = <String, int>{};
    for (final row in enrolled as List) {
      final sectionId = row['section_id'] as String;
      counts[sectionId] = (counts[sectionId] ?? 0) + 1;
    }
    return [
      for (final row in rows)
        AssignedCourse.fromMap(row as Map<String, dynamic>, enrolledCount: counts[row['id'] as String] ?? 0),
    ];
  }

  @override
  Future<List<ModuleMaterial>> getCourseMaterials(String sectionId) async {
    final modules = await _client
        .from('course_modules')
        .select('id, module_sorting')
        .eq('section_id', sectionId)
        .order('module_sorting');
    final moduleIds = [for (final m in modules as List) m['id'] as String];
    if (moduleIds.isEmpty) return [];

    final materials = await _client
        .from('module_materials')
        .select()
        .inFilter('module_id', moduleIds)
        .order('material_sorting');
    return [
      for (final row in materials as List) ModuleMaterial.fromMap(row as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<CourseModule>> getCourseModules(String sectionId) async {
    final rows = await _client
        .from('course_modules')
        .select()
        .eq('section_id', sectionId)
        .order('module_sorting');
    return [for (final row in rows as List) CourseModule.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<String?> getPrimarySectionIdForCourse(String courseId) async {
    final rows = await _client.from('course_sections').select('id').eq('course_id', courseId).order('section_code').limit(1);
    final list = rows as List;
    return list.isEmpty ? null : list.first['id'] as String;
  }

  @override
  Future<Map<String, SectionAssessmentStats>> getSectionAssessmentStats(List<String> sectionIds) async {
    if (sectionIds.isEmpty) return {};
    final zero = {for (final id in sectionIds) id: (pendingAssignments: 0, pendingQuizzes: 0, avgProgress: 0)};

    // Every student enrolled in each section — the denominator for
    // avgProgress. Scoped by `section_id` (not `course_id`), so a student
    // enrolled in the same course through a different section/cohort is
    // correctly excluded.
    final rosterRows = await _client.from('student_courses').select('student_id, section_id').inFilter('section_id', sectionIds);
    final studentIdsBySection = <String, List<String>>{};
    for (final row in rosterRows as List) {
      final sectionId = row['section_id'] as String?;
      if (sectionId == null) continue;
      studentIdsBySection.putIfAbsent(sectionId, () => []).add((row['student_id'] as num).toString());
    }

    final moduleRows = await _client.from('course_modules').select('id, section_id').inFilter('section_id', sectionIds);
    final sectionByModule = {for (final row in moduleRows as List) row['id'] as String: row['section_id'] as String};
    if (sectionByModule.isEmpty) return zero;

    final sessionRows = await _client.from('sessions').select('id, module_id').inFilter('module_id', sectionByModule.keys.toList());
    final moduleBySession = {for (final row in sessionRows as List) row['id'] as String: row['module_id'] as String};
    if (moduleBySession.isEmpty) return zero;

    final blockRows = await _client
        .from('content_blocks')
        .select('id, block_type, session_id')
        .inFilter('session_id', moduleBySession.keys.toList())
        .inFilter('block_type', ['exam', 'assignment']);
    final sectionByBlock = <String, String>{};
    final typeByBlock = <String, String>{};
    final totalAssessmentsBySection = <String, int>{};
    for (final row in blockRows as List) {
      final blockId = row['id'] as String;
      final moduleId = moduleBySession[row['session_id'] as String];
      final sectionId = moduleId == null ? null : sectionByModule[moduleId];
      if (sectionId == null) continue;
      sectionByBlock[blockId] = sectionId;
      typeByBlock[blockId] = row['block_type'] as String;
      totalAssessmentsBySection[sectionId] = (totalAssessmentsBySection[sectionId] ?? 0) + 1;
    }
    if (sectionByBlock.isEmpty) return zero;

    final submissionRows = await _client
        .from('content_block_submissions')
        .select('content_block_id, student_id, status')
        .inFilter('content_block_id', sectionByBlock.keys.toList());

    final assignmentsPendingBySection = <String, int>{};
    final quizzesPendingBySection = <String, int>{};
    final gradedCountByStudentSection = <String, int>{};
    for (final row in submissionRows as List) {
      final blockId = row['content_block_id'] as String;
      final sectionId = sectionByBlock[blockId];
      if (sectionId == null) continue;
      final status = row['status'] as String?;
      if (status == 'submitted') {
        if (typeByBlock[blockId] == 'assignment') {
          assignmentsPendingBySection[sectionId] = (assignmentsPendingBySection[sectionId] ?? 0) + 1;
        } else if (typeByBlock[blockId] == 'exam') {
          quizzesPendingBySection[sectionId] = (quizzesPendingBySection[sectionId] ?? 0) + 1;
        }
      } else if (status == 'graded') {
        final studentId = (row['student_id'] as num).toString();
        final key = '$sectionId:$studentId';
        gradedCountByStudentSection[key] = (gradedCountByStudentSection[key] ?? 0) + 1;
      }
    }

    return {
      for (final id in sectionIds)
        id: (
          pendingAssignments: assignmentsPendingBySection[id] ?? 0,
          pendingQuizzes: quizzesPendingBySection[id] ?? 0,
          avgProgress: _avgProgressForSection(
            studentIds: studentIdsBySection[id] ?? const [],
            totalAssessments: totalAssessmentsBySection[id] ?? 0,
            gradedCountByStudentSection: gradedCountByStudentSection,
            sectionId: id,
          ),
        ),
    };
  }

  int _avgProgressForSection({
    required List<String> studentIds,
    required int totalAssessments,
    required Map<String, int> gradedCountByStudentSection,
    required String sectionId,
  }) {
    if (studentIds.isEmpty || totalAssessments == 0) return 0;
    final progressSum = studentIds.fold<int>(0, (sum, studentId) {
      final graded = gradedCountByStudentSection['$sectionId:$studentId'] ?? 0;
      return sum + ((graded / totalAssessments) * 100).round();
    });
    return (progressSum / studentIds.length).round();
  }
}
