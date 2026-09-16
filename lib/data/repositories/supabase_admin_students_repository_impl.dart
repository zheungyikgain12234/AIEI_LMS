import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/student.dart';
import 'package:stitch_aiei_lms/domain/models/roster_student.dart';
import 'package:stitch_aiei_lms/domain/models/enrollment_candidate.dart';
import 'package:stitch_aiei_lms/domain/repositories/admin_students_repository.dart';

class SupabaseAdminStudentsRepositoryImpl implements AdminStudentsRepository {
  SupabaseAdminStudentsRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Student>> getStudents() async {
    final rows = await _client.from('students').select().order('name');
    return [for (final row in rows as List) Student.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<Map<String, int>> getEnrollmentCounts() async {
    final rows = await _client.from('student_courses').select('student_id');
    final counts = <String, int>{};
    for (final row in rows as List) {
      final id = row['student_id'] as String;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<Map<String, List<String>>> getEarnedCredentialTitles() async {
    final rows = await _client
        .from('student_certifications')
        .select('student_id, status, certifications(title)')
        .inFilter('status', ['earned', 'revoked']);
    final result = <String, List<String>>{};
    for (final row in rows as List) {
      final id = row['student_id'] as String;
      final title = (row['certifications'] as Map<String, dynamic>)['title'] as String;
      final label = row['status'] == 'revoked' ? '$title (Revoked)' : title;
      result.putIfAbsent(id, () => []).add(label);
    }
    return result;
  }

  @override
  Future<List<(String, int)>> getProgramTracks() async {
    final rows = await _client.from('students').select('program_track');
    final counts = <String, int>{};
    for (final row in rows as List) {
      final track = row['program_track'] as String;
      counts[track] = (counts[track] ?? 0) + 1;
    }
    return [
      for (final entry in counts.entries) (entry.key, entry.value),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
  }

  @override
  Future<List<(String, int)>> getEnrollmentTrend() async {
    final rows = await _client.from('enrollment_monthly_stats').select().order('sort_order');
    return [
      for (final row in rows as List) (row['month_label'] as String, row['new_enrollments'] as int),
    ];
  }

  @override
  Future<List<RosterStudent>> getCourseRoster(String courseId) async {
    final rows = await _client
        .from('student_courses')
        .select('*, students(*)')
        .eq('course_id', courseId)
        .order('enrolled_at');
    return [for (final row in rows as List) RosterStudent.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<List<EnrollmentCandidate>> getEnrollmentCandidates(String courseId) async {
    final rows = await _client
        .from('enrollment_candidates')
        .select()
        .eq('target_course_id', courseId)
        .order('requested_at');
    return [
      for (final row in rows as List) EnrollmentCandidate.fromMap(row as Map<String, dynamic>),
    ];
  }
}
