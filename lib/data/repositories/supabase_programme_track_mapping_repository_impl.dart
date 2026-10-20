import 'package:supabase_flutter/supabase_flutter.dart';

/// Which tracks sit under which programme (`programme_tracks`). A programme has
/// many tracks and a track can sit under more than one programme.
class SupabaseProgrammeTrackMappingRepositoryImpl {
  SupabaseProgrammeTrackMappingRepositoryImpl(this._client);

  final SupabaseClient _client;

  /// Track ids under [programmeId].
  Future<Set<String>> getTrackIdsForProgramme(String programmeId) async {
    final rows = await _client.from('programme_tracks').select('track_id').eq('programme_id', programmeId);
    return {for (final row in rows as List) row['track_id'] as String};
  }

  /// Track names under each programme name — for picking a track once a
  /// programme is chosen.
  Future<Map<String, Set<String>>> getTrackNamesByProgrammeName() async {
    final rows = await _client.from('programme_tracks').select('programmes(name), program_tracks(name)');
    final result = <String, Set<String>>{};
    for (final row in rows as List) {
      final programme = (row['programmes'] as Map?)?['name'] as String?;
      final track = (row['program_tracks'] as Map?)?['name'] as String?;
      if (programme == null || track == null) continue;
      result.putIfAbsent(programme, () => {}).add(track);
    }
    return result;
  }

  /// Programme names for each track name (a track can have several).
  Future<Map<String, Set<String>>> getProgrammeNamesByTrackName() async {
    final byProgramme = await getTrackNamesByProgrammeName();
    final result = <String, Set<String>>{};
    byProgramme.forEach((programme, tracks) {
      for (final track in tracks) {
        result.putIfAbsent(track, () => {}).add(programme);
      }
    });
    return result;
  }

  Future<void> setTrackForProgramme(String programmeId, String trackId, bool allowed) async {
    if (allowed) {
      await _client.from('programme_tracks').upsert({'programme_id': programmeId, 'track_id': trackId}, onConflict: 'programme_id,track_id');
    } else {
      await _client.from('programme_tracks').delete().eq('programme_id', programmeId).eq('track_id', trackId);
    }
  }
}
