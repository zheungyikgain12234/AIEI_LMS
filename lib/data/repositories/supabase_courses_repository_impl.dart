import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/session/app_session.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/domain/models/enrolled_course.dart';
import 'package:stitch_aiei_lms/domain/models/course_stats.dart';
import 'package:stitch_aiei_lms/domain/models/critical_action_item.dart';
import 'package:stitch_aiei_lms/domain/models/module_material.dart';
import 'package:stitch_aiei_lms/domain/repositories/courses_repository.dart';

/// Supabase-backed [CoursesRepository]. Queries `courses` joined with the
/// signed-in-demo-student's enrollment/progress rows (see
/// [DemoIdentity.studentId] — there's no real auth session yet, only a
/// role-picker Login screen) and derives the presentational fields
/// (icons/colors/CTA copy) that the UI needs but the schema intentionally
/// doesn't store, the same way a real backend would leave styling to the
/// client.
class SupabaseCoursesRepositoryImpl implements CoursesRepository {
  SupabaseCoursesRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<EnrolledCourse>> getEnrolledCourses() async {
    final courseRows = await _client.from('courses').select('''
      id, course_title, course_description, category, image_url,
      course_tags(tags(label, color_hex)),
      course_badges(certifications(title))
    ''');

    final enrollmentRows = await _client
        .from('student_courses')
        .select('course_id, section_id')
        .eq('student_id', DemoIdentity.studentId);
    // Module content is class-scoped: a student's course content is
    // whichever class (`section_id`) they're enrolled in for that course,
    // which may be null if they haven't been assigned to a class yet.
    final sectionByCourse = <String, String>{
      for (final row in enrollmentRows as List)
        if (row['section_id'] != null) row['course_id'] as String: row['section_id'] as String,
    };
    final enrolledCourseIds = {for (final row in enrollmentRows) row['course_id'] as String};
    // Progress is never read from the stored `student_courses.progress_percentage`
    // column — it's recomputed live from actual gradebook state every time,
    // the same way the lecturer's Student Directory does, so the two views
    // can never disagree and adding/removing assessments or grades is
    // reflected immediately without needing a separate sync step.
    final liveProgressByCourse = await _liveProgressByCourse(sectionByCourse);
    final progressByCourse = <String, int>{
      for (final id in enrolledCourseIds) id: liveProgressByCourse[id] ?? 0,
    };

    final sectionIds = sectionByCourse.values.toSet().toList();
    final sectionRows = sectionIds.isEmpty
        ? <dynamic>[]
        : await _client
            .from('course_sections')
            .select('id, section_code, lecturers(name)')
            .inFilter('id', sectionIds);
    final lecturerNameBySection = <String, String>{
      for (final row in sectionRows)
        if (row['lecturers'] != null) row['id'] as String: row['lecturers']['name'] as String,
    };
    final classCodeBySection = <String, String>{
      for (final row in sectionRows) row['id'] as String: displayCode(row['section_code'] as String),
    };

    return [
      for (final course in courseRows as List)
        if (progressByCourse.containsKey(course['id']))
          _mapCourse(
            course as Map<String, dynamic>,
            progressByCourse,
            sectionByCourse[course['id']],
            lecturerNameBySection[sectionByCourse[course['id']]],
            classCodeBySection[sectionByCourse[course['id']]],
          ),
    ];
  }

  /// Computes each course's progress live as
  /// `graded exam/assignment blocks ÷ total exam/assignment blocks` for the
  /// demo student's own section — the same calculation the lecturer's
  /// Student Directory uses — instead of trusting a stored/denormalized
  /// column that can go stale the moment an assessment is added, removed,
  /// or (un)graded.
  Future<Map<String, int>> _liveProgressByCourse(Map<String, String> sectionByCourse) async {
    if (sectionByCourse.isEmpty) return {};
    final courseBySection = {for (final entry in sectionByCourse.entries) entry.value: entry.key};
    final sectionIds = courseBySection.keys.toList();

    final moduleRows = await _client.from('course_modules').select('id, section_id').inFilter('section_id', sectionIds);
    final sectionByModule = {for (final row in moduleRows as List) row['id'] as String: row['section_id'] as String};
    if (sectionByModule.isEmpty) return {for (final id in sectionByCourse.keys) id: 0};

    final sessionRows = await _client.from('sessions').select('id, module_id').inFilter('module_id', sectionByModule.keys.toList());
    final moduleBySession = {for (final row in sessionRows as List) row['id'] as String: row['module_id'] as String};
    if (moduleBySession.isEmpty) return {for (final id in sectionByCourse.keys) id: 0};

    final blockRows = await _client
        .from('content_blocks')
        .select('id, session_id')
        .inFilter('session_id', moduleBySession.keys.toList())
        .inFilter('block_type', ['exam', 'assignment']);
    final sectionByBlock = <String, String>{};
    final totalAssessmentsBySection = <String, int>{};
    for (final row in blockRows as List) {
      final blockId = row['id'] as String;
      final moduleId = moduleBySession[row['session_id'] as String];
      final sectionId = moduleId == null ? null : sectionByModule[moduleId];
      if (sectionId == null) continue;
      sectionByBlock[blockId] = sectionId;
      totalAssessmentsBySection[sectionId] = (totalAssessmentsBySection[sectionId] ?? 0) + 1;
    }
    if (sectionByBlock.isEmpty) return {for (final id in sectionByCourse.keys) id: 0};

    final gradedRows = await _client
        .from('content_block_submissions')
        .select('content_block_id')
        .eq('student_id', DemoIdentity.studentId)
        .eq('status', 'graded')
        .inFilter('content_block_id', sectionByBlock.keys.toList());
    final gradedCountBySection = <String, int>{};
    for (final row in gradedRows as List) {
      final sectionId = sectionByBlock[row['content_block_id'] as String];
      if (sectionId == null) continue;
      gradedCountBySection[sectionId] = (gradedCountBySection[sectionId] ?? 0) + 1;
    }

    return {
      for (final sectionId in sectionByCourse.keys.map((courseId) => sectionByCourse[courseId]!).toSet())
        courseBySection[sectionId]!: () {
          final total = totalAssessmentsBySection[sectionId] ?? 0;
          if (total == 0) return 0;
          final graded = gradedCountBySection[sectionId] ?? 0;
          return ((graded / total) * 100).round();
        }(),
    };
  }

