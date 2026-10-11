import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/programme.dart';

/// Programme master data plus the optional Programme ↔ Course mapping
/// (`course_programmes`).
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

  Future<Set<String>> getCourseIdsForProgramme(String programmeId) async {
    final rows = await _client.from('course_programmes').select('course_id').eq('programme_id', programmeId);
    return {for (final row in rows as List) row['course_id'] as String};
  }

  Future<void> setCourseForProgramme(String programmeId, String courseId, bool mapped) async {
    if (mapped) {
      await _client.from('course_programmes').upsert(
        {'programme_id': programmeId, 'course_id': courseId},
        onConflict: 'programme_id,course_id',
      );
    } else {
      await _client.from('course_programmes').delete().eq('programme_id', programmeId).eq('course_id', courseId);
    }
  }

  /// Programme names per course id, sorted by name — for the lecturer
  /// portal's class list pills. Courses with no programme are absent.
  Future<Map<String, List<String>>> getProgrammeNamesByCourse() async {
    final rows = await _client.from('course_programmes').select('course_id, programmes(name)');
    final result = <String, List<String>>{};
    for (final row in rows as List) {
      final name = (row['programmes'] as Map<String, dynamic>?)?['name'] as String?;
      if (name == null) continue;
      result.putIfAbsent(row['course_id'] as String, () => []).add(name);
    }
    for (final names in result.values) {
      names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }
    return result;
  }
}
