import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/material_progress.dart';
import 'package:stitch_aiei_lms/domain/repositories/material_progress_repository.dart';

class SupabaseMaterialProgressRepositoryImpl implements MaterialProgressRepository {
  SupabaseMaterialProgressRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<MaterialProgress?> getProgress(String studentId, String materialId) async {
    final row = await _client
        .from('student_materials')
        .select()
        .eq('student_id', studentId)
        .eq('material_id', materialId)
        .maybeSingle();
    return row == null ? null : MaterialProgress.fromMap(row);
  }

  @override
  Future<void> submitContent(
    String studentId,
    String materialId,
    Map<String, dynamic> content, {
    String status = 'completed',
  }) async {
    await _client.from('student_materials').upsert({
      'student_id': studentId,
      'material_id': materialId,
      'status': status,
      'submission_content': content,
      if (status == 'completed') 'completed_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> gradeSubmission(
    String studentId,
    String materialId, {
    required int score,
    required String feedback,
    required String gradedByLecturerId,
  }) async {
    await _client.from('student_materials').upsert({
      'student_id': studentId,
      'material_id': materialId,
      'status': 'completed',
      'score': score,
      'feedback': feedback,
      'graded_by': gradedByLecturerId,
      'graded_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<MaterialProgress>> getSubmissionsForMaterial(String materialId) async {
    final rows = await _client.from('student_materials').select().eq('material_id', materialId);
    return [for (final row in rows as List) MaterialProgress.fromMap(row as Map<String, dynamic>)];
  }
}
