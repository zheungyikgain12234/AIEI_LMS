import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Who's using the app and which tenant their data belongs to. Every portal
/// screen and repository query should eventually scope by [tenantId] once
/// this becomes a real multi-tenant deployment.
///
/// There's no real login/auth session yet (see [DemoIdentity] for the
/// per-portal hardcoded record ids), so this is hardcoded for now — replace
/// with the real signed-in identity once the Login screen does a real
/// Supabase Auth sign-in.
class AppSession {
  final String tenantId;
  final String username;

  const AppSession({required this.tenantId, required this.username});
}

const _demoSession = AppSession(tenantId: 'TN01', username: 'Zack');

/// The current [AppSession], readable from anywhere in the widget tree via
/// `ref.watch(appSessionProvider)`. A future real login screen can overwrite
/// it with `ref.read(appSessionProvider.notifier).set(AppSession(...))`.
class AppSessionNotifier extends Notifier<AppSession> {
  @override
  AppSession build() {
    _currentSession = _demoSession;
    return _demoSession;
  }

  void set(AppSession session) {
    state = session;
    _currentSession = session;
  }
}

final appSessionProvider = NotifierProvider<AppSessionNotifier, AppSession>(AppSessionNotifier.new);

/// Mirrors [appSessionProvider]'s value outside of Riverpod, so plain
/// (non-Consumer) widgets displaying a tenant-prefixed [code] — every master
/// data / lecturer / student / course / class / badge code — can strip that
/// prefix for display without becoming Consumer widgets. Users must never
/// see the tenant ID; it's an internal uniqueness device only.
AppSession _currentSession = _demoSession;

/// Strips the current tenant's prefix (e.g. `TN01-`) from a stored [code]
/// for display. Always use this instead of rendering a raw `code` field.
String displayCode(String code) {
  final prefix = '${_currentSession.tenantId}-';
  return code.startsWith(prefix) ? code.substring(prefix.length) : code;
}
