import 'package:stitch_aiei_lms/data/repositories/supabase_programmes_repository_impl.dart';
import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/data/repositories/student_schedule_conflicts.dart';
import 'package:stitch_aiei_lms/domain/repositories/lecturers_repository.dart' show ScheduleConflictException;
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
      course_badges(badge_id, certifications(title))
    ''');

    final enrollmentRows = await _client
        .from('student_courses')
        .select('course_id, section_id')
        .eq('student_id', DemoIdentity.studentId);
    // Module content is class-scoped: a student's course content is
    // whichever class (`section_id`) they're enrolled in for that course,
    // which may be null if they haven't been assigned to a class yet.
    // Badges the student has actually been granted (not revoked), per course.
    final awardRows = await _client
        .from('badge_awards')
        .select('course_id, badge_id')
        .eq('student_id', DemoIdentity.studentId)
        .eq('is_revoked', false);
    final earnedBadgeIdsByCourse = <String, Set<String>>{};
    for (final row in awardRows as List) {
      earnedBadgeIdsByCourse.putIfAbsent(row['course_id'] as String, () => {}).add(row['badge_id'] as String);
    }
    // Badges the student qualified for that are still waiting for an admin.
    final pendingRows = await _client
        .from('badge_award_requests')
        .select('course_id, badge_id')
        .eq('student_id', DemoIdentity.studentId)
        .eq('status', 'pending');
    final pendingBadgeIdsByCourse = <String, Set<String>>{};
    for (final row in pendingRows as List) {
      pendingBadgeIdsByCourse.putIfAbsent(row['course_id'] as String, () => {}).add(row['badge_id'] as String);
    }
    final enrollments = <({String courseId, String? sectionId})>[
      for (final row in enrollmentRows as List) (courseId: row['course_id'] as String, sectionId: row['section_id'] as String?),
    ];
    final enrolledCourseIds = {for (final e in enrollments) e.courseId};
    // Progress is never read from the stored `student_courses.progress_percentage`
    // column — it's recomputed live from actual gradebook state every time,
    // the same way the lecturer's Student Directory does, so the two views
    // can never disagree and adding/removing assessments or grades is
    // reflected immediately without needing a separate sync step.
    final liveProgressBySection = await _liveProgressBySection({for (final e in enrollments) if (e.sectionId != null) e.sectionId!});

    final sectionIds = {for (final e in enrollments) if (e.sectionId != null) e.sectionId!}.toList();
    final sectionRows = sectionIds.isEmpty
        ? <dynamic>[]
        : await _client
            .from('course_sections')
            .select('id, section_code, lecturers(name), semesters(name)')
            .inFilter('id', sectionIds);
    final lecturerNameBySection = <String, String>{
      for (final row in sectionRows)
        if (row['lecturers'] != null) row['id'] as String: row['lecturers']['name'] as String,
    };
    final classCodeBySection = <String, String>{
      for (final row in sectionRows) row['id'] as String: displayCode(row['section_code'] as String),
    };
    final semesterNameBySection = <String, String>{
      for (final row in sectionRows)
        if (row['semesters'] != null) row['id'] as String: row['semesters']['name'] as String,
    };

    // One card per enrollment: the same course in two different semesters
    // shows as two classes, each with its own progress.
    final programmeNamesByCourse = await SupabaseProgrammesRepositoryImpl(_client).getProgrammeNamesByCourse();
    final courseById = {for (final course in courseRows as List) course['id'] as String: course as Map<String, dynamic>};
    for (final course in courseById.values) {
      course['programme_names'] = programmeNamesByCourse[course['id']] ?? const <String>[];
    }
    return [
      for (final e in enrollments)
        if (courseById[e.courseId] != null)
          _mapCourse(
            courseById[e.courseId]!,
            {e.courseId: e.sectionId == null ? 0 : (liveProgressBySection[e.sectionId] ?? 0)},
            e.sectionId,
            lecturerNameBySection[e.sectionId],
            classCodeBySection[e.sectionId],
            semesterNameBySection[e.sectionId],
            earnedBadgeIds: earnedBadgeIdsByCourse[e.courseId] ?? const {},
            pendingBadgeIds: pendingBadgeIdsByCourse[e.courseId] ?? const {},
          ),
    ];
  }

  /// Computes each class's progress (keyed by section id) live as
  /// `graded exam/assignment blocks ÷ total exam/assignment blocks` for the
  /// demo student's own section — the same calculation the lecturer's
  /// Student Directory uses — instead of trusting a stored/denormalized
  /// column that can go stale the moment an assessment is added, removed,
  /// or (un)graded.
  Future<Map<String, int>> _liveProgressBySection(Set<String> sectionIdSet) async {
    if (sectionIdSet.isEmpty) return {};
    final sectionIds = sectionIdSet.toList();

    final moduleRows = await _client.from('course_modules').select('id, section_id').inFilter('section_id', sectionIds);
    final sectionByModule = {for (final row in moduleRows as List) row['id'] as String: row['section_id'] as String};
    if (sectionByModule.isEmpty) return {for (final id in sectionIds) id: 0};

    final sessionRows = await _client.from('sessions').select('id, module_id').inFilter('module_id', sectionByModule.keys.toList());
    final moduleBySession = {for (final row in sessionRows as List) row['id'] as String: row['module_id'] as String};
    if (moduleBySession.isEmpty) return {for (final id in sectionIds) id: 0};

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
    if (sectionByBlock.isEmpty) return {for (final id in sectionIds) id: 0};

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
      for (final sectionId in sectionIds)
        sectionId: () {
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
    String? classCode,
    String? semester, {
    String? ctaOverride,
    Set<String> earnedBadgeIds = const {},
    Set<String> pendingBadgeIds = const {},
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

    final badges = [
      for (final entry in (course['course_badges'] as List? ?? []))
        if (entry['certifications'] != null)
          CourseBadgeInfo(name: entry['certifications']['title'] as String, earned: earnedBadgeIds.contains(entry['badge_id'] as String?), pendingApproval: pendingBadgeIds.contains(entry['badge_id'] as String?)),
    ];
    final badgeNames = [for (final b in badges) b.name];
    final programmeNames = [for (final name in (course['programme_names'] as List? ?? const [])) name as String];

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
      semester: semester,
      instructorOrBoard: lecturerName ?? 'AIEI Lecturer',
      instructorIcon: categoryIcon,
      instructorIconColor: AppColors.secondary,
      imageUrl: course['image_url'] as String? ?? '',
      tags: tags,
      progressPercentage: progress,
      badgeCount: badgeNames.length,
      badgeNames: badgeNames,
      badges: badges,
      programmeNames: programmeNames,
      ctaButtonText: ctaOverride ?? (isCompleted ? 'Review Course' : 'View Course'),
      isCompleted: isCompleted,
      isEnrolled: ctaOverride == null,
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
        .order('enrolled_at', ascending: false)
        .limit(1)
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
  Future<CourseStats> getCourseStats({List<EnrolledCourse>? courses}) async {
    courses ??= await getEnrolledCourses();
    // Real count from `badge_awards` (excluding revoked), matching the
    // "Total Badges Earned" figure on the My Badges page — previously this
    // just counted completed courses, which drifted from the actual badge
    // count whenever a completed course had zero or more than one badge
    // configured on it.
    final badgeRows = await _client
        .from('badge_awards')
        .select('id')
        .eq('student_id', DemoIdentity.studentId)
        .eq('is_revoked', false);
    return CourseStats(
      enrolledCourses: courses.length,
      inProgressCourses: courses.where((c) => !c.isCompleted).length,
      completedCourses: courses.where((c) => c.isCompleted).length,
      badgesEarned: (badgeRows as List).length,
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
        .select('student_type, role')
        .eq('id', DemoIdentity.studentId)
        .maybeSingle();
    if (studentRow == null || studentRow['student_type'] != 'Internal') return [];
    final roleName = studentRow['role'] as String?;
    if (roleName == null) return [];

    final roleRow = await _client.from('roles').select('id').eq('name', roleName).maybeSingle();
    final roleId = roleRow?['id'] as String?;
    if (roleId == null) return [];

    final mappedRows = await _client.from('role_courses').select('course_id').eq('role_id', roleId);
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
      course_badges(badge_id, certifications(title))
    ''').inFilter('id', compulsoryCourseIds.toList());

    final progressByCourse = {for (final id in compulsoryCourseIds) id: 0};
    final programmeNamesByCourse = await SupabaseProgrammesRepositoryImpl(_client).getProgrammeNamesByCourse();
    for (final course in courseRows as List) {
      (course as Map<String, dynamic>)['programme_names'] = programmeNamesByCourse[course['id']] ?? const <String>[];
    }
    return [
      for (final course in courseRows as List)
        _mapCourse(
          course as Map<String, dynamic>,
          progressByCourse,
          null,
          null,
          null,
          null,
          ctaOverride: 'Enroll Now',
        ),
    ];
  }

  @override
  Future<bool> enrollInCompulsoryCourse(String courseId, {String? semesterId}) async {
    var query = _client.from('course_sections').select('id, semester_id').eq('course_id', courseId);
    if (semesterId != null) query = query.eq('semester_id', semesterId);
    final sectionRow = await query.order('section_code').limit(1).maybeSingle();
    final sectionId = sectionRow?['id'] as String?;
    if (sectionId == null) return false;

    // One class per course per semester: if the student already has a class of
    // this course in this semester, leave it alone instead of moving them. A
    // class in a different semester is fine and is added alongside.
    final targetSemester = sectionRow?['semester_id'] as String?;
    final existing = await _client
        .from('student_courses')
        .select('section_id, course_sections(semester_id)')
        .eq('student_id', DemoIdentity.studentId)
        .eq('course_id', courseId);
    final alreadyInSemester = (existing as List).any((row) {
      final other = row['course_sections'] as Map<String, dynamic>?;
      return row['section_id'] == sectionId || other == null || other['semester_id'] == targetSemester;
    });
    if (!alreadyInSemester) {
      // Refuse a class that overlaps one the student already attends.
      final clashes = await findStudentScheduleConflicts(_client, studentIds: [DemoIdentity.studentId], sectionId: sectionId);
      final clash = clashes[DemoIdentity.studentId];
      if (clash != null) {
        throw ScheduleConflictException('This class clashes with a class you already attend: ${clash.join("; ")}. '
            'You can\x27t enrol in two classes at the same time.');
      }
      await _client.from('student_courses').insert({'student_id': DemoIdentity.studentId, 'course_id': courseId, 'section_id': sectionId});
    }
    return true;
  }

  @override
  Future<List<EnrollableClass>> getEnrollableClasses(String courseId, {String? semesterId}) async {
    var query = _client
        .from('course_sections')
        .select('id, section_code, semester_id, day_of_week, start_time, end_time, start_date, end_date, location, status, semesters(name)')
        .eq('course_id', courseId);
    if (semesterId != null) query = query.eq('semester_id', semesterId);
    final sections = (await query.order('section_code') as List).cast<Map<String, dynamic>>().where((s) => s['status'] != 'cancelled').toList();
    if (sections.isEmpty) return [];

    final existing = await _client
        .from('student_courses')
        .select('section_id, course_sections(semester_id)')
        .eq('student_id', DemoIdentity.studentId)
        .eq('course_id', courseId);
    final semestersTaken = {
      for (final row in existing as List) (row['course_sections'] as Map<String, dynamic>?)?['semester_id'] as String?,
    };

    final result = <EnrollableClass>[];
    for (final s in sections) {
      if (semestersTaken.contains(s['semester_id'] as String?)) continue;
      final clashes = await findStudentScheduleConflicts(_client, studentIds: [DemoIdentity.studentId], sectionId: s['id'] as String);
      if (clashes.isNotEmpty) continue;
      final day = s['day_of_week'] as String?;
      final start = s['start_time'] as String?;
      final end = s['end_time'] as String?;
      result.add(EnrollableClass(
        sectionId: s['id'] as String,
        sectionCode: s['section_code'] as String,
        semesterName: (s['semesters'] as Map<String, dynamic>?)?['name'] as String?,
        scheduleText: day != null && start != null && end != null
            ? '$day ${start.substring(0, 5)}–${end.substring(0, 5)}'
            : 'Schedule TBD',
        location: s['location'] as String?,
      ));
    }
    return result;
  }

  @override
  Future<void> enrollInSection(String courseId, String sectionId) async {
    final clashes = await findStudentScheduleConflicts(_client, studentIds: [DemoIdentity.studentId], sectionId: sectionId);
    final clash = clashes[DemoIdentity.studentId];
    if (clash != null) {
      throw ScheduleConflictException('This class clashes with a class you already attend: ${clash.join("; ")}.');
    }
    await _client.from('student_courses').insert({'student_id': DemoIdentity.studentId, 'course_id': courseId, 'section_id': sectionId});
  }
}
