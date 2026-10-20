import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/grade_distribution.dart';

/// The admin's grade distribution limits (stored as numeric `app_settings`
/// rows) and lecturers' requests to have a deviating distribution approved
/// (`grade_distribution_requests`).
class SupabaseGradeDistributionRepositoryImpl {
  SupabaseGradeDistributionRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const _keys = {
    GradeBandLimit.aPlus: 'grade_cap_a_plus',
    GradeBandLimit.aAndAbove: 'grade_cap_a',
    GradeBandLimit.aMinusAndAbove: 'grade_cap_a_minus',
    GradeBandLimit.bPlusAndAbove: 'grade_cap_b_plus',
  };

  /// A limit that was never saved uses the default; one saved blank means
  /// "no limit" (stored as the setting existing with an empty number).
  Future<GradeDistributionRules> getRules() async {
    try {
      final rows = await _client.from('app_settings').select('key, numeric_value').inFilter('key', _keys.values.toList());
      final byKey = {for (final row in rows as List) row['key'] as String: (row['numeric_value'] as num?)?.toDouble()};
      return GradeDistributionRules({
        for (final band in GradeBandLimit.values)
          band: byKey.containsKey(_keys[band]) ? byKey[_keys[band]] : GradeDistributionRules.defaults.percentFor(band),
      });
    } catch (_) {
      return GradeDistributionRules.defaults;
    }
  }

  Future<void> saveRules(GradeDistributionRules rules) async {
    for (final band in GradeBandLimit.values) {
      final key = _keys[band]!;
      final value = rules.percentFor(band);
      // Update the row if it exists, otherwise create it.
      final updated = await _client.from('app_settings').update({'numeric_value': value}).eq('key', key).select('key');
      if ((updated as List).isEmpty) {
        await _client.from('app_settings').insert({'key': key, 'value': false, 'numeric_value': value});
      }
    }
  }

  /// The newest request for a class, or null if there has never been one.
  Future<GradeDistributionRequest?> getLatestRequest(String sectionId) async {
    final rows = await _client
        .from('grade_distribution_requests')
        .select()
        .eq('section_id', sectionId)
        .order('created_at', ascending: false)
        .limit(1);
    final list = rows as List;
    return list.isEmpty ? null : GradeDistributionRequest.fromMap(list.first as Map<String, dynamic>);
  }

  Future<void> submitRequest({
    required String sectionId,
    required String lecturerId,
    required String justification,
    required GradeDistributionCheck check,
    GradeStatistics? stats,
  }) async {
    // Only one request can wait per class.
    await withdrawPending(sectionId);
    await _client.from('grade_distribution_requests').insert({
      'section_id': sectionId,
      'lecturer_id': lecturerId,
      'justification': justification,
      'distribution': check.counts,
      'enrolled_count': check.enrolled,
      'stats': stats?.toMap(),
    });
  }

  /// Removes the class's request that is still waiting for the admin, e.g.
  /// because the lecturer changed marks after sending it.
  Future<void> withdrawPending(String sectionId) async {
    await _client
        .from('grade_distribution_requests')
        .delete()
        .eq('section_id', sectionId)
        .eq('status', GradeDistributionRequestStatus.pending);
  }

  /// Requests for the admin to review, newest first, with the course, class
  /// and lecturer names filled in.
  Future<List<GradeDistributionRequest>> listRequests() async {
    final rows = await _client
        .from('grade_distribution_requests')
        .select('*, course_sections(section_code, courses(course_title)), lecturers(name)')
        .order('created_at', ascending: false);
    return [for (final row in rows as List) GradeDistributionRequest.fromMap(row as Map<String, dynamic>)];
  }

  Future<void> decide(String id, {required bool approved, String? note}) async {
    await _client.from('grade_distribution_requests').update({
      'status': approved ? GradeDistributionRequestStatus.approved : GradeDistributionRequestStatus.rejected,
      'admin_note': (note == null || note.trim().isEmpty) ? null : note.trim(),
      'decided_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  /// How many requests are waiting for the admin (for a badge).
  Future<int> pendingCount() async {
    final rows = await _client.from('grade_distribution_requests').select('id').eq('status', GradeDistributionRequestStatus.pending);
    return (rows as List).length;
  }
}
