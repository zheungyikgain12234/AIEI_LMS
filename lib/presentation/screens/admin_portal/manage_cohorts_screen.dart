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
      load: () async => [for (final c in await repository.getCohorts()) (c.id, c.name)],
      create: (name) => repository.createCohort(name),
      update: (id, name) => repository.updateCohort(id, name),
      delete: (ids) => repository.deleteCohorts(ids),
    );
  }
}
