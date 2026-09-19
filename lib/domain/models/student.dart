import 'package:stitch_aiei_lms/core/session/app_session.dart';

class Student {
  final String id;
  final String name;
  final String studentCode;
  final String email;
  final String department;
  final String? title;
  final String programTrack;
  final String cohort;
  final String role;
  final double gpa;
  final DateTime registrationDate;

  const Student({
    required this.id,
    required this.name,
    required this.studentCode,
    required this.email,
    required this.department,
    this.title,
    required this.programTrack,
    required this.cohort,
    required this.role,
    required this.gpa,
    required this.registrationDate,
  });

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: (map['id'] as num).toString(),
      name: map['name'] as String,
      studentCode: displayCode(map['student_code'] as String),
      email: map['email'] as String,
      department: map['department'] as String,
      title: map['title'] as String?,
      programTrack: map['program_track'] as String,
      cohort: map['cohort'] as String,
      role: map['role'] as String,
      gpa: (map['gpa'] as num).toDouble(),
      registrationDate: DateTime.parse(map['registration_date'] as String),
    );
  }
}
