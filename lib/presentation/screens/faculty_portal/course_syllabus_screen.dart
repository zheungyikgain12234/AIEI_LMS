import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturer_syllabus_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/content_block.dart';
import 'package:stitch_aiei_lms/domain/models/course_module.dart';
import 'package:stitch_aiei_lms/domain/models/course_session.dart';
import 'package:stitch_aiei_lms/domain/models/syllabus_template.dart';
import 'widgets/embedded_image.dart';
import 'widgets/embedded_video_player.dart';
import 'widgets/faculty_scaffold.dart';
import 'widgets/faculty_sidebar.dart';
import 'widgets/faculty_mobile_top_bar.dart';
import 'widgets/rich_text_field.dart';
import 'widgets/rich_text_viewer.dart';
import 'my_assigned_courses_screen.dart';
import 'student_directory_screen.dart';
import 'grade_assignment_screen.dart';
import 'course_syllabus_preview_screen.dart';

// ---------------------------------------------------------------------------
// CourseSyllabusScreen — reached via the "Syllabus" button on My Assigned
// Courses. Lets the lecturer build a Module → Session → Content-block
// timeline for a course: each module holds any number of sessions, and each
// session holds any number of content blocks (text, video, image, link, or
// file), so a single session can mix e.g. some text with an embedded video
// and an attached file rather than being limited to one content type.
// ---------------------------------------------------------------------------
class CourseSyllabusScreen extends StatefulWidget {
  final String sectionId;
  final String courseTitle;

  const CourseSyllabusScreen({super.key, required this.sectionId, required this.courseTitle});

  @override
  State<CourseSyllabusScreen> createState() => _CourseSyllabusScreenState();
}

