import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'manage_lecturers_screen.dart';
import 'lecturer_allocation_screen.dart';
import 'manage_students_screen.dart';
import 'course_enrollment_screen.dart';

// ---------------------------------------------------------------------------
// EnrollStudentsScreen – Stitch "Enroll Students into Course" faithful
// Flutter conversion.
// ---------------------------------------------------------------------------
class EnrollStudentsScreen extends StatefulWidget {
  const EnrollStudentsScreen({super.key});

  @override
  State<EnrollStudentsScreen> createState() => _EnrollStudentsScreenState();
}

class _EnrollStudentsScreenState extends State<EnrollStudentsScreen> {
  static const int _baseEnrolled = 42;
  static const int _capacity = 50;

  static const _candidates = [
    _Candidate('DR', 'Daniel Ross', 'EMP-61092', 'daniel.ross@enterprise.com', 'Data Architecture', 'Fall 2025 Cohort',
        'CS-101 Met (GPA 3.9)', 'Academic Good Standing', 'Enterprise Full', tag: 'Staged'),
    _Candidate('EL', 'Emily Lawson', 'EMP-88231', 'emily.lawson@enterprise.com', 'AI Engineering', 'Fall 2025 Cohort',
        'MATH-204 Met', 'Academic Good Standing', 'Enterprise Full', tag: 'Waitlist #1'),
    _Candidate('RK', 'Ravi Kumar', 'EMP-54910', 'ravi.kumar@enterprise.com', 'Cloud & Distributed', 'Fall 2025 Cohort',
        'All Prerequisites Met', 'Ready for section assign', 'Enterprise Full'),
    _Candidate('SM', 'Sophia Martinez', 'EMP-30491', 's.martinez@enterprise.com', 'Data Architecture', 'Fall 2025 Cohort',
        'Prereq PY-101 Verified', 'Academic Good Standing', 'Self-Enrolled'),
    _Candidate('JT', 'Jason Todd', 'EMP-77182', 'jason.todd@enterprise.com', 'Executive Operations', 'Summer 2025 Cohort',
        'Prereq Waiver Required', 'Conditional dean approval', 'Enterprise Full', tag: 'Waitlist #2', warn: true),
  ];

  late final Set<String> _staged;

  @override
  void initState() {
    super.initState();
    _staged = {'Daniel Ross', 'Emily Lawson'};
  }

  void _handleNav(AdminNavDestination dest) {
    switch (dest) {
      case AdminNavDestination.manageLecturers:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageLecturersScreen()));
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

