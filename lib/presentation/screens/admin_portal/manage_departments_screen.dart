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
      load: () async => [
        for (final d in await repository.getDepartments())
          MasterDataRow(id: d.id, code: d.code, name: d.name, remarks: d.remarks),
      ],
      create: (code, name, remarks, year) => repository.createDepartment(code, name, remarks),
      update: (id, code, name, remarks, year) => repository.updateDepartment(id, code, name, remarks),
      delete: (ids) => repository.deleteDepartments(ids),
    );
  }
}
