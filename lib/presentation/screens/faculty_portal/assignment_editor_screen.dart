import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'widgets/faculty_mobile_top_bar.dart';

// ---------------------------------------------------------------------------
// AssignmentEditorScreen — reached via "Edit Assignment" on an assignment
// content block in the Syllabus editor. Placeholder only; the actual
// instructions/rubric/submission-settings authoring UI isn't built yet.
// ---------------------------------------------------------------------------
class AssignmentEditorScreen extends StatelessWidget {
  final String assignmentTitle;

  const AssignmentEditorScreen({super.key, required this.assignmentTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: FacultyMobileTopBar(title: assignmentTitle),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.assignment_outlined, size: 48, color: FacultyColors.onSurfaceVariant),
              const SizedBox(height: 16),
              Text('Assignment editor', style: FacultyTypography.titleSm()),
              const SizedBox(height: 8),
              Text(
                'Placeholder — instructions and submission settings for "$assignmentTitle" aren\'t built yet.',
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
