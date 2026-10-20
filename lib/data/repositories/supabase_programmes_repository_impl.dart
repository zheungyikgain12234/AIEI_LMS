import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/programme.dart';

/// Programme master data, plus the programmes each course falls under, derived
/// from Programme ↔ Track Mapping and Track ↔ Course Mapping.
class SupabaseProgrammesRepositoryImpl {
  SupabaseProgrammesRepositoryImpl(this._client);

  final SupabaseClient _client;

  Future<List<Programme>> getProgrammes() async {
    final rows = await _client.from('programmes').select().order('name');
    return [for (final row in rows as List) Programme.fromMap(row as Map<String, dynamic>)];
  }

  Future<Programme> createProgramme(String code, String name, String description) async {
    final row = await _client.from('programmes').insert({'code': code, 'name': name, 'description': description}).select().single();
    return Programme.fromMap(row);
  }

  Future<Programme> updateProgramme(String id, String code, String name, String description) async {
    final row = await _client
        .from('programmes')
        .update({'code': code, 'name': name, 'description': description})
        .eq('id', id)
        .select()
        .single();
    return Programme.fromMap(row);
  }

  Future<void> deleteProgrammes(List<String> ids) async {
    await _client.from('programmes').delete().inFilter('id', ids);
  }

  /// Programme names per course id, sorted by name — for the programme pills in
  /// the student and lecturer portals. A course falls under a programme when one
  /// of its tracks (Track ↔ Course Mapping) belongs to that programme
  /// (Programme ↔ Track Mapping). Courses with no programme are absent.
  Future<Map<String, List<String>>> getProgrammeNamesByCourse() async {
    final trackRows = await _client.from('programme_tracks').select('track_id, programmes(name)');
    final programmesByTrack = <String, List<String>>{};
    for (final row in trackRows as List) {
      final name = (row['programmes'] as Map<String, dynamic>?)?['name'] as String?;
      if (name != null) programmesByTrack.putIfAbsent(row['track_id'] as String, () => []).add(name);
    }
    final courseRows = await _client.from('track_courses').select('course_id, track_id');
    final result = <String, List<String>>{};
    for (final row in courseRows as List) {
      final names = result.putIfAbsent(row['course_id'] as String, () => []);
      for (final name in programmesByTrack[row['track_id']] ?? const <String>[]) {
        if (!names.contains(name)) names.add(name);
      }
    }
    for (final names in result.values) {
      names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }
    return result;
  }
}
