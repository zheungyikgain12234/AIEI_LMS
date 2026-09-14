import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'lecturer_allocation_screen.dart';
import 'manage_students_screen.dart';
import 'course_enrollment_screen.dart';

// ---------------------------------------------------------------------------
// ManageLecturersScreen – Stitch "Manage Lecturers" faithful Flutter
// conversion.
// ---------------------------------------------------------------------------
class ManageLecturersScreen extends StatefulWidget {
  const ManageLecturersScreen({super.key});

  @override
  State<ManageLecturersScreen> createState() => _ManageLecturersScreenState();
}

class _ManageLecturersScreenState extends State<ManageLecturersScreen> {
  static const _lecturers = [
    _Lecturer('Dr. Sarah Lin', 'Lead Data Architect', 'EMP-7721', 'sarah.lin@aiei.edu',
        'Computer Science & Data', 'Distributed ETL & Python', 3, ['PY-402', 'DATA-501', 'AI-301'],
        12, 15, 80, 'Active', accredited: true, manageable: true),
    _Lecturer('Prof. David Miller', 'Senior EHS Director', 'EMP-5402', 'd.miller@aiei.edu',
        'Workplace Safety & EHS', 'OSHA Protocol & Site Risk Analysis', 2, ['OSHE-101', 'SAF-204'],
        8, 15, 53, 'Active', accredited: true),
    _Lecturer('Dr. Aris Thorne', 'Head of AI & Machine Learning', 'EMP-8910', 'a.thorne@aiei.edu',
        'Data Science & AI', 'Deep Neural Architectures', 4, ['ML-800', 'DL-901', 'RL-705', '+1 more'],
        15, 15, 100, 'Active', accredited: true),
    _Lecturer('Elena Rostova', 'VP Leadership Development', 'EMP-3211', 'e.rostova@aiei.edu',
        'Executive Leadership', 'Org Dynamics & Crisis Management', 2, ['LEAD-400', 'COMM-102'],
        6, 12, 50, 'Active', accredited: true),
    _Lecturer('Prof. Kenneth Wu', 'Enterprise Systems Fellow', 'EMP-6129', 'k.wu@aiei.edu',
        'Computer Science & Data', 'Distributed Cloud Governance', 0, [],
        0, 15, 0, 'Sabbatical'),
  ];

