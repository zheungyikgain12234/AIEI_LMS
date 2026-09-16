import 'package:stitch_aiei_lms/domain/models/material_progress.dart';

/// Reads/writes one student's progress on one piece of course material —
/// backs both the student-facing submission screens (assignment upload,
/// compliance quiz) and the faculty-facing grading screens (grade quiz,
/// grade assignment), since they all read/write the same `student_materials`
/// row.
abstract class MaterialProgressRepository {
  Future<MaterialProgress?> getProgress(String studentId, String materialId);

  Future<void> submitContent(
    String studentId,
    String materialId,
    Map<String, dynamic> content, {
    String status = 'completed',
  });

  Future<void> gradeSubmission(
    String studentId,
    String materialId, {
    required int score,
    required String feedback,
    required String gradedByLecturerId,
  });

  /// All students' progress on one material, joined with student names —
  /// the roster shown on the Grade Quiz / Grade Assignment screens.
  Future<List<MaterialProgress>> getSubmissionsForMaterial(String materialId);
}
