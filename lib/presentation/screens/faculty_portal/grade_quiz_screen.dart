import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_material_progress_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/module_material.dart';
import 'widgets/faculty_scaffold.dart';
import 'widgets/faculty_sidebar.dart';
import 'widgets/faculty_mobile_top_bar.dart';
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
  final _progressRepository = SupabaseMaterialProgressRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  int _autoScore = 0;
  int _q3Score = 0;
  int _q4Score = 0;
  bool _mobileShowAllMcqs = false;

  Map<String, dynamic> _q3Data = const {};
  Map<String, dynamic> _q4Data = const {};

  final TextEditingController _q3Feedback = TextEditingController();
  final TextEditingController _q4Feedback = TextEditingController();

  int get _manualTotal => _q3Score + _q4Score;
  int get _projectedTotal => _autoScore + _manualTotal;
  int get _q3MaxScore => (_q3Data['maxScore'] as int?) ?? 20;
  int get _q4MaxScore => (_q4Data['maxScore'] as int?) ?? 20;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final materialRow = await Supabase.instance.client
        .from('module_materials')
        .select()
        .eq('id', DemoIdentity.materialComplianceQuizId)
        .single();
    final material = ModuleMaterial.fromMap(materialRow);
    final progress = await _progressRepository.getProgress(
      DemoIdentity.studentId,
      DemoIdentity.materialComplianceQuizId,
    );

    final freeResponseQuestions = List<Map<String, dynamic>>.from(
      (material.content['freeResponseQuestions'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final q3 = freeResponseQuestions.firstWhere(
      (q) => q['number'] == '03',
      orElse: () => const {},
    );
    final q4 = freeResponseQuestions.firstWhere(
      (q) => q['number'] == '04',
      orElse: () => const {},
    );

    if (!mounted) return;
    setState(() {
      _autoScore = progress?.score ?? 0;
      _q3Data = q3;
      _q4Data = q4;
      _isLoading = false;
    });
  }

  Future<void> _submitGrade() async {
    final combinedFeedback = 'Q03: ${_q3Feedback.text}\n\nQ04: ${_q4Feedback.text}';
    await _progressRepository.gradeSubmission(
      DemoIdentity.studentId,
      DemoIdentity.materialComplianceQuizId,
      score: _projectedTotal,
      feedback: combinedFeedback,
      gradedByLecturerId: DemoIdentity.lecturerId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Grades Successfully Released — Alex Chen has been notified via the student portal.'),
        backgroundColor: FacultyColors.primary,
      ),
    );
  }

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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (MediaQuery.of(context).size.width < 700) {
      return _buildMobileScaffold(context);
    }
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
            prompt: _q3Data['prompt'] as String? ?? '',
            submissionMeta: '48 words • 3 sentences',
            submission:
                '"I implement a dual-stream quarantine pattern. The pipeline isolates records with unseen categorical keys into a quarantined JSON array with an UNKNOWN_ENUM error tag, while valid transactions proceed through normalization. An asynchronous alert is dispatched to the data steward to update the category registry."',
            rubricIntro: _q3Data['rubricIntro'] as String? ?? '',
            rubricTags: List<String>.from(_q3Data['rubricTags'] as List? ?? const []),
            feedbackController: _q3Feedback,
            score: _q3Score,
            maxScore: _q3MaxScore,
            presets: const [10, 15, 18, 20],
            onScoreChanged: (v) => setState(() => _q3Score = v),
          ),
          const SizedBox(height: 16),
          _freeResponseCard(
            number: '04',
            prompt: _q4Data['prompt'] as String? ?? '',
            submissionMeta: '35 words • 3 key phases',
            submission:
                '"First, trigger an automated partition rollback utilizing snapshot time-travel queries to restore the partition to state t-1. Second, freeze the ingestion worker pool. Third, run audit delta reconciliation against the raw landing bucket."',
            rubricIntro: _q4Data['rubricIntro'] as String? ?? '',
            rubricTags: List<String>.from(_q4Data['rubricTags'] as List? ?? const []),
            feedbackController: _q4Feedback,
            score: _q4Score,
            maxScore: _q4MaxScore,
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
                onPressed: _submitGrade,
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

  // ---------------------------------------------------------------------
  // Mobile (<700px) layout
  // ---------------------------------------------------------------------

  BoxDecoration _mobileCardDecoration() {
    return BoxDecoration(
      color: FacultyColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
    );
  }

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: const FacultyMobileTopBar(title: 'Grading Assessment'),
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _mobileNavCard(),
              const SizedBox(height: 12),
              _mobileHeaderCard(),
              const SizedBox(height: 12),
              _mobileTelemetryBento(),
              const SizedBox(height: 12),
              _mobileSectionA(),
              const SizedBox(height: 12),
              _mobileSectionB(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _mobileBottomBar(context),
    );
  }

  Widget _mobileMetaChip(IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: FacultyColors.outline),
      const SizedBox(width: 4),
      Text(label, style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant)),
    ]);
  }

  Widget _mobileNavCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _mobileCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.arrow_back, size: 18, color: FacultyColors.secondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Back to Quiz Submissions',
                        style: FacultyTypography.labelMd(color: FacultyColors.secondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: FacultyColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(9999)),
                child: Text(
                  'COMPL-03-Q3',
                  style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant).copyWith(letterSpacing: 1, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  onPressed: _otherStudent,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.chevron_left, size: 18),
                  color: FacultyColors.secondary,
                  style: IconButton.styleFrom(
                    backgroundColor: FacultyColors.surfaceContainerLow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: FacultyColors.secondary, shape: BoxShape.circle),
                        child: Text('AC', style: FacultyTypography.labelXs(color: Colors.white).copyWith(fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Alex Chen', style: FacultyTypography.labelMd(color: FacultyColors.onSurface), overflow: TextOverflow.ellipsis),
                            Text('EMP-88219', style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  onPressed: _otherStudent,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.chevron_right, size: 18),
                  color: FacultyColors.secondary,
                  style: IconButton.styleFrom(
                    backgroundColor: FacultyColors.surfaceContainerLow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _mobileCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: FacultyColors.secondaryContainer, borderRadius: BorderRadius.circular(9999)),
                child: Text('Faculty Review', style: FacultyTypography.labelXs(color: FacultyColors.onSecondaryContainer).copyWith(fontWeight: FontWeight.w700)),
              ),
              Text('Evaluator: Dr. Sarah Lin', style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Data Protection & Enterprise Governance',
            style: FacultyTypography.headlineMd(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _mobileMetaChip(Icons.calendar_today, 'Nov 14, 2025'),
              _mobileMetaChip(Icons.timer, 'Attempt 1 of 1 (24m)'),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.verified, size: 15, color: FacultyColors.tertiary),
                const SizedBox(width: 4),
                Text('Verified Cohort', style: FacultyTypography.labelMd(color: FacultyColors.tertiary)),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileStatCard({
    required String label,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String outOf,
    required String footer,
    required Color footerColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _mobileCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant).copyWith(letterSpacing: 1, fontWeight: FontWeight.w700),
              ),
            ),
            Icon(icon, size: 18, color: iconColor),
          ]),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: FacultyTypography.headlineLg(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700)),
              Text(outOf, style: FacultyTypography.bodyMd(color: FacultyColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 4),
          Text(footer, style: FacultyTypography.labelMd(color: footerColor), overflow: TextOverflow.ellipsis, maxLines: 1),
        ],
      ),
    );
  }

  Widget _mobileProjectedTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [FacultyColors.primaryContainer, FacultyColors.primary],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                'PROJECTED TOTAL',
                style: FacultyTypography.labelXs(color: Colors.white.withValues(alpha: 0.85)).copyWith(letterSpacing: 1, fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(Icons.workspace_premium, size: 18, color: FacultyColors.tertiaryFixed),
          ]),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$_projectedTotal', style: FacultyTypography.headlineLg(color: Colors.white).copyWith(fontWeight: FontWeight.w700)),
              Text(' / 100', style: FacultyTypography.bodyMd(color: Colors.white.withValues(alpha: 0.85))),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Distinguished • Passing 80% Min',
            style: FacultyTypography.labelMd(color: FacultyColors.tertiaryFixed),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _mobileTelemetryBento() {
    return Column(
      children: [
        _mobileStatCard(
          label: 'Auto-Graded',
          icon: Icons.task_alt,
          iconColor: FacultyColors.tertiary,
          value: '$_autoScore',
          outOf: ' / 60',
          footer: '100% Correct • 6 MCQs Verified',
          footerColor: FacultyColors.tertiary,
        ),
        const SizedBox(height: 12),
        _mobileStatCard(
          label: 'Free Response',
          icon: Icons.edit_note,
          iconColor: FacultyColors.secondary,
          value: '$_manualTotal',
          outOf: ' / 40',
          footer: 'Drafting Scores • 2 Prompts',
          footerColor: FacultyColors.secondary,
        ),
        const SizedBox(height: 12),
        _mobileProjectedTotalCard(),
      ],
    );
  }

  Widget _mobileMcqItem({required String label, required String points, required String prompt, required String answer}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: FacultyColors.onTertiaryFixedVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        style: FacultyTypography.labelMd(color: FacultyColors.onTertiaryFixedVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: FacultyColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4)],
                ),
                child: Text(points, style: FacultyTypography.labelMd(color: FacultyColors.onTertiaryFixedVariant)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(prompt, style: FacultyTypography.bodyMd(color: FacultyColors.onSurface)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: FacultyColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4)],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.done, size: 16, color: FacultyColors.onTertiaryFixedVariant),
                const SizedBox(width: 6),
                Expanded(child: Text(answer, style: FacultyTypography.bodySm(color: FacultyColors.primary))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileSectionA() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _mobileCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SECTION A', style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant).copyWith(letterSpacing: 1, fontWeight: FontWeight.w700)),
                    Text('Objective Evaluation', style: FacultyTypography.headlineMd(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(9999)),
                child: Text('$_autoScore / 60 pts', style: FacultyTypography.labelMd(color: FacultyColors.secondary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _mobileMcqItem(
            label: 'Q01 • Pipeline State Isolation',
            points: '+10 pts',
            prompt: 'Which protocol governs enterprise data isolation when caching intermediate pipeline states?',
            answer: 'Option B: Encrypted ephemeral volume with short-lived STS tokens.',
          ),
          const SizedBox(height: 10),
          _mobileMcqItem(
            label: 'Q02 • Retention Lifecycle',
            points: '+10 pts',
            prompt: 'What is the maximum allowable un-sanitized retention period for raw customer transactional logs?',
            answer: 'Option C: 24 Hours in a quarantined VPC bucket.',
          ),
          if (_mobileShowAllMcqs) ...[
            const SizedBox(height: 10),
            _mobileMcqItem(
              label: 'Q03 • Access Control Layering',
              points: '+10 pts',
              prompt: 'Which access layer enforces least-privilege boundary checks between microservice tenants?',
              answer: 'Option A: Mutual TLS with per-tenant scoped service accounts.',
            ),
            const SizedBox(height: 10),
            _mobileMcqItem(
              label: 'Q04 • Audit Trail Immutability',
              points: '+10 pts',
              prompt: 'What guarantees tamper-evidence for compliance audit logs at rest?',
              answer: 'Option D: Append-only ledger with cryptographic hash chaining.',
            ),
            const SizedBox(height: 10),
            _mobileMcqItem(
              label: 'Q05 • Key Rotation Policy',
              points: '+10 pts',
              prompt: 'What is the maximum rotation interval for envelope encryption keys under the governance policy?',
              answer: 'Option B: 90 days with automated re-wrap.',
            ),
            const SizedBox(height: 10),
            _mobileMcqItem(
              label: 'Q06 • Cross-Border Transfer',
              points: '+10 pts',
              prompt: 'Which mechanism is required before transferring regulated data across jurisdictional boundaries?',
              answer: 'Option C: Standard contractual clauses with data residency attestation.',
            ),
          ],
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _mobileShowAllMcqs = !_mobileShowAllMcqs),
              icon: Icon(_mobileShowAllMcqs ? Icons.expand_less : Icons.expand_more, size: 18, color: FacultyColors.secondary),
              label: Text(
                _mobileShowAllMcqs ? 'Hide Additional MCQs' : 'View Remaining 4 Validated MCQs',
                style: FacultyTypography.labelMd(color: FacultyColors.secondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileRubricChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: FacultyTypography.labelXs(color: FacultyColors.onSurface), overflow: TextOverflow.ellipsis, maxLines: 2),
    );
  }

  Widget _mobileFreeResponseBlock({
    required String questionNumber,
    required String title,
    required int maxScore,
    required String prompt,
    required String wordCount,
    required String submission,
    required List<String> rubricTags,
    required TextEditingController feedbackController,
    required int score,
    required List<int> presets,
    required ValueChanged<int> onScoreChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: Text(
              title,
              style: FacultyTypography.labelMd(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text('Max: $maxScore pts', style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant)),
        ]),
        const SizedBox(height: 4),
        Text(prompt, style: FacultyTypography.bodyMd(color: FacultyColors.onSurface)),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.rate_review, size: 15, color: FacultyColors.secondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        "Alex Chen's Response",
                        style: FacultyTypography.labelMd(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 6),
                Text(wordCount, style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant)),
              ]),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FacultyColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4)],
                ),
                child: Text(
                  submission,
                  style: FacultyTypography.bodyMd(color: FacultyColors.onSurface).copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.menu_book, size: 15, color: FacultyColors.onSecondaryFixed),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'GRADING RUBRIC STANDARDS',
                    overflow: TextOverflow.ellipsis,
                    style: FacultyTypography.labelXs(color: FacultyColors.onSecondaryFixed).copyWith(letterSpacing: 1, fontWeight: FontWeight.w700),
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              LayoutBuilder(builder: (context, constraints) {
                const spacing = 6.0;
                final chipWidth = (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: 6,
                  children: rubricTags.map((t) => SizedBox(width: chipWidth, child: _mobileRubricChip(t))).toList(),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text('Assigned Score for Q$questionNumber', style: FacultyTypography.labelMd(color: FacultyColors.onSurface)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: FacultyColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4)],
          ),
          child: Row(children: [
            Text('$score', style: FacultyTypography.titleSm(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('/ $maxScore pts', style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant)),
          ]),
        ),
        const SizedBox(height: 6),
        Row(
          children: presets.map((p) {
            final active = p == score;
            final label = p == maxScore ? 'Max' : '$p';
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => onScoreChanged(p),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? FacultyColors.secondary : FacultyColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: active ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 4)] : null,
                      ),
                      child: Text(
                        label,
                        style: FacultyTypography.labelMd(color: active ? Colors.white : (p == maxScore ? FacultyColors.secondary : FacultyColors.onSurface)),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Text('Instructor Narrative Feedback', style: FacultyTypography.labelMd(color: FacultyColors.onSurface)),
        const SizedBox(height: 4),
        TextField(
          controller: feedbackController,
          maxLines: 2,
          style: FacultyTypography.bodyMd(color: FacultyColors.onSurface),
          decoration: InputDecoration(
            filled: true,
            fillColor: FacultyColors.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(10),
          ),
        ),
      ],
    );
  }

  Widget _mobileSectionB() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _mobileCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SECTION B', style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant).copyWith(letterSpacing: 1, fontWeight: FontWeight.w700)),
                    Text('Instructor Analytical Review', style: FacultyTypography.headlineMd(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(9999)),
                child: Text('$_manualTotal / 40 pts', style: FacultyTypography.labelMd(color: FacultyColors.secondary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _mobileFreeResponseBlock(
            questionNumber: '03',
            title: 'Question 03 (Analytical Prompt)',
            maxScore: _q3MaxScore,
            prompt: _q3Data['prompt'] as String? ?? '',
            wordCount: '48 words',
            submission:
                '"I implement a dual-stream quarantine pattern. The pipeline isolates records with unseen categorical keys into a quarantined JSON array with an UNKNOWN_ENUM error tag, while valid transactions proceed through normalization. An asynchronous alerting worker notifies schema admins without blocking downstream consumers."',
            rubricTags: List<String>.from(_q3Data['rubricTags'] as List? ?? const []),
            feedbackController: _q3Feedback,
            score: _q3Score,
            presets: const [10, 15, 18, 20],
            onScoreChanged: (v) => setState(() => _q3Score = v),
          ),
          const SizedBox(height: 20),
          _mobileFreeResponseBlock(
            questionNumber: '04',
            title: 'Question 04 (Disaster Recovery & Rollback)',
            maxScore: _q4MaxScore,
            prompt: _q4Data['prompt'] as String? ?? '',
            wordCount: '35 words',
            submission:
                '"First, trigger an automated partition rollback utilizing snapshot time-travel queries to restore the partition to state t-1. Second, freeze the ingestion worker pool. Third, run audit delta reconciliation against the raw landing bucket."',
            rubricTags: List<String>.from(_q4Data['rubricTags'] as List? ?? const []),
            feedbackController: _q4Feedback,
            score: _q4Score,
            presets: const [12, 16, 19, 20],
            onScoreChanged: (v) => setState(() => _q4Score = v),
          ),
        ],
      ),
    );
  }

  Widget _mobileBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        boxShadow: [BoxShadow(color: Color(0x1F000000), blurRadius: 12, offset: Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('$_projectedTotal / 100', style: FacultyTypography.headlineMd(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: FacultyColors.secondary, borderRadius: BorderRadius.circular(9999)),
                      child: Text('Pass: Distinction', style: FacultyTypography.labelXs(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '4 of 4 evaluated',
                  style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progress saved.'))),
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save Draft'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FacultyColors.primary,
                    backgroundColor: FacultyColors.surfaceContainerLow,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _submitGrade,
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Release Grade'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FacultyColors.secondary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
