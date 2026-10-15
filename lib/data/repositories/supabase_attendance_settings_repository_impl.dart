import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/attendance_settings.dart';

class SupabaseAttendanceSettingsRepositoryImpl {
  SupabaseAttendanceSettingsRepositoryImpl(this._client);

  final SupabaseClient _client;

  /// The class's saved settings, or [AttendanceSettings.defaults] if the
  /// lecturer hasn't changed anything yet.
  Future<AttendanceSettings> getSettings(String sectionId) async {
    final row = await _client.from('section_attendance_settings').select().eq('section_id', sectionId).maybeSingle();
    return row == null ? AttendanceSettings.defaults : AttendanceSettings.fromMap(row);
  }

  Future<void> saveSettings(String sectionId, AttendanceSettings settings) async {
    await _client.from('section_attendance_settings').upsert(settings.toMap(sectionId));
  }
}
