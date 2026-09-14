import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'manage_lecturers_screen.dart';
import 'manage_students_screen.dart';
import 'course_enrollment_screen.dart';

// ---------------------------------------------------------------------------
// LecturerAllocationScreen – Stitch "Lecturer Course Allocation" faithful
// Flutter conversion.
// ---------------------------------------------------------------------------
class LecturerAllocationScreen extends StatefulWidget {
  const LecturerAllocationScreen({super.key});

  @override
  State<LecturerAllocationScreen> createState() => _LecturerAllocationScreenState();
}

class _LecturerAllocationScreenState extends State<LecturerAllocationScreen> {
  final Set<String> _assigned = {};

  void _handleNav(AdminNavDestination dest) {
    switch (dest) {
      case AdminNavDestination.manageLecturers:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageLecturersScreen()));
        break;
      case AdminNavDestination.lecturerAllocation:
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

  void _openAssignModal() {
    showDialog(
      context: context,
      builder: (ctx) => _AssignLecturerDialog(
        onConfirm: () {
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lecturer allocation confirmed.'), backgroundColor: AdminColors.primary),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 780 ? 3 : 1;
      final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
      final cards = [
        _kpi('ACTIVE CURRICULAR LOAD', '112 Sections', Icons.calendar_view_week_outlined, 'Distributed across 4 Academic Schools', 0.84),
        _kpi('STAFFING RATIO', '92%', Icons.how_to_reg_outlined, '9 sections require instructor coverage', 0.92, warn: true),
        _kpi('INSTITUTIONAL WORKLOAD', '11.4 / 15 Max Credits', Icons.speed_outlined, 'Optimal Range (Standard compliance baseline)', 0.76),
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
            child: LinearProgressIndicator(value: progress, minHeight: 5, backgroundColor: AdminColors.surfaceContainerLow, valueColor: const AlwaysStoppedAnimation<Color>(AdminColors.secondary)),
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
        _facultyCard('Dr. Sarah Lin', 'EMP-7721', 'Lead Data Architect • Division of Computing', 12, 15, 'Optimal', const [
          ('PY', 'PY-402: Python for Enterprise Data Analysis', 'Primary Instructor', 'Section A01 • 42 Students • 4 Credits • MWF 09:00 - 10:30'),
          ('ETL', 'DATA-501: Automated ETL & Pipelines', 'Primary Instructor', 'Section B02 • 38 Students • 4 Credits • TTh 13:00 - 14:45'),
          ('AI', 'AI-301: Applied ML in Enterprise', 'Co-Lecturer', 'Section C01 • 29 Students • 4 Credits • Lab Fridays 14:00 - 17:00'),
        ], '109 Students taught across all active sections'),
        const SizedBox(height: 16),
        _facultyCard('Prof. David Miller', 'EMP-5402', 'Senior EHS Director • Occupational Health & Safety', 8, 15, 'Bandwidth Available', const [
          ('OSH', 'OSHE-101: Workplace Safety & LOTO Protocols', 'Lead Instructor', 'Section A1 • 56 Students • 4 Credits • Mon/Wed 11:00 - 12:30'),
          ('SAF', 'SAF-204: Industrial Hazard Mitigation', 'Lead Instructor', 'Section H03 • 34 Students • 4 Credits • Thursday 14:00 - 17:30'),
        ], 'Can accept up to 7 more credits (approx 1-2 standard course sections)'),
        const SizedBox(height: 16),
        _facultyCard('Dr. Aris Thorne', 'EMP-8910', 'Head of AI • Center for Advanced Intelligence', 15, 15, 'Capacity Reached', const [
          ('ML', 'ML-800: Deep Neural Architectures', 'Graduate', 'Graduate • 50 Students • 5 Credits • Monday 14:00 - 18:00'),
          ('DL', 'DL-901: Generative Enterprise Systems', 'Doctoral Seminar', 'Doctoral Seminar • 45 Students • 5 Credits • Wednesday 14:00 - 18:00'),
          ('RL', 'RL-705: Reinforcement Learning in Robotics', 'Advanced Lab', 'Advanced Lab • 30 Students • 5 Credits • Friday 08:30 - 12:30'),
        ], 'Workload ceiling reached. Reallocation requires Dean approval.', overCapacity: true),
        const SizedBox(height: 16),
        _facultyCard('Elena Rostova', 'EMP-3211', 'VP Leadership Development • School of Global Governance', 6, 12, 'Available', const [
          ('LD', 'LEAD-400: Executive Leadership & Crisis Management', 'Section E1', 'Section E1 • 28 Students • 3 Credits • Tuesday 18:00 - 21:00'),
          ('CM', 'COMM-102: Strategic Corporate Communication', 'Section C3', 'Section C3 • 40 Students • 3 Credits • Thursday 16:00 - 19:00'),
        ], 'Total Teaching Cohort: 68 Enrolled'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Showing 1-4 of 38 Faculty Members', style: AdminTypography.bodySm()),
              Row(mainAxisSize: MainAxisSize.min, children: [1, 2, 3].map((p) {
                final active = p == 1;
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

  Widget _facultyCard(String name, String empId, String subtitle, int used, int max, String tag, List<(String, String, String, String)> courses, String footer, {bool overCapacity = false}) {
    final pct = (used / max * 100).round();
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
                      Text(name, style: AdminTypography.titleMd()),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AdminColors.surfaceContainer, borderRadius: BorderRadius.circular(4)),
                        child: Text(empId, style: AdminTypography.labelSm()),
                      ),
                    ]),
                    Text(subtitle, style: AdminTypography.bodySm()),
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
                    Text('$used / $max Credits', style: AdminTypography.titleSm()),
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
                Text('ACTIVE ASSIGNMENTS (${courses.length} COURSES)', style: AdminTypography.labelSm().copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                for (final c in courses) ...[
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
                            child: Text(c.$1, style: AdminTypography.labelSm(color: AdminColors.onPrimaryFixed).copyWith(fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 10),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 340),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.$2, style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis),
                                Text(c.$4, style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
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
    const unassigned = [
      ('CYBER-202', 'Zero Trust Architecture', '34 Enrolled • School of Cyber Defense', 'No Faculty Assigned', '4 cr'),
      ('CLOUD-410', 'Kubernetes Infrastructure', '50 Enrolled • DevOps Engineering', 'Lead Instructor Resigned', '3 cr'),
      ('AI-512', 'Multi-Agent Autonomy Lab', '22 Enrolled • AI Research Dept', 'Unallocated Lab Section', '4 cr'),
    ];
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
                              Text(u.$1, style: AdminTypography.titleSm()),
                              Text(u.$2, style: AdminTypography.bodySm(color: AdminColors.onSurface)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AdminColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(4)),
                          child: Text(u.$5, style: AdminTypography.labelSm(color: AdminColors.onSurface)),
                        ),
                      ]),
                      Text(u.$3, style: AdminTypography.bodySm()),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_assigned.contains(u.$1) ? 'Assigned' : u.$4,
                              style: AdminTypography.labelSm(color: _assigned.contains(u.$1) ? AdminColors.secondary : AdminColors.error).copyWith(fontWeight: FontWeight.w700)),
                          if (!_assigned.contains(u.$1))
                            ElevatedButton.icon(
                              onPressed: () => setState(() => _assigned.add(u.$1)),
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
                  child: const Text('View All 9 Pending Unallocated Courses'),
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
              _loadRow('Computer Science & AI', 94, AdminColors.error),
              _loadRow('Industrial EHS', 68, AdminColors.secondary),
              _loadRow('Executive Leadership', 72, AdminColors.secondaryContainer),
              _loadRow('Cloud & DevOps', 89, AdminColors.primaryContainer),
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
                          children: const [
                            TextSpan(text: 'AI recommendation: Assign '),
                            TextSpan(text: 'Prof. David Miller', style: TextStyle(fontWeight: FontWeight.w700, color: AdminColors.onSurface)),
                            TextSpan(text: ' to '),
                            TextSpan(text: 'OSHE-401', style: TextStyle(fontWeight: FontWeight.w700, color: AdminColors.onSurface)),
                            TextSpan(text: ' to balance senior faculty load.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
}

class _AssignLecturerDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  const _AssignLecturerDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
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
            _field('Select Faculty Member', const ['Prof. David Miller (8 / 15 Credits - 7 Available)', 'Elena Rostova (6 / 12 Credits - 6 Available)', 'Dr. Sarah Lin (12 / 15 Credits - 3 Available)']),
            const SizedBox(height: 12),
            _field('Target Course Section', const ['CYBER-202: Zero Trust Architecture (4 Credits)', 'CLOUD-410: Kubernetes Infrastructure (3 Credits)', 'AI-512: Multi-Agent Autonomy Lab (4 Credits)']),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field('Instruction Role', const ['Lead Instructor', 'Primary Instructor', 'Co-Lecturer', 'Lab Supervisor'])),
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
                  onPressed: onConfirm,
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

  Widget _field(String label, List<String> options) {
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
              value: options.first,
              items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: AdminTypography.bodySm(color: AdminColors.onSurface), overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (_) {},
            ),
          ),
        ),
      ],
    );
  }
}
