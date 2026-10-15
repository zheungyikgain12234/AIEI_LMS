import 'package:stitch_aiei_lms/core/utils/refresh_on_return.dart';
import 'package:stitch_aiei_lms/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/ui_contrast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_students_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/student.dart';
import 'package:stitch_aiei_lms/domain/models/enrolled_class.dart';

// ---------------------------------------------------------------------------
// StudentEnrolledCoursesScreen — "Manage Enrolled Courses" for a single
// student. Lists the classes they're currently enrolled in, each pre-checked;
// unchecking one unenrolls the student immediately.
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

  Future<void> _unenroll(EnrolledClass c) async {
    setState(() => _unenrolling.add(c.rowKey));
    try {
      await _repository.unenrollStudentFromCourse(widget.studentId, c.courseId, sectionId: c.sectionId);
      if (!mounted) return;
      setState(() {
        _classes.removeWhere((e) => e.rowKey == c.rowKey);
        _unenrolling.remove(c.rowKey);
      });
      showSuccessSnackBar(context, 'Unenrolled from ${c.displayName}.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _unenrolling.remove(c.rowKey));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unenroll: $e'), backgroundColor: AdminColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: AdminColors.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AdminColors.onSurface,
        title: Text('Manage Enrolled Courses', style: AdminTypography.headlineSm()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                      Text(
                        'Uncheck to unenroll.',
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
                  value: true,
                  onChanged: (v) {
                    if (v == false) _unenroll(c);
                  },
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
