import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'manage_lecturers_screen.dart';
import 'lecturer_allocation_screen.dart';
import 'course_enrollment_screen.dart';

// ---------------------------------------------------------------------------
// ManageStudentsScreen – Stitch "Manage Students" faithful Flutter
// conversion.
// ---------------------------------------------------------------------------
class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  static const _students = [
    _Student('Alex Chen', 'EMP-88219', 'alex.chen@enterprise.com', 'Data Architecture Specialist', 'Fall 2025 Cohort',
        4, '94%', 'Good Standing', ['Python Specialist', 'OSHE Certified'], hasCourses: true),
    _Student('Maya Patel', 'EMP-77402', 'maya.patel@enterprise.com', 'AI Engineering Track', 'Fall 2025 Cohort',
        3, '96%', 'Good Standing', ['Executive Leadership', 'Distinction Honor']),
    _Student('Marcus Vance', 'EMP-55190', 'marcus.vance@enterprise.com', 'Executive Operations', 'Executive Summer 2025',
        2, '82%', 'Good Standing', ['Executive Leadership']),
    _Student('Jordan Taylor', 'EMP-99214', 'jordan.taylor@enterprise.com', 'Workplace Safety Track', 'Spring 2025 Cohort',
        3, '68%', 'Flagged / Remediation', ['OSHE Revoked'], flagged: true),
    _Student('Sarah Jenkins', 'EMP-33109', 'sarah.jenkins@enterprise.com', 'Cloud & Distributed Systems', 'Fall 2025 Cohort',
        4, '91%', 'Good Standing', ['Cloud Architect', 'DevOps Master']),
  ];

  final Set<String> _selected = {};

  void _handleNav(AdminNavDestination dest) {
    switch (dest) {
      case AdminNavDestination.manageLecturers:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageLecturersScreen()));
        break;
      case AdminNavDestination.lecturerAllocation:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LecturerAllocationScreen()));
        break;
      case AdminNavDestination.manageStudents:
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
      selected: AdminNavDestination.manageStudents,
      onDestinationSelected: _handleNav,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 20),
          _buildMetrics(),
          const SizedBox(height: 20),
          _buildTableCard(),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final left = _buildTracksCard();
            final right = _buildCredentialTrendCard();
            if (wide) {
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 4, child: left),
                const SizedBox(width: 16),
                Expanded(flex: 8, child: right),
              ]);
            }
            return Column(children: [left, const SizedBox(height: 16), right]);
          }),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage Students', style: AdminTypography.headlineLg()),
            const SizedBox(height: 2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Text('Institutional learner registry, enrollment status, credential tracking, and cohort management across enterprise academies.', style: AdminTypography.bodyMd()),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _notAvailable,
          icon: const Icon(Icons.person_add_outlined, size: 18),
          label: const Text('Register New Student'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.primaryContainer,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildMetrics() {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 500 ? 2 : 1);
      final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
      final cards = [
        _metric('TOTAL ENROLLED', '1,420 Active', Icons.groups_outlined, '+64 new registrations this term'),
        _metric('AVG COMPLETION', '88.4%', Icons.percent_outlined, '+2.8% vs. previous cohort milestone'),
        _metric('GRANTED CREDENTIALS', '3,812 Granted', Icons.workspace_premium_outlined, '99.1% verified valid'),
        _metric('ACADEMIC REVIEW', '14 Students', Icons.warning_amber_outlined, 'Safety & grading alerts', urgent: true),
      ];
      return Wrap(spacing: 16, runSpacing: 16, children: cards.map((c) => SizedBox(width: width, child: c)).toList());
    });
  }

  Widget _metric(String label, String value, IconData icon, String footer, {bool urgent = false}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(label, style: AdminTypography.labelMd().copyWith(fontWeight: FontWeight.w600))),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: urgent ? AdminColors.errorContainer : AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: urgent ? AdminColors.onErrorContainer : AdminColors.primary),
            ),
          ]),
          const SizedBox(height: 8),
          Text(value, style: AdminTypography.dataMetric(color: urgent ? AdminColors.error : AdminColors.onSurface)),
          const SizedBox(height: 6),
          Text(footer, style: AdminTypography.bodySm()),
        ],
      ),
    );
  }

  Widget _buildTableCard() {
    return Container(
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: AdminTypography.bodySm(color: AdminColors.onSurface),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AdminColors.surfaceContainerLow,
                hintText: 'Search student by name, student ID, email, or company...',
                hintStyle: AdminTypography.bodySm(color: AdminColors.outline),
                prefixIcon: const Icon(Icons.search, size: 18, color: AdminColors.onSurfaceVariant),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_selected.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_box, size: 18, color: AdminColors.secondary),
                    const SizedBox(width: 6),
                    Text('${_selected.length} student${_selected.length == 1 ? '' : 's'} selected', style: AdminTypography.titleSm()),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(_selected.clear),
                      child: Text('Deselect all', style: AdminTypography.labelMd(color: AdminColors.secondary)),
                    ),
                  ]),
                  Wrap(spacing: 6, children: [
                    OutlinedButton(onPressed: _notAvailable, style: _pillButtonStyle(), child: const Text('Bulk Enroll')),
                    OutlinedButton(onPressed: _notAvailable, style: _pillButtonStyle(), child: const Text('Issue Notice')),
                    ElevatedButton(
                      onPressed: _notAvailable,
                      style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), textStyle: AdminTypography.labelSm()),
                      child: const Text('Export Selected'),
                    ),
                  ]),
                ],
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: 980, child: Column(children: [for (final s in _students) _studentRow(s)])),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Showing 1 - 5 of 1,420 students', style: AdminTypography.bodySm()),
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

  ButtonStyle _pillButtonStyle() => OutlinedButton.styleFrom(
        foregroundColor: AdminColors.onSurface,
        backgroundColor: AdminColors.surfaceContainerLowest,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: AdminTypography.labelSm(),
      );

  Widget _studentRow(_Student s) {
    final selected = _selected.contains(s.employeeId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: s.flagged ? AdminColors.errorContainer.withValues(alpha: 0.12) : null,
        border: const Border(bottom: BorderSide(color: AdminColors.surfaceContainer)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: selected,
            onChanged: (v) => setState(() => v == true ? _selected.add(s.employeeId) : _selected.remove(s.employeeId)),
            activeColor: AdminColors.primaryContainer,
          ),
          SizedBox(
            width: 220,
            child: Row(children: [
              Container(width: 36, height: 36, decoration: const BoxDecoration(color: AdminColors.surfaceContainerHigh, shape: BoxShape.circle), child: Icon(s.flagged ? Icons.person_off : Icons.person, color: s.flagged ? AdminColors.error : AdminColors.primary, size: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: AdminTypography.titleSm(color: s.flagged ? AdminColors.error : AdminColors.onSurface), overflow: TextOverflow.ellipsis),
                    Text(s.employeeId, style: AdminTypography.labelSm()),
                    Text(s.email, style: AdminTypography.bodySm(), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ]),
          ),
          SizedBox(
            width: 200,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.track, style: AdminTypography.titleSm()),
              Text(s.cohort, style: AdminTypography.bodySm()),
            ]),
          ),
          SizedBox(
            width: 150,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${s.enrollments} Enrolled', style: AdminTypography.titleSm(color: s.flagged ? AdminColors.error : AdminColors.primary)),
              Text('Avg ${s.avgGrade}', style: AdminTypography.labelSm()),
            ]),
          ),
          SizedBox(
            width: 150,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: s.flagged ? AdminColors.errorContainer : AdminColors.surfaceContainer, borderRadius: BorderRadius.circular(9999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(s.flagged ? Icons.error_outline : Icons.check_circle_outline, size: 14, color: s.flagged ? AdminColors.onErrorContainer : AdminColors.secondary),
                const SizedBox(width: 4),
                Flexible(child: Text(s.standing, style: AdminTypography.labelSm(color: s.flagged ? AdminColors.onErrorContainer : AdminColors.secondary), overflow: TextOverflow.ellipsis)),
              ]),
            ),
          ),
          Expanded(
            child: Wrap(spacing: 4, runSpacing: 4, children: s.credentials.map((c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: s.flagged ? AdminColors.errorContainer : AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(9999)),
              child: Text(c, style: AdminTypography.labelSm(color: s.flagged ? AdminColors.onErrorContainer : AdminColors.onSurface)),
            )).toList()),
          ),
          SizedBox(
            width: 130,
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => s.hasCourses
                    ? Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CourseEnrollmentScreen()))
                    : _notAvailable(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: s.flagged ? AdminColors.error : AdminColors.primary,
                  backgroundColor: s.flagged ? AdminColors.errorContainer : AdminColors.surfaceContainerLow,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: AdminTypography.labelSm(),
                ),
                child: Text(s.flagged ? 'Resolve Flag' : 'Manage Courses'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTracksCard() {
    const tracks = [
      ('AI & Machine Learning', 542, 38),
      ('Cloud & Distributed Computing', 418, 29),
      ('Data Architecture & Analytics', 298, 21),
      ('OSHE & Workplace Safety Compliance', 162, 12),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Learners by Academy Track', style: AdminTypography.titleMd()),
          const SizedBox(height: 4),
          Text('Distribution across active institutional specializations.', style: AdminTypography.bodySm()),
          const SizedBox(height: 12),
          for (final t in tracks)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(t.$1, style: AdminTypography.labelMd(color: AdminColors.onSurface))),
                    Text('${t.$2} Students (${t.$3}%)', style: AdminTypography.labelSm()),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: LinearProgressIndicator(value: t.$3 / 100, minHeight: 6, backgroundColor: AdminColors.surfaceContainerLow, valueColor: const AlwaysStoppedAnimation<Color>(AdminColors.secondaryContainer)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCredentialTrendCard() {
    const months = [('Oct', 48), ('Nov', 64), ('Dec', 82), ('Jan', 96), ('Feb', 110), ('Mar', 132)];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text('Monthly Credential Grant Rate', style: AdminTypography.titleMd())),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AdminColors.surfaceContainer, borderRadius: BorderRadius.circular(6)),
              child: Text('2024–2025 Cycle', style: AdminTypography.labelSm()),
            ),
          ]),
          const SizedBox(height: 4),
          Text('Volume of verified skill badges issued across corporate cohorts.', style: AdminTypography.bodySm()),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: months.map((m) {
                final isLast = m == months.last;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: m.$2.toDouble(),
                          decoration: BoxDecoration(
                            color: isLast ? AdminColors.secondaryContainer : AdminColors.surfaceContainerHigh,
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(m.$1, style: AdminTypography.labelSm(color: isLast ? AdminColors.secondary : AdminColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 6,
              children: [
                Text('Current Term Peak: 488 Badges', style: AdminTypography.bodySm(color: AdminColors.onSurface)),
                GestureDetector(
                  onTap: _notAvailable,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('View Accreditation Audit', style: AdminTypography.titleSm(color: AdminColors.secondary)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 14, color: AdminColors.secondary),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Student {
  final String name;
  final String employeeId;
  final String email;
  final String track;
  final String cohort;
  final int enrollments;
  final String avgGrade;
  final String standing;
  final List<String> credentials;
  final bool flagged;
  final bool hasCourses;

  const _Student(this.name, this.employeeId, this.email, this.track, this.cohort, this.enrollments, this.avgGrade, this.standing, this.credentials, {this.flagged = false, this.hasCourses = false});
}
