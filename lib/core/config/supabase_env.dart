/// Supabase connection settings, injected at build/run time via
/// `--dart-define-from-file=supabase.env.json` (see supabase.env.json.example).
class SupabaseEnv {
  SupabaseEnv._();

  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
