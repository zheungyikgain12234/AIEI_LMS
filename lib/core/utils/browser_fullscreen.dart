/// Browser Fullscreen API access for exam lockdown — no-ops on every
/// platform except Flutter Web, where [requestFullscreen]/[exitFullscreen]
/// drive the real browser window and [listenFullscreenChange] reports when
/// fullscreen state changes (e.g. the student leaving it via Esc, F11, or
/// browser chrome) so the caller can re-prompt them.
library;

export 'browser_fullscreen_types.dart';
export 'browser_fullscreen_stub.dart' if (dart.library.html) 'browser_fullscreen_web.dart';
