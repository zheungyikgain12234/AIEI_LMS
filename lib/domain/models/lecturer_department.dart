class LecturerDepartment {
  final String id;
  final String name;

  const LecturerDepartment({required this.id, required this.name});

  factory LecturerDepartment.fromMap(Map<String, dynamic> map) {
    return LecturerDepartment(id: map['id'] as String, name: map['name'] as String);
  }
}
