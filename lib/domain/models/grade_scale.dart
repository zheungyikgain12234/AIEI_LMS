/// One band of the admin-configured grade scale: [letter] applies from
/// [minScore] up to (but not including) the next band's [minScore].
class GradeBand {
  final String letter;
  final double minScore;

  const GradeBand(this.letter, this.minScore);
}

/// Maps a numeric score to a letter grade. Letters are always derived from the
/// score at display time and never persisted, so they can't go stale when the
/// scale changes. [bands] must be ordered lowest to highest by [GradeBand.minScore].
class GradeScale {
  final List<GradeBand> bands;

  const GradeScale(this.bands);

  static const defaultScale = GradeScale([
    GradeBand('F', 0),
    GradeBand('D', 50),
    GradeBand('C', 56),
    GradeBand('C+', 61),
    GradeBand('B-', 66),
    GradeBand('B', 70),
    GradeBand('B+', 74),
    GradeBand('A-', 78),
    GradeBand('A', 82),
    GradeBand('A+', 86),
  ]);

  String letterFor(double score) {
    var result = bands.first.letter;
    for (final band in bands) {
      if (score >= band.minScore) result = band.letter;
    }
    return result;
  }
}
