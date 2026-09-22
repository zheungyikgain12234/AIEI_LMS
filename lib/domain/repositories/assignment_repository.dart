import 'package:stitch_aiei_lms/domain/models/assignment_criterion.dart';

/// Backs the "Manage Contents" (assignment) screen reached from an `assignment` content
/// block on the Syllabus screen — a flat list of grading criteria (each
/// worth a lecturer-defined number of marks), scoped to that one assignment
/// block. Scored per-student on the "Mark Assignment" screen.
abstract class AssignmentRepository {
  Future<List<AssignmentCriterion>> getCriteria(String contentBlockId);

  Future<AssignmentCriterion> createCriterion({
    required String contentBlockId,
    required String label,
    required double maxMarks,
  });

  Future<AssignmentCriterion> updateCriterion(String id, {required String label, required double maxMarks});

  Future<void> deleteCriterion(String id);

  /// Persists a new criterion order after a drag-to-reorder — [orderedIds]
  /// is every criterion of the assignment, in its new top-to-bottom order.
  Future<void> reorderCriteria(String contentBlockId, List<String> orderedIds);

  /// Sum of every criterion's [AssignmentCriterion.maxMarks] — the
  /// denominator shown on "Manage Contents" and the "Mark Assignment"
  /// grading screen.
  Future<double> getTotalMarks(String contentBlockId);
}
