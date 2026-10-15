/// The grade bands the distribution limits are written in. Each limit is
/// cumulative: "A and above" includes every A+.
enum GradeBandLimit {
  aPlus('A+', ['A+']),
  aAndAbove('A and above', ['A+', 'A']),
  aMinusAndAbove('A- and above', ['A+', 'A', 'A-']),
  bPlusAndAbove('B+ and above', ['A+', 'A', 'A-', 'B+']);

  final String label;

  /// The letter grades that count towards this band.
  final List<String> letters;

  const GradeBandLimit(this.label, this.letters);
}

/// Admin-set caps on how many of a class's enrolled students may receive each
/// grade band, as a percentage of the class. `null` means "no limit".
class GradeDistributionRules {
  final Map<GradeBandLimit, double?> maxPercent;

  const GradeDistributionRules(this.maxPercent);

  /// The starting rules: 5% A+, 10% A and above, 15% A- and above, 60% B+ and above.
  static const defaults = GradeDistributionRules({
    GradeBandLimit.aPlus: 5,
    GradeBandLimit.aAndAbove: 10,
    GradeBandLimit.aMinusAndAbove: 15,
    GradeBandLimit.bPlusAndAbove: 60,
  });

  double? percentFor(GradeBandLimit band) => maxPercent[band];

  /// Counts the students in each band and compares them with the limits.
  /// [letters] holds one final letter grade per enrolled student.
  GradeDistributionCheck evaluate(List<String> letters) {
    final enrolled = letters.length;
    final bands = <GradeBandResult>[];
    for (final band in GradeBandLimit.values) {
      final actual = letters.where(band.letters.contains).length;
      final percent = maxPercent[band];
      // A tiny epsilon keeps 5% of 20 students at exactly 1 (not 0.999...).
      final allowed = percent == null ? null : (percent / 100 * enrolled + 1e-9).floor();
      bands.add(GradeBandResult(band: band, actual: actual, allowed: allowed, maxPercent: percent));
    }
    return GradeDistributionCheck(enrolled: enrolled, bands: bands);
  }
}

/// How one band compares with its limit.
class GradeBandResult {
  final GradeBandLimit band;
  final int actual;

  /// Most students allowed in the band for this class size; null = no limit.
  final int? allowed;
  final double? maxPercent;

  const GradeBandResult({required this.band, required this.actual, required this.allowed, required this.maxPercent});

  bool get exceeds => allowed != null && actual > allowed!;
}

/// The result of checking one class's final grades against the rules.
class GradeDistributionCheck {
  final int enrolled;
  final List<GradeBandResult> bands;

  const GradeDistributionCheck({required this.enrolled, required this.bands});

  List<GradeBandResult> get violations => [for (final b in bands) if (b.exceeds) b];

  bool get isWithinLimits => violations.isEmpty;

  /// The per-band counts, as stored with an approval request.
  Map<String, int> get counts => {for (final b in bands) b.band.name: b.actual};
}

class GradeDistributionRequestStatus {
  GradeDistributionRequestStatus._();

  static const pending = 'pending';
  static const approved = 'approved';
  static const rejected = 'rejected';
}

/// A lecturer's request for the admin to approve a class's grade distribution
/// even though it is outside the limits.
class GradeDistributionRequest {
  final String id;
  final String sectionId;
  final String lecturerId;
  final String status;
  final String justification;

  /// Per-band student counts when the request was sent (see
  /// [GradeDistributionCheck.counts]).
  final Map<String, int> counts;
  final int enrolledCount;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? decidedAt;

  // Display details, filled in for the admin's list.
  final String? courseTitle;
  final String? classCode;
  final String? lecturerName;

  const GradeDistributionRequest({
    required this.id,
    required this.sectionId,
    required this.lecturerId,
    required this.status,
    required this.justification,
    required this.counts,
    required this.enrolledCount,
    required this.createdAt,
    this.adminNote,
    this.decidedAt,
    this.courseTitle,
    this.classCode,
    this.lecturerName,
  });

  bool get isPending => status == GradeDistributionRequestStatus.pending;
  bool get isApproved => status == GradeDistributionRequestStatus.approved;
  bool get isRejected => status == GradeDistributionRequestStatus.rejected;

  /// True when the class's grades today are no worse, in every band, than the
  /// ones the admin looked at — so an approval still covers them.
  bool coversCounts(Map<String, int> current) {
    for (final entry in current.entries) {
      if (entry.value > (counts[entry.key] ?? 0)) return false;
    }
    return true;
  }

  factory GradeDistributionRequest.fromMap(Map<String, dynamic> map) {
    final section = map['course_sections'] as Map<String, dynamic>?;
    final course = section?['courses'] as Map<String, dynamic>?;
    final lecturer = map['lecturers'] as Map<String, dynamic>?;
    return GradeDistributionRequest(
      id: map['id'] as String,
      sectionId: map['section_id'] as String,
      lecturerId: map['lecturer_id'] as String,
      status: map['status'] as String,
      justification: map['justification'] as String? ?? '',
      counts: {for (final e in ((map['distribution'] as Map?) ?? const {}).entries) e.key as String: (e.value as num).toInt()},
      enrolledCount: (map['enrolled_count'] as num?)?.toInt() ?? 0,
      adminNote: map['admin_note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      decidedAt: map['decided_at'] == null ? null : DateTime.parse(map['decided_at'] as String).toLocal(),
      courseTitle: course?['course_title'] as String?,
      classCode: section?['section_code'] as String?,
      lecturerName: lecturer?['name'] as String?,
    );
  }
}
