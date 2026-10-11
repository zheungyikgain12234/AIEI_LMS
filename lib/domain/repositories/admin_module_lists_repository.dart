import 'package:stitch_aiei_lms/domain/models/module_list.dart';

/// Module Lists master data — reusable lists of module names an admin can
/// import while creating a class, or save from the class form.
abstract class AdminModuleListsRepository {
  Future<List<ModuleList>> getModuleLists();
  Future<ModuleList> createModuleList(String name, List<String> moduleNames);
  Future<void> updateModuleList(String id, String name, List<String> moduleNames);
  Future<void> deleteModuleLists(List<String> ids);
}
