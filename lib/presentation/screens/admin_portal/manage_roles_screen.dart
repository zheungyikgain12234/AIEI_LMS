import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_master_data_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_relational_delete.dart';

import 'master_data_screen.dart';
import 'widgets/admin_sidebar.dart';

class ManageRolesScreen extends StatelessWidget {
  const ManageRolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = SupabaseAdminMasterDataRepositoryImpl(
      Supabase.instance.client,
    );
    return MasterDataScreen(
      title: 'Manage Staff Roles',
      description: 'The job roles of internal students, such as IT Support Specialist or HVAC Installer. Each student has one role, and courses can be linked to a role so people get training that fits their job.',
      itemLabel: 'Role',
      note: '',
      navDestination: AdminNavDestination.manageRoles,
      load: () async => [
        for (final r in await repository.getRoles())
          MasterDataRow(
            id: r.id,
            code: r.code,
            name: r.name,
            remarks: r.remarks,
          ),
      ],
      create: (code, name, remarks, year) =>
          repository.createRole(code, name, remarks),
      update: (id, code, name, remarks, year) =>
          repository.updateRole(id, code, name, remarks),
      masterKind: MasterKind.role,
    );
  }
}
