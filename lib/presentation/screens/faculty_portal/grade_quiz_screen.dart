import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'widgets/faculty_scaffold.dart';
import 'widgets/faculty_sidebar.dart';
import 'my_assigned_courses_screen.dart';
import 'student_directory_screen.dart';

// ---------------------------------------------------------------------------
// GradeQuizScreen – Stitch "Grade Quiz Assessment: Alex Chen" faithful
// Flutter conversion.
// ---------------------------------------------------------------------------
class GradeQuizScreen extends StatefulWidget {
  const GradeQuizScreen({super.key});

  @override
  State<GradeQuizScreen> createState() => _GradeQuizScreenState();
}

class _GradeQuizScreenState extends State<GradeQuizScreen> {
  static const int _autoScore = 60;
  int _q3Score = 18;
  int _q4Score = 19;

  final TextEditingController _q3Feedback = TextEditingController(
    text: 'Good explanation of the non-blocking pattern and alerting. Next time include schema fallback defaults.',
  );
  final TextEditingController _q4Feedback = TextEditingController(
    text: 'Precise snapshot time-travel reference and systematic isolation steps.',
  );

  int get _manualTotal => _q3Score + _q4Score;
  int get _projectedTotal => _autoScore + _manualTotal;

  @override
  void dispose() {
    _q3Feedback.dispose();
    _q4Feedback.dispose();
    super.dispose();
  }

