import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'widgets/faculty_mobile_top_bar.dart';

// ---------------------------------------------------------------------------
// ExamEditorScreen — reached via "Edit Exam" on an exam content block in the
// Syllabus editor. Placeholder only; the actual question/answer authoring
// UI isn't built yet.
// ---------------------------------------------------------------------------
class ExamEditorScreen extends StatelessWidget {
  final String examTitle;

  const ExamEditorScreen({super.key, required this.examTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: FacultyMobileTopBar(title: examTitle),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.quiz_outlined, size: 48, color: FacultyColors.onSurfaceVariant),
              const SizedBox(height: 16),
              Text('Exam editor', style: FacultyTypography.titleSm()),
              const SizedBox(height: 8),
              Text(
                'Placeholder — question and answer authoring for "$examTitle" isn\'t built yet.',
                style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
