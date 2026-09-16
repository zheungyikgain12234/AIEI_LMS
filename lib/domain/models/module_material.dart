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
  final bool isPublished;
  final DateTime? dueAt;

  /// Files attached to this material (datasets, starter code, reference
  /// docs) — `[{name, sizeLabel, kind, footer}]`.
  final List<Map<String, dynamic>> attachedFiles;

  const ModuleMaterial({
    required this.id,
    required this.moduleId,
    required this.name,
    required this.type,
    required this.content,
    required this.sorting,
    this.isPublished = true,
    this.dueAt,
    this.attachedFiles = const [],
  });

  factory ModuleMaterial.fromMap(Map<String, dynamic> map) {
    return ModuleMaterial(
      id: map['id'] as String,
      moduleId: map['module_id'] as String,
      name: map['material_name'] as String,
      type: MaterialType.fromKey(map['material_type'] as String),
      content: Map<String, dynamic>.from(map['material_content'] as Map? ?? {}),
      sorting: map['material_sorting'] as int? ?? 0,
      isPublished: map['is_published'] as bool? ?? true,
      dueAt: map['due_at'] != null ? DateTime.parse(map['due_at'] as String) : null,
      attachedFiles: List<Map<String, dynamic>>.from(
        (map['attached_files'] as List? ?? []).map((f) => Map<String, dynamic>.from(f as Map)),
      ),
    );
  }
}