  void _handleNav(AdminNavDestination dest) {
    switch (dest) {
      case AdminNavDestination.manageLecturers:
        break;
      case AdminNavDestination.lecturerAllocation:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LecturerAllocationScreen()));
        break;
      case AdminNavDestination.manageStudents:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageStudentsScreen()));
        break;
      case AdminNavDestination.courseEnrollment:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CourseEnrollmentScreen()));
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
    return AdminScaffold(
      selected: AdminNavDestination.manageLecturers,
      onDestinationSelected: _handleNav,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 20),
          _buildMetrics(),
          const SizedBox(height: 20),
          _buildDirectoryCard(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 16,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AdminColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(4)),
                child: Text('Faculty Governance', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant)),
              ),
              Text('/ Q3 Academic Term', style: AdminTypography.labelSm()),
            ]),
            const SizedBox(height: 4),
            Text('Manage Lecturers', style: AdminTypography.headlineLg()),
            const SizedBox(height: 2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Text('Institutional faculty roster, onboarding, credentials, and departmental appointments.', style: AdminTypography.bodyMd()),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _notAvailable,
          icon: const Icon(Icons.person_add_outlined, size: 18),
          label: const Text('+ Add New Lecturer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.primaryContainer,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildMetrics() {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 700 ? 2 : 1;
      final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
      final cards = [
        _metricCard('TOTAL FACULTY', '38 Active', Icons.groups_outlined, '+3', 'vs last quarter onboarding', 0.82),
        _metricCard('ASSIGNED COURSES', '112 Sections', Icons.menu_book_outlined, null, '94% capacity across 4 schools', 0.94),
      ];
      return Wrap(spacing: 16, runSpacing: 16, children: cards.map((c) => SizedBox(width: width, child: c)).toList());
    });
  }

  Widget _metricCard(String label, String value, IconData icon, String? delta, String footer, double progress) {
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: AdminColors.primary, size: 18),
            ),
          ]),
          const SizedBox(height: 8),
          Text(value, style: AdminTypography.dataMetric()),
          const SizedBox(height: 4),
          Row(children: [
            if (delta != null) ...[
              Icon(Icons.arrow_upward, size: 13, color: AdminColors.secondary),
              Text(delta, style: AdminTypography.labelMd(color: AdminColors.secondary)),
              const SizedBox(width: 4),
            ],
            Expanded(child: Text(footer, style: AdminTypography.labelSm())),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(value: progress, minHeight: 4, backgroundColor: AdminColors.surfaceContainerLow, valueColor: const AlwaysStoppedAnimation<Color>(AdminColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryCard() {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AdminColors.surfaceContainerLow,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: TextField(
                    style: AdminTypography.bodySm(color: AdminColors.onSurface),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: AdminColors.surfaceContainerLowest,
                      hintText: 'Search by faculty name, employee ID, email, or department...',
                      hintStyle: AdminTypography.bodySm(color: AdminColors.outline),
                      prefixIcon: const Icon(Icons.search, size: 18, color: AdminColors.onSurfaceVariant),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(color: AdminColors.surfaceContainer, borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _statusPill('All Status', true),
                    _statusPill('Active', false),
                    _statusPill('Contract', false),
                  ]),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.tune, size: 16, color: AdminColors.onSurfaceVariant),
                  label: const Text('More Filters'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminColors.onSurface,
                    backgroundColor: AdminColors.surfaceContainerLowest,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: AdminTypography.labelSm(),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1060,
              child: Column(children: [for (final l in _lecturers) _lecturerRow(l)]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Showing 1 – 5 of 38 faculty members', style: AdminTypography.bodySm()),
                Row(mainAxisSize: MainAxisSize.min, children: [1, 2, 3].map((p) {
                  final active = p == 1;
                  return Container(
                    margin: const EdgeInsets.only(left: 4),
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: active ? AdminColors.primaryContainer : AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
                    child: Text('$p', style: AdminTypography.labelSm(color: active ? Colors.white : AdminColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
                  );
                }).toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: active ? AdminColors.surfaceContainerLowest : Colors.transparent, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: AdminTypography.labelSm(color: active ? AdminColors.onSurface : AdminColors.onSurfaceVariant)),
    );
  }

  Widget _lecturerRow(_Lecturer l) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AdminColors.surfaceContainer))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 240,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(color: AdminColors.surfaceContainerHigh, shape: BoxShape.circle),
                  child: const Icon(Icons.person, color: AdminColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(child: Text(l.name, style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis)),
                        if (l.accredited) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.verified, size: 14, color: AdminColors.secondary)),
                      ]),
                      Text(l.title, style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
                      Text('${l.employeeId} • ${l.email}', style: AdminTypography.labelSm(), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.department, style: AdminTypography.titleSm()),
                Text(l.specialization, style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.courseCount == 0 ? '0 Courses Assigned' : '${l.courseCount} Active Courses',
                    style: AdminTypography.labelSm(color: l.courseCount == 0 ? AdminColors.onSurfaceVariant : AdminColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Wrap(spacing: 4, runSpacing: 4, children: l.courses.map((c) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AdminColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(4)),
                  child: Text(c, style: AdminTypography.labelSm(color: AdminColors.onPrimaryFixed).copyWith(fontWeight: FontWeight.w700)),
                )).toList()),
              ],
            ),
          ),
          SizedBox(
            width: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${l.creditsUsed} / ${l.creditsMax}', style: AdminTypography.labelSm(color: AdminColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
                  Text('${l.capacityPercent}%', style: AdminTypography.labelSm(color: l.capacityPercent >= 100 ? AdminColors.secondary : AdminColors.onSurfaceVariant)),
                ]),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: LinearProgressIndicator(
                    value: l.capacityPercent / 100,
                    minHeight: 6,
                    backgroundColor: AdminColors.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(l.capacityPercent >= 100 ? AdminColors.secondary : AdminColors.primary),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 90,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: l.status == 'Active' ? AdminColors.surfaceContainerLow : AdminColors.surfaceContainer,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: l.status == 'Active' ? AdminColors.primary : AdminColors.onSurfaceVariant, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(l.status, style: AdminTypography.labelSm(color: l.status == 'Active' ? AdminColors.primary : AdminColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
          SizedBox(
            width: 130,
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => l.manageable
                    ? Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LecturerAllocationScreen()))
                    : _notAvailable(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminColors.primary,
                  backgroundColor: AdminColors.surfaceContainerLow,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: AdminTypography.labelSm(),
                ),
                child: Text(l.courseCount == 0 ? 'Assign Load' : 'Manage Courses'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Lecturer {
  final String name;
  final String title;
  final String employeeId;
  final String email;
  final String department;
  final String specialization;
  final int courseCount;
  final List<String> courses;
  final int creditsUsed;
  final int creditsMax;
  final int capacityPercent;
  final String status;
  final bool accredited;
  final bool manageable;

  const _Lecturer(
    this.name,
    this.title,
    this.employeeId,
    this.email,
    this.department,
    this.specialization,
    this.courseCount,
    this.courses,
    this.creditsUsed,
    this.creditsMax,
    this.capacityPercent,
    this.status, {
    this.accredited = false,
    this.manageable = false,
  });
}
