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
  Future<List<ModuleMaterial>> getCourseMaterials(String courseId) async {
    final modules = await _client
        .from('course_modules')
        .select('id, module_sorting')
        .eq('course_id', courseId)
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
  Future<List<CourseModule>> getCourseModules(String courseId) async {
    final rows = await _client
        .from('course_modules')
        .select()
        .eq('course_id', courseId)
        .order('module_sorting');
    return [for (final row in rows as List) CourseModule.fromMap(row as Map<String, dynamic>)];
  }
}
