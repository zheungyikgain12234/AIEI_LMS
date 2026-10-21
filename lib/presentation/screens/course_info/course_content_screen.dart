import 'package:stitch_aiei_lms/core/utils/refresh_on_return.dart';
import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/presentation/widgets/skeleton.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/ui_contrast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/session/app_session.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/core/utils/numbered_labels.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_announcements_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturer_syllabus_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/content_block.dart';
import 'package:stitch_aiei_lms/domain/models/course_section.dart' show SyllabusStatus;
import 'package:stitch_aiei_lms/domain/models/course_announcement.dart';
import 'package:stitch_aiei_lms/domain/models/course_module.dart';
import 'package:stitch_aiei_lms/domain/models/course_session.dart';
import 'package:stitch_aiei_lms/presentation/widgets/physical_class_attendance_card.dart';
import 'package:stitch_aiei_lms/presentation/widgets/physical_assessment_card.dart';
import 'package:stitch_aiei_lms/presentation/screens/assignment_submission/assignment_submission_screen.dart';
import 'package:stitch_aiei_lms/presentation/screens/quiz_answering/quiz_answering_screen.dart';
import 'package:stitch_aiei_lms/presentation/screens/faculty_portal/widgets/announcements_panel.dart';
import 'package:stitch_aiei_lms/presentation/screens/faculty_portal/widgets/clickable_link.dart';
import 'package:stitch_aiei_lms/presentation/screens/faculty_portal/widgets/downloadable_file.dart';
import 'package:stitch_aiei_lms/presentation/screens/faculty_portal/widgets/embedded_image.dart';
import 'package:stitch_aiei_lms/presentation/screens/faculty_portal/widgets/embedded_video_player.dart';
import 'package:stitch_aiei_lms/presentation/screens/faculty_portal/widgets/faculty_mobile_top_bar.dart';
import 'package:stitch_aiei_lms/presentation/screens/faculty_portal/widgets/rich_text_viewer.dart';

/// One module with its published sessions (each carrying its content
/// blocks) already resolved, for [CourseContentScreen]'s read-only tree.
typedef _ContentModule = ({CourseModule module, List<({CourseSession session, List<ContentBlock> blocks})> sessions});

// ---------------------------------------------------------------------------
// CourseContentScreen — the real student-facing course content page,
// reached from "View Course" on the student portal's My Courses screen.
// A left navigation tree (modules, expandable to their sessions) lets the
// student jump around; the center pane is one continuous scroll of every
// module's full content, so "Course Content" reads like a single document.
// Unpublished modules/sessions are hidden, same as the lecturer's "View as
// Student" preview (faculty_portal/course_syllabus_preview_screen.dart).
// ---------------------------------------------------------------------------
class CourseContentScreen extends StatefulWidget {
  final String sectionId;
  final String courseTitle;

  const CourseContentScreen({super.key, required this.sectionId, required this.courseTitle});

  @override
  State<CourseContentScreen> createState() => _CourseContentScreenState();
}

class _CourseContentScreenState extends State<CourseContentScreen> with RefreshOnReturn<CourseContentScreen> {
  @override
  void onReturnedTo() => _load();

  final _client = Supabase.instance.client;
  final _repository = SupabaseLecturerSyllabusRepositoryImpl(Supabase.instance.client);
  final _announcementsRepository = SupabaseAnnouncementsRepositoryImpl(Supabase.instance.client);
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _moduleKeys = {};
  final Map<String, GlobalKey> _sessionKeys = {};
  final Set<String> _expandedModuleIds = {};

  /// The course contents are loading (placeholders show until they arrive).
  bool _isLoading = true;

  /// The announcements load separately from the contents.
  bool _announcementsReady = false;

