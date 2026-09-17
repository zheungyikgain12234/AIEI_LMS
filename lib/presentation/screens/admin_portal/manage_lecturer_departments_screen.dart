import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_master_data_repository_impl.dart';
import 'master_data_screen.dart';
import 'widgets/admin_sidebar.dart';

class ManageLecturerDepartmentsScreen extends StatelessWidget {
  const ManageLecturerDepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = SupabaseAdminMasterDataRepositoryImpl(Supabase.instance.client);
    return MasterDataScreen(
      title: 'Manage Lecturer Departments',
      description: 'Faculty departments available for lecturer onboarding and allocation.',
      itemLabel: 'Department',
      navDestination: AdminNavDestination.manageLecturerDepartments,
      load: () async => [for (final d in await repository.getLecturerDepartments()) (d.id, d.name)],
      create: (name) => repository.createLecturerDepartment(name),
      update: (id, name) => repository.updateLecturerDepartment(id, name),
      delete: (ids) => repository.deleteLecturerDepartments(ids),
    );
  }
}
