import 'package:stitch_aiei_lms/core/utils/refresh_on_return.dart';
import 'package:stitch_aiei_lms/core/utils/app_snackbar.dart';
import 'package:stitch_aiei_lms/core/utils/busy_overlay.dart';
import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/presentation/widgets/skeleton.dart';
import 'package:stitch_aiei_lms/core/theme/ui_contrast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_students_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/student.dart';
import 'package:stitch_aiei_lms/domain/models/enrolled_class.dart';

// ---------------------------------------------------------------------------
// StudentEnrolledCoursesScreen — "Manage Enrolled Courses" for a single
// student. Lists the classes they're currently enrolled in, each with an
// unticked box: tick the ones to remove and press the red "Unenroll Selected"
// button (after a confirmation dialog they are unenrolled in one go).
// ---------------------------------------------------------------------------
class StudentEnrolledCoursesScreen extends StatefulWidget {
  final String studentId;

  const StudentEnrolledCoursesScreen({super.key, required this.studentId});

  @override
  State<StudentEnrolledCoursesScreen> createState() => _StudentEnrolledCoursesScreenState();
}

class _StudentEnrolledCoursesScreenState extends State<StudentEnrolledCoursesScreen> with RefreshOnReturn<StudentEnrolledCoursesScreen> {
  @override
  void onReturnedTo() => _load();

  final _repository = SupabaseAdminStudentsRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  Student? _student;
  List<EnrolledClass> _classes = [];
  final Set<String> _unenrolling = {};

  /// The classes ticked for removal (by [EnrolledClass.rowKey]). Empty by default.
  final Set<String> _selected = {};
  /// Course ids this student is enrolled in that aren't mapped to their
  /// profile (role/department for Internal, track for External) — same rule
  /// as the red warning icon on the Manage Students table.
  Set<String> _mismatchedCourseIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final student = await _repository.getStudentById(widget.studentId);
    final classes = await _repository.getEnrolledClasses(widget.studentId);
    final mismatched = await _computeMismatches(student, classes);
    if (!mounted) return;
    setState(() {
      _student = student;
      _classes = classes;
      _mismatchedCourseIds = mismatched;
      _isLoading = false;
    });
  }

  Future<Set<String>> _computeMismatches(Student s, List<EnrolledClass> classes) async {
    final enrolled = {for (final c in classes) c.courseId};
    if (enrolled.isEmpty) return {};
    final client = Supabase.instance.client;
    Future<String?> idByName(String table, String? name) async {
      if (name == null) return null;
      final row = await client.from(table).select('id').eq('name', name).maybeSingle();
      return row?['id'] as String?;
    }

    final Set<String> allowed;
    if (s.studentType == StudentType.external) {
      final trackId = await idByName('program_tracks', s.programTrack);
      if (trackId == null) return {};
      final rows = await client.from('track_courses').select('course_id').eq('track_id', trackId);
      allowed = {for (final r in rows) r['course_id'] as String};
    } else {
      final roleId = await idByName('roles', s.role);
      final departmentId = await idByName('departments', s.department);
      if (roleId == null && departmentId == null) return {};
      allowed = {};
      if (roleId != null) {
        final rows = await client.from('role_courses').select('course_id').eq('role_id', roleId);
        allowed.addAll([for (final r in rows) r['course_id'] as String]);
      }
      if (departmentId != null) {
        final rows = await client.from('department_courses').select('course_id').eq('department_id', departmentId);
        allowed.addAll([for (final r in rows) r['course_id'] as String]);
      }
    }
    return enrolled.where((id) => !allowed.contains(id)).toSet();
  }

  Future<void> _unenrollSelected() async {
    final targets = _classes.where((c) => _selected.contains(c.rowKey)).toList();
    if (targets.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unenroll from courses?'),
        content: Text(
          targets.length == 1
              ? 'Unenroll ${_student?.name ?? 'this student'} from ${targets.first.displayName}?'
              : 'Unenroll ${_student?.name ?? 'this student'} from the ${targets.length} selected courses?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', textAlign: TextAlign.center)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.error, foregroundColor: Colors.white),
            child: const Text('Unenroll', textAlign: TextAlign.center),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _unenrolling.addAll(targets.map((t) => t.rowKey)));
    final removed = <String>{};
    Object? failure;
    await runWithBusy(context, 'Unenrolling…', () async {
      for (final c in targets) {
        try {
          await _repository.unenrollStudentFromCourse(widget.studentId, c.courseId, sectionId: c.sectionId);
          removed.add(c.rowKey);
        } catch (e) {
          failure = e;
        }
      }
    });
    if (!mounted) return;
    setState(() {
      _classes.removeWhere((e) => removed.contains(e.rowKey));
      _selected.removeAll(removed);
      _unenrolling.clear();
    });
    if (failure == null) {
      showSuccessSnackBar(context, removed.length == 1 ? 'Unenrolled successfully.' : 'Unenrolled from ${removed.length} courses successfully.');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unenroll from some courses: $failure'), backgroundColor: AdminColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: AdminColors.navSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AdminColors.onSurface,
        title: Text('Manage Enrolled Courses', style: AdminTypography.headlineSm()),
      ),
      body: _isLoading
          ? const SkeletonBody()
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AdminColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(color: AdminColors.surfaceContainerHigh, shape: BoxShape.circle),
                              child: const Icon(Icons.person, color: AdminColors.primary, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_student?.name ?? '', style: AdminTypography.titleMd()),
                                  Text(_student?.studentCode ?? '', style: AdminTypography.labelSm()),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: Text('Enrolled Courses (${_classes.length})', style: AdminTypography.titleSm())),
                          ElevatedButton.icon(
                            onPressed: _selected.isEmpty || _unenrolling.isNotEmpty ? null : _unenrollSelected,
                            icon: const Icon(Icons.person_remove_outlined, size: 18),
                            label: Text(
                              _selected.isEmpty ? 'Unenroll Selected' : 'Unenroll Selected (${_selected.length})',
                              textAlign: TextAlign.center,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminColors.error,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AdminColors.error.withValues(alpha: 0.35),
                              disabledForegroundColor: Colors.white,
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tick the courses to remove, then click Unenroll Selected.',
                        style: AdminTypography.bodySm(color: AdminColors.onSurfaceVariant).copyWith(fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AdminColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _classes.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text('Not enrolled in any classes.', style: AdminTypography.bodyMd()),
                              )
                            : Column(children: [for (final c in _classes) _classRow(c)]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _classRow(EnrolledClass c) {
    final busy = _unenrolling.contains(c.rowKey);
    final mismatch = _mismatchedCourseIds.contains(c.courseId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: UiContrast.divider))),
      child: Row(
        children: [
          busy
              ? const SizedBox(width: 24, height: 24, child: Padding(padding: EdgeInsets.all(2), child: CircularProgressIndicator(strokeWidth: 2)))
              : Checkbox(
                  value: _selected.contains(c.rowKey),
                  onChanged: (v) => setState(() => v == true ? _selected.add(c.rowKey) : _selected.remove(c.rowKey)),
                  activeColor: AdminColors.primaryContainer,
                ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(child: Text(c.displayName, style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis)),
                  if (mismatch) ...[
                    const SizedBox(width: 6),
                    Tooltip(
                      message: _student?.studentType == StudentType.external
                          ? 'This course is not mapped to the student\x27s track'
                          : 'This course is not mapped to the student\x27s role or department',
                      child: const Icon(Icons.error, size: 15, color: AdminColors.error),
                    ),
                  ],
                ]),
                Text(c.courseTitle, style: AdminTypography.labelSm(), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
