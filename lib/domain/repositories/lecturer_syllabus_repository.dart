import 'dart:typed_data';
import 'package:stitch_aiei_lms/domain/models/content_block.dart';
import 'package:stitch_aiei_lms/domain/models/course_module.dart';
import 'package:stitch_aiei_lms/domain/models/course_session.dart';
import 'package:stitch_aiei_lms/domain/models/syllabus_template.dart';

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

  /// A single content block by id — for a screen that only knows the
  /// block id (e.g. a student's "View Exam"/"View Assignment" deep link),
  /// without needing its whole session's block list. Null if it's been
  /// deleted.
  Future<ContentBlock?> getContentBlock(String id);

  Future<ContentBlock> addContentBlock({
    required String sessionId,
    required ContentBlockType type,
    required Map<String, dynamic> content,
  });

  /// Replaces a content block's `content` payload wholesale, e.g. after
  /// editing it from the pen icon on the Syllabus screen.
  Future<ContentBlock> updateContentBlock(String id, {required Map<String, dynamic> content});

  Future<void> deleteContentBlock(String id);

  /// Persists a new content-block order after a drag-to-reorder —
  /// [orderedIds] is every block of the session, in its new top-to-bottom order.
  Future<void> reorderContentBlocks(String sessionId, List<String> orderedIds);

  /// Uploads raw bytes to the `course-content` storage bucket under
  /// `sessionId/fileName` and returns its public URL, for `video`/`image`/
  /// `file` blocks that attach a real uploaded file.
  Future<String> uploadContentFile({required String sessionId, required String fileName, required Uint8List bytes});

  /// All saved templates, newest first — for the "Copy from Template" picker.
  Future<List<SyllabusTemplate>> getTemplates();

  /// Deep-copies the class's current module → session → content-block tree
  /// into a new named template.
  Future<void> saveAsTemplate({required String sectionId, required String name});

  /// Deep-copies a template's modules → sessions → content-blocks into the
  /// class, appended after any modules it already has.
  Future<void> copyFromTemplate({required String sectionId, required String templateId});

  /// Sum of `weightage` across every exam/assignment content block in this
  /// class's whole syllabus (every module/session, not just loaded ones) —
  /// used to enforce the "must not exceed 100%" rule when a lecturer sets a
  /// block's weightage. Pass [excludeContentBlockId] (the block being
  /// edited) so its own current weightage isn't double-counted.
  Future<double> getTotalWeightage(String sectionId, {String? excludeContentBlockId});
}
