enum MaterialType {
  lesson,
  quiz,
  assignment,
  video;

  static MaterialType fromKey(String key) {
    return MaterialType.values.firstWhere(
      (t) => t.name == key,
      orElse: () => MaterialType.lesson,
    );
  }
}

class ModuleMaterial {
  final String id;
  final String moduleId;
  final String name;
  final MaterialType type;

  /// Raw JSON payload — shape depends on [type] (quiz question bank,
  /// assignment instructions, lesson transcript, ...). Parsed by the
  /// screen that knows how to render that material type.
  final Map<String, dynamic> content;
  final int sorting;

  const ModuleMaterial({
    required this.id,
    required this.moduleId,
    required this.name,
    required this.type,
    required this.content,
    required this.sorting,
  });

  factory ModuleMaterial.fromMap(Map<String, dynamic> map) {
    return ModuleMaterial(
      id: map['id'] as String,
      moduleId: map['module_id'] as String,
      name: map['material_name'] as String,
      type: MaterialType.fromKey(map['material_type'] as String),
      content: Map<String, dynamic>.from(map['material_content'] as Map? ?? {}),
      sorting: map['material_sorting'] as int? ?? 0,
    );
  }
}
