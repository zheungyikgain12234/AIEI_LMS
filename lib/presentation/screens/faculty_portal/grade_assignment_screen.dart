import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'widgets/faculty_scaffold.dart';
import 'widgets/faculty_sidebar.dart';
import 'my_assigned_courses_screen.dart';
import 'student_directory_screen.dart';

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
  final TextEditingController _scoreController = TextEditingController(text: '94');
  final TextEditingController _feedbackController = TextEditingController(
    text:
        'Exceptional submission Alex. Your vectorized transformation logic was one of the most performant in the cohort. Solid edge case handling on the tax code and clean quarantine parquet routing.',
  );

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
      case FacultyNavDestination.studentDirectory:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentDirectoryScreen()));
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
                    Text('Grade Assignment: Assignment 02 - Automated Data Pipelines', style: FacultyTypography.headlineLg()),
                    const SizedBox(height: 2),
                    Text('Building Automated Data Pipelines with Pandas & Excel • Cohort Analytics Benchmark: 88.4%', style: FacultyTypography.bodySm()),
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
                          tooltip: 'Prev: Maya Patel',
                          color: FacultyColors.onSurfaceVariant,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: FacultyColors.primary, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text('Alex Chen', style: FacultyTypography.titleSm(color: FacultyColors.primary)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(4)),
                              child: Text('EMP-88219', style: FacultyTypography.labelXs()),
                            ),
                            const SizedBox(width: 6),
                            Text('(2 of 36)', style: FacultyTypography.labelXs(color: FacultyColors.secondary)),
                          ]),
                        ),
                        IconButton(
                          onPressed: _otherStudent,
                          icon: const Icon(Icons.chevron_right, size: 18),
                          tooltip: 'Next: Marcus Vance',
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
                      Text('SUBMITTED ON TIME • Nov 14, 2025, 4:15 PM', style: FacultyTypography.labelXs(color: FacultyColors.tertiary).copyWith(fontWeight: FontWeight.w700)),
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
              _fileRow(Icons.description_outlined, FacultyColors.primary, 'pipeline_etl_v2_chen.py', 'Python Script • 48 KB • Submitted Nov 14, 4:15 PM'),
              const SizedBox(height: 8),
              _fileRow(Icons.picture_as_pdf_outlined, FacultyColors.error, 'pipeline_execution_report.pdf', 'PDF Document • 1.2 MB • Submitted Nov 14, 4:15 PM'),
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
                  '"Handled edge case where column tax_code had null values by defaulting to regional regulatory rate 0.0825. Quarantine routing extracts invalid rows into an isolated parquet buffer with timestamp tracking. Vectorized timestamp transformations yielding a 3.8x execution time reduction compared with standard iteration."',
                  style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
                  child: Text('Grade: A (Pass)', style: FacultyTypography.titleSm(color: FacultyColors.tertiary).copyWith(fontSize: 13)),
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Grade published to Alex Chen.'), backgroundColor: FacultyColors.primary),
                        );
                      },
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
                  label: const Text('Save & Next Student (Marcus Vance)'),
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
}
