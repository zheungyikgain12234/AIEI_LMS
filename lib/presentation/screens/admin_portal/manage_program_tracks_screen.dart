import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_master_data_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_relational_delete.dart';

import 'master_data_screen.dart';
import 'widgets/admin_sidebar.dart';

class ManageProgramTracksScreen extends StatelessWidget {
  const ManageProgramTracksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = SupabaseAdminMasterDataRepositoryImpl(
      Supabase.instance.client,
    );
    return MasterDataScreen(
      title: 'Manage Tracks',
      description: 'The learning tracks for public students, such as AI Engineering. Each student follows one track, and courses are linked to a track so they see the right ones.',
      itemLabel: 'Track',
      navDestination: AdminNavDestination.manageProgramTracks,
      load: () async => [
        for (final t in await repository.getProgramTracks())
          MasterDataRow(
            id: t.id,
            code: t.code,
            name: t.name,
            remarks: t.remarks,
          ),
      ],
      create: (code, name, remarks, year) =>
          repository.createProgramTrack(code, name, remarks),
      update: (id, code, name, remarks, year) =>
          repository.updateProgramTrack(id, code, name, remarks),
      masterKind: MasterKind.programTrack,
    );
  }
}
