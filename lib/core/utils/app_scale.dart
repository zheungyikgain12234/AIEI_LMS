import 'package:flutter/material.dart';

/// Renders the whole app at [scale] of its natural size on wide (desktop /
/// web) windows, so text, icons and spacing all shrink together. The child
/// is laid out in the enlarged logical space (window ÷ scale) and painted
/// scaled down, so breakpoints, dialogs and hit-testing all stay consistent.
/// Narrow (mobile) windows are left untouched.
class AppScale extends StatelessWidget {
  static const double defaultScale = 0.85;
  static const double minWidthToScale = 900;

  final double scale;
  final Widget child;

  const AppScale({super.key, required this.child, this.scale = defaultScale});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width < minWidthToScale || scale == 1) return child;
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
