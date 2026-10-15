import 'package:stitch_aiei_lms/domain/repositories/submission_grading_repository.dart' show AttendanceStatus;

/// A class's attendance scoring: the raw marks one physical class is worth for
/// each [AttendanceStatus], and the percentage of the final grade attendance
/// counts for. Defaults apply until the lecturer changes them.
class AttendanceSettings {
  final double presentMarks;
  final double lateMarks;
  final double validAbsentMarks;
  final double invalidAbsentMarks;
  final double weightage;

  const AttendanceSettings({
    this.presentMarks = 3,
    this.lateMarks = 2,
    this.validAbsentMarks = 1,
    this.invalidAbsentMarks = 0,
    this.weightage = 0,
  });

  static const defaults = AttendanceSettings();

  /// Raw score for one session; an unmarked session earns nothing.
  double marksFor(String? status) => switch (status) {
        AttendanceStatus.present => presentMarks,
        AttendanceStatus.late => lateMarks,
        AttendanceStatus.validAbsent => validAbsentMarks,
        AttendanceStatus.invalidAbsent => invalidAbsentMarks,
        _ => 0,
      };

  factory AttendanceSettings.fromMap(Map<String, dynamic> map) => AttendanceSettings(
        presentMarks: (map['present_marks'] as num).toDouble(),
        lateMarks: (map['late_marks'] as num).toDouble(),
        validAbsentMarks: (map['valid_absent_marks'] as num).toDouble(),
        invalidAbsentMarks: (map['invalid_absent_marks'] as num).toDouble(),
        weightage: (map['attendance_weightage'] as num).toDouble(),
      );

  Map<String, dynamic> toMap(String sectionId) => {
        'section_id': sectionId,
        'present_marks': presentMarks,
        'late_marks': lateMarks,
        'valid_absent_marks': validAbsentMarks,
        'invalid_absent_marks': invalidAbsentMarks,
        'attendance_weightage': weightage,
      };
}
