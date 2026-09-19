import 'package:stitch_aiei_lms/core/session/app_session.dart';

class Department {
  final String id;
  final String code;
  final String name;
  final String remarks;

  const Department({required this.id, required this.code, required this.name, this.remarks = ''});

  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(
      id: map['id'] as String,
      code: displayCode(map['code'] as String),
      name: map['name'] as String,
      remarks: map['remarks'] as String? ?? '',
    );
  }
}
