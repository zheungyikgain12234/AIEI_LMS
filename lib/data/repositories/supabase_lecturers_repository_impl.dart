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
  Future<Lecturer> getLecturerById(String id) async {
    final row = await _client.from('lecturers').select().eq('id', id).single();
    return Lecturer.fromMap(row);
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

  @override
  Future<Lecturer> createLecturer({
    required String name,
    required String title,
    required String employeeId,
    required String email,
    required String department,
    required String specialization,
    required int creditsMax,
    required String status,
    required bool accredited,
  }) async {
    final row = await _client
        .from('lecturers')
        .insert({
          'name': name,
          'title': title,
          'employee_id': employeeId,
          'email': email,
          'department': department,
          'specialization': specialization,
          'credits_max': creditsMax,
          'status': status,
          'accredited': accredited,
        })
        .select()
        .single();
    return Lecturer.fromMap(row);
  }

  @override
  Future<Lecturer> updateLecturer(
    String id, {
    required String name,
    required String title,
    required String employeeId,
    required String email,
    required String department,
    required String specialization,
    required int creditsMax,
    required String status,
    required bool accredited,
  }) async {
    final row = await _client
        .from('lecturers')
        .update({
          'name': name,
          'title': title,
          'employee_id': employeeId,
          'email': email,
          'department': department,
          'specialization': specialization,
          'credits_max': creditsMax,
          'status': status,
          'accredited': accredited,
        })
        .eq('id', id)
        .select()
        .single();
    return Lecturer.fromMap(row);
  }

  @override
  Future<void> deleteLecturers(List<String> ids) async {
    await _client.from('lecturers').delete().inFilter('id', ids);
  }

  @override
  Future<List<String>> getAssignedCourseIds(String lecturerId) async {
    final rows = await _client.from('lecturer_courses').select('course_id').eq('lecturer_id', lecturerId);
    return [for (final row in rows as List) row['course_id'] as String];
  }

  @override
  Future<void> assignCoursesToLecturer(String lecturerId, List<String> courseIds) async {
    await _client.from('lecturer_courses').insert([
      for (final courseId in courseIds) {'lecturer_id': lecturerId, 'course_id': courseId},
    ]);
  }

  @override
  Future<void> setCreditsUsed(String lecturerId, int creditsUsed) async {
    await _client.from('lecturers').update({'credits_used': creditsUsed}).eq('id', lecturerId);
  }
}
