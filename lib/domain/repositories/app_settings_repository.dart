/// Keys for the global, admin-toggleable feature flags stored in
/// `app_settings` (one boolean row per key).
class AppSettingKeys {
  /// When true, a student may submit an exam/quiz at most once — the exam
  /// answering screen blocks re-entry once a submission exists.
  static const singleExamAttempt = 'single_exam_attempt';

  /// When true, the inline "Mark Assignment"/"Mark Exam" buttons on the
  /// Syllabus editor's content-block rows are hidden — the faculty
  /// sidebar's "Grading & Submissions" entry becomes the only way in.
  static const hideMarkButtonsInSyllabus = 'hide_mark_buttons_in_syllabus';

  /// When true, the exam editor ("Manage Contents" on an exam content
  /// block) shows a control letting the lecturer reset one student's exam
  /// attempt by student code, clearing that student's submission so they
  /// can attempt the exam again.
  static const allowLecturerExamReset = 'allow_lecturer_exam_reset';
}

abstract class AppSettingsRepository {
  /// All settings, keyed by their `app_settings.key`. A key absent from the
  /// map (e.g. the table hasn't been seeded yet) should be treated as false
  /// by callers.
  Future<Map<String, bool>> getSettings();

  Future<void> updateSetting(String key, bool value);
}
