import 'dart:typed_data';
import 'package:stitch_aiei_lms/domain/models/content_block.dart';
import 'package:stitch_aiei_lms/domain/models/course_module.dart';
import 'package:stitch_aiei_lms/domain/models/course_session.dart';

/// Backs the lecturer-facing "Syllabus" screen (My Assigned Courses →
/// Syllabus button) — a module → session → content-block authoring tree,
/// kept separate from the existing graded module_materials system. Scoped
/// to a class (`section_id`, a `course_sections` row), not a course — two
/// different classes of the same course can have a different syllabus.
abstract class LecturerSyllabusRepository {
  Future<List<CourseModule>> getModules(String sectionId);

  Future<CourseModule> createModule({required String sectionId, required String name, required String description});

  Future<CourseModule> updateModule(String id, {required String name, required String description, required bool isPublished});

  Future<void> deleteModule(String id);

  /// Persists a new module order after a drag-to-reorder — [orderedIds] is
  /// every module of the class, in its new top-to-bottom order.
  Future<void> reorderModules(String sectionId, List<String> orderedIds);

  Future<List<CourseSession>> getSessions(String moduleId);

  Future<CourseSession> createSession({required String moduleId, required String name, required String description});

  Future<CourseSession> updateSession(String id, {required String name, required String description, required bool isPublished});

  Future<void> deleteSession(String id);

  /// Persists a new session order after a drag-to-reorder — [orderedIds] is
  /// every session of the module, in its new top-to-bottom order.
  Future<void> reorderSessions(String moduleId, List<String> orderedIds);

  Future<List<ContentBlock>> getContentBlocks(String sessionId);

  Future<ContentBlock> addContentBlock({
    required String sessionId,
    required ContentBlockType type,
    required Map<String, dynamic> content,
  });

  Future<void> deleteContentBlock(String id);

  /// Persists a new content-block order after a drag-to-reorder —
  /// [orderedIds] is every block of the session, in its new top-to-bottom order.
  Future<void> reorderContentBlocks(String sessionId, List<String> orderedIds);

  /// Uploads raw bytes to the `course-content` storage bucket under
  /// `sessionId/fileName` and returns its public URL, for `video`/`image`/
  /// `file` blocks that attach a real uploaded file.
  Future<String> uploadContentFile({required String sessionId, required String fileName, required Uint8List bytes});
}
