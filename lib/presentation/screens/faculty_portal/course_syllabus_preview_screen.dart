import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturer_syllabus_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/content_block.dart';
import 'package:stitch_aiei_lms/domain/models/course_module.dart';
import 'package:stitch_aiei_lms/domain/models/course_session.dart';
import 'widgets/embedded_image.dart';
import 'widgets/embedded_video_player.dart';
import 'widgets/faculty_mobile_top_bar.dart';
import 'widgets/rich_text_viewer.dart';

/// One module with its published sessions (each carrying its content
/// blocks) already resolved, for [CourseSyllabusPreviewScreen]'s read-only
/// tree — unlike the editor, which loads sessions/blocks lazily on expand.
typedef _PreviewModule = ({CourseModule module, List<({CourseSession session, List<ContentBlock> blocks})> sessions});

// ---------------------------------------------------------------------------
// CourseSyllabusPreviewScreen — "View as Student" from the Syllabus editor.
// Shows the same module → session → content-block tree read-only, with
// unpublished modules/sessions hidden, so the lecturer can check what
// students will actually see.
// ---------------------------------------------------------------------------
class CourseSyllabusPreviewScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const CourseSyllabusPreviewScreen({super.key, required this.courseId, required this.courseTitle});

  @override
  State<CourseSyllabusPreviewScreen> createState() => _CourseSyllabusPreviewScreenState();
}

class _CourseSyllabusPreviewScreenState extends State<CourseSyllabusPreviewScreen> {
  final _repository = SupabaseLecturerSyllabusRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  List<_PreviewModule> _modules = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final modules = (await _repository.getModules(widget.courseId)).where((m) => m.isPublished).toList();
    final preview = <_PreviewModule>[];
    for (final m in modules) {
      final sessions = (await _repository.getSessions(m.id)).where((s) => s.isPublished).toList();
      final withBlocks = <({CourseSession session, List<ContentBlock> blocks})>[];
      for (final s in sessions) {
        final blocks = await _repository.getContentBlocks(s.id);
        withBlocks.add((session: s, blocks: blocks));
      }
      preview.add((module: m, sessions: withBlocks));
    }
    if (!mounted) return;
    setState(() {
      _modules = preview;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: mobile
          ? const FacultyMobileTopBar(title: 'Student View')
          : AppBar(
              backgroundColor: FacultyColors.surfaceContainerLowest,
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: FacultyColors.onSurface,
              title: Text('Student View', style: FacultyTypography.titleSm()),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _banner(),
                        const SizedBox(height: 16),
                        Text(widget.courseTitle, style: FacultyTypography.headlineLg()),
                        const SizedBox(height: 16),
                        if (_modules.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12)),
                            alignment: Alignment.center,
                            child: Text('No published syllabus content yet.', style: FacultyTypography.bodyMd()),
                          )
                        else
                          Column(children: [for (final m in _modules) ...[_moduleCard(m), const SizedBox(height: 12)]]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _banner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: FacultyColors.secondaryContainer, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined, size: 18, color: FacultyColors.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This is what students see — unpublished modules and sessions are hidden.',
              style: FacultyTypography.bodySm(color: FacultyColors.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moduleCard(_PreviewModule m) {
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
          Text(m.module.name, style: FacultyTypography.titleSm()),
          if (m.module.description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(m.module.description, style: FacultyTypography.bodySm()),
          ],
          const SizedBox(height: 12),
          if (m.sessions.isEmpty)
            Text('No sessions yet.', style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant))
          else
            Column(children: [for (final s in m.sessions) ...[_sessionBlock(s), const SizedBox(height: 10)]]),
        ],
      ),
    );
  }

  Widget _sessionBlock(({CourseSession session, List<ContentBlock> blocks}) s) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.session.name, style: FacultyTypography.bodyLg(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600)),
          if (s.session.description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(s.session.description, style: FacultyTypography.bodySm()),
          ],
          if (s.blocks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Column(children: [for (final b in s.blocks) _contentBlock(b)]),
          ],
        ],
      ),
    );
  }

  Widget _contentBlock(ContentBlock b) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_iconFor(b.type), size: 18, color: FacultyColors.primary),
          const SizedBox(width: 10),
          Expanded(child: _preview(b)),
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
    }
  }

  Widget _preview(ContentBlock b) {
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
            EmbeddedVideoPlayer(url: b.url),
          ],
        );
      case ContentBlockType.link:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(b.label?.isNotEmpty == true ? b.label! : 'Link', style: FacultyTypography.bodySm(color: FacultyColors.onSurface)),
            Text(b.url, style: FacultyTypography.bodySm(color: FacultyColors.primary)),
          ],
        );
      case ContentBlockType.file:
        return Text(b.fileName ?? b.url, style: FacultyTypography.bodySm(color: FacultyColors.onSurface));
    }
  }
}
