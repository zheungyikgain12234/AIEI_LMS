import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_material_progress_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/material_progress.dart';
import 'package:stitch_aiei_lms/domain/models/module_material.dart';
import 'package:stitch_aiei_lms/domain/models/student.dart';
import 'widgets/faculty_scaffold.dart';
import 'widgets/faculty_sidebar.dart';
import 'widgets/faculty_mobile_top_bar.dart';
import 'my_assigned_courses_screen.dart';

// ---------------------------------------------------------------------------
// GradeAssignmentScreen – Stitch "Grade Assignment: Alex Chen — Data
// Pipelines" faithful Flutter conversion.
// ---------------------------------------------------------------------------
class GradeAssignmentScreen extends StatefulWidget {
  const GradeAssignmentScreen({super.key});

  @override
  State<GradeAssignmentScreen> createState() => _GradeAssignmentScreenState();
}

class _GradeAssignmentScreenState extends State<GradeAssignmentScreen> {
  final _progressRepository = SupabaseMaterialProgressRepositoryImpl(Supabase.instance.client);

  final TextEditingController _scoreController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();

  bool _isLoading = true;
  ModuleMaterial? _material;
  MaterialProgress? _progress;
  Student? _student;
  int _totalSubmissions = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = Supabase.instance.client;
    final materialRow =
        await client.from('module_materials').select().eq('id', DemoIdentity.materialAssignment02Id).single();
    final material = ModuleMaterial.fromMap(materialRow);
    final progress = await _progressRepository.getProgress(
      DemoIdentity.studentId,
      DemoIdentity.materialAssignment02Id,
    );
    final studentRow =
        await client.from('students').select().eq('id', DemoIdentity.studentId).single();
    final student = Student.fromMap(studentRow);
    final submissions = await _progressRepository.getSubmissionsForMaterial(DemoIdentity.materialAssignment02Id);
    if (!mounted) return;
    setState(() {
      _material = material;
      _progress = progress;
      _student = student;
      _totalSubmissions = submissions.length;
      _scoreController.text = (progress?.score ?? 0).toString();
      _feedbackController.text = progress?.feedback ?? '';
      _isLoading = false;
    });
  }

  Future<void> _publishGrade() async {
    final score = int.tryParse(_scoreController.text.trim());
    if (score == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid numeric score before publishing.')),
      );
      return;
    }
    await _progressRepository.gradeSubmission(
      DemoIdentity.studentId,
      DemoIdentity.materialAssignment02Id,
      score: score,
      feedback: _feedbackController.text,
      gradedByLecturerId: DemoIdentity.lecturerId,
    );
    if (!mounted) return;
    setState(() {
      _progress = MaterialProgress(
        materialId: DemoIdentity.materialAssignment02Id,
        status: 'completed',
        score: score,
        attempts: _progress?.attempts ?? 1,
        submissionContent: _progress?.submissionContent ?? const {},
        feedback: _feedbackController.text,
        gradedBy: DemoIdentity.lecturerId,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Grade published to Alex Chen.'), backgroundColor: FacultyColors.primary),
    );
  }

  String _formatSubmittedAt(String? iso) {
    if (iso == null) return 'Not submitted';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return iso;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}, $hour12:$minute $period';
  }

  String _letterGrade(int score) {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _handleNav(FacultyNavDestination dest) {
    switch (dest) {
      case FacultyNavDestination.myCourses:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyAssignedCoursesScreen()));
        break;
      case FacultyNavDestination.gradingAndSubmissions:
        break;
    }
  }

  void _otherStudent() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Only Alex Chen\'s submission is available in this preview.')),
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
          _buildHeaderCard(),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1000;
            final left = _buildLeftColumn();
            final right = _buildRightColumn();
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: left),
                  const SizedBox(width: 24),
                  Expanded(flex: 5, child: right),
                ],
              );
            }
            return Column(children: [left, const SizedBox(height: 24), right]);
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    final content = _material?.content ?? const {};
    final title = _material?.name ?? 'Assignment 02: Automated Data Pipelines';
    final benchmark = content['cohortBenchmarkLabel'] as String?;
    final studentName = _student?.name ?? 'Alex Chen';
    final studentEmployeeId = _student?.studentCode ?? 'EMP-88219';
    final submittedAt = _progress?.submissionContent['submittedAt'] as String?;
    final onTime = _progress?.submissionContent['onTime'] as bool? ?? true;
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
                    const Icon(Icons.arrow_back, size: 18, color: FacultyColors.secondary),
                    const SizedBox(width: 4),
                    Text('Back to Submissions Queue', style: FacultyTypography.labelMd(color: FacultyColors.secondary)),
                  ]),
                ),
              ),
              Wrap(spacing: 6, children: [
                _pill('Course DATA-402', FacultyColors.surfaceContainer, FacultyColors.onSurfaceVariant),
                _pill('Cohort Fall 2025', FacultyColors.secondaryContainer, FacultyColors.onSecondaryContainer),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Grade Assignment: $title', style: FacultyTypography.headlineLg()),
                    if (benchmark != null) ...[
                      const SizedBox(height: 2),
                      Text(benchmark, style: FacultyTypography.bodySm()),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _otherStudent,
                          icon: const Icon(Icons.chevron_left, size: 18),
                          tooltip: 'Previous submission',
                          color: FacultyColors.onSurfaceVariant,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: FacultyColors.primary, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(studentName, style: FacultyTypography.titleSm(color: FacultyColors.primary)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(4)),
                              child: Text(studentEmployeeId, style: FacultyTypography.labelXs()),
                            ),
                            const SizedBox(width: 6),
                            Text('($_totalSubmissions submitted)', style: FacultyTypography.labelXs(color: FacultyColors.secondary)),
                          ]),
                        ),
                        IconButton(
                          onPressed: _otherStudent,
                          icon: const Icon(Icons.chevron_right, size: 18),
                          tooltip: 'Next submission',
                          color: FacultyColors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: FacultyColors.tertiaryContainer.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.task_alt, size: 15, color: FacultyColors.tertiary),
                      const SizedBox(width: 4),
                      Text(
                        '${onTime ? 'SUBMITTED ON TIME' : 'SUBMITTED LATE'} • ${_formatSubmittedAt(submittedAt)}',
                        style: FacultyTypography.labelXs(color: FacultyColors.tertiary).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: FacultyTypography.labelXs(color: fg).copyWith(fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildLeftColumn() {
    final files = ((_progress?.submissionContent['files'] as List?) ?? const [])
        .map((f) => Map<String, dynamic>.from(f as Map))
        .toList();
    final writeup = _progress?.submissionContent['writeup'] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FacultyColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.folder_zip_outlined, color: FacultyColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Submitted Files & Artifacts', style: FacultyTypography.titleSm())),
                OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading all files (.zip)...'))),
                  icon: const Icon(Icons.archive_outlined, size: 15),
                  label: const Text('Download All (.zip)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FacultyColors.primary,
                    backgroundColor: FacultyColors.surfaceContainer,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: FacultyTypography.labelXs(),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              if (files.isEmpty)
                Text('No files submitted.', style: FacultyTypography.bodySm())
              else
                for (var i = 0; i < files.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _fileRow(
                    _fileIcon(files[i]['name'] as String? ?? ''),
                    _fileIconColor(files[i]['name'] as String? ?? ''),
                    files[i]['name'] as String? ?? '',
                    '${files[i]['description'] ?? ''} • ${files[i]['sizeLabel'] ?? ''}',
                  ),
                ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FacultyColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.format_quote, color: FacultyColors.primary, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text('Student Submission Notes', style: FacultyTypography.titleSm())),
                Text('Submitted with assignment', style: FacultyTypography.labelXs()),
              ]),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  writeup != null ? '"$writeup"' : 'No submission notes provided.',
                  style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _fileIcon(String name) {
    if (name.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
    if (name.endsWith('.py') || name.endsWith('.ipynb')) return Icons.description_outlined;
    if (name.endsWith('.zip')) return Icons.folder_zip_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Color _fileIconColor(String name) => name.endsWith('.pdf') ? FacultyColors.error : FacultyColors.primary;

  Widget _fileRow(IconData icon, Color iconColor, String name, String meta) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: FacultyTypography.bodySm(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
                Text(meta, style: FacultyTypography.labelXs()),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloading $name...'))),
            icon: const Icon(Icons.download_outlined, size: 15),
            label: const Text('Download'),
            style: OutlinedButton.styleFrom(
              foregroundColor: FacultyColors.primary,
              backgroundColor: FacultyColors.surfaceContainerLowest,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: FacultyTypography.labelXs(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightColumn() {
    final currentScore = int.tryParse(_scoreController.text.trim()) ?? (_progress?.score ?? 0);
    final passMark = (_material?.content['passMarkPercentage'] as num?)?.toInt() ?? 80;
    final gradeLabel = '${_letterGrade(currentScore)} (${currentScore >= passMark ? 'Pass' : 'Fail'})';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FacultyColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.edit_document, color: FacultyColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Mark Entry & Evaluation', style: FacultyTypography.titleSm())),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: FacultyColors.tertiaryContainer.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text('Grade: $gradeLabel', style: FacultyTypography.titleSm(color: FacultyColors.tertiary).copyWith(fontSize: 13)),
                ),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('FINAL ASSIGNMENT SCORE', style: FacultyTypography.labelXs().copyWith(fontWeight: FontWeight.w700)),
                          Text('Scored out of 100 maximum marks', style: FacultyTypography.bodySm()),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 64,
                          child: TextField(
                            controller: _scoreController,
                            textAlign: TextAlign.right,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            style: FacultyTypography.headlineMd(color: FacultyColors.primary),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: FacultyColors.surfaceContainerLowest,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('/ 100', style: FacultyTypography.headlineMd(color: FacultyColors.secondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                const Icon(Icons.chat_bubble_outline, size: 16, color: FacultyColors.primary),
                const SizedBox(width: 6),
                Expanded(child: Text('Instructor Feedback', style: FacultyTypography.titleSm())),
                Text('Visible to Alex', style: FacultyTypography.labelXs()),
              ]),
              const SizedBox(height: 8),
              TextField(
                controller: _feedbackController,
                maxLines: 5,
                style: FacultyTypography.bodySm(color: FacultyColors.onSurface),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: FacultyColors.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FacultyColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft saved.'))),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FacultyColors.onSurface,
                        backgroundColor: FacultyColors.surfaceContainerLow,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Save Draft'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _publishGrade,
                      icon: const Icon(Icons.publish_outlined, size: 16),
                      label: const Text('Save & Publish'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FacultyColors.primaryContainer,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _otherStudent,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Save & Next Submission'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FacultyColors.primary,
                    backgroundColor: FacultyColors.surfaceContainerHigh,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Mobile (<700px) layout — separate Scaffold, drill-in top bar, sticky
  // bottom action bar. Reuses _scoreController / _feedbackController.
  // ---------------------------------------------------------------------

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: const FacultyMobileTopBar(title: 'Grading Assessment'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMobileTopRow(context),
              const SizedBox(height: 16),
              _buildMobileAssignmentCard(),
              const SizedBox(height: 16),
              _buildMobileArtifactsCard(),
              const SizedBox(height: 16),
              _buildMobileNotesCard(),
              const SizedBox(height: 16),
              _buildMobileEvaluationCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildMobileBottomBar(context),
    );
  }

  Widget _mobileCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: child,
    );
  }

  Widget _buildMobileTopRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, size: 18, color: FacultyColors.secondary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Back to Submissions Queue',
                      style: FacultyTypography.labelMd(color: FacultyColors.secondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
          child: Text(
            'DATA-402 • Fall 2025',
            style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _mobileNavChevron({required IconData icon, required String tooltip, required VoidCallback onTap}) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4)],
            ),
            child: Icon(icon, size: 18, color: FacultyColors.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileAssignmentCard() {
    final title = _material?.name ?? 'Assignment 02: Automated Data Pipelines';
    final studentName = _student?.name ?? 'Alex Chen';
    final studentEmployeeId = _student?.studentCode ?? 'EMP-88219';
    final submittedAt = _progress?.submissionContent['submittedAt'] as String?;
    final onTime = _progress?.submissionContent['onTime'] as bool? ?? true;
    return _mobileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.assignment_turned_in, size: 14, color: FacultyColors.secondary),
              const SizedBox(width: 4),
              Text(
                'ASSIGNMENT EVALUATION',
                style: FacultyTypography.labelXs(color: FacultyColors.secondary).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: FacultyTypography.headlineMd(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text('SUBMISSIONS', style: FacultyTypography.labelXs(), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text(
                      '$_totalSubmissions submitted',
                      style: FacultyTypography.labelXs(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _mobileNavChevron(icon: Icons.chevron_left, tooltip: 'Previous submission', onTap: _otherStudent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: FacultyColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4)],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(color: FacultyColors.secondaryContainer, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Text('AC', style: FacultyTypography.labelMd(color: FacultyColors.onSecondaryContainer)),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    studentName,
                                    style: FacultyTypography.titleSm(color: FacultyColors.primary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    studentEmployeeId,
                                    style: FacultyTypography.bodySm(color: FacultyColors.outline),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _mobileNavChevron(icon: Icons.chevron_right, tooltip: 'Next submission', onTap: _otherStudent),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: FacultyColors.tertiaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle, size: 6, color: FacultyColors.tertiary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${onTime ? 'Submitted on Time' : 'Submitted Late'} • ${_formatSubmittedAt(submittedAt)}',
                          style: FacultyTypography.labelXs(color: FacultyColors.tertiary).copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileArtifactsCard() {
    final files = ((_progress?.submissionContent['files'] as List?) ?? const [])
        .map((f) => Map<String, dynamic>.from(f as Map))
        .toList();
    return _mobileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_zip, color: FacultyColors.secondary, size: 20),
              const SizedBox(width: 6),
              Expanded(child: Text('Submitted Artifacts', style: FacultyTypography.titleSm(color: FacultyColors.primary))),
              const SizedBox(width: 6),
              TextButton.icon(
                onPressed: () =>
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading all files (.zip)...'))),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Download All'),
                style: TextButton.styleFrom(
                  foregroundColor: FacultyColors.secondary,
                  backgroundColor: FacultyColors.surfaceContainerLow,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: FacultyTypography.labelMd(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (files.isEmpty)
            Text('No files submitted.', style: FacultyTypography.bodySm())
          else
            for (var i = 0; i < files.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _mobileFileRow(
                _fileIcon(files[i]['name'] as String? ?? ''),
                _fileIconColor(files[i]['name'] as String? ?? ''),
                files[i]['name'] as String? ?? '',
                '${files[i]['description'] ?? ''} • ${files[i]['sizeLabel'] ?? ''}',
              ),
            ],
        ],
      ),
    );
  }

  Widget _mobileFileRow(IconData icon, Color iconColor, String name, String meta) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: FacultyTypography.bodySm(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(meta, style: FacultyTypography.labelXs(), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloading $name...'))),
            icon: const Icon(Icons.download, size: 18),
            color: FacultyColors.secondary,
            tooltip: 'Download $name',
          ),
        ],
      ),
    );
  }

  Widget _buildMobileNotesCard() {
    final writeup = _progress?.submissionContent['writeup'] as String?;
    return _mobileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat, color: FacultyColors.secondary, size: 20),
              const SizedBox(width: 6),
              Expanded(child: Text('Student Implementation Notes', style: FacultyTypography.titleSm(color: FacultyColors.primary))),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
            child: Text(
              writeup != null ? '"$writeup"' : 'No submission notes provided.',
              style: FacultyTypography.bodyMd(color: FacultyColors.onSurfaceVariant).copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileEvaluationCard() {
    final currentScore = int.tryParse(_scoreController.text.trim()) ?? (_progress?.score ?? 0);
    final passMark = (_material?.content['passMarkPercentage'] as num?)?.toInt() ?? 80;
    final gradeLabel = '${_letterGrade(currentScore)} (${currentScore >= passMark ? 'Pass' : 'Fail'})';
    return _mobileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check, color: FacultyColors.secondary, size: 20),
              const SizedBox(width: 6),
              Expanded(child: Text('Evaluation & Feedback', style: FacultyTypography.titleSm(color: FacultyColors.primary))),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: FacultyColors.tertiaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Grade: $gradeLabel',
                  style: FacultyTypography.labelXs(color: FacultyColors.tertiary).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('FINAL SCORE', style: FacultyTypography.labelXs().copyWith(fontWeight: FontWeight.w700)),
                          Text('Scale 0 - 100 max', style: FacultyTypography.bodySm(), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: FacultyColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          SizedBox(
                            width: 44,
                            child: TextField(
                              controller: _scoreController,
                              textAlign: TextAlign.right,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              style: FacultyTypography.headlineMd(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text('/ 100', style: FacultyTypography.titleSm(color: FacultyColors.outline)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Quick Presets:', style: FacultyTypography.labelXs()),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _mobileScorePreset('85')),
                    const SizedBox(width: 8),
                    Expanded(child: _mobileScorePreset('90')),
                    const SizedBox(width: 8),
                    Expanded(child: _mobileScorePreset('94')),
                    const SizedBox(width: 8),
                    Expanded(child: _mobileScorePreset('100')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text('Instructor Written Feedback', style: FacultyTypography.labelMd(color: FacultyColors.onSurface)),
              ),
              const SizedBox(width: 8),
              Text('Markdown supported', style: FacultyTypography.bodySm(), overflow: TextOverflow.ellipsis),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _feedbackController,
            maxLines: 4,
            style: FacultyTypography.bodyMd(color: FacultyColors.onSurface),
            decoration: InputDecoration(
              filled: true,
              fillColor: FacultyColors.surfaceContainerLow,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.check_circle, size: 16, color: FacultyColors.tertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Telemetry criteria auto-verified (5/5)',
                  style: FacultyTypography.labelXs(color: FacultyColors.tertiary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text('Rubric v2.1', style: FacultyTypography.labelXs(color: FacultyColors.outline)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileScorePreset(String value) {
    final selected = _scoreController.text.trim() == value;
    return OutlinedButton(
      onPressed: () => setState(() => _scoreController.text = value),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? FacultyColors.secondary : FacultyColors.surfaceContainerLowest,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        value,
        style: FacultyTypography.labelMd(color: selected ? FacultyColors.onSecondary : FacultyColors.onSurface),
      ),
    );
  }

  Widget _buildMobileBottomBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _mobileActionButton(
                      icon: Icons.save,
                      label: 'Save Draft',
                      background: FacultyColors.surfaceContainerLow,
                      foreground: FacultyColors.secondary,
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft saved.'))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _mobileActionButton(
                      icon: Icons.publish,
                      label: 'Save & Publish',
                      background: FacultyColors.secondary,
                      foreground: FacultyColors.onSecondary,
                      onPressed: _publishGrade,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: _mobileActionButton(
                  icon: Icons.arrow_forward,
                  label: 'Save & Next Submission',
                  background: FacultyColors.primary,
                  foreground: FacultyColors.onPrimary,
                  onPressed: _otherStudent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileActionButton({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              style: FacultyTypography.labelMd(color: foreground),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 18, color: foreground),
        ],
      ),
    );
  }
}
