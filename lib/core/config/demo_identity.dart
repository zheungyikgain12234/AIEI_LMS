/// The Login screen is a role-picker demo (no real Supabase Auth session
/// yet — see the migration plan), so every portal needs a fixed "who am I"
/// to query by. These ids match the seed rows in supabase/seed.sql.
class DemoIdentity {
  DemoIdentity._();

  // students.id is a bigint identity column (not a uuid like the other
  // tables) — David Kim is seeded as row 5. We're now starting on the
  // student portal, so the "signed-in" demo student was switched from Alex
  // Chen (row 1) to David Kim to test with a student who hasn't submitted
  // everything yet. NOTE: the materialAssignment02Id/materialComplianceQuizId/
  // materialOsheFinalExamId ids below only have real submission/progress
  // rows seeded for Alex Chen (see supabase/seed.sql) — the faculty
  // grade_assignment_screen.dart/grade_quiz_screen.dart, still hard-wired to
  // those specific material ids, will show empty/not-started state for
  // David Kim until matching seed rows are added for him too.
  // AssignmentSubmissionScreen/QuizAnsweringScreen (the real student
  // submission pages) don't use these constants — they're keyed by
  // contentBlockId/sectionId/studentId instead.
  static const String studentId = '5';
  static const String lecturerId = '11111111-1111-1111-1111-111111111106'; // Dr. Emmett Brown
  static const String adminId = '33333333-3333-3333-3333-333333333301';

  // ── Courses (see "Courses" block in supabase/seed.sql) ──────────────────
  static const String coursePyId = '44444444-4444-4444-4444-444444444401'; // PY-402
  static const String courseOsheId = '44444444-4444-4444-4444-444444444402'; // OSHE-101
  static const String courseSecId = '44444444-4444-4444-4444-444444444405'; // SEC-410

  // ── Specific module_materials this demo's student-facing submission /
  // faculty-facing grading screens are hard-wired to — only Alex Chen (row
  // 1) has seeded submission/progress rows against these (see comments
  // beside the matching rows in supabase/seed.sql). ───────────────────────
  static const String materialAssignment02Id = '66666666-6666-6666-6666-666666666611';
  static const String materialComplianceQuizId = '66666666-6666-6666-6666-666666666612';
  static const String materialOsheFinalExamId = '66666666-6666-6666-6666-666666666627';
}
