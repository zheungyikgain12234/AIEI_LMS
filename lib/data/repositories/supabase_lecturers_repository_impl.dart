import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/course_section.dart';
import 'package:stitch_aiei_lms/domain/models/lecturer.dart';
import 'package:stitch_aiei_lms/domain/repositories/lecturers_repository.dart';

class SupabaseLecturersRepositoryImpl implements LecturersRepository {
  SupabaseLecturersRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Lecturer>> getLecturers() async {
    final rows = await _client.from('lecturers').select().order('name');
    return [for (final row in rows as List) Lecturer.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<Map<String, List<String>>> getLecturerCourseCodes() async {
    final rows = await _client.from('lecturer_courses').select('lecturer_id, courses(course_code)');
    final result = <String, List<String>>{};
    for (final row in rows as List) {
      final lecturerId = row['lecturer_id'] as String;
      final code = (row['courses'] as Map<String, dynamic>)['course_code'] as String;
      result.putIfAbsent(lecturerId, () => []).add(code);
    }
    return result;
  }

  @override
  Future<List<CourseSection>> getAllSections() async {
    final rows = await _client
        .from('course_sections')
        .select('*, courses(course_code, course_title), lecturers(name)')
        .order('section_code');
    return [
      for (final row in rows as List) CourseSection.fromMap(row as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> assignLecturerToSection(String sectionId, String lecturerId) async {
    await _client.from('course_sections').update({'lecturer_id': lecturerId}).eq('id', sectionId);
  }
}
