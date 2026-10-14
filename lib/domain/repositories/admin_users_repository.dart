import 'package:stitch_aiei_lms/domain/models/admin_user.dart';

/// Admin Portal access to the `admins` table — the Manage Admin screen.
abstract class AdminUsersRepository {
  Future<List<AdminUser>> getAdmins();

  Future<AdminUser> createAdmin({required String name, required String email, required String username});

  Future<AdminUser> updateAdmin(String id, {required String name, required String email, required String username});

  Future<void> deleteAdmins(List<String> ids);
}
