import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/session/app_session.dart';
import 'package:stitch_aiei_lms/core/supabase/supabase_providers.dart';
import 'package:stitch_aiei_lms/domain/models/student.dart';

/// What the portal header shows for whoever is "signed in": their name, a
/// one-line description, and (students and lecturers only) the unique
/// [code] identifying them. Loaded by the per-portal demo id in
/// [DemoIdentity] until there's a real login session.
class UserProfile {
  final String name;
  final String subtitle;
  final String? code;

  const UserProfile({required this.name, required this.subtitle, this.code});
}

final studentProfileProvider = FutureProvider<UserProfile>((ref) async {
  final row = await ref.watch(supabaseClientProvider).from('students').select().eq('id', DemoIdentity.studentId).single();
  final student = Student.fromMap(row);
  final detail = student.studentType == StudentType.internal ? student.department : student.programTrack;
  final parts = [
    if (student.title != null && student.title!.isNotEmpty) student.title!,
    if (detail != null && detail.isNotEmpty) detail,
  ];
  return UserProfile(name: student.name, subtitle: parts.join(' • '), code: student.studentCode);
});

final lecturerProfileProvider = FutureProvider<UserProfile>((ref) async {
  final row = await ref.watch(supabaseClientProvider).from('lecturers').select().eq('id', DemoIdentity.lecturerId).single();
  return UserProfile(
    name: row['name'] as String,
    subtitle: [row['title'] as String, row['department'] as String].join(' • '),
    code: displayCode(row['lecturer_code'] as String),
  );
});

final adminProfileProvider = FutureProvider<UserProfile>((ref) async {
  final row = await ref.watch(supabaseClientProvider).from('admins').select().eq('id', DemoIdentity.adminId).single();
  return UserProfile(name: row['name'] as String, subtitle: row['title'] as String);
});
