import 'package:stitch_aiei_lms/domain/models/department.dart';
import 'package:stitch_aiei_lms/domain/models/program_track.dart';
import 'package:stitch_aiei_lms/domain/models/cohort.dart';
import 'package:stitch_aiei_lms/domain/models/lecturer_department.dart';
import 'package:stitch_aiei_lms/domain/models/specialization.dart';
import 'package:stitch_aiei_lms/domain/models/role.dart';

/// Admin-managed lookup lists that back the Student Registration and
/// Lecturer Onboarding forms' dropdowns.
abstract class AdminMasterDataRepository {
  Future<List<Department>> getDepartments();
  Future<Department> createDepartment(String name);
  Future<Department> updateDepartment(String id, String name);
  Future<void> deleteDepartments(List<String> ids);

  Future<List<ProgramTrack>> getProgramTracks();
  Future<ProgramTrack> createProgramTrack(String name);
  Future<ProgramTrack> updateProgramTrack(String id, String name);
  Future<void> deleteProgramTracks(List<String> ids);

  Future<List<Cohort>> getCohorts();
  Future<Cohort> createCohort(String name);
  Future<Cohort> updateCohort(String id, String name);
  Future<void> deleteCohorts(List<String> ids);

  Future<List<LecturerDepartment>> getLecturerDepartments();
  Future<LecturerDepartment> createLecturerDepartment(String name);
  Future<LecturerDepartment> updateLecturerDepartment(String id, String name);
  Future<void> deleteLecturerDepartments(List<String> ids);

  Future<List<Specialization>> getSpecializations();
  Future<Specialization> createSpecialization(String name);
  Future<Specialization> updateSpecialization(String id, String name);
  Future<void> deleteSpecializations(List<String> ids);

  Future<List<Role>> getRoles();
  Future<Role> createRole(String name);
  Future<Role> updateRole(String id, String name);
  Future<void> deleteRoles(List<String> ids);
}
