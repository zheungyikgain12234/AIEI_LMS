import 'package:stitch_aiei_lms/core/session/app_session.dart';

class Lecturer {
  final String id;
  final String name;
  final String title;
  final String lecturerCode;
  final String email;
  final String department;
  /// Teaching competencies (names from the `specializations` lookup); a
  /// lecturer can have several.
  final List<String> competencies;
  final int creditsUsed;
  final int creditsMax;
  final String status;
  final bool accredited;
  final bool manageable;
  final DateTime joinDate;

  const Lecturer({
    required this.id,
    required this.name,
    required this.title,
    required this.lecturerCode,
    required this.email,
    required this.department,
    this.competencies = const [],
    required this.creditsUsed,
    required this.creditsMax,
    required this.status,
    required this.accredited,
    required this.manageable,
    required this.joinDate,
  });

  /// The competencies as one line for lists.
  String get competenciesLabel => competencies.isEmpty ? '—' : competencies.join(', ');

  int get capacityPercent =>
      creditsMax == 0 ? 0 : ((creditsUsed / creditsMax) * 100).round();

  factory Lecturer.fromMap(Map<String, dynamic> map) {
    return Lecturer(
      id: map['id'] as String,
      name: map['name'] as String,
      title: map['title'] as String,
      lecturerCode: displayCode(map['lecturer_code'] as String),
      email: map['email'] as String,
      department: map['department'] as String,
      competencies: [
        for (final row in (map['lecturer_competencies'] as List? ?? const []))
          if ((row as Map)['specializations'] != null) (row['specializations'] as Map)['name'] as String,
      ]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())),
      creditsUsed: map['credits_used'] as int,
      creditsMax: map['credits_max'] as int,
      status: map['status'] as String,
      accredited: map['accredited'] as bool,
      manageable: map['manageable'] as bool,
      joinDate: DateTime.parse(map['join_date'] as String),
    );
  }
}
