import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/module_list.dart';
import 'package:stitch_aiei_lms/domain/repositories/admin_module_lists_repository.dart';

class SupabaseAdminModuleListsRepositoryImpl implements AdminModuleListsRepository {
  SupabaseAdminModuleListsRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const _select = 'id, name, module_list_items(module_name, item_sorting)';

  @override
  Future<List<ModuleList>> getModuleLists() async {
    final rows = await _client.from('module_lists').select(_select).order('name');
    return [for (final row in rows as List) ModuleList.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<ModuleList> createModuleList(String name, List<String> moduleNames) async {
    final row = await _client.from('module_lists').insert({'name': name}).select('id').single();
    final id = row['id'] as String;
    await _insertItems(id, moduleNames);
    return ModuleList(id: id, name: name, moduleNames: moduleNames);
  }

  @override
  Future<void> updateModuleList(String id, String name, List<String> moduleNames) async {
    await _client.from('module_lists').update({'name': name}).eq('id', id);
    await _client.from('module_list_items').delete().eq('module_list_id', id);
    await _insertItems(id, moduleNames);
  }

  @override
  Future<void> deleteModuleLists(List<String> ids) async {
    await _client.from('module_lists').delete().inFilter('id', ids);
  }

  Future<void> _insertItems(String listId, List<String> moduleNames) async {
    if (moduleNames.isEmpty) return;
    await _client.from('module_list_items').insert([
      for (var i = 0; i < moduleNames.length; i++) {'module_list_id': listId, 'module_name': moduleNames[i], 'item_sorting': i},
    ]);
  }
}
