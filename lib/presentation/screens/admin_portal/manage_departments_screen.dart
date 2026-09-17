import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_master_data_repository_impl.dart';
import 'master_data_screen.dart';
import 'widgets/admin_sidebar.dart';

class ManageDepartmentsScreen extends StatelessWidget {
  const ManageDepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = SupabaseAdminMasterDataRepositoryImpl(Supabase.instance.client);
    return MasterDataScreen(
      title: 'Manage Departments',
      description: 'Institutional departments available for student registration and reporting.',
      itemLabel: 'Department',
      navDestination: AdminNavDestination.manageDepartments,
      load: () async => [for (final d in await repository.getDepartments()) (d.id, d.name)],
      create: (name) => repository.createDepartment(name),
      update: (id, name) => repository.updateDepartment(id, name),
      delete: (ids) => repository.deleteDepartments(ids),
    );
  }
}
