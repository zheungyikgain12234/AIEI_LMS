import 'package:supabase_flutter/supabase_flutter.dart';
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
}
