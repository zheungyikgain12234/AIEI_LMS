import 'package:flutter/material.dart' hide MaterialType;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_faculty_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/course_module.dart';
import 'package:stitch_aiei_lms/domain/models/module_material.dart';
import 'widgets/faculty_scaffold.dart';
import 'widgets/faculty_sidebar.dart';
import 'widgets/faculty_mobile_top_bar.dart';
import 'my_assigned_courses_screen.dart';
import 'grade_assignment_screen.dart';
import 'grading_queue_screen.dart';

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
  final _facultyRepository = SupabaseFacultyRepositoryImpl(Supabase.instance.client);
  bool _isLoading = true;
  List<CourseModule> _modules = [];
  Map<String, List<ModuleMaterial>> _materialsByModule = {};
  List<ModuleMaterial> _allMaterials = [];
  String? _courseCode;

  final Set<int> _expanded = {};
  final Set<String> _locallyPublishedModuleIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Module content is class-scoped, so resolve one class teaching PY-402
    // to load its modules/materials from — see getPrimarySectionIdForCourse.
    final sectionId = await _facultyRepository.getPrimarySectionIdForCourse(DemoIdentity.coursePyId);
    final modules = sectionId == null ? <CourseModule>[] : await _facultyRepository.getCourseModules(sectionId);
    final materials = sectionId == null ? <ModuleMaterial>[] : await _facultyRepository.getCourseMaterials(sectionId);
    final assignedCourses = await _facultyRepository.getAssignedCourses(DemoIdentity.lecturerId);
    if (!mounted) return;

    final byModule = <String, List<ModuleMaterial>>{};
    for (final material in materials) {
      byModule.putIfAbsent(material.moduleId, () => []).add(material);
    }

    String? courseCode;
    for (final course in assignedCourses) {
      if (course.courseId == DemoIdentity.coursePyId) {
        courseCode = course.courseCode;
        break;
      }
    }

    setState(() {
      _modules = modules;
      _materialsByModule = byModule;
      _allMaterials = materials;
      _courseCode = courseCode;
      if (modules.isNotEmpty) _expanded.add(1);
      _isLoading = false;
    });
  }

  // ── Derived counts (real data — no invented numbers) ────────────────────
  int get _publishedModuleCount => _modules.where((m) => m.isPublished).length;
  int get _draftModuleCount => _modules.length - _publishedModuleCount;

  int _lessonCount(CourseModule module) => (_materialsByModule[module.id] ?? const []).length;

  int _fileCount(CourseModule module) =>
      (_materialsByModule[module.id] ?? const []).fold(0, (sum, m) => sum + m.attachedFiles.length);

  List<Map<String, dynamic>> get _allAttachedFiles => [
        for (final m in _allMaterials) ...m.attachedFiles,
      ];

  int get _videoFilterCount => _allMaterials.where((m) => m.type == MaterialType.video).length;
  int get _docFilterCount => _allAttachedFiles.where((f) => f['kind'] == 'doc').length;
  int get _codeFilterCount => _allAttachedFiles.where((f) => f['kind'] == 'code').length;
  int get _datasetFilterCount => _allAttachedFiles.where((f) => f['kind'] == 'dataset').length;
  int get _allFilterCount => _videoFilterCount + _docFilterCount + _codeFilterCount + _datasetFilterCount;

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  String _formatDueDate(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${_formatDate(dt)}, $h:$m';
  }

  IconData _materialIcon(ModuleMaterial m) {
    switch (m.type) {
      case MaterialType.video:
        return Icons.play_circle_outline;
      case MaterialType.lesson:
        return Icons.menu_book_outlined;
      case MaterialType.quiz:
        return Icons.quiz_outlined;
      case MaterialType.assignment:
        return Icons.assignment_outlined;
    }
  }

  Color _materialIconColor(ModuleMaterial m) {
    switch (m.type) {
      case MaterialType.video:
        return FacultyColors.primary;
      case MaterialType.lesson:
        return FacultyColors.tertiary;
      case MaterialType.quiz:
        return FacultyColors.secondary;
      case MaterialType.assignment:
        return FacultyColors.tertiary;
    }
  }

  String _materialMeta(ModuleMaterial m) {
    final duration = m.content['durationMinutes'];
    if (m.type == MaterialType.video && duration != null) return '$duration mins';
    if (m.type == MaterialType.quiz) {
      final len = m.content['quizLength'] ?? (m.content['mcqQuestions'] as List?)?.length;
      if (len != null) return '$len Qs';
    }
    return '';
  }

  String _materialSubtitle(ModuleMaterial m) {
    String base;
    switch (m.type) {
      case MaterialType.video:
        base = 'HD Video';
        break;
      case MaterialType.lesson:
        base = 'Reading material';
        break;
      case MaterialType.quiz:
        final timeMin = m.content['timeAllocatedMinutes'];
        base = timeMin != null ? 'Quiz • $timeMin min time limit' : 'Quiz';
        break;
      case MaterialType.assignment:
        base = 'Assignment';
        break;
    }
    if (m.dueAt != null) base += ' • Due ${_formatDate(m.dueAt!)}';
    return base;
  }

  IconData _fileKindIcon(String kind) {
    switch (kind) {
      case 'dataset':
        return Icons.table_chart_outlined;
      case 'code':
        return Icons.terminal;
      case 'doc':
      default:
        return Icons.description_outlined;
    }
  }

  Color _fileKindColor(String kind) {
    switch (kind) {
      case 'dataset':
        return FacultyColors.tertiaryContainer;
      case 'code':
        return FacultyColors.primaryContainer;
      case 'doc':
      default:
        return FacultyColors.error;
    }
  }

  String _fileKindLabel(String kind) {
    switch (kind) {
      case 'dataset':
        return 'Dataset';
      case 'code':
        return 'Source Code';
      case 'doc':
      default:
        return 'Reference Doc';
    }
  }

  void _handleNav(FacultyNavDestination dest) {
    switch (dest) {
      case FacultyNavDestination.myCourses:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyAssignedCoursesScreen()));
        break;
      case FacultyNavDestination.gradingAndSubmissions:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GradingQueueScreen()));
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
          for (var i = 0; i < _modules.length; i++) ...[
            _moduleCard(_modules[i], i + 1),
            const SizedBox(height: 16),
          ],
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
                      child: Text(_courseCode ?? 'CS-408', style: FacultyTypography.labelXs(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w700)),
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
        _kpi('TOTAL MODULES', '${_modules.length}', '$_publishedModuleCount Published, $_draftModuleCount Draft', Icons.folder_copy_outlined,
            FacultyColors.primary,
            progress: _modules.isEmpty ? 0.0 : _publishedModuleCount / _modules.length),
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
              _filterPill('All ($_allFilterCount)', true),
              _filterPill('Videos ($_videoFilterCount)', false),
              _filterPill('Documents & PDFs ($_docFilterCount)', false),
              _filterPill('Starter Code ($_codeFilterCount)', false),
              _filterPill('Datasets ($_datasetFilterCount)', false),
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
                  if (_expanded.length == _modules.length) {
                    _expanded.clear();
                  } else {
                    _expanded.addAll(List.generate(_modules.length, (i) => i + 1));
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
                        ?trailing,
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

  /// Single reusable module card builder (desktop) — replaces the former
  /// per-index _buildModule1/2/3 methods now that modules come from Supabase.
  Widget _moduleCard(CourseModule module, int displayIndex) {
    final materials = _materialsByModule[module.id] ?? const <ModuleMaterial>[];
    final published = module.isPublished || _locallyPublishedModuleIds.contains(module.id);
    final attachedFiles = [for (final m in materials) ...m.attachedFiles];

    return _moduleShell(
      index: displayIndex,
      titleTop: 'MODULE ${displayIndex.toString().padLeft(2, '0')}',
      badge: published ? 'PUBLISHED' : 'DRAFT',
      badgeBg: published ? FacultyColors.tertiaryFixed : FacultyColors.surfaceContainerHigh,
      badgeFg: published ? FacultyColors.onTertiaryFixedVariant : FacultyColors.secondary,
      extraBadges: [
        Text('•', style: FacultyTypography.labelXs()),
        if (!published && module.unlockAt != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: FacultyColors.secondaryContainer, borderRadius: BorderRadius.circular(4)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lock_clock, size: 11, color: FacultyColors.onSecondaryContainer),
              const SizedBox(width: 2),
              Text('Scheduled: Unlock ${_formatDate(module.unlockAt!)}',
                  style: FacultyTypography.labelXs(color: FacultyColors.onSecondaryContainer).copyWith(fontWeight: FontWeight.w700)),
            ]),
          ),
          Text('•', style: FacultyTypography.labelXs()),
        ],
        Text('${_lessonCount(module)} Lessons • ${_fileCount(module)} Files attached',
            style: FacultyTypography.labelXs(color: FacultyColors.secondary).copyWith(fontWeight: FontWeight.w600)),
      ],
      title: module.name,
      trailing: published
          ? null
          : Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _locallyPublishedModuleIds.add(module.id)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: FacultyColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.publish, size: 14, color: FacultyColors.onSurface),
                    const SizedBox(width: 4),
                    Text('Publish Now', style: FacultyTypography.labelXs(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(module.description, style: FacultyTypography.bodySm(color: FacultyColors.secondary)),
          const SizedBox(height: 10),
          for (final material in materials)
            if (material.id == DemoIdentity.materialAssignment02Id)
              _assignmentRow(material)
            else
              _lessonRow(
                _materialIcon(material),
                _materialIconColor(material),
                material.name,
                _materialMeta(material),
                _materialSubtitle(material),
                status: material.isPublished ? 'Published' : 'Draft',
              ),
          if (attachedFiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.attachment, size: 16, color: FacultyColors.secondary),
                const SizedBox(width: 4),
                Expanded(child: Text('Attached Course Materials & Sandbox Assets (${attachedFiles.length} files)', style: FacultyTypography.titleSm())),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(builder: (context, constraints) {
              final cols = constraints.maxWidth >= 640 ? 3 : 1;
              final width = (constraints.maxWidth - (cols - 1) * 12) / cols;
              final cards = [
                for (final f in attachedFiles)
                  _materialCard(
                    _fileKindIcon(f['kind'] as String? ?? 'doc'),
                    _fileKindColor(f['kind'] as String? ?? 'doc'),
                    f['name'] as String? ?? '',
                    '${_fileKindLabel(f['kind'] as String? ?? 'doc')} • ${f['sizeLabel'] ?? ''}',
                    f['footer'] as String? ?? '',
                  ),
              ];
              return Wrap(spacing: 12, runSpacing: 12, children: cards.map((m) => SizedBox(width: width, child: m)).toList());
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
        ],
      ),
    );
  }

  /// Special-cased row for the Assignment 02 material (the one wired to the
  /// grading flow via GradeAssignmentScreen) — kept from the original design,
  /// now triggered by matching DemoIdentity.materialAssignment02Id.
  Widget _assignmentRow(ModuleMaterial material) {
    return GestureDetector(
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
                    Text(material.name, style: FacultyTypography.bodySm(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
                    Text(material.dueAt != null ? 'Due ${_formatDueDate(material.dueAt!)}' : 'No due date set', style: FacultyTypography.labelXs()),
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
            for (var i = 0; i < _modules.length; i++) ...[
              _mobileModuleCard(_modules[i], i + 1),
              const SizedBox(height: 16),
            ],
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
            _courseCode ?? 'CS-408 / PY-402',
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
                Text('${_modules.length} Modules', style: FacultyTypography.headlineMd(color: FacultyColors.primary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: FacultyColors.onTertiaryFixedVariant, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('$_publishedModuleCount Published • $_draftModuleCount Draft',
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
      ('All', '$_allFilterCount', true),
      ('Videos', '$_videoFilterCount', false),
      ('Documents & PDFs', '$_docFilterCount', false),
      ('Starter Code', '$_codeFilterCount', false),
      ('Datasets', '$_datasetFilterCount', false),
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

  /// Single reusable module card builder (mobile) — replaces the former
  /// per-index _mobileModule1/2/3 methods now that modules come from
  /// Supabase (4 modules instead of a fixed 3).
  Widget _mobileModuleCard(CourseModule module, int displayIndex) {
    final materials = _materialsByModule[module.id] ?? const <ModuleMaterial>[];
    final open = _expanded.contains(displayIndex);
    final published = module.isPublished || _locallyPublishedModuleIds.contains(module.id);
    final attachedFiles = [for (final m in materials) ...m.attachedFiles];

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
            onTap: () => setState(() => open ? _expanded.remove(displayIndex) : _expanded.add(displayIndex)),
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
                    decoration: BoxDecoration(
                        color: published ? FacultyColors.surfaceContainerLow : FacultyColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(displayIndex.toString().padLeft(2, '0'),
                        style: FacultyTypography.titleSm(color: published ? FacultyColors.secondary : FacultyColors.onSurfaceVariant)
                            .copyWith(fontWeight: FontWeight.w700)),
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
                              child: Text(published ? 'PUBLISHED' : 'DRAFT',
                                  style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant)
                                      .copyWith(fontWeight: FontWeight.w700, letterSpacing: 1)),
                            ),
                            Text('${_lessonCount(module)} Lessons • ${_fileCount(module)} Files',
                                style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(module.name,
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
          if (!published)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock, size: 16, color: FacultyColors.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      module.unlockAt != null ? 'Scheduled: Unlock ${_formatDate(module.unlockAt!)}' : 'Scheduled release',
                      style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _locallyPublishedModuleIds.add(module.id)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: FacultyColors.secondary, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.publish, size: 16, color: FacultyColors.onSecondary),
                          const SizedBox(width: 4),
                          Text('Publish Now', style: FacultyTypography.labelMd(color: FacultyColors.onSecondary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  for (final material in materials)
                    if (material.id == DemoIdentity.materialAssignment02Id)
                      _mobileAssignmentRow(material)
                    else
                      _mobileLessonRow(
                        icon: _materialIcon(material),
                        iconColor: _materialIconColor(material),
                        title: material.name,
                        meta: [_materialMeta(material), material.isPublished ? 'Published' : 'Draft']
                            .where((s) => s.isNotEmpty)
                            .join(' • '),
                        trailing: material.isPublished ? _mobileLiveBadge() : null,
                      ),
                  if (attachedFiles.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('ATTACHED SANDBOX ASSETS',
                          style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant).copyWith(letterSpacing: 1)),
                    ),
                    const SizedBox(height: 10),
                    for (final f in attachedFiles)
                      _mobileFileRow(
                        icon: _fileKindIcon(f['kind'] as String? ?? 'doc'),
                        iconColor: _fileKindColor(f['kind'] as String? ?? 'doc'),
                        name: f['name'] as String? ?? '',
                        meta: '${_fileKindLabel(f['kind'] as String? ?? 'doc')} • ${f['sizeLabel'] ?? ''}',
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Mobile equivalent of _assignmentRow — special-cased for the Assignment
  /// 02 material, triggered by DemoIdentity.materialAssignment02Id.
  Widget _mobileAssignmentRow(ModuleMaterial material) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GradeAssignmentScreen())),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
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
                    child: Text(material.name,
                        style: FacultyTypography.labelMd(color: FacultyColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      material.dueAt != null ? 'Due ${_formatDate(material.dueAt!)}' : 'No due date set',
                      style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
