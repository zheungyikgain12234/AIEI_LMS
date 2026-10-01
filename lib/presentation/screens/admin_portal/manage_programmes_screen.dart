import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_programmes_repository_impl.dart';
import 'master_data_screen.dart';
import 'widgets/admin_sidebar.dart';

class ManageProgrammesScreen extends StatelessWidget {
  const ManageProgrammesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = SupabaseProgrammesRepositoryImpl(Supabase.instance.client);
    return MasterDataScreen(
      title: 'Manage Programmes',
      description: 'Academic programmes that courses can be mapped to.',
      itemLabel: 'Programme',
      codeLabel: 'Programme ID',
      nameLabel: 'Programme Name',
      remarksLabel: 'Programme Description',
      showRemarksColumn: true,
      navDestination: AdminNavDestination.manageProgrammes,
      load: () async => [
        for (final p in await repository.getProgrammes())
          MasterDataRow(id: p.id, code: p.code, name: p.name, remarks: p.description),
      ],
      create: (code, name, description, year) => repository.createProgramme(code, name, description),
      update: (id, code, name, description, year) => repository.updateProgramme(id, code, name, description),
      delete: (ids) => repository.deleteProgrammes(ids),
    );
  }
}
