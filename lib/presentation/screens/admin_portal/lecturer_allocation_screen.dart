import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_mobile_top_bar.dart';
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

  // ---------------------------------------------------------------------
  // Mobile (<700px) layout
  // ---------------------------------------------------------------------

  Widget _buildMobileScaffold(BuildContext context) {
    const availableCourses1 = [
      ('OSHE-101', 'Sec A1', 'Lead Instructor', 'Workplace Safety & LOTO Protocols', 'Mon/Wed 11:00-12:30 • 56 students'),
      ('SAF-204', 'Sec H03', 'Lead Instructor', 'Industrial Hazard Mitigation', 'Thu 14:00-17:30 • 34 students'),
    ];
    const availableCourses2 = [
      ('LEAD-400', 'Sec E1', 'Section E1', 'Executive Leadership & Crisis Mgmt', 'Tue 18:00-21:00 • 28 students'),
      ('COMM-102', 'Sec C3', 'Section C3', 'Strategic Corporate Communication', 'Thu 16:00-19:00 • 40 students'),
    ];
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
                value: '112',
                unit: 'Sections',
                footer: 'Across 4 Academic Schools',
                trailing: _pillBadge('Active', Icons.insights, AdminColors.surfaceContainer, AdminColors.secondary),
              ),
              const SizedBox(height: 12),
              _mobileStaffingCard(),
              const SizedBox(height: 12),
              _mobileMetricCard(
                icon: Icons.balance,
                iconBg: AdminColors.surfaceContainer,
                iconColor: AdminColors.tertiaryContainer,
                label: 'Institutional Workload',
                value: '11.4',
                unit: '/ 15 Max Credits',
                footer: 'Optimal balanced tier',
                trailing: _pillBadge('Optimal', null, AdminColors.surfaceContainer, AdminColors.tertiaryContainer),
              ),
              const SizedBox(height: 16),
              _mobileUrgentCard(),
              const SizedBox(height: 16),
              _mobileSearchField(),
              const SizedBox(height: 10),
              _mobileFilterChips(),
              const SizedBox(height: 16),
              _mobileOptimalCard(),
              const SizedBox(height: 12),
              _mobileAvailableCard(
                name: 'Prof. David Miller',
                empId: 'EMP-5402',
                subtitle: 'Senior EHS Director',
                used: 8,
                max: 15,
                courses: availableCourses1,
                callout: 'Can accept up to 7 more credits (approx 1-2 standard course sections)',
                totalLabel: '90 students total',
              ),
              const SizedBox(height: 12),
              _mobileLockedCard(),
              const SizedBox(height: 12),
              _mobileAvailableCard(
                name: 'Elena Rostova',
                empId: 'EMP-3211',
                subtitle: 'VP Leadership Development',
                used: 6,
                max: 12,
                courses: availableCourses2,
                callout: 'Can accept up to 6 more credits before next capacity review',
                totalLabel: '68 students total',
              ),
              const SizedBox(height: 16),
              _mobileDeptLoadCard(),
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

  Widget _mobileStaffingCard() {
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
                    Text('92%', style: AdminTypography.headlineMd(color: AdminColors.secondary)),
                    const SizedBox(width: 4),
                    Text('Assigned', style: AdminTypography.labelMd(color: AdminColors.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.warning_amber_rounded, size: 14, color: AdminColors.error),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '9 sections require coverage',
                      style: AdminTypography.bodySm(color: AdminColors.error).copyWith(fontWeight: FontWeight.w600),
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
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: 0.92,
                    strokeWidth: 5,
                    backgroundColor: AdminColors.surfaceContainerLow,
                    valueColor: AlwaysStoppedAnimation<Color>(AdminColors.secondary),
                  ),
                ),
                Text('92%', style: AdminTypography.labelSm(color: AdminColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileUrgentCard() {
    const items = [
      ('CYBER-202 Sec 02', 'Network Defense Protocols (4 cr)'),
      ('CLOUD-410 Sec 01', 'Kubernetes Infrastructure (3 cr)'),
      ('AI-512 Sec 01', 'Multi-Agent Autonomy Lab (4 cr)'),
    ];
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
                      Expanded(child: Text('3 Urgent Unassigned Courses', style: AdminTypography.headlineSm(), overflow: TextOverflow.ellipsis)),
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
                    for (final item in items) ...[
                      _mobileUrgentRow(item.$1, item.$2),
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

  Widget _mobileUrgentRow(String code, String desc) {
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
          onPressed: () => setState(() => _assigned.add(code)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.secondary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: AdminTypography.labelSm(),
          ),
          child: Text(_assigned.contains(code) ? 'Assigned' : 'Assign'),
        ),
      ]),
    );
  }

  Widget _mobileSearchField() {
    return TextField(
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
    const filters = [('All Faculty', 48, true), ('Optimal (80-90%)', 31, false), ('Underutilized', 11, false), ('Overloaded', 6, false)];
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

  Widget _mobileOptimalCard() {
    const courses = [
      ('PY-402', 'Sec A01', 'Primary Instructor', 'Python for Enterprise Data Analysis', 'MWF 09:00-10:30 • 42 students'),
      ('DATA-501', 'Sec B02', 'Primary Instructor', 'Automated ETL & Pipelines', 'TTh 13:00-14:45 • 38 students'),
      ('AI-301', 'Sec C01', 'Co-Lecturer', 'Applied ML in Enterprise', 'Lab Fri 14:00-17:00 • 29 students'),
    ];
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
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: AdminColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.person, color: AdminColors.primary, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(child: Text('Dr. Sarah Lin', style: AdminTypography.titleMd(), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, size: 16, color: AdminColors.secondary),
                  ]),
                  Text('Lead Data Architect • EMP-7721', style: AdminTypography.bodySm(), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AdminColors.surfaceContainer, borderRadius: BorderRadius.circular(6)),
              child: Text('OPTIMAL', style: AdminTypography.labelSm(color: AdminColors.tertiaryContainer).copyWith(fontWeight: FontWeight.w700)),
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
                  Expanded(child: Text('Teaching Load: 12 / 15 Credits', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
                  Text('80% Capacity', style: AdminTypography.labelSm(color: AdminColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: LinearProgressIndicator(value: 0.8, minHeight: 8, backgroundColor: AdminColors.surfaceContainerHigh, valueColor: const AlwaysStoppedAnimation<Color>(AdminColors.secondaryContainer)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('ASSIGNED CURRICULA (3)', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final c in courses) ...[
            _mobileCourseSubCard(c.$1, c.$2, c.$3, c.$4, c.$5, showButtons: true),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.people_alt, size: 16, color: AdminColors.secondary),
            const SizedBox(width: 4),
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: '109', style: TextStyle(fontWeight: FontWeight.w700, color: AdminColors.onSurface)),
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

  Widget _mobileAvailableCard({
    required String name,
    required String empId,
    required String subtitle,
    required int used,
    required int max,
    required List<(String, String, String, String, String)> courses,
    required String callout,
    required String totalLabel,
  }) {
    final pct = (used / max * 100).round();
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
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: AdminColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.person, color: AdminColors.primary, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AdminTypography.titleMd(), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('$subtitle • $empId', style: AdminTypography.bodySm(), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AdminColors.secondaryFixed, borderRadius: BorderRadius.circular(6)),
              child: Text('AVAILABLE', style: AdminTypography.labelSm(color: AdminColors.secondary).copyWith(fontWeight: FontWeight.w700)),
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
                  Expanded(child: Text('Teaching Load: $used / $max Credits', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
                  Text('$pct% Capacity', style: AdminTypography.labelSm(color: AdminColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: LinearProgressIndicator(value: pct / 100, minHeight: 8, backgroundColor: AdminColors.surfaceContainerHigh, valueColor: const AlwaysStoppedAnimation<Color>(AdminColors.secondary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AdminColors.secondaryFixed, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.info, size: 16, color: AdminColors.secondary),
              const SizedBox(width: 8),
              Expanded(child: Text(callout, style: AdminTypography.bodySm(color: AdminColors.onSecondaryFixedVariant), maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
          ),
          const SizedBox(height: 12),
          Text('ASSIGNED CURRICULA (${courses.length})', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final c in courses) ...[
            _mobileCourseSubCard(c.$1, c.$2, c.$3, c.$4, c.$5, compact: true),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.people_alt, size: 16, color: AdminColors.secondary),
            const SizedBox(width: 4),
            Expanded(child: Text(totalLabel, style: AdminTypography.bodySm(), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ],
      ),
    );
  }

  Widget _mobileLockedCard() {
    const courses = [
      ('ML-800', 'Deep Neural Architectures'),
      ('DL-901', 'Generative Enterprise Systems'),
      ('RL-705', 'Reinforcement Learning in Robotics'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.errorContainer),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: AdminColors.errorContainer, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.person, color: AdminColors.error, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(child: Text('Dr. Aris Thorne', style: AdminTypography.titleMd(), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 4),
                    const Icon(Icons.lock, size: 15, color: AdminColors.error),
                  ]),
                  Text('Head of AI • EMP-8910', style: AdminTypography.bodySm(), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AdminColors.errorContainer, borderRadius: BorderRadius.circular(6)),
              child: Text('LOCKED', style: AdminTypography.labelSm(color: AdminColors.onErrorContainer).copyWith(fontWeight: FontWeight.w700)),
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
                  Expanded(child: Text('Teaching Load: 15 / 15 Credits', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
                  Text('100% Capacity', style: AdminTypography.labelSm(color: AdminColors.error).copyWith(fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: LinearProgressIndicator(value: 1.0, minHeight: 8, backgroundColor: AdminColors.surfaceContainerHigh, valueColor: const AlwaysStoppedAnimation<Color>(AdminColors.error)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AdminColors.errorContainer, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.lock_clock, size: 16, color: AdminColors.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Workload ceiling reached. Reallocation requires Dean approval.',
                  style: AdminTypography.bodySm(color: AdminColors.onErrorContainer),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Text('ASSIGNED CURRICULA (3)', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final c in courses)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AdminColors.surfaceContainer, borderRadius: BorderRadius.circular(4)),
                  child: Text(c.$1, style: AdminTypography.labelSm()),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(c.$2, style: AdminTypography.bodySm(), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ),
          const SizedBox(height: 8),
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
          ),
        ],
      ),
    );
  }

  Widget _mobileDeptLoadCard() {
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
          _mobileLoadRow('Computer Science & AI', 94, AdminColors.error),
          _mobileLoadRow('Industrial EHS', 68, AdminColors.secondary),
          _mobileLoadRow('Executive Leadership', 72, AdminColors.secondaryContainer),
          _mobileLoadRow('Cloud & DevOps', 89, AdminColors.primaryContainer),
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
          child: Text('Page 1 of 5', textAlign: TextAlign.center, style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
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
