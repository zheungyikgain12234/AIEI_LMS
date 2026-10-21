import 'package:stitch_aiei_lms/core/session/app_session.dart';
import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/presentation/widgets/skeleton.dart';
import 'package:stitch_aiei_lms/core/theme/ui_contrast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_app_settings_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_assignment_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_exam_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/content_block_submission.dart';
import 'package:stitch_aiei_lms/domain/models/grade_scale.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/widgets/portal_header.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/widgets/portal_sidebar.dart';
import 'package:stitch_aiei_lms/presentation/widgets/mobile_bottom_nav.dart';
import 'package:stitch_aiei_lms/presentation/widgets/mobile_top_bar.dart';
import 'package:stitch_aiei_lms/presentation/widgets/student_navigation.dart';

class _GradeItem {
  final String title;
  final bool isExam;
  final double weightage;
  final double maxMarks;
  final double? score; // null until graded

  const _GradeItem({
    required this.title,
    required this.isExam,
    required this.weightage,
    required this.maxMarks,
    required this.score,
  });

  /// This item's contribution to the final total (score / max * weightage).
  double? get weighted {
    if (score == null) return null;
    return maxMarks > 0 ? score! / maxMarks * weightage : 0;
  }
}

class _ClassGrades {
  final String label;
  final List<_GradeItem> items;
  final double moderatedScore;

  const _ClassGrades(this.label, this.items, this.moderatedScore);

  double get totalWeightage => items.fold(0, (sum, i) => sum + i.weightage);

  /// Same formula as the lecturer's Student Directory: weighted marks of the
  /// graded items plus the lecturer's moderation, capped at 100.
  double get total => (items.fold<double>(0, (sum, i) => sum + (i.weighted ?? 0)) + moderatedScore).clamp(0, 100);
}

class _CohortGrades {
  final String cohort;
  final List<_ClassGrades> classes;

  const _CohortGrades(this.cohort, this.classes);
}

/// Student "My Grades": cohort → class accordion, each class listing every
/// assessment's mark, then the total and letter grade at the bottom.
class MyGradesScreen extends StatefulWidget {
  const MyGradesScreen({super.key});

  @override
  State<MyGradesScreen> createState() => _MyGradesScreenState();
}

class _MyGradesScreenState extends State<MyGradesScreen> {
  final _client = Supabase.instance.client;
  late final _examRepository = SupabaseExamRepositoryImpl(_client);
  late final _assignmentRepository = SupabaseAssignmentRepositoryImpl(_client);
  late final _settingsRepository = SupabaseAppSettingsRepositoryImpl(_client);

  bool _isLoading = true;
  List<_CohortGrades> _groups = const [];
  GradeScale _gradeScale = GradeScale.defaultScale;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enrollmentRows = await _client
        .from('student_courses')
        .select('section_id, moderated_score')
        .eq('student_id', DemoIdentity.studentId);
    final moderatedBySection = <String, double>{
      for (final row in enrollmentRows as List)
        if (row['section_id'] != null) row['section_id'] as String: (row['moderated_score'] as num?)?.toDouble() ?? 0,
    };
    final sectionIds = moderatedBySection.keys.toList();

    final sectionRows = sectionIds.isEmpty
        ? const <dynamic>[]
        : await _client
            .from('course_sections')
            .select('id, section_code, cohorts(name), courses(course_code, course_title)')
            .inFilter('id', sectionIds);

    final classesByCohort = <String, List<_ClassGrades>>{};
    for (final row in sectionRows) {
      final sectionId = row['id'] as String;
      final course = row['courses'] as Map<String, dynamic>?;
      final cohort = (row['cohorts'] as Map<String, dynamic>?)?['name'] as String? ?? 'No Cohort';
      final label = '${displayCode((course?['course_code'] as String?) ?? '')} • ${displayCode(row['section_code'] as String)} — ${course?['course_title'] ?? ''}';
      final items = await _loadItems(sectionId);
      classesByCohort.putIfAbsent(cohort, () => []).add(_ClassGrades(label, items, moderatedBySection[sectionId] ?? 0));
    }

