class AdminProfile {
  final String id;
  final String name;
  final String title;
  final String email;

  const AdminProfile({
    required this.id,
    required this.name,
    required this.title,
    required this.email,
  });

  factory AdminProfile.fromMap(Map<String, dynamic> map) {
    return AdminProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      title: map['title'] as String,
      email: map['email'] as String,
    );
  }
}
