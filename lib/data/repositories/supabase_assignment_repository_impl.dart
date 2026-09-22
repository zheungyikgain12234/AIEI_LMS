import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/assignment_criterion.dart';
import 'package:stitch_aiei_lms/domain/repositories/assignment_repository.dart';

class SupabaseAssignmentRepositoryImpl implements AssignmentRepository {
  SupabaseAssignmentRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AssignmentCriterion>> getCriteria(String contentBlockId) async {
    final rows = await _client
        .from('assignment_criteria')
        .select()
        .eq('content_block_id', contentBlockId)
        .order('criterion_sorting', ascending: true);
    return [for (final row in rows as List) AssignmentCriterion.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<AssignmentCriterion> createCriterion({
    required String contentBlockId,
    required String label,
    required double maxMarks,
  }) async {
    final existing = await _client.from('assignment_criteria').select('id').eq('content_block_id', contentBlockId);
    final row = await _client
        .from('assignment_criteria')
        .insert({
          'content_block_id': contentBlockId,
          'criterion_label': label,
          'max_marks': maxMarks,
          'criterion_sorting': (existing as List).length,
        })
        .select()
        .single();
    return AssignmentCriterion.fromMap(row);
  }

  @override
  Future<AssignmentCriterion> updateCriterion(String id, {required String label, required double maxMarks}) async {
    final row = await _client
        .from('assignment_criteria')
        .update({'criterion_label': label, 'max_marks': maxMarks})
        .eq('id', id)
        .select()
        .single();
    return AssignmentCriterion.fromMap(row);
  }

  @override
  Future<void> deleteCriterion(String id) async {
    await _client.from('assignment_criteria').delete().eq('id', id);
  }

  @override
  Future<void> reorderCriteria(String contentBlockId, List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      final updated =
          await _client.from('assignment_criteria').update({'criterion_sorting': i}).eq('id', orderedIds[i]).select('id');
      if ((updated as List).isEmpty) {
        throw StateError('No criterion matched id ${orderedIds[i]} — it may have been deleted elsewhere.');
      }
    }
  }

  @override
  Future<double> getTotalMarks(String contentBlockId) async {
    final rows = await _client.from('assignment_criteria').select('max_marks').eq('content_block_id', contentBlockId);
    var total = 0.0;
    for (final row in rows as List) {
      total += ((row as Map<String, dynamic>)['max_marks'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }
}