    final gradeScale = await _settingsRepository.getGradeScale();
    if (!mounted) return;
    setState(() {
      _groups = [for (final e in classesByCohort.entries) _CohortGrades(e.key, e.value)];
      _gradeScale = gradeScale;
      _isLoading = false;
    });
  }

  Future<List<_GradeItem>> _loadItems(String sectionId) async {
    final moduleRows = await _client.from('course_modules').select('id').eq('section_id', sectionId);
    final moduleIds = [for (final r in moduleRows as List) r['id'] as String];
    if (moduleIds.isEmpty) return const [];
    final sessionRows = await _client.from('sessions').select('id').inFilter('module_id', moduleIds);
    final sessionIds = [for (final r in sessionRows as List) r['id'] as String];
    if (sessionIds.isEmpty) return const [];
    final blockRows = await _client
        .from('content_blocks')
        .select('id, block_type, block_content')
        .inFilter('session_id', sessionIds)
        .inFilter('block_type', ['exam', 'assignment', 'physicalExam', 'physicalAssignment']);
    if ((blockRows as List).isEmpty) return const [];

    final submissionRows = await _client
        .from('content_block_submissions')
        .select()
        .eq('student_id', DemoIdentity.studentId)
        .inFilter('content_block_id', [for (final r in blockRows) r['id'] as String]);
    final gradedByBlock = <String, ContentBlockSubmission>{
      for (final r in submissionRows as List)
        if ((r as Map<String, dynamic>)['status'] == 'graded')
          r['content_block_id'] as String: ContentBlockSubmission.fromMap(r),
    };

    final items = <_GradeItem>[];
    var quizNumber = 0;
    var assignmentNumber = 0;
    for (final r in blockRows) {
      final id = r['id'] as String;
      final type = r['block_type'] as String;
      final content = r['block_content'] as Map<String, dynamic>? ?? {};
      final isExam = type == 'exam' || type == 'physicalExam';
      final physical = type.startsWith('physical');
      final title = (content['title'] as String?)?.trim();
      final fallback = isExam ? 'Quiz ${++quizNumber}' : 'Assignment ${++assignmentNumber}';
      final maxMarks = physical
          ? (content['maxMarks'] as num?)?.toDouble() ?? 0.0
          : isExam
              ? await _examRepository.getTotalMarks(id)
              : await _assignmentRepository.getTotalMarks(id);
      items.add(_GradeItem(
        title: (title != null && title.isNotEmpty) ? title : fallback,
        isExam: isExam,
        weightage: (content['weightage'] as num?)?.toDouble() ?? 0.0,
        maxMarks: maxMarks,
        score: gradedByBlock[id] == null ? null : (gradedByBlock[id]!.totalScore ?? 0),
      ));
    }
    return items;
  }

  static String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 900;
    final content = _isLoading
        ? const SkeletonBody()
        : SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 16 : 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('My Grades', style: AppTypography.headlineLg()),
                    const SizedBox(height: 6),
                    Text(
                      'Your marks for every assessment, grouped by cohort and class.',
                      style: AppTypography.bodyMd(),
                    ),
                    const SizedBox(height: 24),
                    if (_groups.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text('You are not enrolled in any class yet.', style: AppTypography.bodyMd()),
                      )
                    else
                      for (final g in _groups) ...[_cohortTile(g), const SizedBox(height: 12)],
                  ],
                ),
              ),
            ),
          );

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const MobileTopBar(),
        bottomNavigationBar: MobileBottomNav(
          selectedIndex: 2,
          onTap: (i) => navigateStudentTab(context, i, current: 2),
        ),
        body: content,
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const PortalHeader(),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PortalSidebar(
            selectedIndex: 2,
            onDestinationSelected: (i) => navigateStudentTab(context, i, current: 2),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _cohortTile(_CohortGrades group) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Material(
          type: MaterialType.transparency,
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Row(
              children: [
                const Icon(Icons.groups_outlined, size: 18, color: AppColors.secondary),
                const SizedBox(width: 8),
                Expanded(child: Text(group.cohort, style: AppTypography.labelLg())),
              ],
            ),
            children: [for (final c in group.classes) _classTile(c)],
          ),
        ),
      ),
    );
  }

  Widget _classTile(_ClassGrades grades) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
      child: Container(
        decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: Material(
            type: MaterialType.transparency,
            child: ExpansionTile(
              initiallyExpanded: true,
              title: Row(
                children: [
                  const Icon(Icons.school_outlined, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      grades.label,
                      style: AppTypography.bodyMd(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              children: [
                for (final item in grades.items) _itemRow(item),
                if (grades.moderatedScore != 0) _summaryRow('Moderation', '+${_fmt(grades.moderatedScore)}'),
                _totalRow(grades),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _itemRow(_GradeItem item) {
    final graded = item.score != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: UiContrast.divider))),
      child: Row(
        children: [
          Icon(
            item.isExam ? Icons.quiz_outlined : Icons.assignment_outlined,
            size: 18,
            color: item.isExam ? AppColors.primary : AppColors.secondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTypography.bodyMd(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${item.isExam ? 'Quiz' : 'Assignment'} • ${_fmt(item.weightage)}% of grade',
                  style: AppTypography.labelSm(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                graded ? '${_fmt(item.score!)} / ${_fmt(item.maxMarks)}' : 'Not graded',
                style: AppTypography.bodyMd(color: graded ? AppColors.onSurface : AppColors.outline)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              if (graded) Text('${_fmt(item.weighted!)} / ${_fmt(item.weightage)}', style: AppTypography.labelSm()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: UiContrast.divider))),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.bodyMd(color: AppColors.onSurface))),
          Text(value, style: AppTypography.bodyMd(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _totalRow(_ClassGrades grades) {
    final total = grades.total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('Total', style: AppTypography.labelLg().copyWith(fontWeight: FontWeight.w700)),
          ),
          Text(
            '${_fmt(total)} / 100',
            style: AppTypography.labelLg().copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: BorderRadius.circular(8)),
            child: Text(
              _gradeScale.letterFor(total),
              style: AppTypography.labelLg(color: AppColors.onSecondaryContainer).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