  void _handleNav(FacultyNavDestination dest) {
    switch (dest) {
      case FacultyNavDestination.myCourses:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyAssignedCoursesScreen()));
        break;
      case FacultyNavDestination.studentDirectory:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentDirectoryScreen()));
        break;
      case FacultyNavDestination.gradingAndSubmissions:
        break;
    }
  }

  void _otherStudent() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Only Alex Chen\'s quiz attempt is available in this preview.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FacultyScaffold(
      selected: FacultyNavDestination.gradingAndSubmissions,
      onDestinationSelected: _handleNav,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 16),
          _buildScoreBanner(),
          const SizedBox(height: 24),
          _sectionMarker('A', 'Auto-Graded Objective Section', 'Verified against cryptographically hashed course master key',
              '2 of 6 Displayed (All 6 Passed)', FacultyColors.tertiary),
          const SizedBox(height: 12),
          _mcqCard(
            number: '01',
            prompt: 'Which protocol governs enterprise data isolation when caching intermediate pipeline states?',
            options: const [
              'Option A: Public readable S3 staging tier with ACL hashing',
              'Option B: Encrypted ephemeral volume with short-lived STS tokens',
              'Option C: Uncompressed local node temp directory with UID 0',
              'Option D: Shared NFS volume mounts across microservices',
            ],
            correctIndex: 1,
          ),
          const SizedBox(height: 12),
          _mcqCard(
            number: '02',
            prompt: 'What is the maximum allowable un-sanitized retention period for raw customer transactional logs?',
            options: const [
              'Option A: 72 Hours in primary database cache',
              'Option B: Indefinitely within encrypted cold storage',
              'Option C: 24 Hours in a quarantined VPC bucket',
              'Option D: Zero retention (in-memory transformation only)',
            ],
            correctIndex: 2,
          ),
          const SizedBox(height: 24),
          _sectionMarker('B', 'Instructor Evaluation: Free Response', 'Subjective assessment requiring rubric calibration & faculty sign-off',
              '2 Analytical Prompts Pending Final Release', FacultyColors.primary),
          const SizedBox(height: 12),
          _freeResponseCard(
            number: '03',
            prompt: 'Explain how you would handle an unmapped categorical value encountered mid-pipeline without breaking downstream consumers or halting the ETL batch.',
            submissionMeta: '48 words • 3 sentences',
            submission:
                '"I implement a dual-stream quarantine pattern. The pipeline isolates records with unseen categorical keys into a quarantined JSON array with an UNKNOWN_ENUM error tag, while valid transactions proceed through normalization. An asynchronous alert is dispatched to the data steward to update the category registry."',
            rubricIntro: 'Expected Core Elements: Quarantine isolation, structured error tagging (UNKNOWN_ENUM), alerting steward mechanism, and non-blocking streaming execution.',
            rubricTags: const ['Non-blocking Flow (+6)', 'Error Tagging (+5)', 'Async Alerting (+5)', 'Fallback Schema (+4)'],
            feedbackController: _q3Feedback,
            score: _q3Score,
            maxScore: 20,
            presets: const [10, 15, 18, 20],
            onScoreChanged: (v) => setState(() => _q3Score = v),
          ),
          const SizedBox(height: 16),
          _freeResponseCard(
            number: '04',
            prompt: 'Describe the rollback and disaster recovery procedure if an automated ETL job corrupts a production table partition.',
            submissionMeta: '35 words • 3 key phases',
            submission:
                '"First, trigger an automated partition rollback utilizing snapshot time-travel queries to restore the partition to state t-1. Second, freeze the ingestion worker pool. Third, run audit delta reconciliation against the raw landing bucket."',
            rubricIntro: 'Benchmark Rubric: Immediate partition isolation, point-in-time recovery mechanism (time-travel/snapshot), upstream pipeline freeze, and subsequent idempotent replay from raw bronze ingest.',
            rubricTags: const ['Snapshot Time-travel (+8)', 'Ingestion Worker Freeze (+6)', 'Delta Reconciliation (+6)'],
            feedbackController: _q4Feedback,
            score: _q4Score,
            maxScore: 20,
            presets: const [12, 16, 19, 20],
            onScoreChanged: (v) => setState(() => _q4Score = v),
          ),
          const SizedBox(height: 24),
          _buildActionDock(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.arrow_back, size: 18, color: FacultyColors.primary),
                  const SizedBox(width: 4),
                  Text('Back to Quiz Submissions', style: FacultyTypography.labelMd(color: FacultyColors.primary)),
                ]),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(onPressed: _otherStudent, icon: const Icon(Icons.chevron_left, size: 18), color: FacultyColors.secondary),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: FacultyColors.tertiary, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('Alex Chen', style: FacultyTypography.titleSm()),
                      const SizedBox(width: 6),
                      Text('EMP-88219', style: FacultyTypography.labelXs(color: FacultyColors.secondary)),
                    ]),
                  ),
                  IconButton(onPressed: _otherStudent, icon: const Icon(Icons.chevron_right, size: 18), color: FacultyColors.secondary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 16,
          runSpacing: 8,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: FacultyColors.secondaryContainer, borderRadius: BorderRadius.circular(4)),
                    child: Text('GRADING WORKSPACE', style: FacultyTypography.labelXs(color: FacultyColors.onSecondaryContainer).copyWith(fontWeight: FontWeight.w700)),
                  ),
                  Text('• Assessment ID: COMPL-03-Q3', style: FacultyTypography.labelXs()),
                ]),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Text('Lesson Compliance Quiz Assessment: Data Protection & Enterprise Governance', style: FacultyTypography.headlineLg()),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
              child: Wrap(
                spacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _metaChip(Icons.calendar_today_outlined, 'Nov 14, 2025'),
                  _metaChip(Icons.repeat, 'Attempt 1 of 1'),
                  _metaChip(Icons.schedule_outlined, '24 mins duration'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: FacultyColors.outline),
      const SizedBox(width: 4),
      Text(text, style: FacultyTypography.labelMd(color: FacultyColors.secondary)),
    ]);
  }

  Widget _buildScoreBanner() {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 720;
      final width = wide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth;
      final cards = [
        SizedBox(
          width: width,
          child: _scoreCard(
            label: 'Auto-Graded Section',
            badge: '100% Correct',
            badgeColor: FacultyColors.tertiary,
            value: '$_autoScore',
            outOf: '/ 60 pts',
            footerLeft: '6 Multiple-choice questions',
            footerRight: 'All verified',
            footerRightColor: FacultyColors.tertiary,
          ),
        ),
        SizedBox(
          width: width,
          child: _scoreCard(
            label: 'Open-Ended Evaluation',
            badge: 'Manual Review',
            badgeColor: FacultyColors.primary,
            badgeBg: FacultyColors.secondaryContainer,
            badgeFg: FacultyColors.onSecondaryContainer,
            value: '$_manualTotal',
            valueColor: FacultyColors.primary,
            outOf: '/ 40 pts',
            footerLeft: '2 Analytical essay prompts',
            footerRight: 'Drafting scores',
            footerRightColor: FacultyColors.primary,
          ),
        ),
        SizedBox(
          width: width,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: FacultyColors.primary, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text('PROJECTED FINAL GRADE', style: FacultyTypography.labelXs(color: Colors.white.withValues(alpha: 0.8)).copyWith(fontWeight: FontWeight.w700))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(9999)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.military_tech, size: 13, color: Colors.white),
                      const SizedBox(width: 3),
                      Text('Passing (80% Min)', style: FacultyTypography.labelXs(color: Colors.white).copyWith(fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ]),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('$_projectedTotal', style: FacultyTypography.displayLg(color: Colors.white)),
                    const SizedBox(width: 4),
                    Text('/ 100 pts', style: FacultyTypography.titleSm(color: Colors.white.withValues(alpha: 0.75))),
                    const Spacer(),
                    Text('$_projectedTotal%', style: FacultyTypography.headlineMd(color: FacultyColors.tertiaryFixed)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: Text('Mastery Tier: Distinguished', style: FacultyTypography.bodySm(color: Colors.white.withValues(alpha: 0.8)))),
                  Text('+${_projectedTotal - 80}% over cutoff', style: FacultyTypography.bodySm(color: Colors.white).copyWith(fontWeight: FontWeight.w700)),
                ]),
              ],
            ),
          ),
        ),
      ];
      return Wrap(spacing: 16, runSpacing: 16, children: cards);
    });
  }

  Widget _scoreCard({
    required String label,
    required String badge,
    required Color badgeColor,
    Color? badgeBg,
    Color? badgeFg,
    required String value,
    Color? valueColor,
    required String outOf,
    required String footerLeft,
    required String footerRight,
    required Color footerRightColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(label, style: FacultyTypography.labelXs().copyWith(fontWeight: FontWeight.w700))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: badgeBg ?? badgeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(9999)),
              child: Text(badge, style: FacultyTypography.labelXs(color: badgeFg ?? badgeColor).copyWith(fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: FacultyTypography.displayLg().copyWith(color: valueColor ?? FacultyColors.onSurface)),
              const SizedBox(width: 4),
              Text(outOf, style: FacultyTypography.titleSm(color: FacultyColors.secondary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text(footerLeft, style: FacultyTypography.bodySm())),
            Text(footerRight, style: FacultyTypography.bodySm(color: footerRightColor).copyWith(fontWeight: FontWeight.w700)),
          ]),
        ],
      ),
    );
  }

  Widget _sectionMarker(String letter, String title, String subtitle, String badge, Color badgeColor) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
            child: Text(letter, style: FacultyTypography.labelMd(color: FacultyColors.primary)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: FacultyTypography.titleSm()),
              Text(subtitle, style: FacultyTypography.labelXs()),
            ],
          ),
        ]),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(badge, style: FacultyTypography.labelXs(color: badgeColor).copyWith(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _mcqCard({required String number, required String prompt, required List<String> options, required int correctIndex}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
                child: Text(number, style: FacultyTypography.titleSm()),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MULTIPLE CHOICE • QUESTION ${int.parse(number)}', style: FacultyTypography.labelXs(color: FacultyColors.secondary).copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(prompt, style: FacultyTypography.bodyLg(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: FacultyColors.tertiaryFixed.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(9999)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check, size: 14, color: FacultyColors.onTertiaryFixedVariant),
                  const SizedBox(width: 3),
                  Text('Correct (+10 pts)', style: FacultyTypography.labelMd(color: FacultyColors.onTertiaryFixedVariant)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 560;
            final width = wide ? (constraints.maxWidth - 8) / 2 : constraints.maxWidth;
            return Padding(
              padding: const EdgeInsets.only(left: 42),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(options.length, (i) {
                  final chosen = i == correctIndex;
                  return SizedBox(
                    width: width,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: chosen ? FacultyColors.tertiary.withValues(alpha: 0.08) : FacultyColors.surfaceContainerLow.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(chosen ? Icons.check_circle : Icons.circle_outlined, size: 17, color: chosen ? FacultyColors.tertiary : FacultyColors.outline),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              options[i],
                              style: FacultyTypography.bodySm(color: chosen ? FacultyColors.onSurface : FacultyColors.secondary)
                                  .copyWith(fontWeight: chosen ? FontWeight.w600 : FontWeight.w400),
                            ),
                          ),
                          if (chosen)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(4)),
                              child: Text('Student Choice', style: FacultyTypography.labelXs(color: FacultyColors.tertiary)),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _freeResponseCard({
    required String number,
    required String prompt,
    required String submissionMeta,
    required String submission,
    required String rubricIntro,
    required List<String> rubricTags,
    required TextEditingController feedbackController,
    required int score,
    required int maxScore,
    required List<int> presets,
    required ValueChanged<int> onScoreChanged,
  }) {
    final achieved = ((score / maxScore) * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
                child: Text(number, style: FacultyTypography.titleSm(color: FacultyColors.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('OPEN-ENDED FREE RESPONSE • QUESTION ${int.parse(number)}',
                        style: FacultyTypography.labelXs(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(prompt, style: FacultyTypography.bodyLg(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: FacultyColors.secondaryContainer, borderRadius: BorderRadius.circular(9999)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.draw_outlined, size: 14, color: FacultyColors.onSecondaryContainer),
                  const SizedBox(width: 3),
                  Text('Max $maxScore pts', style: FacultyTypography.labelMd(color: FacultyColors.onSecondaryContainer)),
                ]),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 42, top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.person_outline, size: 15, color: FacultyColors.primary),
                  const SizedBox(width: 4),
                  Text("Alex Chen's Submission", style: FacultyTypography.labelXs().copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(submissionMeta, style: FacultyTypography.labelXs(color: FacultyColors.outline)),
                ]),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                  child: Text(submission, style: FacultyTypography.bodyMd(color: FacultyColors.onSurface)),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 640;
                  final leftWidth = wide ? (constraints.maxWidth - 16) * 7 / 12 : constraints.maxWidth;
                  final rightWidth = wide ? (constraints.maxWidth - 16) * 5 / 12 : constraints.maxWidth;
                  final rubricAndFeedback = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          backgroundColor: FacultyColors.surfaceContainerLow,
                          collapsedBackgroundColor: FacultyColors.surfaceContainerLow,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          leading: const Icon(Icons.key_outlined, size: 16, color: FacultyColors.primary),
                          title: Text('Grading Criteria & Model Answer Reference', style: FacultyTypography.bodySm(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
                          children: [
                            Text(rubricIntro, style: FacultyTypography.bodySm(color: FacultyColors.secondary)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: rubricTags
                                  .map((t) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(6)),
                                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                                          Container(width: 5, height: 5, decoration: const BoxDecoration(color: FacultyColors.tertiary, shape: BoxShape.circle)),
                                          const SizedBox(width: 4),
                                          Text(t, style: FacultyTypography.labelXs(color: FacultyColors.onSurface)),
                                        ]),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('INSTRUCTOR WRITTEN FEEDBACK', style: FacultyTypography.labelXs().copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: feedbackController,
                        maxLines: 2,
                        style: FacultyTypography.bodySm(color: FacultyColors.onSurface),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: FacultyColors.surfaceContainerLowest,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.all(10),
                        ),
                      ),
                    ],
                  );

                  final scoreSetter = Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Row(children: [
                          Expanded(child: Text('SCORE ALLOCATION', style: FacultyTypography.labelXs().copyWith(fontWeight: FontWeight.w700))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: FacultyColors.tertiaryFixed.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(6)),
                            child: Text('$achieved% Achieved', style: FacultyTypography.labelXs(color: FacultyColors.onTertiaryFixedVariant).copyWith(fontWeight: FontWeight.w700)),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12)),
                              child: Text('$score', style: FacultyTypography.headlineLg(color: FacultyColors.primary)),
                            ),
                            const SizedBox(width: 8),
                            Text('/ $maxScore pts', style: FacultyTypography.titleSm(color: FacultyColors.secondary)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: presets.map((p) {
                            final active = p == score;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: GestureDetector(
                                  onTap: () => onScoreChanged(p),
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: active ? FacultyColors.primary : FacultyColors.surfaceContainerLowest,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(p == maxScore ? 'Max' : '$p',
                                          style: FacultyTypography.labelMd(color: active ? Colors.white : FacultyColors.secondary)),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );

                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: leftWidth, child: rubricAndFeedback),
                        const SizedBox(width: 16),
                        SizedBox(width: rightWidth, child: scoreSetter),
                      ],
                    );
                  }
                  return Column(children: [rubricAndFeedback, const SizedBox(height: 12), scoreSetter]);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionDock() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 24)],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FINAL ASSESSMENT SCORE', style: FacultyTypography.labelXs().copyWith(fontWeight: FontWeight.w700)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('$_projectedTotal', style: FacultyTypography.displayLg().copyWith(fontSize: 26)),
                      const SizedBox(width: 4),
                      Text('/ 100 pts', style: FacultyTypography.titleSm(color: FacultyColors.secondary)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: FacultyColors.tertiaryFixed.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(9999)),
                        child: Text('Pass (Distinction)', style: FacultyTypography.labelXs(color: FacultyColors.onTertiaryFixedVariant).copyWith(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Container(width: 1, height: 32, color: FacultyColors.surfaceContainerHigh),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Grading Integrity', style: FacultyTypography.labelXs()),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_circle, size: 15, color: FacultyColors.tertiary),
                    const SizedBox(width: 4),
                    Text('All 4 items evaluated', style: FacultyTypography.bodySm(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w500)),
                  ]),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progress saved.'))),
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('Save Progress'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FacultyColors.onSurface,
                  backgroundColor: FacultyColors.surfaceContainerLow,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Grades Successfully Released — Alex Chen has been notified via the student portal.'),
                      backgroundColor: FacultyColors.primary,
                    ),
                  );
                },
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Release Grade & Feedback'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FacultyColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
