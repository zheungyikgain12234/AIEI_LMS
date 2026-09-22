import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_announcements_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturer_syllabus_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/content_block.dart';
import 'package:stitch_aiei_lms/domain/models/course_announcement.dart';
import 'package:stitch_aiei_lms/domain/models/course_module.dart';
import 'package:stitch_aiei_lms/domain/models/course_session.dart';
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

class _CourseContentScreenState extends State<CourseContentScreen> {
  final _repository = SupabaseLecturerSyllabusRepositoryImpl(Supabase.instance.client);
  final _announcementsRepository = SupabaseAnnouncementsRepositoryImpl(Supabase.instance.client);
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _moduleKeys = {};
  final Map<String, GlobalKey> _sessionKeys = {};
  final Set<String> _expandedModuleIds = {};

  bool _isLoading = true;
  List<_ContentModule> _modules = [];
  List<CourseAnnouncement> _announcements = const [];
  String? _activeId;

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
    setState(() => _isLoading = true);
    final modules = (await _repository.getModules(widget.sectionId)).where((m) => m.isPublished).toList();
    final content = <_ContentModule>[];
    for (final m in modules) {
      final sessions = (await _repository.getSessions(m.id)).where((s) => s.isPublished).toList();
      final withBlocks = <({CourseSession session, List<ContentBlock> blocks})>[];
      for (final s in sessions) {
        final blocks = await _repository.getContentBlocks(s.id);
        withBlocks.add((session: s, blocks: blocks));
      }
      content.add((module: m, sessions: withBlocks));
    }
    final announcements = await _announcementsRepository.getAnnouncementsForSection(widget.sectionId);
    if (!mounted) return;
    setState(() {
      _modules = content;
      _announcements = announcements;
      _expandedModuleIds
        ..clear()
        ..addAll(content.map((m) => m.module.id));
      _isLoading = false;
    });
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 320), curve: Curves.easeInOut, alignment: 0.04);
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: mobile
          ? FacultyMobileTopBar(title: widget.courseTitle)
          : AppBar(
              backgroundColor: FacultyColors.surfaceContainerLowest,
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: FacultyColors.onSurface,
              title: Text(widget.courseTitle, style: FacultyTypography.titleSm()),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _modules.isEmpty
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
            Text('No published course content yet.', style: FacultyTypography.bodyMd()),
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
            child: _announcements.isEmpty
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
            child: ListView.builder(
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
                      m.module.name,
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
                    s.session.name,
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
                child: _announcements.isEmpty
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
                child: StatefulBuilder(
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
                const SizedBox(height: 4),
                Text(
                  '${_modules.length} module${_modules.length == 1 ? '' : 's'}',
                  style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant),
                ),
                const SizedBox(height: 28),
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
                      Text(m.module.name, style: FacultyTypography.headlineMd()),
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
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: FacultyColors.surfaceContainer))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.play_lesson_outlined, size: 18, color: FacultyColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.session.name, style: FacultyTypography.titleSm()),
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
    }
  }

  Widget _content(ContentBlock b) {
    switch (b.type) {
      case ContentBlockType.text:
        return RichTextViewer(delta: b.delta, plainText: b.body, plainStyle: FacultyTypography.bodySm(color: FacultyColors.onSurface));
      case ContentBlockType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (b.caption != null && b.caption!.isNotEmpty) Text(b.caption!, style: FacultyTypography.bodySm(color: FacultyColors.onSurface)),
            const SizedBox(height: 4),
            EmbeddedImage(url: b.url, height: 140, width: double.infinity),
          ],
        );
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(b.label?.isNotEmpty == true ? b.label! : 'Link', style: FacultyTypography.bodySm(color: FacultyColors.onSurface)),
            ClickableLink(url: b.url, style: FacultyTypography.bodySm(color: FacultyColors.primary)),
          ],
        );
      case ContentBlockType.file:
        return DownloadableFile(url: b.url, label: b.fileName ?? b.url, style: FacultyTypography.bodySm(color: FacultyColors.onSurface));
      case ContentBlockType.exam:
        return _linkRow(b.title?.isNotEmpty == true ? b.title! : 'Exam', onTap: () => _openExam(b));
      case ContentBlockType.assignment:
        return _linkRow(b.title?.isNotEmpty == true ? b.title! : 'Assignment', onTap: () => _openAssignment(b));
    }
  }

  Widget _linkRow(String label, {required VoidCallback onTap}) {
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
    );
  }
}