class _CourseSyllabusScreenState extends State<CourseSyllabusScreen> {
  final _repository = SupabaseLecturerSyllabusRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  List<CourseModule> _modules = [];
  final Map<String, List<CourseSession>> _sessionsByModule = {};
  final Map<String, List<ContentBlock>> _blocksBySession = {};
  final Set<String> _expandedModules = {};
  final Set<String> _expandedSessions = {};
  final Set<String> _loadingModules = {};
  final Set<String> _loadingSessions = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final modules = await _repository.getModules(widget.sectionId);
    if (!mounted) return;
    setState(() {
      _modules = modules;
      _isLoading = false;
    });
  }

  Future<void> _toggleModule(String moduleId) async {
    if (_expandedModules.contains(moduleId)) {
      setState(() => _expandedModules.remove(moduleId));
      return;
    }
    setState(() {
      _expandedModules.add(moduleId);
      _loadingModules.add(moduleId);
    });
    final sessions = await _repository.getSessions(moduleId);
    if (!mounted) return;
    setState(() {
      _sessionsByModule[moduleId] = sessions;
      _loadingModules.remove(moduleId);
    });
  }

  Future<void> _toggleSession(String sessionId) async {
    if (_expandedSessions.contains(sessionId)) {
      setState(() => _expandedSessions.remove(sessionId));
      return;
    }
    setState(() {
      _expandedSessions.add(sessionId);
      _loadingSessions.add(sessionId);
    });
    final blocks = await _repository.getContentBlocks(sessionId);
    if (!mounted) return;
    setState(() {
      _blocksBySession[sessionId] = blocks;
      _loadingSessions.remove(sessionId);
    });
  }

  Future<void> _refreshSessionsFor(String moduleId) async {
    final sessions = await _repository.getSessions(moduleId);
    if (!mounted) return;
    setState(() => _sessionsByModule[moduleId] = sessions);
  }

  Future<void> _refreshBlocksFor(String sessionId) async {
    final blocks = await _repository.getContentBlocks(sessionId);
    if (!mounted) return;
    setState(() => _blocksBySession[sessionId] = blocks);
  }

  // ── Module CRUD ──────────────────────────────────────────────────────

  Future<void> _addModule() async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _NameDescriptionDialog(dialogTitle: 'Add Module', nameLabel: 'Module name'),
    );
    if (result == null) return;
    await _repository.createModule(sectionId: widget.sectionId, name: result.$1, description: result.$2);
    await _load();
  }

  Future<void> _editModule(CourseModule m) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _NameDescriptionDialog(
        dialogTitle: 'Edit Module',
        nameLabel: 'Module name',
        existingName: m.name,
        existingDescription: m.description,
      ),
    );
    if (result == null) return;
    await _repository.updateModule(m.id, name: result.$1, description: result.$2, isPublished: m.isPublished);
    await _load();
  }

  Future<void> _deleteModule(CourseModule m) async {
    final confirmed = await _confirmDelete(
      title: 'Delete module?',
      message: 'This deletes "${m.name}" and every session and content block inside it. This cannot be undone.',
    );
    if (confirmed != true) return;
    await _repository.deleteModule(m.id);
    _expandedModules.remove(m.id);
    _sessionsByModule.remove(m.id);
    await _load();
  }

  Future<void> _reorderModules(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final previous = List<CourseModule>.from(_modules);
    setState(() {
      final m = _modules.removeAt(oldIndex);
      _modules.insert(newIndex, m);
    });
    try {
      await _repository.reorderModules(widget.sectionId, [for (final m in _modules) m.id]);
      _showReorderSaved();
    } catch (e, st) {
      debugPrint('reorderModules failed: $e\n$st');
      if (!mounted) return;
      setState(() => _modules = previous);
      _showReorderError(e);
    }
  }

  void _showReorderSaved() {
    debugPrint('Reorder saved.');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order saved.'), duration: Duration(seconds: 2)));
  }

  void _showReorderError(Object e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Could not save the new order: $e'), duration: const Duration(seconds: 8)));
  }

  // ── Session CRUD ─────────────────────────────────────────────────────

  Future<void> _addSession(String moduleId) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _NameDescriptionDialog(dialogTitle: 'Add Session', nameLabel: 'Session name'),
    );
    if (result == null) return;
    await _repository.createSession(moduleId: moduleId, name: result.$1, description: result.$2);
    await _refreshSessionsFor(moduleId);
  }

  Future<void> _editSession(String moduleId, CourseSession s) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _NameDescriptionDialog(
        dialogTitle: 'Edit Session',
        nameLabel: 'Session name',
        existingName: s.name,
        existingDescription: s.description,
      ),
    );
    if (result == null) return;
    await _repository.updateSession(s.id, name: result.$1, description: result.$2, isPublished: s.isPublished);
    await _refreshSessionsFor(moduleId);
  }

  Future<void> _deleteSession(String moduleId, CourseSession s) async {
    final confirmed = await _confirmDelete(
      title: 'Delete session?',
      message: 'This deletes "${s.name}" and every content block inside it. This cannot be undone.',
    );
    if (confirmed != true) return;
    await _repository.deleteSession(s.id);
    _expandedSessions.remove(s.id);
    _blocksBySession.remove(s.id);
    await _refreshSessionsFor(moduleId);
  }

  Future<void> _reorderSessions(String moduleId, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final previous = List<CourseSession>.from(_sessionsByModule[moduleId] ?? const []);
    final sessions = List<CourseSession>.from(previous);
    final s = sessions.removeAt(oldIndex);
    sessions.insert(newIndex, s);
    setState(() => _sessionsByModule[moduleId] = sessions);
    try {
      await _repository.reorderSessions(moduleId, [for (final s in sessions) s.id]);
      _showReorderSaved();
    } catch (e, st) {
      debugPrint('reorderSessions failed: $e\n$st');
      if (!mounted) return;
      setState(() => _sessionsByModule[moduleId] = previous);
      _showReorderError(e);
    }
  }

  // ── Content block CRUD ───────────────────────────────────────────────

  Future<void> _addContentBlock(String sessionId) async {
    final result = await showDialog<({ContentBlockType type, Map<String, dynamic> content})>(
      context: context,
      builder: (_) => _AddContentBlockDialog(repository: _repository, sessionId: sessionId),
    );
    if (result == null) return;
    await _repository.addContentBlock(sessionId: sessionId, type: result.type, content: result.content);
    await _refreshBlocksFor(sessionId);
  }

  Future<void> _deleteContentBlock(String sessionId, ContentBlock b) async {
    await _repository.deleteContentBlock(b.id);
    await _refreshBlocksFor(sessionId);
  }

  Future<void> _reorderContentBlocks(String sessionId, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final previous = List<ContentBlock>.from(_blocksBySession[sessionId] ?? const []);
    final blocks = List<ContentBlock>.from(previous);
    final b = blocks.removeAt(oldIndex);
    blocks.insert(newIndex, b);
    setState(() => _blocksBySession[sessionId] = blocks);
    try {
      await _repository.reorderContentBlocks(sessionId, [for (final b in blocks) b.id]);
      _showReorderSaved();
    } catch (e, st) {
      debugPrint('reorderContentBlocks failed: $e\n$st');
      if (!mounted) return;
      setState(() => _blocksBySession[sessionId] = previous);
      _showReorderError(e);
    }
  }

  Future<bool?> _confirmDelete({required String title, required String message}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: FacultyColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewAsStudent() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseSyllabusPreviewScreen(sectionId: widget.sectionId, courseTitle: widget.courseTitle),
      ),
    );
  }

  Future<void> _saveAsTemplate() async {
    final name = await showDialog<String>(context: context, builder: (_) => const _SaveAsTemplateDialog());
    if (name == null || name.trim().isEmpty) return;
    await _repository.saveAsTemplate(sectionId: widget.sectionId, name: name.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved as template "${name.trim()}".')));
  }

  Future<void> _copyFromTemplate() async {
    final template = await showDialog<SyllabusTemplate>(
      context: context,
      builder: (_) => _CopyFromTemplateDialog(repository: _repository),
    );
    if (template == null) return;
    await _repository.copyFromTemplate(sectionId: widget.sectionId, templateId: template.id);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied from template "${template.name}".')));
  }

  void _handleNav(FacultyNavDestination dest) {
    switch (dest) {
      case FacultyNavDestination.myCourses:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyAssignedCoursesScreen()));
      case FacultyNavDestination.studentDirectory:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentDirectoryScreen()));
      case FacultyNavDestination.gradingAndSubmissions:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GradeAssignmentScreen()));
    }
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopBar(),
                const SizedBox(height: 20),
                _buildModuleList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: const FacultyMobileTopBar(title: 'Syllabus'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.courseTitle, style: FacultyTypography.headlineMd()),
              const SizedBox(height: 4),
              Text(
                'Build the module and session timeline students will follow through this course.',
                style: FacultyTypography.bodySm(),
              ),
              const SizedBox(height: 16),
              Row(children: [Expanded(child: _viewAsStudentButton()), const SizedBox(width: 10), Expanded(child: _addModuleButton())]),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _saveAsTemplateButton()),
                  const SizedBox(width: 10),
                  Expanded(child: _copyFromTemplateButton()),
                ],
              ),
              const SizedBox(height: 16),
              _buildModuleList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Syllabus', style: FacultyTypography.headlineLg()),
              const SizedBox(height: 2),
              Text(widget.courseTitle, style: FacultyTypography.bodyLg(color: FacultyColors.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(
                'Build the module and session timeline students will follow through this course.',
                style: FacultyTypography.bodySm(),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _viewAsStudentButton(),
            const SizedBox(height: 8),
            _addModuleButton(),
            const SizedBox(height: 8),
            Row(children: [_saveAsTemplateButton(), const SizedBox(width: 8), _copyFromTemplateButton()]),
          ],
        ),
      ],
    );
  }

  Widget _viewAsStudentButton() {
    return OutlinedButton.icon(
      onPressed: _viewAsStudent,
      icon: const Icon(Icons.visibility_outlined, size: 16),
      label: const Text('View as Student'),
      style: OutlinedButton.styleFrom(
        foregroundColor: FacultyColors.primary,
        side: const BorderSide(color: FacultyColors.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: FacultyTypography.labelMd(),
      ),
    );
  }

  Widget _addModuleButton() {
    return ElevatedButton.icon(
      onPressed: _addModule,
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add Module'),
      style: ElevatedButton.styleFrom(
        backgroundColor: FacultyColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _saveAsTemplateButton() {
    return OutlinedButton.icon(
      onPressed: _saveAsTemplate,
      icon: const Icon(Icons.save_outlined, size: 16),
      label: const Text('Save as Template'),
      style: OutlinedButton.styleFrom(
        foregroundColor: FacultyColors.primary,
        side: const BorderSide(color: FacultyColors.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: FacultyTypography.labelMd(),
      ),
    );
  }

  Widget _copyFromTemplateButton() {
    return OutlinedButton.icon(
      onPressed: _copyFromTemplate,
      icon: const Icon(Icons.content_copy_outlined, size: 16),
      label: const Text('Copy from Template'),
      style: OutlinedButton.styleFrom(
        foregroundColor: FacultyColors.primary,
        side: const BorderSide(color: FacultyColors.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: FacultyTypography.labelMd(),
      ),
    );
  }

  Widget _buildModuleList() {
    if (_modules.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Text('No modules yet. Add one to start building the syllabus.', style: FacultyTypography.bodyMd()),
      );
    }
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorder: _reorderModules,
      itemCount: _modules.length,
      itemBuilder: (context, index) {
        final m = _modules[index];
        return Padding(key: ValueKey(m.id), padding: const EdgeInsets.only(bottom: 12), child: _moduleCard(m, index));
      },
    );
  }

  Widget _moduleCard(CourseModule m, int index) {
    final expanded = _expandedModules.contains(m.id);
    final loading = _loadingModules.contains(m.id);
    final sessions = _sessionsByModule[m.id] ?? const <CourseSession>[];
    return Container(
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleModule(m.id),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_indicator, color: FacultyColors.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  Icon(expanded ? Icons.expand_more : Icons.chevron_right, color: FacultyColors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name, style: FacultyTypography.titleSm()),
                        if (m.description.isNotEmpty)
                          Text(m.description, style: FacultyTypography.bodySm(), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _editModule(m),
                    icon: const Icon(Icons.edit_outlined, size: 18, color: FacultyColors.onSurfaceVariant),
                    tooltip: 'Edit module',
                  ),
                  IconButton(
                    onPressed: () => _deleteModule(m),
                    icon: const Icon(Icons.delete_outline, size: 18, color: FacultyColors.error),
                    tooltip: 'Delete module',
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1, color: FacultyColors.surfaceContainer),
                  const SizedBox(height: 12),
                  if (loading)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                  else ...[
                    if (sessions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('No sessions yet.', style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant)),
                      )
                    else
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        onReorder: (oldIndex, newIndex) => _reorderSessions(m.id, oldIndex, newIndex),
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final s = sessions[index];
                          return Padding(
                            key: ValueKey(s.id),
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _sessionCard(m.id, s, index),
                          );
                        },
                      ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => _addSession(m.id),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Session'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: FacultyColors.primary,
                          side: const BorderSide(color: FacultyColors.outlineVariant),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: FacultyTypography.labelMd(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sessionCard(String moduleId, CourseSession s, int index) {
    final expanded = _expandedSessions.contains(s.id);
    final loading = _loadingSessions.contains(s.id);
    final blocks = _blocksBySession[s.id] ?? const <ContentBlock>[];
    return Container(
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleSession(s.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_indicator, size: 18, color: FacultyColors.onSurfaceVariant),
                  ),
                  const SizedBox(width: 6),
                  Icon(expanded ? Icons.expand_more : Icons.chevron_right, size: 18, color: FacultyColors.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: FacultyTypography.bodyLg(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600)),
                        if (s.description.isNotEmpty)
                          Text(s.description, style: FacultyTypography.bodySm(), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _editSession(moduleId, s),
                    icon: const Icon(Icons.edit_outlined, size: 16, color: FacultyColors.onSurfaceVariant),
                    tooltip: 'Edit session',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: () => _deleteSession(moduleId, s),
                    icon: const Icon(Icons.delete_outline, size: 16, color: FacultyColors.error),
                    tooltip: 'Delete session',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1, color: FacultyColors.surfaceContainerHigh),
                  const SizedBox(height: 8),
                  if (loading)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                  else ...[
                    if (blocks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text('No content yet.', style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant)),
                      )
                    else
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        onReorder: (oldIndex, newIndex) => _reorderContentBlocks(s.id, oldIndex, newIndex),
                        itemCount: blocks.length,
                        itemBuilder: (context, index) =>
                            KeyedSubtree(key: ValueKey(blocks[index].id), child: _contentBlockRow(s.id, blocks[index], index)),
                      ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _addContentBlock(s.id),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Content'),
                        style: TextButton.styleFrom(foregroundColor: FacultyColors.primary, textStyle: FacultyTypography.labelMd()),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _contentBlockRow(String sessionId, ContentBlock b, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_indicator, size: 18, color: FacultyColors.onSurfaceVariant),
          ),
          const SizedBox(width: 8),
          Icon(_iconFor(b.type), size: 18, color: FacultyColors.primary),
          const SizedBox(width: 10),
          Expanded(child: _contentPreview(b)),
          IconButton(
            onPressed: () => _deleteContentBlock(sessionId, b),
            icon: const Icon(Icons.close, size: 16, color: FacultyColors.onSurfaceVariant),
            tooltip: 'Remove',
            visualDensity: VisualDensity.compact,
          ),
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

  Widget _contentPreview(ContentBlock b) {
    switch (b.type) {
      case ContentBlockType.text:
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 90),
          child: ClipRect(
            child: RichTextViewer(delta: b.delta, plainText: b.body, plainStyle: FacultyTypography.bodySm(color: FacultyColors.onSurface)),
          ),
        );
      case ContentBlockType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (b.caption != null && b.caption!.isNotEmpty) Text(b.caption!, style: FacultyTypography.bodySm(color: FacultyColors.onSurface)),
            const SizedBox(height: 4),
            EmbeddedImage(url: b.url, height: 80),
          ],
        );
      case ContentBlockType.video:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (b.caption != null && b.caption!.isNotEmpty) Text(b.caption!, style: FacultyTypography.bodySm(color: FacultyColors.onSurface)),
            const SizedBox(height: 4),
            ConstrainedBox(constraints: const BoxConstraints(maxWidth: 280), child: EmbeddedVideoPlayer(url: b.url)),
          ],
        );
      case ContentBlockType.link:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(b.label?.isNotEmpty == true ? b.label! : 'Link', style: FacultyTypography.bodySm(color: FacultyColors.onSurface)),
            Text(b.url, style: FacultyTypography.labelXs(color: FacultyColors.primary), overflow: TextOverflow.ellipsis),
          ],
        );
      case ContentBlockType.file:
        return Text(b.fileName ?? b.url, style: FacultyTypography.bodySm(color: FacultyColors.onSurface), overflow: TextOverflow.ellipsis);
    }
  }
}

