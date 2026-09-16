import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/domain/models/enrolled_course.dart';
import 'package:stitch_aiei_lms/domain/models/course_stats.dart';
import 'package:stitch_aiei_lms/domain/models/module_material.dart';
import 'package:stitch_aiei_lms/domain/models/urgent_notice.dart';
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
      course_modules(id, module_sorting, module_materials(id, material_name, material_sorting))
    ''');

    final enrollmentRows = await _client
        .from('student_courses')
        .select('course_id, progress_percentage')
        .eq('student_id', DemoIdentity.studentId);
    final progressByCourse = <String, int>{
      for (final row in enrollmentRows as List)
        row['course_id'] as String: row['progress_percentage'] as int,
    };

    final materialIds = <String>[
      for (final course in courseRows as List)
        for (final module in (course['course_modules'] as List? ?? []))
          for (final material in (module['module_materials'] as List? ?? []))
            material['id'] as String,
    ];
    final progressRows = materialIds.isEmpty
        ? <dynamic>[]
        : await _client
            .from('student_materials')
            .select('material_id, status')
            .eq('student_id', DemoIdentity.studentId)
            .inFilter('material_id', materialIds);
    final completedMaterialIds = {
      for (final row in progressRows)
        if (row['status'] == 'completed') row['material_id'] as String,
    };

    return [
      for (final course in courseRows)
        if (progressByCourse.containsKey(course['id']))
          _mapCourse(course, progressByCourse, completedMaterialIds),
    ];
  }

  EnrolledCourse _mapCourse(
    Map<String, dynamic> course,
    Map<String, int> progressByCourse,
    Set<String> completedMaterialIds,
  ) {
    final id = course['id'] as String;
    final category = CourseCategory.fromKey(course['category'] as String);
    final progress = progressByCourse[id] ?? 0;
    final isCompleted = progress >= 100;

    final modules = (course['course_modules'] as List? ?? [])
      ..sort((a, b) => (a['module_sorting'] as int).compareTo(b['module_sorting'] as int));
    final materials = <Map<String, dynamic>>[
      for (final module in modules)
        for (final material in (module['module_materials'] as List? ?? []))
          material as Map<String, dynamic>,
    ]..sort((a, b) => (a['material_sorting'] as int).compareTo(b['material_sorting'] as int));
    final totalLessons = materials.length;
    final completedLessons =
        materials.where((m) => completedMaterialIds.contains(m['id'])).length;
    final nextMaterial = materials.firstWhere(
      (m) => !completedMaterialIds.contains(m['id']),
      orElse: () => const {},
    );

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
      instructorOrBoard: 'AIEI Faculty',
      instructorIcon: categoryIcon,
      instructorIconColor: AppColors.secondary,
      imageUrl: course['image_url'] as String? ?? '',
      tags: tags,
      progressPercentage: progress,
      completedLessons: completedLessons,
      totalLessons: totalLessons,
      nextLessonOrStatus: isCompleted
          ? 'All modules completed'
          : (nextMaterial.isEmpty
              ? 'Get started'
              : 'Next: ${nextMaterial['material_name']}'),
      unlockBadgeTitle: 'Unlocks: Course Completion Badge',
      unlockBadgeIcon: Icons.military_tech_outlined,
      deadlineDays: 30,
      ctaButtonText: isCompleted ? 'Review Course / View Badge' : 'Continue Course',
      isCompleted: isCompleted,
    );
  }

  @override
  Future<List<(ModuleMaterial, String)>> getCourseLessons(String courseId) async {
    final modules = await _client
        .from('course_modules')
        .select('id, module_sorting')
        .eq('course_id', courseId)
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
      completedLessons: courses.fold(0, (sum, c) => sum + c.completedLessons),
      totalLessons: courses.fold(0, (sum, c) => sum + c.totalLessons),
      badgesEarned: courses.where((c) => c.isCompleted).length,
    );
  }

  @override
  Future<UrgentNotice?> getUrgentNotice() async {
    final courses = await getEnrolledCourses();
    if (courses.isEmpty) return null;
    final urgent = courses
        .where((c) => !c.isCompleted)
        .fold<EnrolledCourse?>(null, (best, c) =>
            best == null || c.deadlineDays < best.deadlineDays ? c : best);
    if (urgent == null) return null;

    return UrgentNotice(
      title: urgent.title,
      subtitle: urgent.nextLessonOrStatus,
      badgeText: 'Critical Action',
      dueText: 'Due in ${urgent.deadlineDays} Days',
      progressPercentage: urgent.progressPercentage,
      ctaLabel: 'Resume',
    );
  }
}
