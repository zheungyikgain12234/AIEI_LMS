import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/core/utils/date_format.dart';
import 'widgets/faculty_mobile_top_bar.dart';

// ---------------------------------------------------------------------------
// AssignmentEditorScreen — reached via "Edit Assignment" on an assignment
// content block in the Syllabus editor. Shows the assignment's info
// (description, instructions, due date) set from the "Add Content" form;
// the rubric/submission-settings authoring UI isn't built yet.
// ---------------------------------------------------------------------------
class AssignmentEditorScreen extends StatelessWidget {
  final String assignmentTitle;
  final String? description;
  final String? instructions;
  final DateTime? dueDate;

  const AssignmentEditorScreen({
    super.key,
    required this.assignmentTitle,
    this.description,
    this.instructions,
    this.dueDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: FacultyMobileTopBar(title: assignmentTitle),
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
                  _infoCard(),
                  const SizedBox(height: 20),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.assignment_outlined, size: 48, color: FacultyColors.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text('Assignment editor', style: FacultyTypography.titleSm()),
                          const SizedBox(height: 8),
                          Text(
                            'Placeholder — rubric and submission settings for "$assignmentTitle" aren\'t built yet.',
                            style: FacultyTypography.bodySm(color: FacultyColors.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard() {
    final hasAnyInfo = (description?.isNotEmpty ?? false) || (instructions?.isNotEmpty ?? false) || dueDate != null;
    if (!hasAnyInfo) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dueDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: FacultyColors.secondaryContainer, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_outlined, size: 14, color: FacultyColors.onSecondaryContainer),
                  const SizedBox(width: 6),
                  Text('Due ${formatDueDate(dueDate!)}', style: FacultyTypography.labelXs(color: FacultyColors.onSecondaryContainer)),
                ],
              ),
            ),
          if (description?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Text('Description', style: FacultyTypography.labelMd(color: FacultyColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(description!, style: FacultyTypography.bodySm(color: FacultyColors.onSurface)),
          ],
          if (instructions?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Text('Instructions', style: FacultyTypography.labelMd(color: FacultyColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(instructions!, style: FacultyTypography.bodySm(color: FacultyColors.onSurface)),
          ],
        ],
      ),
    );
  }
}