// ---------------------------------------------------------------------------
// _NameDescriptionDialog — shared Add/Edit form for both Modules and
// Sessions, which only differ by a name + an optional description.
// ---------------------------------------------------------------------------
class _NameDescriptionDialog extends StatefulWidget {
  final String dialogTitle;
  final String nameLabel;
  final String? existingName;
  final String? existingDescription;

  const _NameDescriptionDialog({
    required this.dialogTitle,
    required this.nameLabel,
    this.existingName,
    this.existingDescription,
  });

  @override
  State<_NameDescriptionDialog> createState() => _NameDescriptionDialogState();
}

class _NameDescriptionDialogState extends State<_NameDescriptionDialog> {
  late final _nameController = TextEditingController(text: widget.existingName ?? '');
  late final _descController = TextEditingController(text: widget.existingDescription ?? '');

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.dialogTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(labelText: widget.nameLabel),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _nameController.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop((_nameController.text.trim(), _descController.text.trim())),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _AddContentBlockDialog — picks a content type, then shows the fields (and
// optional real-file upload via Supabase Storage) that type needs.
// ---------------------------------------------------------------------------
class _AddContentBlockDialog extends StatefulWidget {
  final SupabaseLecturerSyllabusRepositoryImpl repository;
  final String sessionId;

  const _AddContentBlockDialog({required this.repository, required this.sessionId});

  @override
  State<_AddContentBlockDialog> createState() => _AddContentBlockDialogState();
}

class _AddContentBlockDialogState extends State<_AddContentBlockDialog> {
  ContentBlockType _type = ContentBlockType.text;
  final _richTextController = createRichTextController();
  final _urlController = TextEditingController();
  final _captionController = TextEditingController();
  final _labelController = TextEditingController();
  String? _uploadedFileName;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _richTextController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _richTextController.dispose();
    _urlController.dispose();
    _captionController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  bool get _canSave {
    switch (_type) {
      case ContentBlockType.text:
        return !isRichTextEmpty(_richTextController);
      case ContentBlockType.video:
      case ContentBlockType.image:
      case ContentBlockType.link:
      case ContentBlockType.file:
        return _urlController.text.trim().isNotEmpty;
    }
  }

  Future<void> _pickAndUpload({required FileType fileType}) async {
    final result = await FilePicker.platform.pickFiles(type: fileType, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final url = await widget.repository.uploadContentFile(sessionId: widget.sessionId, fileName: file.name, bytes: bytes);
      if (!mounted) return;
      setState(() {
        _urlController.text = url;
        _uploadedFileName = file.name;
        _uploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Upload failed: $e';
        _uploading = false;
      });
    }
  }

  Map<String, dynamic> _buildContent() {
    switch (_type) {
      case ContentBlockType.text:
        return {'delta': deltaJsonOf(_richTextController), 'body': plainTextOf(_richTextController)};
      case ContentBlockType.video:
      case ContentBlockType.image:
        return {
          'url': _urlController.text.trim(),
          if (_captionController.text.trim().isNotEmpty) 'caption': _captionController.text.trim(),
        };
      case ContentBlockType.link:
        return {
          'url': _urlController.text.trim(),
          if (_labelController.text.trim().isNotEmpty) 'label': _labelController.text.trim(),
        };
      case ContentBlockType.file:
        return {
          'url': _urlController.text.trim(),
          if (_uploadedFileName != null) 'name': _uploadedFileName,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Content'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<ContentBlockType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Content type'),
                items: [for (final t in ContentBlockType.values) DropdownMenuItem(value: t, child: Text(_labelFor(t)))],
                onChanged: (t) => setState(() {
                  if (t != null) _type = t;
                  _error = null;
                }),
              ),
              const SizedBox(height: 14),
              ..._fieldsFor(_type),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: FacultyColors.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: !_canSave || _uploading ? null : () => Navigator.of(context).pop((type: _type, content: _buildContent())),
          child: const Text('Add'),
        ),
      ],
    );
  }

  String _labelFor(ContentBlockType t) {
    switch (t) {
      case ContentBlockType.text:
        return 'Text';
      case ContentBlockType.video:
        return 'Video';
      case ContentBlockType.image:
        return 'Image';
      case ContentBlockType.link:
        return 'Link';
      case ContentBlockType.file:
        return 'File';
    }
  }

  List<Widget> _fieldsFor(ContentBlockType type) {
    switch (type) {
      case ContentBlockType.text:
        return [RichTextField(controller: _richTextController)];
      case ContentBlockType.video:
        return [
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Video URL',
              helperText: 'A YouTube link, or a direct video file link (.mp4/.webm) for an unskippable player',
              helperMaxLines: 2,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          _orDivider(),
          const SizedBox(height: 8),
          _uploadButton(fileType: FileType.video, label: 'Upload a video file'),
          const SizedBox(height: 12),
          TextField(controller: _captionController, decoration: const InputDecoration(labelText: 'Caption (optional)')),
          if (_urlController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            EmbeddedVideoPlayer(url: _urlController.text.trim()),
          ],
        ];
      case ContentBlockType.image:
        return [
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(labelText: 'Image URL'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          _orDivider(),
          const SizedBox(height: 8),
          _uploadButton(fileType: FileType.image, label: 'Upload an image'),
          const SizedBox(height: 12),
          TextField(controller: _captionController, decoration: const InputDecoration(labelText: 'Caption (optional)')),
          if (_urlController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            EmbeddedImage(url: _urlController.text.trim(), height: 140, width: double.infinity),
          ],
        ];
      case ContentBlockType.link:
        return [
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(labelText: 'URL'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(controller: _labelController, decoration: const InputDecoration(labelText: 'Link label (optional)')),
        ];
      case ContentBlockType.file:
        return [
          _uploadButton(fileType: FileType.any, label: 'Upload a file'),
          if (_uploadedFileName != null) ...[
            const SizedBox(height: 8),
            Text('Selected: $_uploadedFileName', style: const TextStyle(fontSize: 13)),
          ],
        ];
    }
  }

  Widget _orDivider() => const Row(children: [
        Expanded(child: Divider()),
        Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('or', style: TextStyle(fontSize: 12, color: FacultyColors.onSurfaceVariant))),
        Expanded(child: Divider()),
      ]);

  Widget _uploadButton({required FileType fileType, required String label}) {
    return OutlinedButton.icon(
      onPressed: _uploading ? null : () => _pickAndUpload(fileType: fileType),
      icon: _uploading
          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.upload_file, size: 16),
      label: Text(label),
    );
  }
}

