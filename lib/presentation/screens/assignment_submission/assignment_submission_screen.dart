import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturers_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_material_progress_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/lecturer.dart';
import 'package:stitch_aiei_lms/domain/models/material_progress.dart';
import 'package:stitch_aiei_lms/domain/models/module_material.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/widgets/portal_header.dart';

// ---------------------------------------------------------------------------
// AssignmentSubmissionScreen – Stitch "Student Assignment Submission (Python
// for Enterprise)" faithful Flutter conversion.
// ---------------------------------------------------------------------------
class AssignmentSubmissionScreen extends StatefulWidget {
  const AssignmentSubmissionScreen({super.key});

  @override
  State<AssignmentSubmissionScreen> createState() => _AssignmentSubmissionScreenState();
}

class _AssignmentSubmissionScreenState extends State<AssignmentSubmissionScreen> {
  final _progressRepository = SupabaseMaterialProgressRepositoryImpl(Supabase.instance.client);
  final _lecturersRepository = SupabaseLecturersRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  bool _briefingExpanded = true;
  bool _submitting = false;
  bool _submitted = false;

  ModuleMaterial? _material;
  MaterialProgress? _progress;
  Lecturer? _facultyContact;

  int _secondsLeft = 50;
  Timer? _timer;

  final TextEditingController _notesController = TextEditingController();

