import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/badge_catalog_item.dart';
import 'package:stitch_aiei_lms/domain/repositories/admin_badge_catalog_repository.dart';

class SupabaseAdminBadgeCatalogRepositoryImpl implements AdminBadgeCatalogRepository {
  SupabaseAdminBadgeCatalogRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const _select = 'id, code, title, description, issuing_body';

  @override
  Future<List<BadgeCatalogItem>> getBadges() async {
    final rows = await _client.from('certifications').select(_select).order('code');
    return [for (final row in rows as List) BadgeCatalogItem.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<BadgeCatalogItem> getBadgeById(String id) async {
    final row = await _client.from('certifications').select(_select).eq('id', id).single();
    return BadgeCatalogItem.fromMap(row);
  }

  @override
  Future<BadgeCatalogItem> createBadge({
    required String code,
    required String title,
    required String description,
    required String issuingBody,
  }) async {
    final row = await _client
        .from('certifications')
        .insert({'code': code, 'title': title, 'description': description, 'issuing_body': issuingBody})
        .select(_select)
        .single();
    return BadgeCatalogItem.fromMap(row);
  }

  @override
  Future<BadgeCatalogItem> updateBadge(
    String id, {
    required String code,
    required String title,
    required String description,
    required String issuingBody,
  }) async {
    final row = await _client
        .from('certifications')
        .update({'code': code, 'title': title, 'description': description, 'issuing_body': issuingBody})
        .eq('id', id)
        .select(_select)
        .single();
    return BadgeCatalogItem.fromMap(row);
  }

  @override
  Future<void> deleteBadges(List<String> ids) async {
    await _client.from('certifications').delete().inFilter('id', ids);
  }
}
