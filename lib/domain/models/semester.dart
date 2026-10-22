import 'package:stitch_aiei_lms/core/session/app_session.dart';

class Semester {
  final String id;
  final String code;
  final String name;
  final int year;
  final String remarks;

  const Semester({required this.id, required this.code, required this.name, required this.year, this.remarks = ''});

  factory Semester.fromMap(Map<String, dynamic> map) {
    return Semester(
      id: map['id'] as String,
      code: displayCode(map['code'] as String),
      name: map['name'] as String,
      year: map['year'] as int,
      remarks: map['remarks'] as String? ?? '',
    );
  }
}
