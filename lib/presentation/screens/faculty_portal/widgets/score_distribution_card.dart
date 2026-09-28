import 'dart:math';
import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';

/// Fitted-normal (mean, standard deviation) for [values] — a class of one
/// student has no real spread to fit, so it falls back to a wide default
/// so the curve still reads as a curve rather than a needle.
(double, double)? _fitNormal(List<double> values) {
  if (values.isEmpty) return null;
  final mean = values.reduce((a, b) => a + b) / values.length;
  if (values.length < 2) return (mean, 12.0);
  final variance = values.fold<double>(0, (sum, v) => sum + (v - mean) * (v - mean)) / values.length;
  final sd = sqrt(variance);
  return (mean, sd < 2 ? 2 : sd);
}

double _pdf(double x, double mean, double sd) {
  final z = (x - mean) / sd;
  return (1 / (sd * sqrt(2 * pi))) * exp(-0.5 * z * z);
}

/// KPI-row card showing the class's score distribution as two overlaid
/// fitted normal ("bell") curves — one for raw scores (before moderation),
/// one for final scores (raw + moderated, capped at 100) — so a lecturer
/// can see at a glance whether moderation shifted/tightened the spread.
/// Hovering (or tapping, on touch) reveals each curve's mean/SD; a labeled
/// 0–100 axis runs under the curve so the x position is always readable.
class ScoreDistributionCard extends StatefulWidget {
  final List<double> rawScores;
  final List<double> moderatedScores;

  const ScoreDistributionCard({super.key, required this.rawScores, required this.moderatedScores});

  @override
  State<ScoreDistributionCard> createState() => _ScoreDistributionCardState();
}

class _ScoreDistributionCardState extends State<ScoreDistributionCard> {
  bool _showStats = false;

  @override
  Widget build(BuildContext context) {
    final rawStats = _fitNormal(widget.rawScores);
    final modStats = _fitNormal(widget.moderatedScores);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SCORE DISTRIBUTION', style: FacultyTypography.labelXs().copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(
            children: [
              _legend(FacultyColors.secondary, 'Raw'),
              const SizedBox(width: 12),
              _legend(FacultyColors.primary, 'Moderated'),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.rawScores.isEmpty)
            SizedBox(
              height: 64,
              child: Center(child: Text('No data yet', style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant))),
            )
          else
            MouseRegion(
              onEnter: (_) => setState(() => _showStats = true),
              onExit: (_) => setState(() => _showStats = false),
              child: GestureDetector(
                onTap: () => setState(() => _showStats = !_showStats),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 16,
                      child: _showStats
                          ? Row(
                              children: [
                                if (rawStats != null) Expanded(child: _statLabel('Raw', rawStats, FacultyColors.secondary)),
                                if (modStats != null) Expanded(child: _statLabel('Moderated', modStats, FacultyColors.primary)),
                              ],
                            )
                          : null,
                    ),
                    SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _BellCurvePainter(
                          raw: widget.rawScores,
                          moderated: widget.moderatedScores,
                          rawColor: FacultyColors.secondary,
                          moderatedColor: FacultyColors.primary,
                          axisColor: FacultyColors.surfaceContainerHigh,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final tick in const [0, 25, 50, 75, 100])
                          Text('$tick', style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant).copyWith(fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statLabel(String name, (double, double) stats, Color color) {
    return Text(
      '$name μ=${stats.$1.toStringAsFixed(1)} σ=${stats.$2.toStringAsFixed(1)}',
      style: FacultyTypography.labelXs(color: color).copyWith(fontWeight: FontWeight.w700, fontSize: 9.5),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant)),
      ],
    );
  }
}

class _BellCurvePainter extends CustomPainter {
  final List<double> raw;
  final List<double> moderated;
  final Color rawColor;
  final Color moderatedColor;
  final Color axisColor;

  const _BellCurvePainter({
    required this.raw,
    required this.moderated,
    required this.rawColor,
    required this.moderatedColor,
    required this.axisColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Baseline axis + tick marks (0/25/50/75/100), matching the labeled
    // Row underneath so the curve's x position lines up with a real value.
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axisPaint);
    for (final tick in const [0, 25, 50, 75, 100]) {
      final tx = tick / 100 * size.width;
      canvas.drawLine(Offset(tx, size.height), Offset(tx, size.height - 4), axisPaint);
    }

    final rawStats = _fitNormal(raw);
    final modStats = _fitNormal(moderated);
    if (rawStats == null && modStats == null) return;

    final maxPdf = [
      if (rawStats != null) _pdf(rawStats.$1, rawStats.$1, rawStats.$2),
      if (modStats != null) _pdf(modStats.$1, modStats.$1, modStats.$2),
    ].reduce((a, b) => a > b ? a : b);
    if (maxPdf <= 0) return;

    if (rawStats != null) _drawCurve(canvas, size, rawStats.$1, rawStats.$2, maxPdf, rawColor);
    if (modStats != null) _drawCurve(canvas, size, modStats.$1, modStats.$2, maxPdf, moderatedColor);
  }

  void _drawCurve(Canvas canvas, Size size, double mean, double sd, double maxPdf, Color color) {
    final path = Path();
    const steps = 80;
    for (var i = 0; i <= steps; i++) {
      final x = i / steps * 100;
      final y = _pdf(x, mean, sd);
      final px = x / 100 * size.width;
      final py = size.height - (y / maxPdf) * size.height * 0.9;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    final meanPx = mean.clamp(0, 100) / 100 * size.width;
    final meanPy = size.height - (_pdf(mean, mean, sd) / maxPdf) * size.height * 0.9;
    canvas.drawCircle(Offset(meanPx, meanPy), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BellCurvePainter oldDelegate) =>
      oldDelegate.raw != raw || oldDelegate.moderated != moderated;
}
