import 'package:stitch_aiei_lms/core/session/app_session.dart';

class Role {
  final String id;
  final String code;
  final String name;
  final String remarks;

  const Role({required this.id, required this.code, required this.name, this.remarks = ''});

  factory Role.fromMap(Map<String, dynamic> map) {
    return Role(
      id: map['id'] as String,
      code: displayCode(map['code'] as String),
      name: map['name'] as String,
      remarks: map['remarks'] as String? ?? '',
    );
  }
}