  EnrolledCourse _mapCourse(
    Map<String, dynamic> course,
    Map<String, int> progressByCourse,
    String? sectionId,
    String? lecturerName,
    String? classCode, {
    String? ctaOverride,
  }) {
    final id = course['id'] as String;
    final category = CourseCategory.fromKey(course['category'] as String);
    final progress = progressByCourse[id] ?? 0;
    final isCompleted = progress >= 100;

    final tags = [
      for (final entry in (course['course_tags'] as List? ?? []))
        if (entry['tags'] != null)
          CourseTag(
            label: entry['tags']['label'] as String,
            backgroundColor: _hexToColor(entry['tags']['color_hex'] as String?) ??
                AppColors.surfaceContainerLowest,
            textColor: AppColors.onSurface,
            hasCheckIcon: entry['tags']['label'] == 'Completed',
          ),
    ];

    final badgeNames = [
      for (final entry in (course['course_badges'] as List? ?? []))
        if (entry['certifications'] != null) entry['certifications']['title'] as String,
    ];

    final categoryIcon = switch (category) {
      CourseCategory.compliance => Icons.verified_outlined,
      CourseCategory.aiTools => Icons.smart_toy_outlined,
      CourseCategory.productivity => Icons.record_voice_over_outlined,
      _ => Icons.school_outlined,
    };

    return EnrolledCourse(
      id: id,
      title: course['course_title'] as String,
      category: category,
      sectionId: sectionId,
      classCode: classCode,
      instructorOrBoard: lecturerName ?? 'AIEI Faculty',
      instructorIcon: categoryIcon,
      instructorIconColor: AppColors.secondary,
      imageUrl: course['image_url'] as String? ?? '',
      tags: tags,
      progressPercentage: progress,
      badgeCount: badgeNames.length,
      badgeNames: badgeNames,
      ctaButtonText: ctaOverride ?? (isCompleted ? 'Review Course / View Badge' : 'View Course'),
      isCompleted: isCompleted,
    );
  }

  @override
  Future<List<(ModuleMaterial, String)>> getCourseLessons(String courseId) async {
    // Module content is class-scoped, so resolve the demo student's own
    // class for this course before loading its modules.
    final enrollment = await _client
        .from('student_courses')
        .select('section_id')
        .eq('student_id', DemoIdentity.studentId)
        .eq('course_id', courseId)
        .maybeSingle();
    final sectionId = enrollment?['section_id'] as String?;
    if (sectionId == null) return [];

    final modules = await _client
        .from('course_modules')
        .select('id, module_sorting')
        .eq('section_id', sectionId)
        .order('module_sorting');
    final moduleIds = [for (final m in modules as List) m['id'] as String];
    if (moduleIds.isEmpty) return [];

    final materialRows = await _client
        .from('module_materials')
        .select()
        .inFilter('module_id', moduleIds)
        .order('material_sorting');
    final materials = [
      for (final row in materialRows as List) ModuleMaterial.fromMap(row as Map<String, dynamic>),
    ];

    final progressRows = await _client
        .from('student_materials')
        .select('material_id, status')
        .eq('student_id', DemoIdentity.studentId)
        .inFilter('material_id', [for (final m in materials) m.id]);
    final statusByMaterial = {
      for (final row in progressRows as List)
        row['material_id'] as String: row['status'] as String,
    };

    return [
      for (final material in materials)
        (material, statusByMaterial[material.id] ?? 'not_started'),
    ];
  }

  Color? _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  @override
  Future<CourseStats> getCourseStats() async {
    final courses = await getEnrolledCourses();
    return CourseStats(
      enrolledCourses: courses.length,
      inProgressCourses: courses.where((c) => !c.isCompleted).length,
      completedCourses: courses.where((c) => c.isCompleted).length,
      badgesEarned: courses.where((c) => c.isCompleted).length,
    );
  }

