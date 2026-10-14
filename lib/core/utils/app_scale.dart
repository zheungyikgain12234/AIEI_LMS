import 'package:flutter/material.dart';

/// Renders the whole app scaled to suit the window, so it looks the same
/// physical size on a laptop and on a large monitor: text, icons and spacing
/// all scale together. The child is laid out in the adjusted logical space
/// (window ÷ scale) and painted scaled, so breakpoints, dialogs and
/// hit-testing stay consistent. Narrow (mobile) windows are left untouched.
class AppScale extends StatelessWidget {
  /// Window width (logical px) at which [baseScale] looks right — a typical laptop.
  static const double referenceWidth = 1530;
  static const double baseScale = 0.85;

  /// Never scale below the laptop look, nor above this (very large monitors).
  static const double minScale = 0.85;
  static const double maxScale = 1.3;

  static const double minWidthToScale = 900;

  final Widget child;

  const AppScale({super.key, required this.child});

  /// 0.85 up to the reference width, then grows in step with the window.
  static double scaleForWidth(double width) =>
      (baseScale * width / referenceWidth).clamp(minScale, maxScale).toDouble();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width < minWidthToScale) return child;
    final scale = scaleForWidth(media.size.width);
    final inner = Size(media.size.width / scale, media.size.height / scale);
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: inner.width,
        maxWidth: inner.width,
        minHeight: inner.height,
        maxHeight: inner.height,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topLeft,
          child: MediaQuery(
            data: media.copyWith(
              size: inner,
              padding: media.padding / scale,
              viewPadding: media.viewPadding / scale,
              viewInsets: media.viewInsets / scale,
            ),
            child: SizedBox.fromSize(size: inner, child: child),
          ),
        ),
      ),
    );
  }
}
