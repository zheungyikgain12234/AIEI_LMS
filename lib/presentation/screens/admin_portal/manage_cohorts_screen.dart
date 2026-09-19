import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_master_data_repository_impl.dart';
import 'master_data_screen.dart';
import 'widgets/admin_sidebar.dart';

class ManageCohortsScreen extends StatelessWidget {
  const ManageCohortsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = SupabaseAdminMasterDataRepositoryImpl(Supabase.instance.client);
    return MasterDataScreen(
      title: 'Manage Cohorts',
      description: 'Enrollment cohorts students are grouped into for cohort-based reporting.',
      itemLabel: 'Cohort',
      navDestination: AdminNavDestination.manageCohorts,
      showYear: true,
      load: () async => [
        for (final c in await repository.getCohorts())
          MasterDataRow(id: c.id, code: c.code, name: c.name, remarks: c.remarks, year: c.year),
      ],
      create: (code, name, remarks, year) => repository.createCohort(code, name, year!, remarks),
      update: (id, code, name, remarks, year) => repository.updateCohort(id, code, name, year!, remarks),
      delete: (ids) => repository.deleteCohorts(ids),
    );
  }
}
