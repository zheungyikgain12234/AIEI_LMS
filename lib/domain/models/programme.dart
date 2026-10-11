import 'package:stitch_aiei_lms/core/session/app_session.dart';

/// An academic programme (e.g. a diploma or degree). `code` is the
/// Programme ID.
class Programme {
  final String id;
  final String code;
  final String name;
  final String description;

  const Programme({required this.id, required this.code, required this.name, this.description = ''});

  factory Programme.fromMap(Map<String, dynamic> map) {
    return Programme(
      id: map['id'] as String,
      code: displayCode(map['code'] as String),
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
    );
  }
}
