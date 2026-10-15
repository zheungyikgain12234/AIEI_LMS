import 'package:flutter/material.dart';

/// A softly pulsing grey block shown where content is still loading, so a page
/// can show its frame and fill in piece by piece instead of a full-screen
/// spinner.
class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const Skeleton({super.key, this.width, required this.height, this.radius = 6});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(const Color(0xFFE2E8F0), const Color(0xFFF1F5F9), _controller.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// A white card with skeleton rows: stands in for a list/table while it loads.
class SkeletonCard extends StatelessWidget {
  final int rows;
  final double rowHeight;
  final bool withSearchBar;

  const SkeletonCard({super.key, this.rows = 7, this.rowHeight = 48, this.withSearchBar = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (withSearchBar) ...const [Skeleton(height: 44, radius: 10), SizedBox(height: 16)],
          for (var i = 0; i < rows; i++) ...[
            Skeleton(height: rowHeight, radius: 8),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

/// The body of a page while its data loads: a title, a subtitle and a list
/// card, all as placeholders. The page's own frame (header, side menu) is shown
/// around it by the caller.
class SkeletonPage extends StatelessWidget {
  const SkeletonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Skeleton(width: 280, height: 34),
        SizedBox(height: 10),
        Skeleton(width: 460, height: 14),
        SizedBox(height: 22),
        SkeletonCard(),
      ],
    );
  }
}

/// [SkeletonPage] in a plain scrollable [Scaffold], for screens with no
/// side menu (editors, marking screens, forms) and for phones.
class SkeletonScaffold extends StatelessWidget {
  const SkeletonScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: SkeletonPage(),
        ),
      ),
    );
  }
}

/// Placeholder for the student catalogue's top banner (stats + critical actions).
class SkeletonBanner extends StatelessWidget {
  const SkeletonBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1024;
      Widget card({double height = 150}) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Skeleton(width: 200, height: 22),
                const SizedBox(height: 16),
                Skeleton(height: height - 90, radius: 10),
              ],
            ),
          );
      return wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 8, child: card()), const SizedBox(width: 24), Expanded(flex: 4, child: card())])
          : Column(children: [card(), const SizedBox(height: 16), card()]);
    });
  }
}

/// Placeholder for a grid of course cards.
class SkeletonCourseGrid extends StatelessWidget {
  final int count;

  const SkeletonCourseGrid({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 1100 ? 3 : (constraints.maxWidth >= 700 ? 2 : 1);
      final width = (constraints.maxWidth - (cols - 1) * 24) / cols;
      return Wrap(
        spacing: 24,
        runSpacing: 24,
        children: [
          for (var i = 0; i < count; i++)
            Container(
              width: width,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(height: 160, radius: 8),
                  SizedBox(height: 16),
                  Skeleton(width: 220, height: 22),
                  SizedBox(height: 10),
                  Skeleton(height: 14),
                  SizedBox(height: 16),
                  Skeleton(height: 56, radius: 8),
                  SizedBox(height: 16),
                  Skeleton(height: 40, radius: 8),
                ],
              ),
            ),
        ],
      );
    });
  }
}

/// The body placeholder for screens that keep their own app bar while loading.
class SkeletonBody extends StatelessWidget {
  const SkeletonBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      child: SkeletonPage(),
    );
  }
}