// ---------------------------------------------------------------------------
// _SaveAsTemplateDialog — names the template that "Save as Template" will
// deep-copy the class's current module → session → content-block tree into.
// ---------------------------------------------------------------------------
class _SaveAsTemplateDialog extends StatefulWidget {
  const _SaveAsTemplateDialog();

  @override
  State<_SaveAsTemplateDialog> createState() => _SaveAsTemplateDialogState();
}

class _SaveAsTemplateDialogState extends State<_SaveAsTemplateDialog> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save as Template'),
      content: SizedBox(
        width: 380,
        child: TextField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Template name'),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (_nameController.text.trim().isNotEmpty) Navigator.of(context).pop(_nameController.text.trim());
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _nameController.text.trim().isEmpty ? null : () => Navigator.of(context).pop(_nameController.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _CopyFromTemplateDialog — lists saved templates for "Copy from Template"
// to pick one to deep-copy into the current class.
// ---------------------------------------------------------------------------
class _CopyFromTemplateDialog extends StatefulWidget {
  final SupabaseLecturerSyllabusRepositoryImpl repository;

  const _CopyFromTemplateDialog({required this.repository});

  @override
  State<_CopyFromTemplateDialog> createState() => _CopyFromTemplateDialogState();
}

class _CopyFromTemplateDialogState extends State<_CopyFromTemplateDialog> {
  bool _isLoading = true;
  List<SyllabusTemplate> _templates = [];
  SyllabusTemplate? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final templates = await widget.repository.getTemplates();
    if (!mounted) return;
    setState(() {
      _templates = templates;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Copy from Template'),
      content: SizedBox(
        width: 420,
        height: 360,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _templates.isEmpty
                ? Center(
                    child: Text('No saved templates yet.', style: FacultyTypography.bodyMd(color: FacultyColors.onSurfaceVariant)),
                  )
                : ListView.separated(
                    itemCount: _templates.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final t = _templates[index];
                      final selected = _selected?.id == t.id;
                      return Material(
                        color: selected ? FacultyColors.secondaryContainer : FacultyColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => setState(() => _selected = t),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Icon(
                                  selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  size: 18,
                                  color: selected ? FacultyColors.primary : FacultyColors.onSurfaceVariant,
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(t.name, style: FacultyTypography.bodyMd())),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _selected == null ? null : () => Navigator.of(context).pop(_selected),
          child: const Text('Copy'),
        ),
      ],
    );
  }
}
