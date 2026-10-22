import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// One line of text that scrolls sideways when it does not fit, instead of
/// being cut off with "…". Only the text moves; the rest of the row stays put.
/// A soft fade at the clipped edge hints that there is more to scroll to.
class ScrollableText extends StatefulWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;

  const ScrollableText(this.data, {super.key, this.style, this.textAlign});

  @override
  State<ScrollableText> createState() => _ScrollableTextState();
}

class _ScrollableTextState extends State<ScrollableText> {
  static const _fade = 24.0;
  final _controller = ScrollController();
  bool _fadeLeft = false;
  bool _fadeRight = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _onMetrics(ScrollMetrics m) {
    final left = m.pixels > 0.5;
    final right = m.pixels < m.maxScrollExtent - 0.5;
    if (left != _fadeLeft || right != _fadeRight) {
      // Metrics arrive during layout/after a frame; update after it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _fadeLeft = left;
          _fadeRight = right;
        });
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final behavior = ScrollConfiguration.of(context).copyWith(
      scrollbars: false,
      dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad, PointerDeviceKind.stylus},
    );
    Widget scroller = ScrollConfiguration(
      behavior: behavior,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Text(widget.data, style: widget.style, textAlign: widget.textAlign, softWrap: false, maxLines: 1),
      ),
    );
    scroller = NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _onMetrics(n.metrics),
      child: NotificationListener<ScrollNotification>(onNotification: (n) => _onMetrics(n.metrics), child: scroller),
    );
    if (!_fadeLeft && !_fadeRight) return scroller;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) {
        final f = (_fade / (rect.width == 0 ? 1 : rect.width)).clamp(0.0, 0.5);
        return LinearGradient(
          stops: [0, f, 1 - f, 1],
          colors: [
            _fadeLeft ? Colors.transparent : Colors.black,
            Colors.black,
            Colors.black,
            _fadeRight ? Colors.transparent : Colors.black,
          ],
        ).createShader(rect);
      },
      child: scroller,
    );
  }
}
