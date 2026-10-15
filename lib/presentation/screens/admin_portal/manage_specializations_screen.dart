import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_master_data_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_relational_delete.dart';
import 'master_data_screen.dart';
import 'widgets/admin_sidebar.dart';

class ManageSpecializationsScreen extends StatelessWidget {
  const ManageSpecializationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = SupabaseAdminMasterDataRepositoryImpl(Supabase.instance.client);
    return MasterDataScreen(
      title: 'Manage Lecturer Specialisation',
      description: 'The subject areas lecturers are expert in, such as Cloud Computing. Tag each lecturer with them to help match lecturers to suitable courses.',
      itemLabel: 'Specialisation',
      navDestination: AdminNavDestination.manageSpecializations,
      load: () async => [
        for (final s in await repository.getSpecializations())
          MasterDataRow(id: s.id, code: s.code, name: s.name, remarks: s.remarks),
      ],
      create: (code, name, remarks, year) => repository.createSpecialization(code, name, remarks),
      update: (id, code, name, remarks, year) => repository.updateSpecialization(id, code, name, remarks),
      masterKind: MasterKind.specialization,
    );
  }
}
