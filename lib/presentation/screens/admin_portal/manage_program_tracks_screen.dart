import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_master_data_repository_impl.dart';
import 'master_data_screen.dart';
import 'widgets/admin_sidebar.dart';

class ManageProgramTracksScreen extends StatelessWidget {
  const ManageProgramTracksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = SupabaseAdminMasterDataRepositoryImpl(Supabase.instance.client);
    return MasterDataScreen(
      title: 'Manage Program Tracks',
      description: 'Academy specialization tracks students can be enrolled into.',
      itemLabel: 'Program Track',
      navDestination: AdminNavDestination.manageProgramTracks,
      load: () async => [for (final t in await repository.getProgramTracks()) (t.id, t.name)],
      create: (name) => repository.createProgramTrack(name),
      update: (id, name) => repository.updateProgramTrack(id, name),
      delete: (ids) => repository.deleteProgramTracks(ids),
    );
  }
}
