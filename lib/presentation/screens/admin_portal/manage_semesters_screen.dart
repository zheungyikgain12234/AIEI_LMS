import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_master_data_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_relational_delete.dart';

import 'master_data_screen.dart';
import 'widgets/admin_sidebar.dart';

class ManageSemestersScreen extends StatelessWidget {
  const ManageSemestersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = SupabaseAdminMasterDataRepositoryImpl(
      Supabase.instance.client,
    );
    return MasterDataScreen(
      title: 'Manage Semesters',
      description: 'Create a semester here so that classes can be created and assigned to it later',
      itemLabel: 'Semester',
      navDestination: AdminNavDestination.manageSemesters,
      showYear: true,
      load: () async => [
        for (final c in await repository.getSemesters())
          MasterDataRow(
            id: c.id,
            code: c.code,
            name: c.name,
            remarks: c.remarks,
            year: c.year,
          ),
      ],
      create: (code, name, remarks, year) =>
          repository.createSemester(code, name, year!, remarks),
      update: (id, code, name, remarks, year) =>
          repository.updateSemester(id, code, name, year!, remarks),
      masterKind: MasterKind.semester,
    );
  }
}
