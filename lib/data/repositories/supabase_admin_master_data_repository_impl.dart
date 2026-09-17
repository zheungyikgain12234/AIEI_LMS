import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/department.dart';
import 'package:stitch_aiei_lms/domain/models/program_track.dart';
import 'package:stitch_aiei_lms/domain/models/cohort.dart';
import 'package:stitch_aiei_lms/domain/models/lecturer_department.dart';
import 'package:stitch_aiei_lms/domain/models/specialization.dart';
import 'package:stitch_aiei_lms/domain/models/role.dart';
import 'package:stitch_aiei_lms/domain/repositories/admin_master_data_repository.dart';

class SupabaseAdminMasterDataRepositoryImpl implements AdminMasterDataRepository {
  SupabaseAdminMasterDataRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Department>> getDepartments() async {
    final rows = await _client.from('departments').select().order('name');
    return [for (final row in rows as List) Department.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<Department> createDepartment(String name) async {
    final row = await _client.from('departments').insert({'name': name}).select().single();
    return Department.fromMap(row);
  }

  @override
  Future<Department> updateDepartment(String id, String name) async {
    final row = await _client.from('departments').update({'name': name}).eq('id', id).select().single();
    return Department.fromMap(row);
  }

  @override
  Future<void> deleteDepartments(List<String> ids) async {
    await _client.from('departments').delete().inFilter('id', ids);
  }

  @override
  Future<List<ProgramTrack>> getProgramTracks() async {
    final rows = await _client.from('program_tracks').select().order('name');
    return [for (final row in rows as List) ProgramTrack.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<ProgramTrack> createProgramTrack(String name) async {
    final row = await _client.from('program_tracks').insert({'name': name}).select().single();
    return ProgramTrack.fromMap(row);
  }

  @override
  Future<ProgramTrack> updateProgramTrack(String id, String name) async {
    final row = await _client.from('program_tracks').update({'name': name}).eq('id', id).select().single();
    return ProgramTrack.fromMap(row);
  }

  @override
  Future<void> deleteProgramTracks(List<String> ids) async {
    await _client.from('program_tracks').delete().inFilter('id', ids);
  }

  @override
  Future<List<Cohort>> getCohorts() async {
    final rows = await _client.from('cohorts').select().order('name');
    return [for (final row in rows as List) Cohort.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<Cohort> createCohort(String name) async {
    final row = await _client.from('cohorts').insert({'name': name}).select().single();
    return Cohort.fromMap(row);
  }

  @override
  Future<Cohort> updateCohort(String id, String name) async {
    final row = await _client.from('cohorts').update({'name': name}).eq('id', id).select().single();
    return Cohort.fromMap(row);
  }

  @override
  Future<void> deleteCohorts(List<String> ids) async {
    await _client.from('cohorts').delete().inFilter('id', ids);
  }

  @override
  Future<List<LecturerDepartment>> getLecturerDepartments() async {
    final rows = await _client.from('lecturer_departments').select().order('name');
    return [for (final row in rows as List) LecturerDepartment.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<LecturerDepartment> createLecturerDepartment(String name) async {
    final row = await _client.from('lecturer_departments').insert({'name': name}).select().single();
    return LecturerDepartment.fromMap(row);
  }

  @override
  Future<LecturerDepartment> updateLecturerDepartment(String id, String name) async {
    final row = await _client.from('lecturer_departments').update({'name': name}).eq('id', id).select().single();
    return LecturerDepartment.fromMap(row);
  }

  @override
  Future<void> deleteLecturerDepartments(List<String> ids) async {
    await _client.from('lecturer_departments').delete().inFilter('id', ids);
  }

  @override
  Future<List<Specialization>> getSpecializations() async {
    final rows = await _client.from('specializations').select().order('name');
    return [for (final row in rows as List) Specialization.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<Specialization> createSpecialization(String name) async {
    final row = await _client.from('specializations').insert({'name': name}).select().single();
    return Specialization.fromMap(row);
  }

  @override
  Future<Specialization> updateSpecialization(String id, String name) async {
    final row = await _client.from('specializations').update({'name': name}).eq('id', id).select().single();
    return Specialization.fromMap(row);
  }

  @override
  Future<void> deleteSpecializations(List<String> ids) async {
    await _client.from('specializations').delete().inFilter('id', ids);
  }

  @override
  Future<List<Role>> getRoles() async {
    final rows = await _client.from('roles').select().order('name');
    return [for (final row in rows as List) Role.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<Role> createRole(String name) async {
    final row = await _client.from('roles').insert({'name': name}).select().single();
    return Role.fromMap(row);
  }

  @override
  Future<Role> updateRole(String id, String name) async {
    final row = await _client.from('roles').update({'name': name}).eq('id', id).select().single();
    return Role.fromMap(row);
  }

  @override
  Future<void> deleteRoles(List<String> ids) async {
    await _client.from('roles').delete().inFilter('id', ids);
  }
}
