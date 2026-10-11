/// A reusable, named list of module names (`module_lists` +
/// `module_list_items` tables) — Module Lists master data, importable while
/// creating a class.
class ModuleList {
  final String id;
  final String name;
  final List<String> moduleNames;

  const ModuleList({required this.id, required this.name, required this.moduleNames});

  factory ModuleList.fromMap(Map<String, dynamic> map) {
    final items = [...(map['module_list_items'] as List? ?? const [])].cast<Map<String, dynamic>>()
      ..sort((a, b) => (a['item_sorting'] as int).compareTo(b['item_sorting'] as int));
    return ModuleList(
      id: map['id'] as String,
      name: map['name'] as String,
      moduleNames: [for (final item in items) item['module_name'] as String],
    );
  }
}
