import 'browser_fullscreen_types.dart';

Future<void> requestFullscreen() async {}

Future<void> exitFullscreen() async {}

bool get isFullscreenActive => false;

Unsubscribe listenFullscreenChange(void Function() onChange) => () {};

Unsubscribe listenPageHidden(void Function() onHidden) => () {};
