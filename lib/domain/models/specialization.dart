class Specialization {
  final String id;
  final String name;

  const Specialization({required this.id, required this.name});

  factory Specialization.fromMap(Map<String, dynamic> map) {
    return Specialization(id: map['id'] as String, name: map['name'] as String);
  }
}
