import 'package:stitch_aiei_lms/core/session/app_session.dart';

/// Internal ("Staff") students only carry [department] + [role]
/// ([programTrack] stays null); External ("Public") students only carry a
/// [programTrack] ([department]/[role] stay null) — enforced by the
/// `students_type_fields_check` constraint in schema.sql, which the
/// registration form mirrors. [dbValue] is the literal stored in
/// `students.student_type` (never shown to the user); [label] is the
/// display text ("Staff"/"Public").
enum StudentType {
  internal('Internal', 'Staff'),
  external('External', 'Public');

  final String dbValue;
  final String label;
  const StudentType(this.dbValue, this.label);

  static StudentType fromDbValue(String dbValue) =>
      StudentType.values.firstWhere((t) => t.dbValue == dbValue, orElse: () => StudentType.internal);
}

class Student {
  final String id;
  final String name;
  final String studentCode;
  final String email;
  final StudentType studentType;
  final String? department;
  final String? title;
  final String? programTrack;
  // Not set at registration — a student's cohort follows from the class
  // they're later enrolled into, not a standalone choice up front.
  final String? cohort;
  final String? role;
  final double gpa;
  final DateTime registrationDate;

  const Student({
    required this.id,
    required this.name,
    required this.studentCode,
    required this.email,
    required this.studentType,
    this.department,
    this.title,
    this.programTrack,
    this.cohort,
    this.role,
    required this.gpa,
    required this.registrationDate,
  });

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: (map['id'] as num).toString(),
      name: map['name'] as String,
      studentCode: displayCode(map['student_code'] as String),
      email: map['email'] as String,
      studentType: StudentType.fromDbValue(map['student_type'] as String? ?? 'Internal'),
      department: map['department'] as String?,
      title: map['title'] as String?,
      programTrack: map['program_track'] as String?,
      cohort: map['cohort'] as String?,
      role: map['role'] as String?,
      gpa: (map['gpa'] as num).toDouble(),
      registrationDate: DateTime.parse(map['registration_date'] as String),
    );
  }
}
