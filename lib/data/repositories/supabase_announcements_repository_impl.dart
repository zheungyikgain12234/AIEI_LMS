import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/course_announcement.dart';
import 'package:stitch_aiei_lms/domain/repositories/announcements_repository.dart';

class SupabaseAnnouncementsRepositoryImpl implements AnnouncementsRepository {
  SupabaseAnnouncementsRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CourseAnnouncement>> getAnnouncementsForSection(String sectionId) async {
    final rows = await _client
        .from('course_announcements')
        .select('*, lecturers(name)')
        .eq('section_id', sectionId)
        .order('created_at', ascending: false);
    return [for (final row in rows as List) CourseAnnouncement.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<void> postAnnouncement({
    required String sectionId,
    required String lecturerId,
    required String title,
    required String body,
  }) async {
    await _client.from('course_announcements').insert({
      'section_id': sectionId,
      'lecturer_id': lecturerId,
      'title': title,
      'body': body,
    });
  }
}
