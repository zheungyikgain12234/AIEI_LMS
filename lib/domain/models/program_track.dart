class ProgramTrack {
  final String id;
  final String name;

  const ProgramTrack({required this.id, required this.name});

  factory ProgramTrack.fromMap(Map<String, dynamic> map) {
    return ProgramTrack(id: map['id'] as String, name: map['name'] as String);
  }
}
