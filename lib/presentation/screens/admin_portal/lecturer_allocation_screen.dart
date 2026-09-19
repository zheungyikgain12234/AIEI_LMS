import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturers_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/lecturer.dart';
import 'package:stitch_aiei_lms/domain/models/course_section.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_mobile_top_bar.dart';
import 'widgets/admin_nav.dart';

// ---------------------------------------------------------------------------
// LecturerAllocationScreen – Stitch "Lecturer Course Allocation" faithful
// Flutter conversion. Backed by Supabase via SupabaseLecturersRepositoryImpl.
// ---------------------------------------------------------------------------
class LecturerAllocationScreen extends StatefulWidget {
  const LecturerAllocationScreen({super.key});

  @override
  State<LecturerAllocationScreen> createState() => _LecturerAllocationScreenState();
}

class _LecturerAllocationScreenState extends State<LecturerAllocationScreen> {
  final _repository = SupabaseLecturersRepositoryImpl(Supabase.instance.client);
  bool _isLoading = true;
  List<Lecturer> _lecturers = [];
  List<CourseSection> _sections = [];
  final _searchController = TextEditingController();
  String _query = '';

  final Set<String> _assigned = {};

  List<Lecturer> get _filteredLecturers {
    if (_query.isEmpty) return _lecturers;
    return _lecturers.where((l) =>
        l.name.toLowerCase().contains(_query) ||
        _sectionsFor(l).any((s) => s.courseCode.toLowerCase().contains(_query))).toList();
  }

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
    final lecturers = await _repository.getLecturers();
    final sections = await _repository.getAllSections();
    if (!mounted) return;
    setState(() {
      _lecturers = lecturers;
      _sections = sections;
      _isLoading = false;
    });
  }

  // -------------------------------------------------------------------
  // Derived data helpers
  // -------------------------------------------------------------------

  List<CourseSection> get _unassignedSections => _sections.where((s) => s.lecturerId == null).toList();

  int get _totalSections => _sections.length;

  int get _assignedSectionsCount => _sections.where((s) => s.lecturerId != null).length;

  int get _unassignedSectionsCount => _totalSections - _assignedSectionsCount;

  int get _departmentCount => _lecturers.map((l) => l.department).toSet().length;

  double get _avgCreditsUsed =>
      _lecturers.isEmpty ? 0 : _lecturers.map((l) => l.creditsUsed).reduce((a, b) => a + b) / _lecturers.length;

  double get _avgCreditsMax =>
      _lecturers.isEmpty ? 0 : _lecturers.map((l) => l.creditsMax).reduce((a, b) => a + b) / _lecturers.length;

  List<CourseSection> _sectionsFor(Lecturer l) => _sections.where((s) => s.lecturerId == l.id).toList();

  // >=100 -> Capacity Reached, >=80 -> Optimal, else -> Bandwidth Available.
  String _capacityTag(int pct) {
    if (pct >= 100) return 'Capacity Reached';
    if (pct >= 80) return 'Optimal';
    return 'Bandwidth Available';
  }

  /// Department -> average capacityPercent of its lecturers (rounded).
  Map<String, int> get _departmentLoadBalance {
    final byDept = <String, List<int>>{};
    for (final l in _lecturers) {
      byDept.putIfAbsent(l.department, () => []).add(l.capacityPercent);
    }
    return {
      for (final e in byDept.entries) e.key: (e.value.reduce((a, b) => a + b) / e.value.length).round(),
    };
  }

  Color _loadColor(int pct) {
    if (pct >= 90) return AdminColors.error;
    if (pct >= 75) return AdminColors.primaryContainer;
    return AdminColors.secondary;
  }

  void _handleNav(AdminNavDestination dest) =>
      handleAdminNav(context, AdminNavDestination.lecturerAllocation, dest);

  void _notAvailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Not wired up in this preview.')),
    );
  }

  void _openAssignModal() {
    final eligibleLecturers = _lecturers.where((l) => l.capacityPercent < 100).toList();
    final targetSections = _unassignedSections;
    showDialog(
      context: context,
      builder: (ctx) => _AssignLecturerDialog(
        lecturers: eligibleLecturers,
        sections: targetSections,
        onConfirm: (sectionId, lecturerId) async {
          await _repository.assignLecturerToSection(sectionId, lecturerId);
          if (!mounted) return;
          Navigator.of(ctx).pop();
          await _load();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lecturer allocation confirmed.'), backgroundColor: AdminColors.primary),
          );
        },
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
    return AdminScaffold(
      selected: AdminNavDestination.lecturerAllocation,
      onDestinationSelected: _handleNav,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 20),
          _buildKpiRow(),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1000;
            final left = _buildLecturerList();
            final right = _buildSidePanels();
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 8, child: left),
                  const SizedBox(width: 20),
                  Expanded(flex: 4, child: right),
                ],
              );
            }
            return Column(children: [left, const SizedBox(height: 20), right]);
          }),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.account_tree_outlined, size: 18, color: AdminColors.secondary),
                const SizedBox(width: 6),
                Text('FACULTY LOGISTICS & OPERATIONS', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 4),
              Text('Lecturer Course Allocation', style: AdminTypography.headlineLg()),
              const SizedBox(height: 2),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text('Assign curricula, balance teaching credit loads, and monitor instructor course coverage across academic departments.', style: AdminTypography.bodyMd()),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.calendar_today, size: 16, color: AdminColors.secondary),
                  const SizedBox(width: 6),
                  Text('Term: AY 2024-Q3 (Active)', style: AdminTypography.titleSm()),
                ]),
              ),
              ElevatedButton.icon(
                onPressed: _openAssignModal,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('+ Assign Lecturer to Course'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.primaryContainer,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow() {
    final total = _totalSections;
    final assigned = _assignedSectionsCount;
    final staffingPct = total == 0 ? 0 : (assigned / total * 100).round();
    final avgUsed = _avgCreditsUsed;
    final avgMax = _avgCreditsMax;
    final workloadPct = avgMax == 0 ? 0 : (avgUsed / avgMax * 100).round();
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 780 ? 3 : 1;
      final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
      final cards = [
        _kpi(
          'ACTIVE CURRICULAR LOAD',
          '$total Sections',
          Icons.calendar_view_week_outlined,
          'Distributed across $_departmentCount academic departments',
          total == 0 ? 0 : assigned / total,
        ),
        _kpi(
          'STAFFING RATIO',
          '$staffingPct%',
          Icons.how_to_reg_outlined,
          '$_unassignedSectionsCount sections require instructor coverage',
          staffingPct / 100,
          warn: _unassignedSectionsCount > 0,
        ),
        _kpi(
          'INSTITUTIONAL WORKLOAD',
          '${avgUsed.toStringAsFixed(1)} / ${avgMax.toStringAsFixed(0)} Max Credits',
          Icons.speed_outlined,
          _capacityTag(workloadPct),
          workloadPct / 100,
        ),
      ];
      return Wrap(spacing: 16, runSpacing: 16, children: cards.map((c) => SizedBox(width: width, child: c)).toList());
    });
  }

  Widget _kpi(String label, String value, IconData icon, String footer, double progress, {bool warn = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(label, style: AdminTypography.labelMd().copyWith(fontWeight: FontWeight.w600))),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: AdminColors.secondaryFixed, shape: BoxShape.circle),
              child: Icon(icon, size: 16, color: AdminColors.onSecondaryFixedVariant),
            ),
          ]),
          const SizedBox(height: 10),
          Text(value, style: AdminTypography.dataMetric()),
          const SizedBox(height: 6),
          Row(children: [
            if (warn) const Icon(Icons.warning_amber_rounded, size: 14, color: AdminColors.error),
            Expanded(child: Text(footer, style: AdminTypography.bodySm(color: warn ? AdminColors.error : AdminColors.onSurfaceVariant))),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(value: progress.clamp(0, 1).toDouble(), minHeight: 5, backgroundColor: AdminColors.surfaceContainerLow, valueColor: const AlwaysStoppedAnimation<Color>(AdminColors.secondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildLecturerList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: AdminTypography.bodySm(color: AdminColors.onSurface),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: AdminColors.surfaceContainerLow,
                    hintText: 'Search by faculty name or assigned course code (e.g. PY-402)...',
                    hintStyle: AdminTypography.bodySm(color: AdminColors.outline),
                    prefixIcon: const Icon(Icons.search, size: 18, color: AdminColors.onSurfaceVariant),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.filter_list, size: 18, color: AdminColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_lecturers.isNotEmpty && _filteredLecturers.isEmpty)
          Padding(padding: const EdgeInsets.all(24), child: Text('No faculty found.', style: AdminTypography.bodyMd())),
        for (final l in _filteredLecturers) ...[
          _facultyCard(l),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Showing ${_filteredLecturers.isEmpty ? 0 : 1}-${_filteredLecturers.length} of ${_filteredLecturers.length} Faculty Members', style: AdminTypography.bodySm()),
              Row(mainAxisSize: MainAxisSize.min, children: [1].map((p) {
                const active = true;
                return Container(
                  margin: const EdgeInsets.only(left: 4),
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: active ? AdminColors.primaryContainer : AdminColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
                  child: Text('$p', style: AdminTypography.labelSm(color: active ? Colors.white : AdminColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
                );
              }).toList()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _facultyCard(Lecturer lecturer) {
    final pct = lecturer.capacityPercent;
    final overCapacity = pct >= 100;
    final tag = _capacityTag(pct);
    final sections = _sectionsFor(lecturer);
    final totalStudents = sections.fold<int>(0, (sum, s) => sum + s.enrolledCount);
    final available = lecturer.creditsMax - lecturer.creditsUsed;
    final footer = overCapacity
        ? 'Workload ceiling reached. Reallocation requires Dean approval.'
        : 'Can accept up to $available more credits • $totalStudents Students taught across all active sections';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 10,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: AdminColors.surfaceContainerHigh, shape: BoxShape.circle),
                  child: const Icon(Icons.person, color: AdminColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(lecturer.name, style: AdminTypography.titleMd()),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AdminColors.surfaceContainer, borderRadius: BorderRadius.circular(4)),
                        child: Text(lecturer.lecturerCode, style: AdminTypography.labelSm()),
                      ),
                    ]),
                    Text('${lecturer.title} • ${lecturer.department}', style: AdminTypography.bodySm()),
                  ],
                ),
              ]),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (overCapacity)
                      Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AdminColors.errorContainer, borderRadius: BorderRadius.circular(4)),
                        child: Text('Capacity Reached', style: AdminTypography.labelSm(color: AdminColors.onErrorContainer).copyWith(fontWeight: FontWeight.w700)),
                      ),
                    Text('${lecturer.creditsUsed} / ${lecturer.creditsMax} Credits', style: AdminTypography.titleSm()),
                    Text('$pct% Capacity • $tag', style: AdminTypography.labelSm(color: overCapacity ? AdminColors.error : AdminColors.secondary).copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 96,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 8,
                      backgroundColor: AdminColors.surfaceContainerLow,
                      valueColor: AlwaysStoppedAnimation<Color>(overCapacity ? AdminColors.error : AdminColors.secondaryContainer),
                    ),
                  ),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ACTIVE ASSIGNMENTS (${sections.length} COURSES)', style: AdminTypography.labelSm().copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                for (final s in sections) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(10)),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: AdminColors.primaryFixed, borderRadius: BorderRadius.circular(8)),
                            child: Text(s.courseCode.split('-').first, style: AdminTypography.labelSm(color: AdminColors.onPrimaryFixed).copyWith(fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 10),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 340),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.courseTitle, style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis),
                                Text('${s.sectionCode} • ${s.enrolledCount} Students • ${s.scheduleText}', style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ]),
                        OutlinedButton(
                          onPressed: _notAvailable,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AdminColors.onSurfaceVariant,
                            backgroundColor: Colors.transparent,
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            textStyle: AdminTypography.labelSm(),
                          ),
                          child: const Text('Details'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(overCapacity ? Icons.block : Icons.check_circle_outline, size: 15, color: overCapacity ? AdminColors.error : AdminColors.secondary),
                const SizedBox(width: 4),
                Text(footer, style: AdminTypography.bodySm(color: overCapacity ? AdminColors.error : AdminColors.onSurfaceVariant)),
              ]),
              if (!overCapacity)
                OutlinedButton.icon(
                  onPressed: _openAssignModal,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Course'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AdminColors.primaryContainer,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: AdminTypography.labelSm(),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanels() {
    final unassigned = _unassignedSections;
    final deptLoad = _departmentLoadBalance;

    // Genericized AI recommendation: pick the first unassigned section and
    // the lecturer with the most spare capacity (was hardcoded to a
    // specific "Prof. David Miller to OSHE-401" pairing that no longer
    // exists in the seed data).
    CourseSection? recSection = unassigned.isNotEmpty ? unassigned.first : null;
    Lecturer? recLecturer;
    if (recSection != null) {
      final candidates = _lecturers.where((l) => l.capacityPercent < 100).toList()
        ..sort((a, b) => a.capacityPercent.compareTo(b.capacityPercent));
      if (candidates.isNotEmpty) recLecturer = candidates.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.assignment_late_outlined, color: AdminColors.error, size: 20),
                const SizedBox(width: 6),
                Expanded(child: Text('Unassigned Courses', style: AdminTypography.titleMd())),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AdminColors.errorContainer, borderRadius: BorderRadius.circular(9999)),
                  child: Text('${unassigned.length} Urgent', style: AdminTypography.labelSm(color: AdminColors.onErrorContainer).copyWith(fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 4),
              Text('Sections currently lacking certified primary instructors for Q3.', style: AdminTypography.bodySm()),
              const SizedBox(height: 12),
              for (final u in unassigned) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.courseCode, style: AdminTypography.titleSm()),
                              Text(u.courseTitle, style: AdminTypography.bodySm(color: AdminColors.onSurface)),
                            ],
                          ),
                        ),
                        // No credits/units column on CourseSection — using a
                        // generic placeholder label (see report).
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AdminColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(4)),
                          child: Text('4 cr', style: AdminTypography.labelSm(color: AdminColors.onSurface)),
                        ),
                      ]),
                      Text('${u.enrolledCount} Enrolled', style: AdminTypography.bodySm()),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_assigned.contains(u.id) ? 'Assigned' : 'No Faculty Assigned',
                              style: AdminTypography.labelSm(color: _assigned.contains(u.id) ? AdminColors.secondary : AdminColors.error).copyWith(fontWeight: FontWeight.w700)),
                          if (!_assigned.contains(u.id))
                            ElevatedButton.icon(
                              onPressed: () => setState(() => _assigned.add(u.id)),
                              icon: const Icon(Icons.person_add_alt_1, size: 14),
                              label: const Text('1-Click Assign'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminColors.secondary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                textStyle: AdminTypography.labelSm(),
                              ),
                            )
                          else
                            const Icon(Icons.check_circle, size: 18, color: AdminColors.secondary),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _notAvailable,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminColors.onSurface,
                    backgroundColor: AdminColors.surfaceContainer,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('View All ${unassigned.length} Pending Unallocated Courses'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Departmental Load Balance', style: AdminTypography.titleSm()),
              const SizedBox(height: 12),
              for (final entry in deptLoad.entries) _loadRow(entry.key, entry.value, _loadColor(entry.value)),
              if (recSection != null && recLecturer != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_fix_high, size: 18, color: AdminColors.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: AdminTypography.bodySm(),
                            children: [
                              const TextSpan(text: 'AI recommendation: Assign '),
                              TextSpan(text: recLecturer.name, style: const TextStyle(fontWeight: FontWeight.w700, color: AdminColors.onSurface)),
                              const TextSpan(text: ' to '),
                              TextSpan(text: recSection.courseCode, style: const TextStyle(fontWeight: FontWeight.w700, color: AdminColors.onSurface)),
                              const TextSpan(text: ' to balance senior faculty load.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _loadRow(String label, int pct, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: AdminTypography.bodySm(color: AdminColors.onSurface)),
            Text('$pct% Capacity', style: AdminTypography.bodySm(color: AdminColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(value: pct / 100, minHeight: 6, backgroundColor: AdminColors.surfaceContainerLow, valueColor: AlwaysStoppedAnimation<Color>(color)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Mobile (<700px) layout
  // ---------------------------------------------------------------------

  Widget _buildMobileScaffold(BuildContext context) {
    final total = _totalSections;
    final assigned = _assignedSectionsCount;
    final staffingPct = total == 0 ? 0 : (assigned / total * 100).round();
    final avgUsed = _avgCreditsUsed;
    final avgMax = _avgCreditsMax;
    final workloadPct = avgMax == 0 ? 0 : (avgUsed / avgMax * 100).round();
    final unassigned = _unassignedSections;
    final deptLoad = _departmentLoadBalance;

    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: const AdminMobileTopBar.detail(title: 'Lecturer Allocation Detail'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Assign curricula, balance teaching credit loads, and monitor instructor course coverage across academic departments.',
                style: AdminTypography.bodyMd(),
              ),
              const SizedBox(height: 16),
              _mobileTermSelector(),
              const SizedBox(height: 10),
              _mobileAssignButton(),
              const SizedBox(height: 16),
              _mobileMetricCard(
                icon: Icons.domain_verification,
                iconBg: AdminColors.surfaceContainer,
                iconColor: AdminColors.secondary,
                label: 'Curricular Load',
                value: '$total',
                unit: 'Sections',
                footer: 'Across $_departmentCount Academic Departments',
                trailing: _pillBadge('Active', Icons.insights, AdminColors.surfaceContainer, AdminColors.secondary),
              ),
              const SizedBox(height: 12),
              _mobileStaffingCard(staffingPct, _unassignedSectionsCount),
              const SizedBox(height: 12),
              _mobileMetricCard(
                icon: Icons.balance,
                iconBg: AdminColors.surfaceContainer,
                iconColor: AdminColors.tertiaryContainer,
                label: 'Institutional Workload',
                value: avgUsed.toStringAsFixed(1),
                unit: '/ ${avgMax.toStringAsFixed(0)} Max Credits',
                footer: _capacityTag(workloadPct),
                trailing: _pillBadge(_capacityTag(workloadPct), null, AdminColors.surfaceContainer, AdminColors.tertiaryContainer),
              ),
              const SizedBox(height: 16),
              _mobileUrgentCard(unassigned),
              const SizedBox(height: 16),
              _mobileSearchField(),
              const SizedBox(height: 10),
              _mobileFilterChips(),
              const SizedBox(height: 16),
              if (_lecturers.isNotEmpty && _filteredLecturers.isEmpty)
                Padding(padding: const EdgeInsets.all(24), child: Text('No faculty found.', style: AdminTypography.bodyMd())),
              for (final l in _filteredLecturers) ...[
                _mobileFacultyCard(l),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 4),
              _mobileDeptLoadCard(deptLoad),
              const SizedBox(height: 16),
              _mobilePaginationFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileTermSelector() {
    const options = ['Term: AY 2024-Q3 (Active)', 'Term: AY 2024-Q4 (Upcoming)', 'Term: AY 2024-Q2 (Archived)'];
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: options.first,
          icon: const Icon(Icons.expand_more, color: AdminColors.onSurfaceVariant),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o, style: AdminTypography.bodySm(color: AdminColors.onSurface), overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (_) {},
        ),
      ),
    );
  }

  Widget _mobileAssignButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _openAssignModal,
        icon: const Icon(Icons.person_add, size: 18),
        label: const Text('+ Assign Lecturer to Course'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminColors.secondary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: AdminTypography.labelMd(),
        ),
      ),
    );
  }

  Widget _pillBadge(String text, IconData? icon, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 3)],
        Text(text, style: AdminTypography.labelSm(color: fg).copyWith(fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _mobileMetricCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
    required String footer,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant)),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: AdminTypography.headlineMd(color: AdminColors.onSurface)),
                    const SizedBox(width: 4),
                    Flexible(child: Text(unit, style: AdminTypography.labelMd(color: AdminColors.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(footer, style: AdminTypography.bodySm(color: AdminColors.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }

  Widget _mobileStaffingCard(int staffingPct, int uncoveredCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AdminColors.secondaryFixed, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.group_work, size: 22, color: AdminColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STAFFING RATIO', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant)),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('$staffingPct%', style: AdminTypography.headlineMd(color: AdminColors.secondary)),
                    const SizedBox(width: 4),
                    Text('Assigned', style: AdminTypography.labelMd(color: AdminColors.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(children: [
                  if (uncoveredCount > 0) ...[
                    const Icon(Icons.warning_amber_rounded, size: 14, color: AdminColors.error),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      uncoveredCount > 0 ? '$uncoveredCount sections require coverage' : 'All sections covered',
                      style: AdminTypography.bodySm(color: uncoveredCount > 0 ? AdminColors.error : AdminColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: staffingPct / 100,
                    strokeWidth: 5,
                    backgroundColor: AdminColors.surfaceContainerLow,
                    valueColor: const AlwaysStoppedAnimation<Color>(AdminColors.secondary),
                  ),
                ),
                Text('$staffingPct%', style: AdminTypography.labelSm(color: AdminColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileUrgentCard(List<CourseSection> unassigned) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: AdminColors.error),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.error, color: AdminColors.error, size: 20),
                      const SizedBox(width: 6),
                      Expanded(child: Text('${unassigned.length} Urgent Unassigned Courses', style: AdminTypography.headlineSm(), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AdminColors.errorContainer, borderRadius: BorderRadius.circular(9999)),
                        child: Text('AY-Q3 Critical', style: AdminTypography.labelSm(color: AdminColors.onErrorContainer).copyWith(fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                      'Classes start in 12 days. Immediate faculty assignment required to finalize syllabus publishing.',
                      style: AdminTypography.bodySm(),
                    ),
                    const SizedBox(height: 10),
                    for (final s in unassigned) ...[
                      // No credits/units column on CourseSection — using a
                      // generic placeholder label (see report).
                      _mobileUrgentRow(s.id, '${s.courseCode} ${s.sectionCode}', '${s.courseTitle} (4 cr)'),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileUrgentRow(String sectionId, String code, String desc) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(code, style: AdminTypography.titleSm(), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(desc, style: AdminTypography.bodySm(), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => setState(() => _assigned.add(sectionId)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.secondary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: AdminTypography.labelSm(),
          ),
          child: Text(_assigned.contains(sectionId) ? 'Assigned' : 'Assign'),
        ),
      ]),
    );
  }

  Widget _mobileSearchField() {
    return TextField(
      controller: _searchController,
      style: AdminTypography.bodySm(color: AdminColors.onSurface),
      decoration: InputDecoration(
        filled: true,
        fillColor: AdminColors.surfaceContainerLowest,
        hintText: 'Search by faculty name or assigned course code...',
        hintStyle: AdminTypography.bodySm(color: AdminColors.outline),
        prefixIcon: const Icon(Icons.search, size: 20, color: AdminColors.outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _mobileFilterChips() {
    final total = _lecturers.length;
    final optimal = _lecturers.where((l) => l.capacityPercent >= 80 && l.capacityPercent < 100).length;
    final underutilized = _lecturers.where((l) => l.capacityPercent < 80).length;
    final overloaded = _lecturers.where((l) => l.capacityPercent >= 100).length;
    final filters = [
      ('All Faculty', total, true),
      ('Optimal (80-99%)', optimal, false),
      ('Underutilized', underutilized, false),
      ('Overloaded', overloaded, false),
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = filters[i];
          final active = f.$3;
          return Material(
            color: active ? AdminColors.primaryContainer : AdminColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(9999),
            child: InkWell(
              borderRadius: BorderRadius.circular(9999),
              onTap: _notAvailable,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9999),
                  border: active ? null : Border.all(color: AdminColors.outlineVariant),
                ),
                child: Text('${f.$1} (${f.$2})', style: AdminTypography.labelMd(color: active ? Colors.white : AdminColors.onSurfaceVariant)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _mobileCourseSubCard(String code, String section, String badge, String title, String scheduleInfo, {bool showButtons = false, bool compact = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AdminColors.primaryFixed, borderRadius: BorderRadius.circular(4)),
              child: Text(code, style: AdminTypography.labelSm(color: AdminColors.onPrimaryFixed).copyWith(fontWeight: FontWeight.w700)),
            ),
            Text(section, style: AdminTypography.labelSm()),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AdminColors.surfaceContainer, borderRadius: BorderRadius.circular(4)),
              child: Text(badge, style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(title, style: AdminTypography.titleSm(), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Row(children: [
            const Icon(Icons.schedule, size: 13, color: AdminColors.onSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(child: Text(scheduleInfo, style: AdminTypography.bodySm(), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          if (showButtons) ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _notAvailable,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminColors.onSurfaceVariant,
                    side: const BorderSide(color: AdminColors.outlineVariant),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: AdminTypography.labelSm(),
                  ),
                  child: const Text('Syllabus'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _notAvailable,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AdminColors.secondary,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: AdminTypography.labelSm(),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [Icon(Icons.swap_horiz, size: 14, color: Colors.white), SizedBox(width: 4), Text('Reassign')],
                  ),
                ),
              ),
            ]),
          ] else if (compact) ...[
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _notAvailable,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminColors.onSurfaceVariant,
                    side: const BorderSide(color: AdminColors.outlineVariant),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    textStyle: AdminTypography.labelSm(),
                  ),
                  child: const Text('Details'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton(
                  onPressed: _notAvailable,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminColors.secondary,
                    side: const BorderSide(color: AdminColors.secondary),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    textStyle: AdminTypography.labelSm(),
                  ),
                  child: const Text('Reassign'),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  /// Single mobile faculty card, replacing the previous three hand-authored
  /// variants (_mobileOptimalCard / _mobileAvailableCard / _mobileLockedCard)
  /// which were each hardcoded to a specific named lecturer. The visual
  /// variant (locked / optimal / available) is now derived from
  /// [Lecturer.capacityPercent].
  Widget _mobileFacultyCard(Lecturer lecturer) {
    final pct = lecturer.capacityPercent;
    final locked = pct >= 100;
    final optimal = pct >= 80 && pct < 100;
    final sections = _sectionsFor(lecturer);
    final totalStudents = sections.fold<int>(0, (sum, s) => sum + s.enrolledCount);
    final available = lecturer.creditsMax - lecturer.creditsUsed;

    final badgeText = locked ? 'LOCKED' : (optimal ? 'OPTIMAL' : 'AVAILABLE');
    final badgeBg = locked ? AdminColors.errorContainer : (optimal ? AdminColors.surfaceContainer : AdminColors.secondaryFixed);
    final badgeFg = locked ? AdminColors.onErrorContainer : (optimal ? AdminColors.tertiaryContainer : AdminColors.secondary);
    final barColor = locked ? AdminColors.error : AdminColors.secondary;
    final calloutBg = locked ? AdminColors.errorContainer : AdminColors.secondaryFixed;
    final calloutFg = locked ? AdminColors.onErrorContainer : AdminColors.onSecondaryFixedVariant;
    final calloutText = locked
        ? 'Workload ceiling reached. Reallocation requires Dean approval.'
        : 'Can accept up to $available more credits before next capacity review';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: locked ? Border.all(color: AdminColors.errorContainer) : null,
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: locked ? AdminColors.errorContainer : AdminColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.person, color: locked ? AdminColors.error : AdminColors.primary, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(child: Text(lecturer.name, style: AdminTypography.titleMd(), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 4),
                    Icon(locked ? Icons.lock : Icons.verified, size: 15, color: locked ? AdminColors.error : AdminColors.secondary),
                  ]),
                  Text('${lecturer.title} • ${lecturer.lecturerCode}', style: AdminTypography.bodySm(), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
              child: Text(badgeText, style: AdminTypography.labelSm(color: badgeFg).copyWith(fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text('Teaching Load: ${lecturer.creditsUsed} / ${lecturer.creditsMax} Credits', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
                  Text('$pct% Capacity', style: AdminTypography.labelSm(color: locked ? AdminColors.error : AdminColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: LinearProgressIndicator(value: pct / 100, minHeight: 8, backgroundColor: AdminColors.surfaceContainerHigh, valueColor: AlwaysStoppedAnimation<Color>(barColor)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: calloutBg, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(locked ? Icons.lock_clock : Icons.info, size: 16, color: calloutFg),
              const SizedBox(width: 8),
              Expanded(child: Text(calloutText, style: AdminTypography.bodySm(color: calloutFg), maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
          ),
          const SizedBox(height: 12),
          Text('ASSIGNED CURRICULA (${sections.length})', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (locked)
            for (final s in sections)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AdminColors.surfaceContainer, borderRadius: BorderRadius.circular(4)),
                    child: Text(s.courseCode, style: AdminTypography.labelSm()),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.courseTitle, style: AdminTypography.bodySm(), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              )
          else
            for (final s in sections) ...[
              _mobileCourseSubCard(s.courseCode, s.sectionCode, s.roleLabel, s.courseTitle, '${s.scheduleText} • ${s.enrolledCount} students', showButtons: optimal, compact: !optimal),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 4),
          if (locked)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AdminColors.surfaceContainer,
                  foregroundColor: AdminColors.outline,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: AdminTypography.labelMd(),
                ),
                child: const Text('Max Load Reached'),
              ),
            )
          else
            Row(children: [
              const Icon(Icons.people_alt, size: 16, color: AdminColors.secondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '$totalStudents', style: const TextStyle(fontWeight: FontWeight.w700, color: AdminColors.onSurface)),
                    TextSpan(text: ' students total', style: AdminTypography.bodySm()),
                  ]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _openAssignModal,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Course'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminColors.secondary,
                  backgroundColor: AdminColors.surfaceContainer,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: AdminTypography.labelMd(),
                ),
              ),
            ]),
        ],
      ),
    );
  }

  Widget _mobileDeptLoadCard(Map<String, int> deptLoad) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Departmental Load Balance', style: AdminTypography.titleMd()),
          const SizedBox(height: 12),
          for (final entry in deptLoad.entries) _mobileLoadRow(entry.key, entry.value, _loadColor(entry.value)),
        ],
      ),
    );
  }

  // Mobile-safe variant of _loadRow: wraps the label in Expanded with
  // ellipsis so it can never overflow at narrow widths (the shared desktop
  // _loadRow is left untouched).
  Widget _mobileLoadRow(String label, int pct, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(label, style: AdminTypography.bodySm(color: AdminColors.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Text('$pct% Capacity', style: AdminTypography.bodySm(color: AdminColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(value: pct / 100, minHeight: 6, backgroundColor: AdminColors.surfaceContainerLow, valueColor: AlwaysStoppedAnimation<Color>(color)),
          ),
        ],
      ),
    );
  }

  Widget _mobilePaginationFooter() {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.chevron_left, size: 16),
          label: const Text('Previous'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AdminColors.outline,
            side: const BorderSide(color: AdminColors.outlineVariant),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: AdminTypography.labelSm(),
          ),
        ),
        Expanded(
          child: Text('Page 1 of 1', textAlign: TextAlign.center, style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
        ),
        OutlinedButton.icon(
          onPressed: _notAvailable,
          icon: const Icon(Icons.chevron_right, size: 16),
          label: const Text('Next'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AdminColors.onSurface,
            side: const BorderSide(color: AdminColors.outlineVariant),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: AdminTypography.labelSm(),
          ),
        ),
      ],
    );
  }
}

class _AssignLecturerDialog extends StatefulWidget {
  final List<Lecturer> lecturers;
  final List<CourseSection> sections;
  final Future<void> Function(String sectionId, String lecturerId) onConfirm;

  const _AssignLecturerDialog({
    required this.lecturers,
    required this.sections,
    required this.onConfirm,
  });

  @override
  State<_AssignLecturerDialog> createState() => _AssignLecturerDialogState();
}

class _AssignLecturerDialogState extends State<_AssignLecturerDialog> {
  static const _roleOptions = ['Lead Instructor', 'Primary Instructor', 'Co-Lecturer', 'Lab Supervisor'];

  String? _lecturerId;
  String? _sectionId;
  String _role = _roleOptions.first;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.lecturers.isNotEmpty) _lecturerId = widget.lecturers.first.id;
    if (widget.sections.isNotEmpty) _sectionId = widget.sections.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !_submitting && _lecturerId != null && _sectionId != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.assignment_ind_outlined, color: AdminColors.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(child: Text('Assign Lecturer to Course', style: AdminTypography.headlineSm())),
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
            ]),
            const SizedBox(height: 12),
            _lecturerField(),
            const SizedBox(height: 12),
            _sectionField(),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _staticField('Instruction Role', _roleOptions, _role, (v) => setState(() => _role = v))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Term Window', style: AdminTypography.labelMd()),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(color: AdminColors.surfaceContainer, borderRadius: BorderRadius.circular(10)),
                      child: Text('AY 2024 - Q3', style: AdminTypography.bodySm()),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.verified, size: 18, color: AdminColors.secondary),
                const SizedBox(width: 8),
                Expanded(child: Text('System will automatically verify prerequisite certifications and notify registrar office upon commit.', style: AdminTypography.bodySm())),
              ]),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: canSubmit
                      ? () async {
                          setState(() => _submitting = true);
                          await widget.onConfirm(_sectionId!, _lecturerId!);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primaryContainer, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('Confirm Allocation'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _lecturerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Faculty Member', style: AdminTypography.labelMd()),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _lecturerId,
              hint: const Text('No faculty with spare capacity'),
              items: widget.lecturers
                  .map((l) => DropdownMenuItem(
                        value: l.id,
                        child: Text(
                          '${l.name} (${l.creditsUsed} / ${l.creditsMax} Credits - ${l.creditsMax - l.creditsUsed} Available)',
                          style: AdminTypography.bodySm(color: AdminColors.onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _lecturerId = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Target Course Section', style: AdminTypography.labelMd()),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _sectionId,
              hint: const Text('No unassigned sections'),
              items: widget.sections
                  .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(
                          '${s.courseCode}: ${s.courseTitle}',
                          style: AdminTypography.bodySm(color: AdminColors.onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _sectionId = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _staticField(String label, List<String> options, String value, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AdminTypography.labelMd()),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: AdminTypography.bodySm(color: AdminColors.onSurface), overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
