import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturers_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/course_section.dart';
import 'package:stitch_aiei_lms/presentation/screens/faculty_portal/course_syllabus_screen.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_mobile_top_bar.dart';
import 'widgets/admin_nav.dart';

// ---------------------------------------------------------------------------
// ManageSyllabiScreen — master data page listing every class's syllabus with
// its approval status. Opening one shows the full syllabus editor in admin
// mode (edit anything, any time) with an Approve button; students only see a
// syllabus once it is approved.
// ---------------------------------------------------------------------------
class ManageSyllabiScreen extends StatefulWidget {
  const ManageSyllabiScreen({super.key});

  @override
  State<ManageSyllabiScreen> createState() => _ManageSyllabiScreenState();
}

class _ManageSyllabiScreenState extends State<ManageSyllabiScreen> {
  final _repository = SupabaseLecturersRepositoryImpl(Supabase.instance.client);
  bool _isLoading = true;
  List<CourseSection> _sections = [];
  String? _statusFilter;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _query = _searchController.text.trim().toLowerCase()));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final sections = await _repository.getAllSections();
    if (!mounted) return;
    setState(() {
      _sections = sections;
      _isLoading = false;
    });
  }

  static const _filters = [
    (null, 'All'),
    (SyllabusStatus.submitted, 'Pending approval'),
    (SyllabusStatus.draft, 'Draft'),
    (SyllabusStatus.approved, 'Approved'),
  ];

  int _rank(String status) => switch (status) {
        SyllabusStatus.submitted => 0,
        SyllabusStatus.draft => 1,
        _ => 2,
      };

  List<CourseSection> get _filtered {
    final rows = _sections.where((s) {
      if (_statusFilter != null && s.syllabusStatus != _statusFilter) return false;
      if (_query.isEmpty) return true;
      return [s.courseCode, s.courseTitle, s.sectionCode, s.cohort ?? '', s.lecturerName ?? '']
          .any((v) => v.toLowerCase().contains(_query));
    }).toList();
    rows.sort((a, b) {
      final byStatus = _rank(a.syllabusStatus).compareTo(_rank(b.syllabusStatus));
      return byStatus != 0 ? byStatus : a.sectionCode.toLowerCase().compareTo(b.sectionCode.toLowerCase());
    });
    return rows;
  }

  void _handleNav(AdminNavDestination dest) => handleAdminNav(context, AdminNavDestination.manageSyllabi, dest);

  Future<void> _open(CourseSection s) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CourseSyllabusScreen(sectionId: s.id, courseTitle: s.courseTitle, isAdmin: true)),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (MediaQuery.of(context).size.width < 700) {
      return Scaffold(
        backgroundColor: AdminColors.background,
        appBar: const AdminMobileTopBar.detail(title: 'Manage Syllabi'),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_buildHeader(), const SizedBox(height: 16), _buildListCard()]),
          ),
        ),
      );
    }
    return AdminScaffold(
      selected: AdminNavDestination.manageSyllabi,
      onDestinationSelected: _handleNav,
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildHeader(), const SizedBox(height: 20), _buildListCard()]),
    );
  }

  Widget _buildHeader() {
    final pending = _sections.where((s) => s.syllabusStatus == SyllabusStatus.submitted).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Manage Syllabi', style: AdminTypography.headlineLg()),
        const SizedBox(height: 2),
        Text(
          'Every class\'s syllabus. Open one to edit it in full and approve it — students only see a syllabus once it is approved.'
          '${pending > 0 ? ' $pending awaiting approval.' : ''}',
          style: AdminTypography.bodyMd(),
        ),
      ],
    );
  }

  Widget _buildListCard() {
    final rows = _filtered;
    return Container(
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  style: AdminTypography.bodySm(color: AdminColors.onSurface),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: AdminColors.surfaceContainerLow,
                    hintText: 'Search by course, class, cohort or lecturer...',
                    hintStyle: AdminTypography.bodySm(color: AdminColors.outline),
                    prefixIcon: const Icon(Icons.search, size: 18, color: AdminColors.onSurfaceVariant),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final f in _filters)
                      ChoiceChip(
                        label: Text(f.$2),
                        selected: _statusFilter == f.$1,
                        onSelected: (_) => setState(() => _statusFilter = f.$1),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (rows.isEmpty)
            Padding(padding: const EdgeInsets.all(32), child: Text('No syllabi found.', style: AdminTypography.bodyMd()))
          else
            Column(children: [for (final s in rows) _row(s)]),
        ],
      ),
    );
  }

  Widget _row(CourseSection s) {
    return InkWell(
      onTap: () => _open(s),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AdminColors.surfaceContainer))),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${s.courseCode} • ${s.sectionCode} — ${s.courseTitle}', style: AdminTypography.bodyMd(color: AdminColors.onSurface).copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    [if (s.cohort != null) s.cohort!, if (s.lecturerName != null) s.lecturerName!].join(' • '),
                    style: AdminTypography.bodySm(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _statusChip(s.syllabusStatus),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AdminColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final (label, bg, fg) = switch (status) {
      SyllabusStatus.approved => ('Approved', const Color(0xFFE3F4E5), const Color(0xFF2E7D32)),
      SyllabusStatus.submitted => ('Pending approval', const Color(0xFFFFF3CD), const Color(0xFF8A6D00)),
      _ => ('Draft', AdminColors.surfaceContainerLow, AdminColors.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9999)),
      child: Text(label, style: AdminTypography.labelSm(color: fg).copyWith(fontWeight: FontWeight.w700)),
    );
  }
}
