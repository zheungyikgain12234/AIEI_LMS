import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'widgets/faculty_scaffold.dart';
import 'widgets/faculty_sidebar.dart';
import 'widgets/faculty_mobile_top_bar.dart';
import 'my_assigned_courses_screen.dart';
import 'student_directory_screen.dart';
import 'grade_assignment_screen.dart';

// ---------------------------------------------------------------------------
// CurriculumManagerScreen – Stitch "Course Curriculum & Content Manager"
// faithful Flutter conversion.
// ---------------------------------------------------------------------------
class CurriculumManagerScreen extends StatefulWidget {
  const CurriculumManagerScreen({super.key});

  @override
  State<CurriculumManagerScreen> createState() => _CurriculumManagerScreenState();
}

class _CurriculumManagerScreenState extends State<CurriculumManagerScreen> {
  final Set<int> _expanded = {2};
  bool _module3Published = false;

  void _handleNav(FacultyNavDestination dest) {
    switch (dest) {
      case FacultyNavDestination.myCourses:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyAssignedCoursesScreen()));
        break;
      case FacultyNavDestination.studentDirectory:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentDirectoryScreen()));
        break;
      case FacultyNavDestination.gradingAndSubmissions:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GradeAssignmentScreen()));
        break;
    }
  }

  void _notAvailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Not wired up in this preview.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width < 700) {
      return _buildMobileScaffold(context);
    }
    return FacultyScaffold(
      selected: FacultyNavDestination.myCourses,
      onDestinationSelected: _handleNav,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 20),
          _buildKpiRow(),
          const SizedBox(height: 20),
          _buildToolbar(),
          const SizedBox(height: 20),
          _buildModule1(),
          const SizedBox(height: 16),
          _buildModule2(),
          const SizedBox(height: 16),
          _buildModule3(),
          const SizedBox(height: 20),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back, size: 18, color: FacultyColors.secondary),
                const SizedBox(width: 4),
                Text('Back to Course Dashboard', style: FacultyTypography.labelMd(color: FacultyColors.secondary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: FacultyColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(6)),
                      child: Text('CS-408', style: FacultyTypography.labelXs(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700)),
                    ),
                    Text('•', style: FacultyTypography.labelXs()),
                    Text('Fall Cohort Alpha', style: FacultyTypography.labelXs(color: FacultyColors.secondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Course Curriculum & Content Manager', style: FacultyTypography.headlineLg()),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: FacultyTypography.bodySm(color: FacultyColors.secondary),
                    children: const [
                      TextSpan(text: 'Manage modules, video lectures, coding sandbox environments, and supplementary lecture files for '),
                      TextSpan(text: 'Python for Enterprise Data Analysis & Automation', style: TextStyle(fontWeight: FontWeight.w700, color: FacultyColors.onSurface)),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: _notAvailable,
                  icon: const Icon(Icons.library_add_outlined, size: 18, color: FacultyColors.primary),
                  label: const Text('Add Module'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FacultyColors.onSurface,
                    backgroundColor: FacultyColors.surfaceContainerLowest,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _notAvailable,
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: const Text('Upload Material'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FacultyColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiRow() {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 500 ? 2 : 1);
      final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
      final cards = [
        _kpi('TOTAL MODULES', '6', '2 Published, 4 Draft', Icons.folder_copy_outlined, FacultyColors.primary, progress: 0.33),
        _kpi('INTERACTIVE SANDBOX', 'Python 3.11', 'Runtime cluster operational', Icons.terminal, FacultyColors.tertiary, extra: 'JupyterLab 4.2'),
        _kpi('ATTACHED STORAGE', '4.8 GB', '/ 10 GB Quota', Icons.storage_outlined, FacultyColors.primaryContainer, progress: 0.48),
        _kpi('STUDENT ACCESS RATE', '94.2%', 'Active on Module 2 materials', Icons.insights_outlined, FacultyColors.primary, extra: '+3.1%'),
      ];
      return Wrap(spacing: 16, runSpacing: 16, children: cards.map((c) => SizedBox(width: width, child: c)).toList());
    });
  }

  Widget _kpi(String label, String value, String footer, IconData icon, Color iconColor, {double? progress, String? extra}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: FacultyTypography.labelXs(color: FacultyColors.secondary).copyWith(fontWeight: FontWeight.w700))),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: FacultyTypography.displayLg().copyWith(fontSize: 24)),
              if (extra != null) ...[
                const SizedBox(width: 6),
                Text(extra, style: FacultyTypography.labelXs(color: FacultyColors.tertiary).copyWith(fontWeight: FontWeight.w600)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (progress != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(9999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: FacultyColors.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              ),
            )
          else
            Text(footer, style: FacultyTypography.bodySm(color: FacultyColors.secondary)),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: TextField(
                  style: FacultyTypography.bodySm(color: FacultyColors.onSurface),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: FacultyColors.surfaceContainerLow,
                    hintText: 'Filter materials, videos, datasets, code files...',
                    hintStyle: FacultyTypography.bodySm(color: FacultyColors.outline),
                    prefixIcon: const Icon(Icons.search, size: 16, color: FacultyColors.outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              _filterPill('All (18)', true),
              _filterPill('Videos (9)', false),
              _filterPill('Documents & PDFs (4)', false),
              _filterPill('Starter Code (3)', false),
              _filterPill('Datasets (2)', false),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                offset: const Offset(0, 40),
                onSelected: (_) => _notAvailable(),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'publish', child: Text('Publish Selected')),
                  PopupMenuItem(value: 'unpublish', child: Text('Unpublish')),
                  PopupMenuItem(value: 'export', child: Text('Export Manifest')),
                  PopupMenuItem(value: 'delete', child: Text('Delete Selected', style: TextStyle(color: FacultyColors.error))),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.select_all, size: 16, color: FacultyColors.secondary),
                    const SizedBox(width: 4),
                    Text('Bulk Actions', style: FacultyTypography.labelXs(color: FacultyColors.secondary)),
                    const Icon(Icons.expand_more, size: 16, color: FacultyColors.secondary),
                  ]),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() {
                  if (_expanded.length == 3) {
                    _expanded.clear();
                  } else {
                    _expanded.addAll([1, 2, 3]);
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.unfold_more, size: 16, color: FacultyColors.secondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterPill(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? FacultyColors.primaryContainer : FacultyColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: FacultyTypography.labelXs(color: active ? FacultyColors.onPrimaryContainer : FacultyColors.secondary)),
    );
  }

  Widget _moduleShell({
    required int index,
    required String badge,
    required Color badgeBg,
    required Color badgeFg,
    List<Widget> extraBadges = const [],
    required String titleTop,
    required String title,
    required Widget content,
    Widget? trailing,
    bool accent = false,
  }) {
    final open = _expanded.contains(index);
    return Container(
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: accent
            ? const [BoxShadow(color: Color(0x14000000), blurRadius: 10)]
            : const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (accent) Container(width: 5, color: FacultyColors.primary, height: 64),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => open ? _expanded.remove(index) : _expanded.add(index)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.drag_indicator, size: 20, color: FacultyColors.outline),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(titleTop, style: FacultyTypography.labelXs(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700)),
                                  Text('•', style: FacultyTypography.labelXs()),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(4)),
                                    child: Text(badge, style: FacultyTypography.labelXs(color: badgeFg).copyWith(fontWeight: FontWeight.w700)),
                                  ),
                                  ...extraBadges,
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(title, style: FacultyTypography.titleSm()),
                            ],
                          ),
                        ),
                        if (trailing != null) trailing,
                        Icon(open ? Icons.expand_less : Icons.expand_more, color: FacultyColors.secondary, size: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (open)
            Padding(
              padding: EdgeInsets.fromLTRB(accent ? 21 : 16, 0, 16, 16),
              child: content,
            ),
        ],
      ),
    );
  }

  Widget _lessonRow(IconData icon, Color iconColor, String title, String meta, String subtitle, {String status = 'Published'}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          const Icon(Icons.drag_handle, size: 18, color: FacultyColors.outline),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(child: Text(title, style: FacultyTypography.bodySm(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(4)),
                    child: Text(meta, style: FacultyTypography.labelXs(color: FacultyColors.secondary)),
                  ),
                ]),
                Text(subtitle, style: FacultyTypography.labelXs()),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: status == 'Published' ? FacultyColors.tertiaryFixed : FacultyColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(status,
                style: FacultyTypography.labelXs(color: status == 'Published' ? FacultyColors.onTertiaryFixedVariant : FacultyColors.secondary)
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildModule1() {
    return _moduleShell(
      index: 1,
      titleTop: 'MODULE 01',
      badge: 'PUBLISHED',
      badgeBg: FacultyColors.tertiaryFixed,
      badgeFg: FacultyColors.onTertiaryFixedVariant,
      extraBadges: [
        Text('•', style: FacultyTypography.labelXs()),
        Text('8 Lessons • 4 Files attached', style: FacultyTypography.labelXs(color: FacultyColors.secondary).copyWith(fontWeight: FontWeight.w600)),
      ],
      title: 'Foundations of Enterprise Data Processing',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Core concepts covering Python virtual environments, memory-safe tabular streams, and parsing malformed enterprise legacy formats.',
              style: FacultyTypography.bodySm(color: FacultyColors.secondary)),
          const SizedBox(height: 10),
          _lessonRow(Icons.play_circle_outline, FacultyColors.primary, 'Lesson 1.1: Virtual Environments & Poetry Setup', '18 mins',
              'HD Video • Captions auto-generated • Embed code ready'),
          _lessonRow(Icons.menu_book_outlined, FacultyColors.tertiary, 'Lesson 1.2: Reading Heterogeneous Data Sources', 'Guide & Notebook',
              'Reading material • Interactive Jupyter Notebook linked'),
          _lessonRow(Icons.play_circle_outline, FacultyColors.primary, 'Lesson 1.3: Memory Management in Large DataFrames', '24 mins',
              'HD Video • Garbage collector telemetry examples'),
          _lessonRow(Icons.picture_as_pdf_outlined, FacultyColors.error, 'Python_Enterprise_CheatSheet.pdf', '',
              'Document • 1.4 MB • Updated Aug 14'),
        ],
      ),
    );
  }

  Widget _buildModule2() {
    return _moduleShell(
      index: 2,
      accent: true,
      titleTop: 'MODULE 02',
      badge: 'PUBLISHED',
      badgeBg: FacultyColors.tertiaryFixed,
      badgeFg: FacultyColors.onTertiaryFixedVariant,
      extraBadges: [
        Text('•', style: FacultyTypography.labelXs()),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(color: FacultyColors.secondaryContainer, borderRadius: BorderRadius.circular(4)),
          child: Text('ACTIVE MODULE', style: FacultyTypography.labelXs(color: FacultyColors.onSecondaryContainer).copyWith(fontWeight: FontWeight.w700)),
        ),
        Text('•', style: FacultyTypography.labelXs()),
        Text('6 Lessons • 6 Files attached', style: FacultyTypography.labelXs(color: FacultyColors.secondary).copyWith(fontWeight: FontWeight.w600)),
      ],
      title: 'Automation Pipelines with Pandas & Excel',
      trailing: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text('Students here: 38/42', style: FacultyTypography.labelXs()),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hands-on production pipeline construction: parsing nested multi-sheet client financials, data type casting, error quarantining, and automatic CSV output sync.',
              style: FacultyTypography.bodySm(color: FacultyColors.secondary)),
          const SizedBox(height: 10),
          _lessonRow(Icons.play_circle_outline, FacultyColors.primary, 'Lesson 2.1: Multi-Tab Workbook ETL Ingestion', '32 mins',
              'Video Lecture • openpyxl vs pandas read_excel performance'),
          _lessonRow(Icons.play_circle_outline, FacultyColors.primary, 'Lesson 2.2: Schema Sanitization & Date Formatting', '21 mins',
              'Video Lecture • Handling mismatched regional dates & string casting'),
          _lessonRow(Icons.code, FacultyColors.tertiary, 'Lesson 2.3: Automated Quarantine Routing for Corrupted Rows', 'Code Walkthrough',
              'Interactive Python script • PyTest suite included'),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GradeAssignmentScreen())),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: FacultyColors.surfaceContainerHigh.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Icons.drag_handle, size: 18, color: FacultyColors.outline),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: FacultyColors.primary, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.assignment_outlined, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Assignment 02: Building Automated Data Pipelines',
                              style: FacultyTypography.bodySm(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
                          Text('Due Oct 28, 23:59 EST • Pass rate 80% • 34/42 Submitted', style: FacultyTypography.labelXs()),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(8)),
                      child: Text('View Submissions', style: FacultyTypography.labelXs(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.attachment, size: 16, color: FacultyColors.secondary),
              const SizedBox(width: 4),
              Expanded(child: Text('Attached Course Materials & Sandbox Assets (3 files)', style: FacultyTypography.titleSm())),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth >= 640 ? 3 : 1;
            final width = (constraints.maxWidth - (cols - 1) * 12) / cols;
            final materials = [
              _materialCard(Icons.table_chart_outlined, FacultyColors.tertiaryContainer, 'dataset_q3_raw.xlsx', 'Dataset • 3.4 MB', 'Replaced 2 days ago'),
              _materialCard(Icons.terminal, FacultyColors.primaryContainer, 'starter_pipeline.py', 'Source Code • 48 KB', 'Pre-configured template'),
              _materialCard(Icons.description_outlined, FacultyColors.error, 'pipeline_architecture_spec.pdf', 'Reference Doc • 850 KB', 'Verified checksum'),
            ];
            return Wrap(spacing: 12, runSpacing: 12, children: materials.map((m) => SizedBox(width: width, child: m)).toList());
          }),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _notAvailable,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.upload_file_outlined, color: FacultyColors.primary, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text('Drop replacement or new files here', style: FacultyTypography.titleSm()),
                    const SizedBox(height: 2),
                    Text('Supported: .xlsx, .py, .pdf, .zip, .csv, .ipynb (Max 250 MB)', style: FacultyTypography.labelXs(), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(8)),
                      child: Text('Browse Local Files', style: FacultyTypography.labelXs(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _materialCard(IconData icon, Color iconColor, String name, String meta, String footer) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(name, style: FacultyTypography.bodySm(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
          Text(meta, style: FacultyTypography.labelXs()),
          const SizedBox(height: 8),
          Divider(height: 1, color: FacultyColors.surfaceContainerHigh),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: Text(footer, style: FacultyTypography.labelXs(color: FacultyColors.tertiary))),
              const Icon(Icons.download_outlined, size: 16, color: FacultyColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModule3() {
    return _moduleShell(
      index: 3,
      titleTop: 'MODULE 03',
      badge: 'DRAFT',
      badgeBg: FacultyColors.surfaceContainerHigh,
      badgeFg: FacultyColors.secondary,
      extraBadges: [
        Text('•', style: FacultyTypography.labelXs()),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(color: FacultyColors.secondaryContainer, borderRadius: BorderRadius.circular(4)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lock_clock, size: 11, color: FacultyColors.onSecondaryContainer),
            const SizedBox(width: 2),
            Text('Scheduled: Unlock Nov 20', style: FacultyTypography.labelXs(color: FacultyColors.onSecondaryContainer).copyWith(fontWeight: FontWeight.w700)),
          ]),
        ),
        Text('•', style: FacultyTypography.labelXs()),
        Text('4 lessons queued', style: FacultyTypography.labelXs(color: FacultyColors.secondary).copyWith(fontWeight: FontWeight.w600)),
      ],
      title: 'Enterprise Database Connectors & Async Tasks',
      trailing: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => setState(() {
            _module3Published = true;
            _expanded.add(3);
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _module3Published ? FacultyColors.tertiaryFixed : FacultyColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_module3Published ? Icons.check : Icons.publish, size: 14, color: _module3Published ? FacultyColors.onTertiaryFixedVariant : FacultyColors.onSurface),
              const SizedBox(width: 4),
              Text(_module3Published ? 'Published' : 'Publish Now',
                  style: FacultyTypography.labelXs(color: _module3Published ? FacultyColors.onTertiaryFixedVariant : FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Advanced topics in SQLAlchemy 2.0 async sessions, connection pooling under concurrency, and Celery asynchronous task queues.',
              style: FacultyTypography.bodySm(color: FacultyColors.secondary)),
          const SizedBox(height: 10),
          _lessonRow(Icons.play_circle_outline, FacultyColors.secondary, 'Lesson 3.1: Asyncpg & Connection Pool Optimization', '',
              'Video Lecture (Unpublished draft • Processing transcription)', status: 'Draft'),
          _lessonRow(Icons.terminal, FacultyColors.secondary, 'Lesson 3.2: Redis Queue Integration for Batch Pipelines', '',
              'Interactive Sandbox Environment', status: 'Draft'),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: FacultyColors.tertiaryFixed, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.cloud_done_outlined, color: FacultyColors.onTertiaryFixedVariant, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Curriculum Manifest Synchronized', style: FacultyTypography.titleSm()),
                  Text('Last automated cloud snapshot saved at 14:32 EST to AWS S3 (eu-west-1).', style: FacultyTypography.labelXs()),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: _notAvailable,
                style: OutlinedButton.styleFrom(
                  foregroundColor: FacultyColors.onSurface,
                  backgroundColor: FacultyColors.surfaceContainerLow,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Student Preview Mode'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All curriculum changes published.'), backgroundColor: FacultyColors.primary),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: FacultyColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Publish All Changes'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE (<700px) LAYOUT
  // ---------------------------------------------------------------------------

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: const FacultyMobileTopBar(title: 'Curriculum Manager'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _mobileBackRow(),
            const SizedBox(height: 16),
            _mobileHeaderSection(),
            const SizedBox(height: 20),
            _mobileStatsCarousel(),
            const SizedBox(height: 20),
            _mobileSearchField(),
            const SizedBox(height: 10),
            _mobileFilterBar(),
            const SizedBox(height: 20),
            _mobileModule1(),
            const SizedBox(height: 16),
            _mobileModule2(),
            const SizedBox(height: 16),
            _mobileModule3(),
            const SizedBox(height: 20),
            _mobileSyncBanner(),
          ],
        ),
      ),
    );
  }

  Widget _mobileBackRow() {
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
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Back to Course Dashboard',
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
          child: Text(
            'CS-408 / PY-402',
            style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant).copyWith(letterSpacing: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _mobileHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Curriculum & Content', style: FacultyTypography.headlineLg(color: FacultyColors.primary)),
                  const SizedBox(height: 2),
                  Text(
                    'Dr. Sarah Lin • Python for Enterprise Data Analysis',
                    style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.developer_board, size: 24, color: FacultyColors.secondary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _notAvailable,
                icon: const Icon(Icons.add_circle, size: 18),
                label: const Text('Add Module'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FacultyColors.secondary,
                  foregroundColor: FacultyColors.onSecondary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _notAvailable,
                icon: const Icon(Icons.cloud_upload, size: 18),
                label: const Text('Upload Asset'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FacultyColors.surfaceContainerLow,
                  foregroundColor: FacultyColors.secondary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _mobileStatsCarousel() {
    return SizedBox(
      height: 134,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _mobileStatCardShell(
            width: 176,
            header: 'STRUCTURE',
            headerIcon: Icons.view_module,
            headerIconColor: FacultyColors.secondary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('6 Modules', style: FacultyTypography.headlineMd(color: FacultyColors.primary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: FacultyColors.onTertiaryFixedVariant, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('2 Published • 4 Draft',
                          style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _mobileStatCardShell(
            width: 208,
            header: 'SANDBOX RUNTIME',
            headerTrailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: FacultyColors.onTertiaryContainer, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('Active', style: FacultyTypography.labelXs(color: FacultyColors.onTertiaryContainer)),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Python 3.11', style: FacultyTypography.headlineMd(color: FacultyColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('JupyterLab 4.2 Runtime',
                    style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _mobileStatCardShell(
            width: 192,
            header: 'BUCKET STORAGE',
            headerIcon: Icons.storage,
            headerIconColor: FacultyColors.outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('4.8 GB', style: FacultyTypography.headlineMd(color: FacultyColors.primary)),
                    const SizedBox(width: 4),
                    Text('/ 10 GB', style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: LinearProgressIndicator(
                    value: 0.48,
                    minHeight: 6,
                    backgroundColor: FacultyColors.surfaceContainer,
                    valueColor: const AlwaysStoppedAnimation<Color>(FacultyColors.secondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _mobileStatCardShell(
            width: 176,
            header: 'TELEMETRY',
            headerIcon: Icons.trending_up,
            headerIconColor: FacultyColors.onTertiaryFixedVariant,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('94.2%', style: FacultyTypography.headlineMd(color: FacultyColors.primary)),
                const SizedBox(height: 4),
                Text('Cohort Access Rate',
                    style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileStatCardShell({
    required double width,
    required String header,
    IconData? headerIcon,
    Color? headerIconColor,
    Widget? headerTrailing,
    required Widget child,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FacultyColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(header,
                      style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant).copyWith(letterSpacing: 1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                if (headerIcon != null) Icon(headerIcon, size: 18, color: headerIconColor ?? FacultyColors.secondary),
                ?headerTrailing,
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _mobileSearchField() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: FacultyColors.outline),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: FacultyTypography.bodyMd(color: FacultyColors.onSurface),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Filter materials, videos, datasets...',
                hintStyle: FacultyTypography.bodyMd(color: FacultyColors.outline),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileFilterBar() {
    final filters = <(String, String, bool)>[
      ('All', '18', true),
      ('Videos', '9', false),
      ('Documents & PDFs', '4', false),
      ('Starter Code', '3', false),
      ('Datasets', '2', false),
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, i) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (label, count, active) = filters[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? FacultyColors.secondary : FacultyColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: FacultyTypography.labelMd(color: active ? FacultyColors.onSecondary : FacultyColors.onSurfaceVariant)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: active ? FacultyColors.onSecondary.withValues(alpha: 0.2) : FacultyColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(count, style: FacultyTypography.labelXs(color: active ? FacultyColors.onSecondary : FacultyColors.onSurfaceVariant)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _mobileLessonRow({
    required IconData icon,
    required Color iconColor,
    Color? iconBg,
    required String title,
    required String meta,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg ?? FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: FacultyTypography.bodyMd(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(meta, style: FacultyTypography.labelXs(), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
        ],
      ),
    );
  }

  Widget _mobileFileRow({required IconData icon, required Color iconColor, required String name, required String meta}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: FacultyTypography.bodyMd(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(meta, style: FacultyTypography.labelXs(), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _mobileDownloadButton(),
        ],
      ),
    );
  }

  Widget _mobileLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: FacultyColors.tertiaryFixed, borderRadius: BorderRadius.circular(6)),
      child: Text('Live', style: FacultyTypography.labelXs(color: FacultyColors.onTertiaryFixedVariant).copyWith(fontWeight: FontWeight.w700)),
    );
  }

  Widget _mobileDownloadButton() {
    return GestureDetector(
      onTap: _notAvailable,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.download, size: 16, color: FacultyColors.secondary),
      ),
    );
  }

  Widget _mobileTuneButton() {
    return GestureDetector(
      onTap: _notAvailable,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.tune, size: 16, color: FacultyColors.secondary),
      ),
    );
  }

  Widget _mobileModule1() {
    final open = _expanded.contains(1);
    return Container(
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => open ? _expanded.remove(1) : _expanded.add(1)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(top: 2),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
                    child: Text('01', style: FacultyTypography.titleSm(color: FacultyColors.secondary).copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
                              child: Text('PUBLISHED',
                                  style: FacultyTypography.labelXs(color: FacultyColors.onSecondaryFixedVariant)
                                      .copyWith(fontWeight: FontWeight.w700, letterSpacing: 1)),
                            ),
                            Text('8 Lessons • 4 Files', style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Foundation Architecture & Virtual Runtimes',
                            style: FacultyTypography.titleSm(color: FacultyColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
                    child: Icon(open ? Icons.expand_less : Icons.expand_more, size: 20, color: FacultyColors.outline),
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _mobileLessonRow(
                    icon: Icons.play_circle,
                    iconColor: FacultyColors.primary,
                    title: '1.1 Virtual Environments & Poetry Setup',
                    meta: '18m HD Video',
                    trailing: _mobileLiveBadge(),
                  ),
                  _mobileLessonRow(
                    icon: Icons.code,
                    iconColor: FacultyColors.tertiary,
                    title: '1.2 Reading Heterogeneous Data Sources',
                    meta: 'Jupyter Notebook (.ipynb)',
                    trailing: _mobileLiveBadge(),
                  ),
                  _mobileLessonRow(
                    icon: Icons.description,
                    iconColor: FacultyColors.error,
                    title: 'Python_Enterprise_CheatSheet.pdf',
                    meta: '1.4 MB Attached Guide',
                    trailing: _mobileDownloadButton(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _mobileModule2() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: FacultyColors.secondary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 4)],
                ),
                child: Text('02', style: FacultyTypography.titleSm(color: FacultyColors.onSecondary).copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: FacultyColors.secondary,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 4)],
                          ),
                          child: Text('ACTIVE MODULE',
                              style: FacultyTypography.labelXs(color: FacultyColors.onSecondary).copyWith(fontWeight: FontWeight.w700, letterSpacing: 1)),
                        ),
                        Text('6 Lessons • 6 Files', style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Automation Pipelines with Pandas & Excel',
                        style: FacultyTypography.titleSm(color: FacultyColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _notAvailable,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.more_vert, size: 20, color: FacultyColors.outline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                const Icon(Icons.groups, size: 18, color: FacultyColors.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant),
                      children: const [
                        TextSpan(text: 'Cohort Progress: '),
                        TextSpan(text: '38 / 42 Students currently here', style: TextStyle(fontWeight: FontWeight.w700, color: FacultyColors.onSurface)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('90%', style: FacultyTypography.labelMd(color: FacultyColors.secondary).copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text('CURRICULUM UNITS',
                    style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant).copyWith(letterSpacing: 1)),
              ),
              GestureDetector(
                onTap: _notAvailable,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 16, color: FacultyColors.secondary),
                    const SizedBox(width: 2),
                    Text('Add Unit', style: FacultyTypography.labelMd(color: FacultyColors.secondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _mobileLessonRow(
            icon: Icons.play_circle,
            iconColor: FacultyColors.primary,
            title: 'Lesson 2.1: Multi-Tab Workbook ETL Ingestion',
            meta: '32m Video • Published',
            trailing: _mobileTuneButton(),
          ),
          _mobileLessonRow(
            icon: Icons.play_circle,
            iconColor: FacultyColors.primary,
            title: 'Lesson 2.2: Schema Sanitization & Date Formatting',
            meta: '21m Video • Published',
            trailing: _mobileTuneButton(),
          ),
          _mobileLessonRow(
            icon: Icons.terminal,
            iconColor: FacultyColors.onSecondaryContainer,
            iconBg: FacultyColors.secondaryContainer,
            title: 'Lesson 2.3: Automated Quarantine Routing',
            meta: 'Code Walkthrough (.py) • Published',
            trailing: _mobileTuneButton(),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GradeAssignmentScreen())),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assignment, size: 20, color: FacultyColors.secondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Assignment 02: Building Automated Pipelines',
                              style: FacultyTypography.labelMd(color: FacultyColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: FacultyColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4)],
                          ),
                          child: Text('Graded', style: FacultyTypography.labelXs(color: FacultyColors.secondary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant),
                              children: const [
                                TextSpan(text: 'Due Oct 28 • '),
                                TextSpan(text: '34/42 Submitted', style: TextStyle(fontWeight: FontWeight.w700, color: FacultyColors.onSurface)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GradeAssignmentScreen())),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('View Submissions', style: FacultyTypography.labelMd(color: FacultyColors.secondary)),
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_forward, size: 14, color: FacultyColors.secondary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('ATTACHED SANDBOX ASSETS',
              style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant).copyWith(letterSpacing: 1)),
          const SizedBox(height: 10),
          _mobileFileRow(icon: Icons.table_view, iconColor: FacultyColors.tertiaryContainer, name: 'dataset_q3_raw.xlsx', meta: 'Dataset • 3.4 MB'),
          _mobileFileRow(icon: Icons.data_object, iconColor: FacultyColors.primaryContainer, name: 'starter_pipeline.py', meta: 'Source Code • 48 KB'),
          _mobileFileRow(
              icon: Icons.picture_as_pdf, iconColor: FacultyColors.error, name: 'pipeline_architecture_spec.pdf', meta: 'Reference Doc • 850 KB'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _notAvailable,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: FacultyColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4)],
                      ),
                      child: const Icon(Icons.upload_file, size: 22, color: FacultyColors.secondary),
                    ),
                    const SizedBox(height: 8),
                    Text('Tap to upload lesson files or starter datasets',
                        style: FacultyTypography.labelMd(color: FacultyColors.primary), textAlign: TextAlign.center),
                    const SizedBox(height: 2),
                    Text('Supports .xlsx, .py, .ipynb, .pdf (Max 500MB)',
                        style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileModule3() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
                child: Text('03', style: FacultyTypography.titleSm(color: FacultyColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
                          child: Text('DRAFT',
                              style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant)
                                  .copyWith(fontWeight: FontWeight.w700, letterSpacing: 1)),
                        ),
                        Text('Scheduled Nov 20', style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Enterprise Database Connectors & Async Tasks',
                        style: FacultyTypography.titleSm(color: FacultyColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.lock_clock, size: 16, color: FacultyColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text('4 Pending Lessons Configured',
                    style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _module3Published = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _module3Published ? FacultyColors.tertiaryFixed : FacultyColors.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_module3Published ? Icons.check : Icons.publish,
                          size: 16, color: _module3Published ? FacultyColors.onTertiaryFixedVariant : FacultyColors.onSecondary),
                      const SizedBox(width: 4),
                      Text(_module3Published ? 'Published' : 'Publish Now',
                          style: FacultyTypography.labelMd(
                              color: _module3Published ? FacultyColors.onTertiaryFixedVariant : FacultyColors.onSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileSyncBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                const Icon(Icons.cloud_done, size: 18, color: FacultyColors.onTertiaryFixedVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Curriculum Manifest Synchronized to AWS S3',
                      style: FacultyTypography.labelXs(color: FacultyColors.onTertiaryFixedVariant).copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _notAvailable,
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('Student Preview'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FacultyColors.surfaceContainerLow,
                    foregroundColor: FacultyColors.secondary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All curriculum changes published.'), backgroundColor: FacultyColors.primary),
                    );
                  },
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Publish Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FacultyColors.secondary,
                    foregroundColor: FacultyColors.onSecondary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
}
