import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_master_data_repository_impl.dart';
import 'master_data_screen.dart';
import 'widgets/admin_sidebar.dart';

class ManageRolesScreen extends StatelessWidget {
  const ManageRolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = SupabaseAdminMasterDataRepositoryImpl(Supabase.instance.client);
    return MasterDataScreen(
      title: 'Manage Roles',
      description: 'Job roles (e.g. IT Support Specialist, HVAC / Aircon Installer) used for student registration and the Role ↔ Course Mapping screen.',
      itemLabel: 'Role',
      note: 'For internal, role list are controlled externally by HRIQ system. For external customers, manage roles here.',
      navDestination: AdminNavDestination.manageRoles,
      load: () async => [for (final r in await repository.getRoles()) (r.id, r.name)],
      create: (name) => repository.createRole(name),
      update: (id, name) => repository.updateRole(id, name),
      delete: (ids) => repository.deleteRoles(ids),
    );
  }
}