  @override
  Future<List<CriticalActionItem>> getCriticalActions({int limit = 2}) async {
    final enrollmentRows = await _client
        .from('student_courses')
        .select('section_id')
        .eq('student_id', DemoIdentity.studentId)
        .not('section_id', 'is', null);
    final sectionIds = {for (final row in enrollmentRows as List) row['section_id'] as String}.toList();
    if (sectionIds.isEmpty) return [];

    final sectionRows = await _client
        .from('course_sections')
        .select('id, courses(course_title)')
        .inFilter('id', sectionIds);
    final courseTitleBySection = {
      for (final row in sectionRows as List)
        row['id'] as String: (row['courses'] as Map<String, dynamic>?)?['course_title'] as String? ?? 'Course',
    };

    final moduleRows = await _client.from('course_modules').select('id, section_id').inFilter('section_id', sectionIds);
    final sectionByModule = {for (final row in moduleRows as List) row['id'] as String: row['section_id'] as String};
    if (sectionByModule.isEmpty) return [];

    final sessionRows = await _client.from('sessions').select('id, module_id').inFilter('module_id', sectionByModule.keys.toList());
    final moduleBySession = {for (final row in sessionRows as List) row['id'] as String: row['module_id'] as String};
    if (moduleBySession.isEmpty) return [];

    final blockRows = await _client
        .from('content_blocks')
        .select('id, block_type, block_content, session_id')
        .inFilter('session_id', moduleBySession.keys.toList())
        .inFilter('block_type', ['exam', 'assignment']);

    final submissionRows = await _client
        .from('content_block_submissions')
        .select('content_block_id')
        .eq('student_id', DemoIdentity.studentId)
        .inFilter('content_block_id', [for (final row in blockRows as List) row['id'] as String]);
    final submittedBlockIds = {for (final row in submissionRows as List) row['content_block_id'] as String};

    final items = <CriticalActionItem>[];
    for (final row in blockRows) {
      final blockId = row['id'] as String;
      if (submittedBlockIds.contains(blockId)) continue;
      final moduleId = moduleBySession[row['session_id'] as String];
      final sectionId = moduleId == null ? null : sectionByModule[moduleId];
      if (sectionId == null) continue;
      final content = row['block_content'] as Map<String, dynamic>?;
      final dueDate = DateTime.tryParse(content?['dueDate'] as String? ?? '');
      if (dueDate == null) continue;
      items.add(CriticalActionItem(
        contentBlockId: blockId,
        sectionId: sectionId,
        courseTitle: courseTitleBySection[sectionId] ?? 'Course',
        title: content?['title'] as String? ?? 'Untitled',
        type: row['block_type'] as String,
        dueDate: dueDate,
      ));
    }

    items.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return items.take(limit).toList();
  }

  @override
  Future<List<EnrolledCourse>> getCompulsoryCourses() async {
    final studentRow = await _client
        .from('students')
        .select('student_type, department')
        .eq('id', DemoIdentity.studentId)
        .maybeSingle();
    if (studentRow == null || studentRow['student_type'] != 'Internal') return [];
    final departmentName = studentRow['department'] as String?;
    if (departmentName == null) return [];

    final departmentRow =
        await _client.from('departments').select('id').eq('name', departmentName).maybeSingle();
    final departmentId = departmentRow?['id'] as String?;
    if (departmentId == null) return [];

    final mappedRows = await _client.from('department_courses').select('course_id').eq('department_id', departmentId);
    final mappedCourseIds = {for (final row in mappedRows as List) row['course_id'] as String};
    if (mappedCourseIds.isEmpty) return [];

    final enrollmentRows = await _client
        .from('student_courses')
        .select('course_id')
        .eq('student_id', DemoIdentity.studentId);
    final enrolledCourseIds = {for (final row in enrollmentRows as List) row['course_id'] as String};

    final compulsoryCourseIds = mappedCourseIds.difference(enrolledCourseIds);
    if (compulsoryCourseIds.isEmpty) return [];

    final courseRows = await _client.from('courses').select('''
      id, course_title, course_description, category, image_url,
      course_tags(tags(label, color_hex)),
      course_badges(certifications(title))
    ''').inFilter('id', compulsoryCourseIds.toList());

    final progressByCourse = {for (final id in compulsoryCourseIds) id: 0};
    return [
      for (final course in courseRows as List)
        _mapCourse(
          course as Map<String, dynamic>,
          progressByCourse,
          null,
          null,
          null,
          ctaOverride: 'Enroll Now',
        ),
    ];
  }

  @override
  Future<bool> enrollInCompulsoryCourse(String courseId) async {
    final sectionRow = await _client
        .from('course_sections')
        .select('id')
        .eq('course_id', courseId)
        .order('section_code')
        .limit(1)
        .maybeSingle();
    final sectionId = sectionRow?['id'] as String?;
    if (sectionId == null) return false;

    await _client.from('student_courses').upsert(
      {'student_id': DemoIdentity.studentId, 'course_id': courseId, 'section_id': sectionId},
      onConflict: 'student_id,course_id',
    );
    return true;
  }
}