  final List<_StagedFile> _stagedFiles = [];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _secondsLeft = _secondsLeft > 0 ? _secondsLeft - 1 : 59);
    });
    _load();
  }

  Future<void> _load() async {
    final materialRow = await Supabase.instance.client
        .from('module_materials')
        .select()
        .eq('id', DemoIdentity.materialAssignment02Id)
        .single();
    final material = ModuleMaterial.fromMap(materialRow);
    final progress = await _progressRepository.getProgress(
      DemoIdentity.studentId,
      DemoIdentity.materialAssignment02Id,
    );
    final lecturers = await _lecturersRepository.getLecturers();
    final contact = lecturers.where((l) => l.id == DemoIdentity.lecturerId).firstOrNull;
    if (!mounted) return;
    setState(() {
      _material = material;
      _progress = progress;
      _facultyContact = contact;
      if (progress != null && progress.submissionContent.isNotEmpty) {
        _notesController.text = progress.submissionContent['writeup'] as String? ?? '';
        final files = progress.submissionContent['files'] as List? ?? [];
        _stagedFiles.addAll(files.map((raw) {
          final f = Map<String, dynamic>.from(raw as Map);
          final name = f['name'] as String? ?? 'file';
          return _StagedFile(
            icon: _iconForFile(name),
            name: name,
            sizeLabel: f['sizeLabel'] as String? ?? '',
            description: f['description'] as String? ?? '',
          );
        }));
      }
      _submitted = progress != null && progress.status == 'completed';
      _isLoading = false;
    });
  }

  IconData _iconForFile(String name) {
    if (name.endsWith('.py') || name.endsWith('.ipynb')) return Icons.code;
    if (name.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (name.endsWith('.zip')) return Icons.folder_zip;
    return Icons.insert_drive_file;
  }

  String _formatDueAt(DateTime? dueAt) {
    if (dueAt == null) return 'No due date set';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final local = dueAt.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final minute = local.minute.toString().padLeft(2, '0');
    return 'Due ${months[local.month - 1]} ${local.day}, ${local.year} • $hour12:$minute $period';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.primaryContainer),
    );
  }

  void _removeFile(_StagedFile file) {
    setState(() => _stagedFiles.remove(file));
    _showToast('Artifact detached from staged payload.');
  }

  void _resetDraft() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Are you sure you want to discard unsaved alterations?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _notesController.clear();
              Navigator.of(ctx).pop();
              _showToast('Form fields cleared to initial checkpoint.');
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await _progressRepository.submitContent(
      DemoIdentity.studentId,
      DemoIdentity.materialAssignment02Id,
      {
        'writeup': _notesController.text,
        'files': [
          for (final f in _stagedFiles)
            {'name': f.name, 'sizeLabel': f.sizeLabel, 'description': f.description},
        ],
        'submittedAt': DateTime.now().toIso8601String(),
        'onTime': true,
      },
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _submitted = true;
    });
    _showToast('Assignment successfully transmitted to auto-grading queue.');
  }

  void _showRubricModal() {
    final content = _material?.content ?? const {};
    final rubricLabel = content['rubricLabel'] as String? ?? 'Institutional Grading Rubric (100 Pts)';
    final passMark = content['passMarkPercentage'];
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 640),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assignment_turned_in, color: AppColors.secondary, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(rubricLabel, style: AppTypography.headlineMd()),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                Text(
                  'Submissions undergo synchronous static analysis, syntax verification, and dual-blind review by course enterprise faculty. '
                  'A composite score of ${passMark ?? 80}% is required for module credentialing.',
                  style: AppTypography.bodyMd(),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _rubricItem('1. Modular Architecture & PEP-8 Standards', '30 Points',
                            'Functions must isolate extraction, parsing, transformation, and ingestion phases. Flake8 score must be zero-warning. Fully documented type hints and PEP-257 docstrings are required.'),
                        const SizedBox(height: 10),
                        _rubricItem('2. Schema Validation & Quarantine Partitioning', '30 Points',
                            'Null checks, data type coercion safeguards, and invalid entity routing into separate JSON audit logs without terminating the active worker thread.'),
                        const SizedBox(height: 10),
                        _rubricItem('3. Computational Efficiency & Vectorization', '20 Points',
                            'Zero explicit for-loop record iteration across sales rows; strictly vectorized aggregations with memory foot-printing under 128 MB.'),
                        const SizedBox(height: 10),
                        _rubricItem('4. Verification Logs & Executive Output', '20 Points',
                            'Output execution report capturing line items ingested, discarded transactions count, memory profiling, and final revenue metrics summary.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.onSecondary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Close Rubric Overview'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rubricItem(String title, String points, String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTypography.labelLg())),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(points, style: AppTypography.labelMd(color: AppColors.secondary)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(description, style: AppTypography.bodySm()),
        ],
      ),
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
                        _buildBreadcrumb(context),
                        const SizedBox(height: 16),
                        _buildHeroBanner(),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 900;
                            if (isWide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 8, child: _buildLeftColumn()),
                                  const SizedBox(width: 24),
                                  SizedBox(width: 340, child: _buildRightColumn()),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                _buildLeftColumn(),
                                const SizedBox(height: 24),
                                _buildRightColumn(),
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
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
        ),
        title: Text('Assignment Submission', style: AppTypography.headlineSm(color: AppColors.onSurface)),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeroBanner(),
              const SizedBox(height: 12),
              _buildTimeCard(),
              const SizedBox(height: 12),
              _buildFacultyCard(),
              const SizedBox(height: 12),
              _buildBriefingCard(),
              const SizedBox(height: 12),
              _buildSubmissionCard(),
            ],
          ),
        ),
      ),
    );
  }

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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(8)),
            child: Text('My Enrolled Courses', style: AppTypography.labelLg(color: AppColors.onSecondary)),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text('Certifications & Badges', style: AppTypography.labelLg(color: AppColors.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back, size: 20, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 8),
            Text('Back to Module 2: Automation Pipelines', style: AppTypography.labelMd(color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    final material = _material;
    final content = material?.content ?? const {};
    final title = material?.name ?? 'Assignment 02: Building Automated Data Pipelines with Pandas & Excel';
    final description = content['instruction'] as String? ??
        'Develop an end-to-end Python script to validate, cleanse, and automate enterprise Excel sales reports into clean database-ready format with quarantine auditing.';
    final maxScore = content['maxScore'] ?? 100;
    final passMark = content['passMarkPercentage'] ?? 80;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _submitted ? 'STATUS: SUBMITTED' : 'STATUS: PENDING SUBMISSION',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSm(color: AppColors.secondary),
                      ),
                    ),
                  ],
                ),
              ),
              _pillBadge('AUTOMATED PIPELINE VERIFICATION'),
              _pillBadge('Single-Worker Async'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.headlineLg(color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTypography.bodyMd(),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 560;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: wide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
                  child: _metricPill(Icons.calendar_today, 'FORMAL DEADLINE', _formatDueAt(material?.dueAt)),
                ),
                SizedBox(
                  width: wide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
                  child: GestureDetector(
                    onTap: _showRubricModal,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: _metricPill(
                          Icons.military_tech, 'EVALUATION WEIGHTS', '$maxScore Points (Pass mark: $passMark%)',
                          trailing: 'View Rubric'),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _pillBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(9999)),
      child: Text(text, style: AppTypography.labelSm()),
    );
  }

  Widget _metricPill(IconData icon, String label, String value, {String? trailing}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.labelSm(), overflow: TextOverflow.ellipsis),
                Text(value, style: AppTypography.labelLg(), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(trailing, style: AppTypography.labelMd(color: AppColors.secondary), overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  // ── Left Column ───────────────────────────────────────────────────────────
  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBriefingCard(),
        const SizedBox(height: 24),
        _buildSubmissionCard(),
      ],
    );
  }

  Widget _buildBriefingCard() {
    final content = _material?.content ?? const {};
    final instruction = content['instruction'] as String? ??
        'In this assignment, you act as the Senior Analytics Engineer for Global Retail Corp. You have been provided quarterly workbook dumps containing raw unformatted transactions spanning 14 regional distribution entities.';
    final notes = content['notes'] as String?;
    final references = (content['references'] as List?)?.cast<String>() ?? const [];
    final attachedFiles = _material?.attachedFiles ?? const [];
    return Container(
      padding: const EdgeInsets.all(24),
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
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: const Icon(Icons.terminal, size: 16, color: AppColors.onPrimary),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text('Instructions & Technical Briefing', style: AppTypography.headlineSm())),
              GestureDetector(
                onTap: () => setState(() => _briefingExpanded = !_briefingExpanded),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_briefingExpanded ? 'Collapse Brief' : 'Expand Brief',
                          style: AppTypography.labelMd(color: AppColors.onSurfaceVariant)),
                      Icon(_briefingExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 18, color: AppColors.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_briefingExpanded) ...[
            const SizedBox(height: 12),
            Text(
              instruction,
              style: AppTypography.bodyMd(),
            ),
            if (notes != null) ...[
              const SizedBox(height: 6),
              Text(notes, style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)),
            ],
            if (references.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('References: ${references.join(', ')}', style: AppTypography.bodySm(color: AppColors.secondary)),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CORE PIPELINE OBJECTIVES', style: AppTypography.labelMd()),
                  const SizedBox(height: 8),
                  _objectiveBullet('Data Ingestion:', 'Multi-tab parsing of dataset_q3_raw.xlsx dynamically detecting headers.'),
                  _objectiveBullet('Schema Sanitization:', 'Cast timestamps to ISO-8601, strip currency symbols, enforce numeric precision on line totals.'),
                  _objectiveBullet('Quarantine Routing:', 'Segregate incomplete rows into rejected_records.json with distinct error codes.'),
                  _objectiveBullet('Synthesis & KPI Rollup:', 'Aggregate net margins per SKU category and auto-generate an executive summary PDF artifact.'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final f in attachedFiles)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.folder_zip, color: AppColors.secondary, size: 24),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(f['name'] as String? ?? '',
                                          style: AppTypography.labelMd(), overflow: TextOverflow.ellipsis, maxLines: 2),
                                      Text('${f['footer'] ?? ''} • ${f['sizeLabel'] ?? ''}',
                                          style: AppTypography.bodySm(), overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _showToast('${f['name']} download initiated.'),
                            icon: const Icon(Icons.cloud_download, size: 16),
                            label: Text('Download (${f['sizeLabel'] ?? ''})'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.onSurface,
                              backgroundColor: AppColors.surfaceContainer,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _objectiveBullet(String label, String rest) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(color: AppColors.onSurface)),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: '$label ', style: AppTypography.labelMd()),
                  TextSpan(text: rest, style: AppTypography.bodyMd()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: const Icon(Icons.upload_file, size: 16, color: AppColors.onSecondary),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text('Solution Upload & Artifacts', style: AppTypography.headlineSm())),
              Text('Step 2 of 2', style: AppTypography.labelSm()),
            ],
          ),
          const SizedBox(height: 16),
          if (_progress?.score != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.grade, size: 18, color: AppColors.onTertiaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Already graded: ${_progress!.score}/100', style: AppTypography.labelLg()),
                        if (_progress!.feedback != null) ...[
                          const SizedBox(height: 4),
                          Text(_progress!.feedback!, style: AppTypography.bodySm()),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildDropZone(),
          const SizedBox(height: 16),
          Text('STAGED ARTIFACTS (${_stagedFiles.length} Files Attached)', style: AppTypography.labelSm()),
          const SizedBox(height: 8),
          for (final f in _stagedFiles) _buildFileRow(f),
          const SizedBox(height: 16),
          Text('Submission Notes', style: AppTypography.labelMd()),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _notesController,
              maxLines: 4,
              style: AppTypography.bodyMd(color: AppColors.onSurface),
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(12)),
            ),
          ),
          const SizedBox(height: 16),
          _buildActionBar(),
        ],
      ),
    );
  }

  Widget _buildDropZone() {
    return GestureDetector(
      onTap: () => _showToast('Staged file attached: solution_upload.py'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.cloud_upload, size: 28, color: AppColors.secondary),
              ),
              const SizedBox(height: 12),
              Text('Drag & drop your solution files here', style: AppTypography.headlineSm()),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: AppTypography.bodySm(),
                  children: const [
                    TextSpan(text: 'or '),
                    TextSpan(
                      text: 'Browse from computer',
                      style: TextStyle(color: AppColors.secondary, decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  _extPill('.py'),
                  _extPill('.ipynb'),
                  _extPill('.zip'),
                  _extPill('.pdf'),
                  Text('Max single file payload: 25 MB', style: AppTypography.bodySm()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _extPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(9999)),
      child: Text(text.toUpperCase(), style: AppTypography.labelSm()),
    );
  }

  Widget _buildFileRow(_StagedFile file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Icon(file.icon, size: 22, color: AppColors.secondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.name, style: AppTypography.labelLg(), overflow: TextOverflow.ellipsis),
                Text(file.subtitle, style: AppTypography.bodySm()),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeFile(file),
            icon: const Icon(Icons.delete, size: 18, color: AppColors.onSurfaceVariant),
            tooltip: 'Delete file',
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        OutlinedButton(
          onPressed: _resetDraft,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.onSurface,
            backgroundColor: AppColors.surfaceContainer,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Discard Changes'),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton(
              onPressed: () => _showToast('Assignment draft saved to institutional cloud.'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onSurface,
                backgroundColor: AppColors.surfaceContainerHigh,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save Draft'),
            ),
            ElevatedButton.icon(
              onPressed: _submitting || _submitted ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onSecondary),
                    )
                  : Icon(_submitted ? Icons.check_circle : Icons.arrow_forward, size: 18),
              label: Text(_submitting
                  ? 'Submitting payload...'
                  : _submitted
                      ? 'Submitted Successfully!'
                      : 'Submit Assignment for Grading'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _submitted ? AppColors.tertiaryContainer : AppColors.secondary,
                foregroundColor: _submitted ? AppColors.onTertiaryContainer : AppColors.onSecondary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Right Column ──────────────────────────────────────────────────────────
  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTimeCard(),
        const SizedBox(height: 24),
        _buildFacultyCard(),
      ],
    );
  }

  Widget _buildTimeCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TIME REMAINING', style: AppTypography.labelSm()),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9999)),
                child: Text('On Track', style: AppTypography.labelMd(color: AppColors.secondary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 4,
            runSpacing: 4,
            children: [
              Text('03', style: AppTypography.headlineXl()),
              const SizedBox(width: 4),
              Text('Days', style: AppTypography.labelMd(color: AppColors.onSurfaceVariant)),
              const SizedBox(width: 6),
              Text('08', style: AppTypography.headlineXl()),
              const SizedBox(width: 4),
              Text('Hours', style: AppTypography.labelMd(color: AppColors.onSurfaceVariant)),
              const SizedBox(width: 6),
              Text(_secondsLeft.toString().padLeft(2, '0'), style: AppTypography.headlineXl(color: AppColors.secondary)),
              const SizedBox(width: 4),
              Text('Sec', style: AppTypography.labelMd(color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text('Attempt Window', style: AppTypography.labelSm()),
              Text('Attempt ${_progress?.attempts ?? 1} of 3', style: AppTypography.labelSm()),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: (_progress?.attempts ?? 1) / 3,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainer,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacultyCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('FACULTY ACADEMIC SUPPORT', style: AppTypography.labelSm()),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.onTertiaryContainer, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.person, color: AppColors.onPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_facultyContact?.name ?? 'Dr. Sarah Lin', style: AppTypography.labelLg()),
                    Text(
                      _facultyContact != null
                          ? '${_facultyContact!.title} • ${_facultyContact!.specialization}'
                          : 'Lead Data Architect • Enterprise Fellow',
                      style: AppTypography.bodySm(),
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
}

class _StagedFile {
  final IconData icon;
  final String name;
  final String sizeLabel;
  final String description;

  _StagedFile({
    required this.icon,
    required this.name,
    required this.sizeLabel,
    required this.description,
  });

  String get subtitle => [
        if (sizeLabel.isNotEmpty) sizeLabel,
        if (description.isNotEmpty) description,
      ].join(' • ');
}
