/// The Login screen is a role-picker demo (no real Supabase Auth session
/// yet — see the migration plan), so every portal needs a fixed "who am I"
/// to query by. These ids match the seed rows in supabase/seed.sql.
class DemoIdentity {
  DemoIdentity._();

  static const String studentId = '22222222-2222-2222-2222-222222222201';
  static const String lecturerId = '11111111-1111-1111-1111-111111111101';
  static const String adminId = '33333333-3333-3333-3333-333333333301';
}