  @override
  Widget build(BuildContext context) {
    final postCapacity = _baseEnrolled + _staged.length;
    return AdminScaffold(
      selected: AdminNavDestination.courseEnrollment,
      onDestinationSelected: _handleNav,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 12),
          Text('Enroll Students into Course', style: AdminTypography.headlineLg()),
          const SizedBox(height: 2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text('Search eligible students from the enterprise registry, verify prerequisite compliance, and assign enrollments to this cohort.', style: AdminTypography.bodyMd()),
          ),
          const SizedBox(height: 20),
          _buildCourseSummary(postCapacity),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1000;
            final left = _buildCandidateTable();
            final right = _buildStagedPanel(postCapacity);
            if (wide) {
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 8, child: left),
                const SizedBox(width: 20),
                Expanded(flex: 4, child: right),
              ]);
            }
            return Column(children: [left, const SizedBox(height: 20), right]);
          }),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.arrow_back, size: 18, color: AdminColors.onSurfaceVariant),
            const SizedBox(width: 6),
            Text('Back to Course Roster', style: AdminTypography.labelMd()),
          ]),
        ),
      ),
    );
  }

  Widget _buildCourseSummary(int postCapacity) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: AdminColors.secondaryFixed, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.class_outlined, color: AdminColors.primary, size: 26)),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 6, children: [
                _tag('Active Cohort', AdminColors.tertiaryFixed, AdminColors.onTertiaryFixedVariant, dot: true),
                _tag('TERM: FALL 2025', AdminColors.surfaceContainer, AdminColors.onSurfaceVariant),
                _tag('4 CREDIT UNITS', AdminColors.surfaceContainer, AdminColors.onSurfaceVariant),
              ]),
              const SizedBox(height: 4),
              Text('PY-402: Python for Enterprise Data Analysis & Automation', style: AdminTypography.headlineSm()),
              const SizedBox(height: 4),
              Wrap(spacing: 8, children: [
                Text('Instructor: Dr. Sarah Lin (Lead Data Architect)', style: AdminTypography.bodySm(color: AdminColors.onSurface).copyWith(fontWeight: FontWeight.w600)),
                Text('• Schedule: Mon / Wed 18:00–20:30 UTC', style: AdminTypography.bodySm()),
                Text('• Location: Virtual Synchronous Lab 04', style: AdminTypography.bodySm()),
              ]),
            ]),
          ]),
          Container(
            width: 260,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Cohort Capacity Status', style: AdminTypography.bodySm(color: AdminColors.onSurface)),
                  Text('$postCapacity / $_capacity Enrolled', style: AdminTypography.titleSm()),
                ]),
                const SizedBox(height: 6),
                ClipRRect(borderRadius: BorderRadius.circular(9999), child: LinearProgressIndicator(value: postCapacity / _capacity, minHeight: 8, backgroundColor: AdminColors.surfaceContainerHigh, valueColor: const AlwaysStoppedAnimation<Color>(AdminColors.primaryContainer))),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${_capacity - postCapacity} seats remaining', style: AdminTypography.labelSm(color: AdminColors.secondary).copyWith(fontWeight: FontWeight.w700)),
                  Text('4 on Waitlist', style: AdminTypography.labelSm()),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color bg, Color fg, {bool dot = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (dot) ...[Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)), const SizedBox(width: 4)],
          Text(text, style: AdminTypography.labelSm(color: fg).copyWith(fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _buildCandidateTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      style: AdminTypography.bodySm(color: AdminColors.onSurface),
                      decoration: InputDecoration(isDense: true, filled: true, fillColor: AdminColors.surfaceContainerLow, hintText: 'Search student by name, corporate ID, track...', hintStyle: AdminTypography.bodySm(color: AdminColors.outline), prefixIcon: const Icon(Icons.search, size: 16, color: AdminColors.onSurfaceVariant), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 10)),
                    ),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      Text('Filter by:', style: AdminTypography.labelSm()),
                      _pill('All Eligible (18)', true),
                      _pill('From Waitlist (4)', false),
                      _pill('Corporate Sponsored (14)', false),
                    ]),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(width: 950, child: Column(children: [for (final c in _candidates) _candidateRow(c)])),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFDBEAFE))),
          child: Row(children: [
            const Icon(Icons.info_outline, size: 18, color: AdminColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text('Only students meeting prerequisite compliance appear as eligible. Waitlisted students require manual dean sign-off before staging.', style: AdminTypography.bodySm(color: AdminColors.onSurface))),
          ]),
        ),
      ],
    );
  }

  Widget _pill(String label, bool active) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: active ? AdminColors.secondaryFixed : AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(9999)),
        child: Text(label, style: AdminTypography.labelSm(color: active ? AdminColors.onSecondaryFixedVariant : AdminColors.onSurfaceVariant)),
      );

  Widget _candidateRow(_Candidate c) {
    final staged = _staged.contains(c.name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: staged ? AdminColors.secondaryFixed.withValues(alpha: 0.15) : null,
        border: const Border(bottom: BorderSide(color: AdminColors.surfaceContainer)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(value: staged, onChanged: (v) => setState(() => v == true ? _staged.add(c.name) : _staged.remove(c.name)), activeColor: AdminColors.primaryContainer),
          SizedBox(
            width: 230,
            child: Row(children: [
              Container(width: 32, height: 32, alignment: Alignment.center, decoration: const BoxDecoration(color: AdminColors.tertiary, shape: BoxShape.circle), child: Text(c.initials, style: AdminTypography.labelSm(color: Colors.white).copyWith(fontWeight: FontWeight.w700))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(c.name, style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis)),
                  if (c.tag != null) ...[
                    const SizedBox(width: 4),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: c.warn ? AdminColors.errorContainer : AdminColors.primaryFixed, borderRadius: BorderRadius.circular(4)), child: Text(c.tag!, style: AdminTypography.labelSm(color: c.warn ? AdminColors.onErrorContainer : AdminColors.onPrimaryFixed))),
                  ],
                ]),
                Text('${c.employeeId} • ${c.email}', style: AdminTypography.labelSm(), overflow: TextOverflow.ellipsis),
              ])),
            ]),
          ),
          SizedBox(width: 150, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.track, style: AdminTypography.bodyMd(color: AdminColors.onSurface)),
            Text(c.cohort, style: AdminTypography.labelSm()),
          ])),
          SizedBox(width: 220, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(c.warn ? Icons.warning_amber_rounded : Icons.check_circle, size: 14, color: c.warn ? const Color(0xFFB45309) : AdminColors.secondary),
              const SizedBox(width: 4),
              Flexible(child: Text(c.prereq, style: AdminTypography.bodyMd(color: c.warn ? const Color(0xFFB45309) : AdminColors.secondary).copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            ]),
            Text(c.standing, style: AdminTypography.labelSm()),
          ])),
          SizedBox(width: 120, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(color: c.sponsorship == 'Self-Enrolled' ? AdminColors.surfaceContainer : const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(4)),
            child: Text(c.sponsorship, style: AdminTypography.labelSm(color: c.sponsorship == 'Self-Enrolled' ? AdminColors.onSurfaceVariant : const Color(0xFF047857))),
          )),
          SizedBox(
            width: 90,
            child: Align(
              alignment: Alignment.centerRight,
              child: staged
                  ? OutlinedButton(
                      onPressed: () => setState(() => _staged.remove(c.name)),
                      style: OutlinedButton.styleFrom(foregroundColor: AdminColors.error, backgroundColor: AdminColors.errorContainer.withValues(alpha: 0.3), side: BorderSide.none, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), textStyle: AdminTypography.labelSm()),
                      child: const Text('Remove'),
                    )
                  : OutlinedButton(
                      onPressed: () => setState(() => _staged.add(c.name)),
                      style: OutlinedButton.styleFrom(foregroundColor: AdminColors.primary, backgroundColor: AdminColors.surfaceContainerLow, side: BorderSide.none, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), textStyle: AdminTypography.labelSm()),
                      child: const Text('+ Add'),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStagedPanel(int postCapacity) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Enrollment Batch Summary', style: AdminTypography.titleMd()),
              Text('${_staged.length} students queued for commit', style: AdminTypography.bodySm()),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AdminColors.primaryFixed, borderRadius: BorderRadius.circular(9999)),
              child: Text('${_staged.length} Staged', style: AdminTypography.labelSm(color: AdminColors.onPrimaryFixed).copyWith(fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Capacity Post-Enrollment:', style: AdminTypography.titleSm()),
                  Text('$postCapacity / $_capacity', style: AdminTypography.titleSm(color: AdminColors.primary).copyWith(fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(borderRadius: BorderRadius.circular(9999), child: LinearProgressIndicator(value: postCapacity / _capacity, minHeight: 6, backgroundColor: AdminColors.surfaceContainerHigh, valueColor: const AlwaysStoppedAnimation<Color>(AdminColors.primaryContainer))),
                const SizedBox(height: 6),
                Text('Remaining seats will reduce from ${_capacity - _baseEnrolled} to ${_capacity - postCapacity} seats.', style: AdminTypography.labelSm()),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _staged.isEmpty
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${_staged.length} student(s) enrolled into PY-402.'), backgroundColor: AdminColors.primary),
                      );
                    },
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: Text('Confirm & Enroll ${_staged.length} Students'),
              style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primaryContainer, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(foregroundColor: AdminColors.onSurfaceVariant, backgroundColor: AdminColors.surfaceContainerLowest, side: BorderSide(color: AdminColors.outlineVariant), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Cancel & Return'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Candidate {
  final String initials, name, employeeId, email, track, cohort, prereq, standing, sponsorship;
  final String? tag;
  final bool warn;

  const _Candidate(this.initials, this.name, this.employeeId, this.email, this.track, this.cohort, this.prereq, this.standing, this.sponsorship, {this.tag, this.warn = false});
}
