import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'browser_fullscreen_types.dart';

Future<void> requestFullscreen() async {
  final el = web.document.documentElement;
  if (el == null) return;
  try {
    await el.requestFullscreen().toDart;
  } catch (_) {
    // Browsers refuse this without a fresh user gesture — the caller
    // surfaces its own "click to continue in fullscreen" prompt instead of
    // failing silently.
  }
}

Future<void> exitFullscreen() async {
  if (web.document.fullscreenElement == null) return;
  try {
    await web.document.exitFullscreen().toDart;
  } catch (_) {}
}

bool get isFullscreenActive => web.document.fullscreenElement != null;

/// Calls [onChange] every time the browser enters or leaves fullscreen —
/// including the browser's own exit-fullscreen chrome (Esc, F11) as well as
/// our own [requestFullscreen]/[exitFullscreen] calls. Callers re-check
/// [isFullscreenActive] rather than trust an exited/entered flag here.
Unsubscribe listenFullscreenChange(void Function() onChange) {
  final listener = ((web.Event _) => onChange()).toJS;
  web.document.addEventListener('fullscreenchange', listener);
  return () => web.document.removeEventListener('fullscreenchange', listener);
}

/// Calls [onHidden] when the browser tab/window loses OS-level focus or
/// visibility — Alt+Tab, Win+Tab, switching to another app, minimizing, or
/// the focus loss that happens the instant Ctrl+Alt+Del is pressed. Windows
/// reserves Ctrl+Alt+Del as a secure attention sequence no user-mode
/// software (this included) can intercept or block directly — this only
/// observes the resulting focus loss, same as it does for any other
/// app-switch. Listens on both signals since either can fire without the
/// other depending on platform/window manager.
Unsubscribe listenPageHidden(void Function() onHidden) {
  final visibilityListener = ((web.Event _) {
    if (web.document.visibilityState == 'hidden') onHidden();
  }).toJS;
  final blurListener = ((web.Event _) => onHidden()).toJS;
  web.document.addEventListener('visibilitychange', visibilityListener);
  web.window.addEventListener('blur', blurListener);
  return () {
    web.document.removeEventListener('visibilitychange', visibilityListener);
    web.window.removeEventListener('blur', blurListener);
  };
}
