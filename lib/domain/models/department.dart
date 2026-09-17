class Department {
  final String id;
  final String name;

  const Department({required this.id, required this.name});

  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(id: map['id'] as String, name: map['name'] as String);
  }
}
