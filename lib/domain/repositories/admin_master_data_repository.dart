import 'package:stitch_aiei_lms/domain/models/department.dart';
import 'package:stitch_aiei_lms/domain/models/program_track.dart';
import 'package:stitch_aiei_lms/domain/models/cohort.dart';
import 'package:stitch_aiei_lms/domain/models/lecturer_department.dart';
import 'package:stitch_aiei_lms/domain/models/specialization.dart';
import 'package:stitch_aiei_lms/domain/models/role.dart';

/// Admin-managed lookup lists that back the Student Registration and
/// Lecturer Onboarding forms' dropdowns. Every row has a tenant-prefixed
/// unique [code] alongside its display [name] and free-text [remarks]
/// (never shown on the table, only in the edit form) — see AppSession.
abstract class AdminMasterDataRepository {
  Future<List<Department>> getDepartments();
  Future<Department> createDepartment(String code, String name, String remarks);
  Future<Department> updateDepartment(String id, String code, String name, String remarks);
  Future<void> deleteDepartments(List<String> ids);

  Future<List<ProgramTrack>> getProgramTracks();
  Future<ProgramTrack> createProgramTrack(String code, String name, String remarks);
  Future<ProgramTrack> updateProgramTrack(String id, String code, String name, String remarks);
  Future<void> deleteProgramTracks(List<String> ids);

  Future<List<Cohort>> getCohorts();
  Future<Cohort> createCohort(String code, String name, int year, String remarks);
  Future<Cohort> updateCohort(String id, String code, String name, int year, String remarks);
  Future<void> deleteCohorts(List<String> ids);

  Future<List<LecturerDepartment>> getLecturerDepartments();
  Future<LecturerDepartment> createLecturerDepartment(String code, String name, String remarks);
  Future<LecturerDepartment> updateLecturerDepartment(String id, String code, String name, String remarks);
  Future<void> deleteLecturerDepartments(List<String> ids);

  Future<List<Specialization>> getSpecializations();
  Future<Specialization> createSpecialization(String code, String name, String remarks);
  Future<Specialization> updateSpecialization(String id, String code, String name, String remarks);
  Future<void> deleteSpecializations(List<String> ids);

  Future<List<Role>> getRoles();
  Future<Role> createRole(String code, String name, String remarks);
  Future<Role> updateRole(String id, String code, String name, String remarks);
  Future<void> deleteRoles(List<String> ids);
}
