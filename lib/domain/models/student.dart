import 'package:stitch_aiei_lms/core/session/app_session.dart';

/// Internal students only carry [department] + [role] ([programTrack] stays
/// null); External students only carry a [programTrack] ([department]/[role]
/// stay null) — enforced by the `students_type_fields_check` constraint in
/// schema.sql, which the registration form mirrors.
enum StudentType {
  internal('Internal'),
  external('External');

  final String label;
  const StudentType(this.label);

  static StudentType fromLabel(String label) =>
      StudentType.values.firstWhere((t) => t.label == label, orElse: () => StudentType.internal);
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
      studentType: StudentType.fromLabel(map['student_type'] as String? ?? 'Internal'),
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
