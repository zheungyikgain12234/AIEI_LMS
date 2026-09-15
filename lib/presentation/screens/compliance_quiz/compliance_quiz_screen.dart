import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/widgets/portal_header.dart';

// ---------------------------------------------------------------------------
// ComplianceQuizScreen – Stitch "Lesson Compliance Quiz Assessment" faithful
// Flutter conversion (Chemical Handling Mandatory Compliance Exam).
// ---------------------------------------------------------------------------
class ComplianceQuizScreen extends StatefulWidget {
  const ComplianceQuizScreen({super.key});

  @override
  State<ComplianceQuizScreen> createState() => _ComplianceQuizScreenState();
}

class _ComplianceQuizScreenState extends State<ComplianceQuizScreen> {
  static const int _totalQuestions = 15;
  static const int _passingCount = 12;
  static const int _currentQuestion = 6;

  int _timerSeconds = 18 * 60 + 42;
  Timer? _timer;

  final Set<int> _answered = {1, 2, 3, 4, 5};
  final Set<int> _flagged = {3, 8};
  String? _q6Selection;
  late final TextEditingController _freeResponseController;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _freeResponseController = TextEditingController(
      text:
          'Phase 1: Immediate Personnel Safety. Activate the Bay emergency pull station to trip audible alarm for Assembly Cell 3, mandating immediate evacuation to Upwind Assembly Point Charlie. Prevent any unauthorized shop personnel from approaching the plume corridor.\n\n'
          'Phase 2: Responder PPE Gear-Up. Secondary spill response team must don Level B HazMat PPE equipped with Self-Contained Breathing Apparatus (SCBA) due to organic acetic acid vapors exceeding IDLH thresholds, alongside butyl-rubber protective coveralls and chemically resistant footwear.\n\n'
          'Phase 3: Containment and Neutralization. Deploy non-combustible polypropylene absorbent berm socks around drain grates. Apply dry sodium bicarbonate gradually to neutralize corrosive runoff while checking pH telemetry.',
    );
    _recomputeWordCount();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _freeResponseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timerSeconds <= 0) {
        _timer?.cancel();
        return;
      }
      setState(() => _timerSeconds--);
    });
  }

  void _recomputeWordCount() {
    final text = _freeResponseController.text.trim();
    _wordCount = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
  }

  String get _formattedTimer {
    final m = _timerSeconds ~/ 60;
    final s = _timerSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  int get _answeredCount => _answered.length;
  double get _progress => _answeredCount / _totalQuestions;

  void _toggleFlag(int q) {
    setState(() {
      if (_flagged.contains(q)) {
        _flagged.remove(q);
      } else {
        _flagged.add(q);
      }
    });
  }

  void _selectQ6(String value) {
    setState(() {
      _q6Selection = value;
      _answered.add(6);
    });
  }

  void _saveAndExit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Progress saved. You can resume this exam anytime.'),
        backgroundColor: AppColors.primaryContainer,
      ),
    );
    final navigator = Navigator.of(context);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) navigator.pop();
    });
  }

  void _openSubmitModal() {
    showDialog(
      context: context,
      builder: (ctx) => _SubmitDialog(
        answeredCount: _answeredCount,
        totalQuestions: _totalQuestions,
        flaggedCount: _flagged.length,
        onConfirm: () {
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Your assessment answers have been submitted for compliance evaluation.',
              ),
              backgroundColor: AppColors.secondary,
            ),
          );
          final navigator = Navigator.of(context);
          Future.delayed(const Duration(milliseconds: 900), () {
            if (mounted) navigator.pop();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width < 700) {
      return _buildMobileScaffold(context);
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PortalHeader(onSearch: (_) {}),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSidebar(),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTopUtilityBar(context),
                        const SizedBox(height: 16),
                        _buildBanner(),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 900;
                            if (isWide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 8, child: _buildLeftColumn()),
                                  const SizedBox(width: 16),
                                  SizedBox(width: 340, child: _buildPaletteCard()),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                _buildLeftColumn(),
                                const SizedBox(height: 16),
                                _buildPaletteCard(),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile layout ─────────────────────────────────────────────────────────
  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: _saveAndExit,
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
        ),
        title: Text('Compliance Quiz', style: AppTypography.headlineSm(color: AppColors.onSurface)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.secondaryContainer.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, size: 15, color: AppColors.secondary),
                    const SizedBox(width: 5),
                    Text(_formattedTimer, style: AppTypography.labelMd(color: AppColors.primary).copyWith(fontFeatures: [const FontFeature.tabularFigures()], fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMobileMetaCard(),
              const SizedBox(height: 12),
              _buildMobileQuestionStrip(),
              const SizedBox(height: 12),
              _buildQuestion6Card(),
              const SizedBox(height: 12),
              _buildQuestion7Card(),
              const SizedBox(height: 12),
              _buildFooterActionBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileMetaCard() {
    final remaining = _totalQuestions - _answeredCount;
    final percent = (_progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: AppColors.secondaryContainer.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.verified_user, color: AppColors.secondary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Chemical Handling Mandatory Compliance Exam',
                  style: AppTypography.labelLg(color: AppColors.primary).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final w = (constraints.maxWidth - 16) / 3;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(width: w, child: _mobileStat('Pass', '80%')),
                SizedBox(width: w, child: _mobileStat('Retakes', '1 of 3')),
                SizedBox(width: w, child: _mobileStat('Weight', '35%')),
              ],
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Q$_currentQuestion of $_totalQuestions • $percent% Done',
                  style: AppTypography.labelSm(color: AppColors.primary).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text('$remaining left', style: AppTypography.labelSm()),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainer,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(label, style: AppTypography.labelSm(), textAlign: TextAlign.center),
          Text(value, style: AppTypography.labelMd(color: AppColors.primary).copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildMobileQuestionStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Question Palette', style: AppTypography.labelMd(color: AppColors.primary).copyWith(fontWeight: FontWeight.w700)),
              ),
              Text('$_answeredCount answered', style: AppTypography.labelSm()),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _totalQuestions,
              separatorBuilder: (context, i) => const SizedBox(width: 8),
              itemBuilder: (context, i) => SizedBox(width: 40, child: _paletteTile(i + 1)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sidebar ───────────────────────────────────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      width: 256,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(1, 0))],
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sidebarItem('My Enrolled Courses'),
          const SizedBox(height: 4),
          _sidebarItem('Certification and Badges'),
        ],
      ),
    );
  }

  Widget _sidebarItem(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(label, style: AppTypography.labelLg(color: AppColors.onSurfaceVariant)),
    );
  }

  // ── Top utility bar ──────────────────────────────────────────────────────
  Widget _buildTopUtilityBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back, size: 18, color: AppColors.secondary),
                    const SizedBox(width: 6),
                    Text('Back to Course', style: AppTypography.labelMd()),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, size: 18, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Time Remaining', style: AppTypography.labelSm()),
                        Text(
                          _formattedTimer,
                          style: AppTypography.headlineSm(color: AppColors.primary)
                              .copyWith(fontFeatures: [const FontFeature.tabularFigures()]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _saveAndExit,
                icon: const Icon(Icons.bookmark_border, size: 18),
                label: const Text('Save & Exit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onSurfaceVariant,
                  backgroundColor: AppColors.surfaceContainerLow,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Banner ────────────────────────────────────────────────────────────────
  Widget _buildBanner() {
    final remaining = _totalQuestions - _answeredCount;
    final percent = (_progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 20,
            runSpacing: 16,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.verified_user, color: AppColors.secondary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Text(
                      'Chemical Handling Mandatory Compliance Exam',
                      style: AppTypography.headlineMd(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  _statPill('Passing Benchmark', '80% ($_passingCount of $_totalQuestions)', AppColors.secondaryContainer),
                  _statPill('Allowed Retakes', 'Attempt 1 of 3', AppColors.onTertiaryContainer),
                  _statPill('Exam Weight', '35% Module Grade', AppColors.secondary),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Progress: Question $_currentQuestion of $_totalQuestions • $percent% Completed',
                  style: AppTypography.labelSm(color: AppColors.primary).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text('$remaining Questions Remaining', style: AppTypography.labelSm()),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainer,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, String value, Color dotColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTypography.labelSm()),
            Text(value, style: AppTypography.labelLg(color: AppColors.primary).copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  // ── Left column (questions + footer) ─────────────────────────────────────
  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildQuestion6Card(),
        const SizedBox(height: 16),
        _buildQuestion7Card(),
        const SizedBox(height: 16),
        _buildFooterActionBar(),
      ],
    );
  }

  Widget _questionHeader({
    required String number,
    required String kicker,
    required String title,
    required int flagQuestion,
  }) {
    final isFlagged = _flagged.contains(flagQuestion);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(number, style: AppTypography.headlineSm(color: AppColors.primary)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(kicker, style: AppTypography.labelSm()),
              Text(title, style: AppTypography.labelMd(color: AppColors.primary).copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _toggleFlag(flagQuestion),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag, size: 16, color: isFlagged ? AppColors.error : AppColors.outline),
                  const SizedBox(width: 4),
                  Text(
                    isFlagged ? 'Flagged' : 'Flag for Review',
                    style: AppTypography.labelMd(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion6Card() {
    const options = [
      (
        'A',
        'OSHA General Exception',
        'No secondary label is mandatory provided the decanted chemical remains under the continuous, direct control of the employee who performed the transfer and is fully consumed within that work shift.',
      ),
      (
        'B',
        'Full GHS Relabel',
        'A full 6-point GHS secondary label (including pictograms, signal word, hazard statements, and manufacturer address) must be affixed prior to transferring any liquid volume greater than 500 mL.',
      ),
      (
        'C',
        'Simplified NFPA Diamond',
        'Only an abbreviated NFPA 704 standard diamond stamp with health rating 3 is required, regardless of usage duration or proximity to other shop personnel.',
      ),
      (
        'D',
        'Shift Lead Certification',
        'The secondary container may be left unmarked only if co-signed on the department whiteboard log by an authorized shift supervisor and environmental officer.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _questionHeader(
            number: '06',
            kicker: 'MULTIPLE CHOICE • STANDARD 4 POINTS',
            title: 'OSHA Secondary Container Labeling GHS Exemptions',
            flagQuestion: 6,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emergency, size: 16, color: AppColors.secondary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Workplace Compliance Scenario',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMd(color: AppColors.secondary).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: AppTypography.bodyMd(color: AppColors.onSurface),
                    children: const [
                      TextSpan(text: 'At 09:30 AM, an industrial technician decants '),
                      TextSpan(
                        text: '2.5 liters of Concentrated Sulfuric Acid (98% H₂SO₄)',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text:
                            ' from a certified 55-gallon primary drum into an unlabelled polyethylene secondary beaker to neutralize an adjacent alkaline spill basin. The technician intends to execute the spill neutralization immediately and complete the task within 45 minutes of their shift.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.policy, size: 15, color: AppColors.secondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: AppTypography.bodySm(),
                            children: const [
                              TextSpan(text: 'Reference Standard: '),
                              TextSpan(
                                text: 'OSHA HazCom CFR 1910.1200(f)(8) Portable Container Rule',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'According to standard GHS alignment and OSHA workplace standards, which regulatory action is required regarding the secondary beaker container?',
            style: AppTypography.headlineSm(color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          for (final o in options) ...[
            _optionTile(letter: o.$1, title: o.$2, description: o.$3),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _optionTile({required String letter, required String title, required String description}) {
    final selected = _q6Selection == letter;
    return GestureDetector(
      onTap: () => _selectQ6(letter),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.secondaryContainer.withValues(alpha: 0.1) : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.secondary : AppColors.outlineVariant.withValues(alpha: 0.3),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Radio<String>(
                value: letter,
                groupValue: _q6Selection,
                onChanged: (v) => _selectQ6(v!),
                activeColor: AppColors.secondary,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Option $letter', style: AppTypography.labelLg(color: AppColors.primary)),
                    const SizedBox(height: 2),
                    Text(description, style: AppTypography.bodyMd()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion7Card() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _questionHeader(
            number: '07',
            kicker: 'FREE RESPONSE • CASE STUDY • 6 POINTS',
            title: 'Incident Containment Plan & PPE Protocol Diagnosis',
            flagQuestion: 7,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning, size: 16, color: AppColors.error),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Critical Facility Incident Narrative',
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMd(color: AppColors.error).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: AppTypography.bodyMd(color: AppColors.onSurface),
              children: const [
                TextSpan(
                  text:
                      'During a routine forklift repositioning at the East Chem Bay storage rack, a puncture occurs on an intermediate bulk container (IBC) carrying ',
                ),
                TextSpan(
                  text: 'Glacial Acetic Acid (approx. 450 Liters)',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text:
                      '. Dense pungent vapors are propagating toward an adjacent assembly cell with 18 unevacuated personnel. The ventilation stack has entered automatic fault fallback.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: AppTypography.bodyMd(),
              children: const [
                TextSpan(text: 'Task Prompt: ', style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(
                  text:
                      'Outline the immediate 4-step emergency containment action sequence. Identify the exact minimum Level PPE required for the entry response team, specific neutralization agent, and mandatory regulatory reporting triggers under EPCRA / OSHA.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              backgroundColor: AppColors.surfaceContainer,
              collapsedBackgroundColor: AppColors.surfaceContainerLow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              leading: const Icon(Icons.psychology, size: 18, color: AppColors.secondary),
              title: Text(
                'View Evaluator Scoring Rubric & Keyword Criteria',
                style: AppTypography.labelMd(color: AppColors.secondary).copyWith(fontWeight: FontWeight.w700),
              ),
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _rubricChip('1. Immediate Evacuation (2 pts)',
                        'Must state alarm sounding and 100m upwind muster protocol before physical containment.'),
                    _rubricChip('2. Proper PPE Specified (2 pts)',
                        'Must designate Level B minimum with SCBA (due to vapor threshold) and neoprene/butyl gloves.'),
                    _rubricChip('3. Neutralizer & Agency (2 pts)',
                        'Must specify dry sodium carbonate / bicarbonate absorbent and National Response Center if threshold exceeded.'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                  ),
                  child: Row(
                    children: [
                      _toolbarIcon(Icons.format_bold),
                      _toolbarIcon(Icons.format_italic),
                      _toolbarIcon(Icons.format_list_bulleted),
                      _toolbarIcon(Icons.format_list_numbered),
                      const Spacer(),
                      const Icon(Icons.check_circle, size: 14, color: AppColors.tertiaryContainer),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Auto-saved 14s ago',
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSm(),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _freeResponseController,
                    maxLines: 7,
                    style: AppTypography.bodyMd(color: AppColors.onSurface),
                    onChanged: (_) => setState(_recomputeWordCount),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText:
                          'Draft your step-by-step incident response plan here... Mention evacuation radius, Level B PPE equipment, neutralization chemistry, and regulatory notifications.',
                      hintStyle: AppTypography.bodyMd(color: AppColors.outline),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text('Recommended: 80 - 250 words', style: AppTypography.labelSm()),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _wordCount >= 80
                      ? AppColors.tertiaryContainer.withValues(alpha: 0.15)
                      : AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_note, size: 14, color: _wordCount >= 80 ? AppColors.onTertiaryContainer : AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '$_wordCount word${_wordCount == 1 ? '' : 's'}',
                      style: AppTypography.labelSm(
                        color: _wordCount >= 80 ? AppColors.onTertiaryContainer : AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      _wordCount >= 80 ? ' • Threshold Met' : ' • Below Threshold',
                      style: AppTypography.labelSm(
                        color: _wordCount >= 80 ? AppColors.onTertiaryContainer : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toolbarIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
    );
  }

  Widget _rubricChip(String title, String body) {
    return SizedBox(
      width: 220,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.labelSm(color: AppColors.primary).copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(body, style: AppTypography.bodySm()),
          ],
        ),
      ),
    );
  }

  // ── Footer action bar ─────────────────────────────────────────────────────
  Widget _buildFooterActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Previous Question'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onSurfaceVariant,
                  backgroundColor: AppColors.surface,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _toggleFlag(_currentQuestion),
                icon: const Icon(Icons.flag, size: 18),
                label: const Text('Flag'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onSurfaceVariant,
                  backgroundColor: AppColors.surfaceContainerLow,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Save & Next Question'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryContainer,
                  foregroundColor: AppColors.onSecondaryContainer,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _openSubmitModal,
                icon: const Icon(Icons.send, size: 18),
                label: const Text('Submit Exam'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Palette sidebar ───────────────────────────────────────────────────────
  Widget _buildPaletteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Question Palette', style: AppTypography.headlineSm(color: AppColors.primary)),
                    Text('$_totalQuestions Questions Total', style: AppTypography.bodySm()),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$_answeredCount Answered',
                  style: AppTypography.labelSm(color: AppColors.secondary).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: List.generate(_totalQuestions, (i) => _paletteTile(i + 1)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _legendDot(AppColors.onTertiaryContainer, Icons.check, 'Answered (${_answered.length})'),
              _legendDot(AppColors.secondaryContainer, null, 'Current ($_currentQuestion)'),
              _legendDot(AppColors.error, null, 'Flagged (${_flagged.length})'),
              _legendDot(AppColors.surfaceContainerLow, null, 'Unvisited'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openSubmitModal,
              icon: const Icon(Icons.verified, size: 18),
              label: const Text('Finish & Submit Evaluation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paletteTile(int n) {
    final isCurrent = n == _currentQuestion;
    final isAnswered = _answered.contains(n);
    final isOpenEnded = n == 7;
    final isFlagged = _flagged.contains(n);

    Color bg = AppColors.surfaceContainerLow;
    Color fg = AppColors.onSurfaceVariant;
    if (isCurrent) {
      bg = AppColors.secondaryContainer;
      fg = AppColors.onSecondaryContainer;
    } else if (isAnswered) {
      bg = AppColors.surface;
      fg = AppColors.primary;
    } else if (isOpenEnded) {
      bg = AppColors.surfaceContainerHigh;
      fg = AppColors.primary;
    }

    return Stack(
      children: [
        Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: isCurrent ? Border.all(color: AppColors.secondary, width: 2) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                n.toString().padLeft(2, '0'),
                style: AppTypography.labelLg(color: fg).copyWith(fontWeight: FontWeight.w700),
              ),
              if (isAnswered)
                const Icon(Icons.check, size: 12, color: AppColors.onTertiaryContainer)
              else if (isOpenEnded)
                const Icon(Icons.edit, size: 12, color: AppColors.secondary),
            ],
          ),
        ),
        if (isFlagged)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
            ),
          ),
      ],
    );
  }

  Widget _legendDot(Color color, IconData? icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: icon != null ? Icon(icon, size: 9, color: AppColors.onTertiaryContainer) : null,
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.labelSm()),
      ],
    );
  }
}

// ── Submission confirmation dialog ─────────────────────────────────────────
class _SubmitDialog extends StatelessWidget {
  final int answeredCount;
  final int totalQuestions;
  final int flaggedCount;
  final VoidCallback onConfirm;

  const _SubmitDialog({
    required this.answeredCount,
    required this.totalQuestions,
    required this.flaggedCount,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final unanswered = totalQuestions - answeredCount;
    final percent = ((answeredCount / totalQuestions) * 100).round();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.assignment_turned_in, color: AppColors.secondary, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ready to Submit Quiz?', style: AppTypography.headlineMd(color: AppColors.primary)),
                      Text('Review your answer distribution before finalizing.', style: AppTypography.bodySm()),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryRow('Completed Questions:', '$answeredCount of $totalQuestions ($percent%)', AppColors.primary),
                  const SizedBox(height: 6),
                  _summaryRow('Flagged for Review:', '$flaggedCount Questions', AppColors.error),
                  const SizedBox(height: 6),
                  _summaryRow('Unanswered Questions:', '$unanswered Questions', AppColors.error),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: AppTypography.bodySm(),
                        children: const [
                          TextSpan(text: 'Note: ', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                          TextSpan(
                            text:
                                'Unanswered questions will receive 0 points. Minimum required for certification is 80%.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Return to Test'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryContainer,
                    foregroundColor: AppColors.onSecondaryContainer,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Yes, Confirm Submission'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMd()),
        Text(value, style: AppTypography.labelMd(color: valueColor).copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
