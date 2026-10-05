import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/grade_scale.dart';
import 'package:stitch_aiei_lms/domain/repositories/app_settings_repository.dart';

class SupabaseAppSettingsRepositoryImpl implements AppSettingsRepository {
  SupabaseAppSettingsRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, bool>> getSettings() async {
    final rows = await _client.from('app_settings').select('key, value');
    return {for (final row in rows as List) row['key'] as String: row['value'] as bool};
  }

  @override
  Future<void> updateSetting(String key, bool value) async {
    await _client.from('app_settings').update({'value': value}).eq('key', key);
  }

  @override
  Future<Map<String, double?>> getNumericSettings() async {
    final rows = await _client.from('app_settings').select('key, numeric_value');
    return {for (final row in rows as List) row['key'] as String: (row['numeric_value'] as num?)?.toDouble()};
  }

  @override
  Future<void> updateNumericSetting(String key, double? value) async {
    await _client.from('app_settings').update({'numeric_value': value}).eq('key', key);
  }

  @override
  Future<GradeScale> getGradeScale() async {
    try {
      final rows = await _client.from('grade_scale').select('letter, min_score');
      final bands = [
        for (final row in rows as List) GradeBand(row['letter'] as String, (row['min_score'] as num).toDouble()),
      ]..sort((a, b) => a.minScore.compareTo(b.minScore));
      return bands.isEmpty ? GradeScale.defaultScale : GradeScale(bands);
    } catch (_) {
      return GradeScale.defaultScale;
    }
  }

  @override
  Future<void> saveGradeScale(GradeScale scale) async {
    await _client.from('grade_scale').upsert([
      for (var i = 0; i < scale.bands.length; i++)
        {'letter': scale.bands[i].letter, 'min_score': scale.bands[i].minScore, 'sort_order': i},
    ]);
  }
}
