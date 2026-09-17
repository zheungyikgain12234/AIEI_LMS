class Cohort {
  final String id;
  final String name;

  const Cohort({required this.id, required this.name});

  factory Cohort.fromMap(Map<String, dynamic> map) {
    return Cohort(id: map['id'] as String, name: map['name'] as String);
  }
}