  /// After the first load a refresh updates in place, with no placeholders.
  bool _contentLoadedOnce = false;
  bool _approved = true;
  String? _loadError;
  /// This student's submission status (`submitted` / `graded`) by assignment block id; absent = not submitted.
  Map<String, String> _submissionStatus = {};
  /// "Module n : Name" / "Lesson n : Name" by id (position among what students see).
  final Map<String, String> _labels = {};
  List<_ContentModule> _modules = [];
  List<CourseAnnouncement> _announcements = const [];
  String? _activeId;
  String? _classCode;
  String? _lecturerName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // The announcements don't depend on the syllabus, so they load alongside
    // it; each side shows as soon as it is ready.
    await Future.wait([_loadAnnouncements(), _loadContent()]);
  }

  Future<void> _loadAnnouncements() async {
    try {
      final announcements = await _announcementsRepository.getAnnouncementsForSection(widget.sectionId);
      if (!mounted) return;
      setState(() => _announcements = announcements);
    } catch (e) {
      debugPrint('CourseContentScreen announcements failed: $e');
    }
    if (mounted) setState(() => _announcementsReady = true);
  }

  Future<void> _loadContent() async {
    setState(() {
      if (!_contentLoadedOnce) _isLoading = true;
      _loadError = null;
    });
    try {
      final sectionRow = await _client
          .from('course_sections')
          .select('section_code, syllabus_status, lecturers(name)')
          .eq('id', widget.sectionId)
          .maybeSingle();
      if (!mounted) return;
      // Students only see a syllabus once an admin has approved it.
      final approved = sectionRow?['syllabus_status'] == SyllabusStatus.approved;
      // The class and lecturer are known already, so show them right away
      // while the (much slower) module content is still loading.
      setState(() {
        _approved = approved;
        _classCode = sectionRow == null ? null : displayCode(sectionRow['section_code'] as String);
        _lecturerName = (sectionRow?['lecturers'] as Map<String, dynamic>?)?['name'] as String?;
      });
      final modules = approved ? (await _repository.getModules(widget.sectionId)).where((m) => m.isPublished).toList() : <CourseModule>[];
      // Fetch every module's sessions, and every session's blocks, in
      // parallel rather than one round trip at a time.
      final content = await Future.wait(modules.map((m) async {
        final sessions = (await _repository.getSessions(m.id)).where((s) => s.isPublished).toList();
        final withBlocks = await Future.wait(sessions.map((s) async => (session: s, blocks: await _repository.getContentBlocks(s.id))));
        return (module: m, sessions: withBlocks);
      }));
      final submitted = await _loadSubmissionStatuses(content);
      if (!mounted) return;
      setState(() {
        _submissionStatus = submitted;
        _modules = content;
        _labels
          ..clear()
          ..addEntries([
            for (var i = 0; i < content.length; i++) ...[
              MapEntry(content[i].module.id, numberedLabel('Module', i + 1, content[i].module.name)),
              for (var j = 0; j < content[i].sessions.length; j++)
                MapEntry(content[i].sessions[j].session.id, numberedLabel('Session', j + 1, content[i].sessions[j].session.name)),
            ],
          ]);
        _expandedModuleIds
          ..clear()
          ..addAll(content.map((m) => m.module.id));
        _isLoading = false;
        _contentLoadedOnce = true;
      });
    } catch (e, st) {
      debugPrint('CourseContentScreen load failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  /// This student's submission status by assignment block id.
  Future<Map<String, String>> _loadSubmissionStatuses(List<_ContentModule> content) async {
    final assignments = {
      for (final m in content)
        for (final s in m.sessions)
          for (final b in s.blocks)
            if (b.type == ContentBlockType.assignment) b.id: b,
    };
    final assignmentIds = assignments.keys.toList();
    if (assignmentIds.isEmpty) return {};
    final rows = await _client
        .from('content_block_submissions')
        .select('content_block_id, status, submitted_at')
        .eq('student_id', DemoIdentity.studentId)
        .inFilter('content_block_id', assignmentIds);
    return {
      for (final r in rows as List)
        r['content_block_id'] as String: _statusOf(r as Map<String, dynamic>, assignments[r['content_block_id']]),
    };
  }

  /// `graded`, `late` (handed in after the due date, not graded yet) or `submitted`.
  String _statusOf(Map<String, dynamic> row, ContentBlock? block) {
    final status = row['status'] as String? ?? 'submitted';
    if (status == 'graded') return status;
    final submittedAt = DateTime.tryParse(row['submitted_at'] as String? ?? '');
    final due = block?.dueDate;
    return submittedAt != null && due != null && submittedAt.isAfter(due) ? 'late' : status;
  }

  /// Re-checks which assignments are submitted after returning from one.
  Future<void> _refreshSubmissions() async {
    try {
      final submitted = await _loadSubmissionStatuses(_modules);
      if (mounted) setState(() => _submissionStatus = submitted);
    } catch (_) {}
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: FacultyColors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Could not load this course.', style: FacultyTypography.bodyMd(), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(_loadError ?? '', style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: const Text('Retry', textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 320), curve: Curves.easeInOut, alignment: 0.04);
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width <= 900;
    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: mobile
          ? FacultyMobileTopBar(title: widget.courseTitle)
          : AppBar(
              backgroundColor: AdminColors.navSurface,
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: FacultyColors.onSurface,
              title: Text(widget.courseTitle, style: FacultyTypography.titleSm()),
            ),
      body: !_isLoading && _loadError != null
          ? _errorState()
          : !_isLoading && _modules.isEmpty
              ? _emptyState()
              : SafeArea(top: false, child: mobile ? _buildMobileBody() : _buildDesktopBody()),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_outlined, size: 48, color: FacultyColors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(_approved ? 'No published course content yet.' : 'This course content is not available yet — it is awaiting approval.', style: FacultyTypography.bodyMd(), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── Desktop: navigation tree sidebar + content + announcements sidebar ──
  Widget _buildDesktopBody() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSidebar(),
        Expanded(child: _buildCenterContent()),
        _buildAnnouncementsSidebar(),
      ],
    );
  }

  Widget _buildAnnouncementsSidebar() {
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: FacultyColors.surfaceContainerLow,
        border: Border(left: BorderSide(color: FacultyColors.surfaceContainerHigh)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
            child: Row(
              children: [
                const Icon(Icons.campaign_outlined, size: 17, color: FacultyColors.primary),
                const SizedBox(width: 8),
                Text(
                  'ANNOUNCEMENTS',
                  style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: FacultyColors.surfaceContainerHigh),
          Expanded(
            child: !_announcementsReady
                ? const _AnnouncementsPlaceholder()
                : _announcements.isEmpty
                    ? const Padding(padding: EdgeInsets.all(20), child: AnnouncementsEmptyState())
                    : ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: _announcements.length,
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AnnouncementCard(announcement: _announcements[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: FacultyColors.surfaceContainerLow,
        border: Border(right: BorderSide(color: FacultyColors.surfaceContainerHigh)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
            child: Row(
              children: [
                const Icon(Icons.menu_book_outlined, size: 17, color: FacultyColors.primary),
                const SizedBox(width: 8),
                Text(
                  'COURSE CONTENTS',
                  style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: FacultyColors.surfaceContainerHigh),
          Expanded(
            child: _isLoading
                ? const _ContentsPlaceholder()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
                    itemCount: _modules.length,
                    itemBuilder: (context, i) => Padding(padding: const EdgeInsets.only(bottom: 4), child: _moduleTreeItem(_modules[i], i)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _moduleTreeItem(_ContentModule m, int index, {VoidCallback? onSelect, StateSetter? rebuild}) {
    final expanded = _expandedModuleIds.contains(m.module.id);
    final active = _activeId == m.module.id;
    final setLocal = rebuild ?? setState;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setLocal(() {
                _activeId = m.module.id;
                _expandedModuleIds.add(m.module.id);
              });
              onSelect?.call();
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(_moduleKeys.putIfAbsent(m.module.id, () => GlobalKey())));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              decoration: BoxDecoration(
                color: active ? FacultyColors.primaryContainer : FacultyColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => setLocal(() {
                      if (expanded) {
                        _expandedModuleIds.remove(m.module.id);
                      } else {
                        _expandedModuleIds.add(m.module.id);
                      }
                    }),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: AnimatedRotation(
                        turns: expanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(Icons.chevron_right, size: 17, color: active ? FacultyColors.onPrimaryContainer : FacultyColors.onSurfaceVariant),
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      _labels[m.module.id] ?? m.module.name,
                      style: FacultyTypography.bodySm(color: active ? FacultyColors.onPrimaryContainer : FacultyColors.onSurface)
                          .copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 150),
          crossFadeState: expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(left: 22, top: 2, bottom: 4),
            child: Column(children: [for (final s in m.sessions) _sessionTreeItem(s, onSelect: onSelect, rebuild: rebuild)]),
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _sessionTreeItem(({CourseSession session, List<ContentBlock> blocks}) s, {VoidCallback? onSelect, StateSetter? rebuild}) {
    final active = _activeId == s.session.id;
    final setLocal = rebuild ?? setState;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setLocal(() => _activeId = s.session.id);
            onSelect?.call();
            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(_sessionKeys.putIfAbsent(s.session.id, () => GlobalKey())));
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: active ? FacultyColors.primaryContainer : FacultyColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(color: active ? FacultyColors.onPrimaryContainer : FacultyColors.outline, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _labels[s.session.id] ?? s.session.name,
                    style: FacultyTypography.labelMd(color: active ? FacultyColors.onPrimaryContainer : FacultyColors.onSurfaceVariant)
                        .copyWith(fontWeight: active ? FontWeight.w600 : FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Mobile: a "Course Contents" bar that opens the tree in a sheet, plus
  // an "Announcements" bar that opens the announcements list in a sheet ───
  Widget _buildMobileBody() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _openContentsSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  decoration: const BoxDecoration(
                    color: FacultyColors.surfaceContainerLow,
                    border: Border(
                      bottom: BorderSide(color: FacultyColors.surfaceContainerHigh),
                      right: BorderSide(color: FacultyColors.surfaceContainerHigh),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.view_list_outlined, size: 18, color: FacultyColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Course Contents', style: FacultyTypography.labelMd(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600)),
                      ),
                      const Icon(Icons.unfold_more, size: 18, color: FacultyColors.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: _openAnnouncementsSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  decoration: const BoxDecoration(
                    color: FacultyColors.surfaceContainerLow,
                    border: Border(bottom: BorderSide(color: FacultyColors.surfaceContainerHigh)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.campaign_outlined, size: 18, color: FacultyColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Announcements', style: FacultyTypography.labelMd(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600)),
                      ),
                      const Icon(Icons.unfold_more, size: 18, color: FacultyColors.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Expanded(child: _buildCenterContent()),
      ],
    );
  }

  void _openAnnouncementsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: FacultyColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  children: [Text('Announcements', style: FacultyTypography.titleSm())],
                ),
              ),
              const Divider(height: 1, color: FacultyColors.surfaceContainer),
              Expanded(
                child: !_announcementsReady
                    ? const _AnnouncementsPlaceholder()
                    : _announcements.isEmpty
                    ? const Padding(padding: EdgeInsets.all(20), child: AnnouncementsEmptyState())
                    : ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: _announcements.length,
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AnnouncementCard(announcement: _announcements[i]),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openContentsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: FacultyColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: FacultyColors.surfaceContainer, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  children: [Text('Course Contents', style: FacultyTypography.titleSm())],
                ),
              ),
              const Divider(height: 1, color: FacultyColors.surfaceContainer),
              Expanded(
                child: _isLoading
                    ? const _ContentsPlaceholder()
                    : StatefulBuilder(
                  builder: (context, sheetSetState) => ListView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
                    itemCount: _modules.length,
                    itemBuilder: (context, i) => _moduleTreeItem(
                      _modules[i],
                      i,
                      onSelect: () => Navigator.of(sheetContext).pop(),
                      rebuild: sheetSetState,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Center content (shared by desktop/mobile): every module, in full ────
  Widget _buildCenterContent() {
    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 56),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.courseTitle, style: FacultyTypography.headlineLg()),
                const SizedBox(height: 8),
                _classAndLecturerBadges(),
                const SizedBox(height: 10),
                if (!_isLoading)
                  Text(
                    '${_modules.length} module${_modules.length == 1 ? '' : 's'}',
                    style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant),
                  ),
                const SizedBox(height: 28),
                if (_isLoading)
                  const _ModulesPlaceholder()
                else
                for (int i = 0; i < _modules.length; i++) ...[
                  _moduleSection(_modules[i], i),
                  if (i != _modules.length - 1) ...[
                    const SizedBox(height: 8),
                    const Divider(color: FacultyColors.surfaceContainer, height: 1),
                    const SizedBox(height: 32),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Class code + lecturer name, shown prominently right under the course
  /// title so a student can tell which class/instructor this content
  /// belongs to at a glance.
  Widget _classAndLecturerBadges() {
    if (_classCode == null && _lecturerName == null) return const SizedBox.shrink();
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        if (_classCode != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: FacultyColors.primaryContainer, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.event_note_outlined, size: 15, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'Class: $_classCode',
                  style: FacultyTypography.labelMd(color: Colors.white).copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        if (_lecturerName != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: FacultyColors.secondaryContainer, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline, size: 15, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 6),
                Text(
                  'Lecturer: $_lecturerName',
                  style: FacultyTypography.labelMd(color: const Color(0xFF1E3A8A)).copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _moduleSection(_ContentModule m, int index) {
    return KeyedSubtree(
      key: _moduleKeys.putIfAbsent(m.module.id, () => GlobalKey()),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: FacultyColors.primary, borderRadius: BorderRadius.circular(10)),
                  child: Text('${index + 1}', style: FacultyTypography.labelMd(color: Colors.white).copyWith(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_labels[m.module.id] ?? m.module.name, style: FacultyTypography.headlineMd()),
                      if (m.module.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(m.module.description, style: FacultyTypography.bodyMd(color: FacultyColors.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (m.sessions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 46),
                child: Text('No sessions in this module yet.', style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant)),
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: 46),
                child: Column(children: [for (final s in m.sessions) ...[_sessionCard(s), const SizedBox(height: 14)]]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sessionCard(({CourseSession session, List<ContentBlock> blocks}) s) {
    return KeyedSubtree(
      key: _sessionKeys.putIfAbsent(s.session.id, () => GlobalKey()),
      child: Container(
        decoration: BoxDecoration(
          color: FacultyColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FacultyColors.surfaceContainer),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: UiContrast.divider))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.play_lesson_outlined, size: 18, color: FacultyColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_labels[s.session.id] ?? s.session.name, style: FacultyTypography.titleSm()),
                        if (s.session.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(s.session.description, style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (s.blocks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(18),
                child: Text('No content yet.', style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant)),
              )
            else
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(children: [for (final b in s.blocks) ...[_contentBlock(b), const SizedBox(height: 8)]]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _contentBlock(ContentBlock b) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(8)),
            child: Icon(_iconFor(b.type), size: 16, color: FacultyColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: _content(b)),
        ],
      ),
    );
  }

  IconData _iconFor(ContentBlockType type) {
    switch (type) {
      case ContentBlockType.text:
        return Icons.notes;
      case ContentBlockType.video:
        return Icons.play_circle_outline;
      case ContentBlockType.image:
        return Icons.image_outlined;
      case ContentBlockType.link:
        return Icons.link;
      case ContentBlockType.file:
        return Icons.attach_file;
      case ContentBlockType.exam:
        return Icons.quiz_outlined;
      case ContentBlockType.assignment:
        return Icons.assignment_outlined;
      case ContentBlockType.physicalClass:
        return Icons.meeting_room_outlined;
      case ContentBlockType.physicalExam:
        return Icons.edit_note;
      case ContentBlockType.physicalAssignment:
        return Icons.draw_outlined;
    }
  }

  Widget _content(ContentBlock b) {
    switch (b.type) {
      case ContentBlockType.text:
        return RichTextViewer(delta: b.delta, plainText: b.body, plainStyle: FacultyTypography.bodySm(color: FacultyColors.onSurface));
      case ContentBlockType.image:
        return ImageFileLink(url: b.url, title: b.caption, style: FacultyTypography.bodySm(color: FacultyColors.onSurface));
      case ContentBlockType.video:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (b.caption != null && b.caption!.isNotEmpty) Text(b.caption!, style: FacultyTypography.bodySm(color: FacultyColors.onSurface)),
            const SizedBox(height: 4),
            EmbeddedVideoPlayer(url: b.url, thumbnailUrl: b.thumbnailUrl),
          ],
        );
      case ContentBlockType.link:
        return ClickableLink(url: b.url, text: b.label, style: FacultyTypography.bodySm(color: FacultyColors.primary));
      case ContentBlockType.file:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final f in b.files)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: DownloadableFile(
                  url: f['url'] as String? ?? '',
                  label: f['name'] as String? ?? f['url'] as String? ?? 'File',
                  style: FacultyTypography.bodySm(color: FacultyColors.onSurface),
                ),
              ),
          ],
        );
      case ContentBlockType.exam:
        return _linkRow(b.title?.isNotEmpty == true ? b.title! : 'Exam', onTap: () => _openExam(b));
      case ContentBlockType.assignment:
        final status = _submissionStatus[b.id];
        final pill = status == 'graded'
            ? _Pill.graded
            : status == 'late'
                ? _Pill.late
                : status != null
                    ? _Pill.submitted
                : (b.dueDate != null && DateTime.now().isAfter(b.dueDate!) ? _Pill.overdue : null);
        return _linkRow(b.title?.isNotEmpty == true ? b.title! : 'Assignment', onTap: () => _openAssignment(b), pill: pill);
      case ContentBlockType.physicalClass:
        return PhysicalClassAttendanceCard(block: b, studentId: DemoIdentity.studentId);
      case ContentBlockType.physicalExam:
        return PhysicalClassAttendanceCard(block: b, studentId: DemoIdentity.studentId, fallbackTitle: 'Physical Exam');
      case ContentBlockType.physicalAssignment:
        return PhysicalAssessmentCard(block: b, studentId: DemoIdentity.studentId);
    }
  }

  Widget _linkRow(String label, {required VoidCallback onTap, _Pill? pill})  {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: FacultyTypography.bodySm(color: FacultyColors.primary).copyWith(decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
            ),
          ),
          if (pill != null)
            Container(
              margin: const EdgeInsets.only(left: 8, right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: pill.background, borderRadius: BorderRadius.circular(999)),
              child: Text(pill.label, style: FacultyTypography.labelXs(color: pill.foreground).copyWith(fontWeight: FontWeight.w700)),
            ),
          const Icon(Icons.chevron_right, size: 16, color: FacultyColors.primary),
        ],
      ),
    );
  }

  void _openExam(ContentBlock b) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizAnsweringScreen(contentBlockId: b.id, sectionId: widget.sectionId, studentId: DemoIdentity.studentId),
      ),
    );
  }

  void _openAssignment(ContentBlock b) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AssignmentSubmissionScreen(contentBlockId: b.id, sectionId: widget.sectionId, studentId: DemoIdentity.studentId),
      ),
    ).then((_) => _refreshSubmissions());
  }
}

/// Status pill beside an assignment in the course content: exactly one of
/// Overdue (past due, nothing submitted — red), Late (submitted after the due date — orange), Submitted, or Graded.
enum _Pill {
  overdue('Overdue', Color(0xFFFFDAD6), Color(0xFF93000A)),
  submitted('Submitted', Color(0xFFD8E6FF), Color(0xFF0B3D91)),
  late('Late', Color(0xFFFFE0B2), Color(0xFF8A4B00)),
  graded('Graded', Color(0xFFC8F0D4), Color(0xFF0F5C33));

  final String label;
  final Color background;
  final Color foreground;
  const _Pill(this.label, this.background, this.foreground);
}

/// Placeholder rows for the "Announcements" list while it loads.
class _AnnouncementsPlaceholder extends StatelessWidget {
  const _AnnouncementsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(14),
      child: Column(children: [
        Skeleton(height: 84, radius: 10),
        SizedBox(height: 10),
        Skeleton(height: 84, radius: 10),
      ]),
    );
  }
}

/// Placeholder rows for the "Course Contents" tree while it loads.
class _ContentsPlaceholder extends StatelessWidget {
  const _ContentsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Column(children: [
        Skeleton(height: 30, radius: 8),
        SizedBox(height: 10),
        Skeleton(height: 30, radius: 8),
        SizedBox(height: 10),
        Skeleton(height: 30, radius: 8),
        SizedBox(height: 10),
        Skeleton(height: 30, radius: 8),
      ]),
    );
  }
}

/// Placeholder for the module cards in the middle of the page while they load.
class _ModulesPlaceholder extends StatelessWidget {
  const _ModulesPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Skeleton(width: 240, height: 24),
      SizedBox(height: 14),
      Skeleton(height: 18),
      SizedBox(height: 10),
      Skeleton(height: 18),
      SizedBox(height: 10),
      Skeleton(width: 360, height: 18),
      SizedBox(height: 30),
      Skeleton(width: 220, height: 24),
      SizedBox(height: 14),
      Skeleton(height: 18),
      SizedBox(height: 10),
      Skeleton(width: 420, height: 18),
    ]);
  }
}
