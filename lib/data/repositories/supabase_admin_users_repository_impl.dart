import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/admin_user.dart';
import 'package:stitch_aiei_lms/domain/repositories/admin_users_repository.dart';

class SupabaseAdminUsersRepositoryImpl implements AdminUsersRepository {
  SupabaseAdminUsersRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AdminUser>> getAdmins() async {
    final rows = await _client.from('admins').select('id, name, email, username').order('name');
    return [for (final r in rows as List) AdminUser.fromMap(r as Map<String, dynamic>)];
  }

  @override
  Future<AdminUser> createAdmin({required String name, required String email, required String username}) async {
    final row = await _client
        .from('admins')
        .insert({'name': name, 'email': email, 'username': username})
        .select('id, name, email, username')
        .single();
    return AdminUser.fromMap(row);
  }

  @override
  Future<AdminUser> updateAdmin(String id, {required String name, required String email, required String username}) async {
    final row = await _client
        .from('admins')
        .update({'name': name, 'email': email, 'username': username})
        .eq('id', id)
        .select('id, name, email, username')
        .single();
    return AdminUser.fromMap(row);
  }

  @override
  Future<void> deleteAdmins(List<String> ids) async {
    await _client.from('admins').delete().inFilter('id', ids);
  }
}
