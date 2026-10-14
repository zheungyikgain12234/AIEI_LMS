/// One row of `admins` — an Admin Portal user. Only name, email and username
/// are managed from the UI (`title` is shown in the header and left alone).
class AdminUser {
  final String id;
  final String name;
  final String email;
  final String username;

  const AdminUser({required this.id, required this.name, required this.email, required this.username});

  factory AdminUser.fromMap(Map<String, dynamic> map) => AdminUser(
        id: map['id'] as String,
        name: map['name'] as String,
        email: map['email'] as String,
        username: (map['username'] as String?) ?? '',
      );
}
