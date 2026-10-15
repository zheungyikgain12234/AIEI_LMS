import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';

/// A single-line row of pills that scrolls sideways when it doesn't fit, with
/// no scrollbar. To hint that it can be scrolled, hovering over it nudges the
/// row a little to the side and bounces it back. Touch and mouse drags scroll
/// it too.
class HintScrollRow extends StatefulWidget {
  final List<Widget> children;
  final double spacing;

  const HintScrollRow({super.key, required this.children, this.spacing = 6});

  @override
  State<HintScrollRow> createState() => _HintScrollRowState();
}

class _HintScrollRowState extends State<HintScrollRow> {
  final _controller = ScrollController();
  bool _nudging = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _nudge() async {
    if (_nudging || !_controller.hasClients) return;
    final max = _controller.position.maxScrollExtent;
    if (max <= 0) return; // everything already fits
    _nudging = true;
    try {
      await _controller.animateTo(max < 48 ? max : 48, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
      if (!mounted) return;
      await _controller.animateTo(0, duration: const Duration(milliseconds: 550), curve: Curves.bounceOut);
    } finally {
      _nudging = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _nudge(),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
          dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad, PointerDeviceKind.stylus},
        ),
        child: SingleChildScrollView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < widget.children.length; i++) ...[
                if (i > 0) SizedBox(width: widget.spacing),
                widget.children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small rounded pill used in the course card rows.
class CardPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  const CardPill({super.key, required this.label, required this.background, required this.foreground, this.icon});

  /// Programme the course belongs to.
  const CardPill.programme(this.label, {super.key})
      : background = const Color(0xFFEDE9FE),
        foreground = const Color(0xFF5B21B6),
        icon = null;

  /// A badge the student has not been granted yet.
  const CardPill.badgePending(this.label, {super.key})
      : background = const Color(0xFFDBEAFE),
        foreground = const Color(0xFF1E3A8A),
        icon = Icons.military_tech_outlined;

  /// A badge the student has already been granted.
  const CardPill.badgeGranted(this.label, {super.key})
      : background = const Color(0xFFDCFCE7),
        foreground = const Color(0xFF166534),
        icon = Icons.check_circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(9999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(label, maxLines: 1, style: AppTypography.labelSm(color: foreground).copyWith(fontWeight: FontWeight.w700, fontSize: 11)),
        ],
      ),
    );
  }
}
