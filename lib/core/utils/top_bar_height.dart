import 'dart:ui';

/// Height of the custom mobile top bars: the 64px bar plus the status-bar /
/// notch inset, so the `SafeArea` inside a bar doesn't eat into its 64px.
/// Read from the platform view because `preferredSize` has no BuildContext.
double mobileTopBarHeight() {
  final views = PlatformDispatcher.instance.views;
  if (views.isEmpty) return 64;
  final view = views.first;
  return 64 + view.padding.top / view.devicePixelRatio;
}
