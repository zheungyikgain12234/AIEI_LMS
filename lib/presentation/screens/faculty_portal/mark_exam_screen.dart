import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_students_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_submission_grading_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/content_block_submission.dart';
import 'package:stitch_aiei_lms/domain/models/roster_student.dart';
import 'exam_grading_screen.dart';
import 'widgets/faculty_mobile_top_bar.dart';

// ---------------------------------------------------------------------------
// MarkExamScreen — reached via "Mark Exam" on an exam content block in the
// Syllabus editor. Shows the class roster with each student's submission
// status; tapping a student opens their answers for grading on
// ExamGradingScreen.
// ---------------------------------------------------------------------------
class MarkExamScreen extends StatefulWidget {
  final String contentBlockId;
  final String sectionId;
  final String title;

  const MarkExamScreen({super.key, required this.contentBlockId, required this.sectionId, required this.title});

  @override
  State<MarkExamScreen> createState() => _MarkExamScreenState();
}

class _MarkExamScreenState extends State<MarkExamScreen> {
  final _rosterRepository = SupabaseAdminStudentsRepositoryImpl(Supabase.instance.client);
  final _gradingRepository = SupabaseSubmissionGradingRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  List<RosterStudent> _roster = const [];
  Map<String, ContentBlockSubmission> _submissions = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final roster = await _rosterRepository.getSectionRoster(widget.sectionId);
    final submissions = await _gradingRepository.getRosterSubmissions(widget.contentBlockId);
    if (!mounted) return;
    setState(() {
      _roster = roster;
      _submissions = submissions;
      _isLoading = false;
    });
  }

  Future<void> _openStudent(RosterStudent s) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExamGradingScreen(contentBlockId: widget.contentBlockId, studentId: s.studentId, studentName: s.name),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: FacultyMobileTopBar(title: widget.title),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Mark Exam', style: FacultyTypography.headlineMd()),
                  const SizedBox(height: 4),
                  Text('Select a student to grade their answers.', style: FacultyTypography.bodySm()),
                  const SizedBox(height: 16),
                  if (_roster.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(color: FacultyColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: Text('No students enrolled in this class yet.', style: FacultyTypography.bodyMd()),
                    )
                  else
                    for (final s in _roster) _studentRow(s),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _studentRow(RosterStudent s) {
    final submission = _submissions[s.studentId];
    final (statusLabel, statusColor, statusBg) = _statusFor(submission);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _openStudent(s),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: FacultyColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: FacultyColors.surfaceContainerHigh, shape: BoxShape.circle),
                child: Icon(Icons.person, color: FacultyColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: FacultyTypography.bodyMd(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600)),
                    Text(s.studentCode, style: FacultyTypography.labelXs()),
                  ],
                ),
              ),
              if (submission?.totalScore != null) ...[
                Text(_formatScore(submission!.totalScore!), style: FacultyTypography.titleSm(color: FacultyColors.primary)),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                child: Text(statusLabel, style: FacultyTypography.labelXs(color: statusColor).copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: FacultyColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  String _formatScore(double score) => score.toStringAsFixed(score.truncateToDouble() == score ? 0 : 1);

  (String, Color, Color) _statusFor(ContentBlockSubmission? submission) {
    if (submission == null) return ('Not submitted', FacultyColors.onSurfaceVariant, FacultyColors.surfaceContainer);
    if (submission.isGraded) return ('Graded', FacultyColors.primary, FacultyColors.secondaryContainer);
    return ('Needs grading', FacultyColors.error, FacultyColors.errorContainer);
  }
}
