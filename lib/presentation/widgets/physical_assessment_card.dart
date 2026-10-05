import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/domain/models/content_block.dart';

/// Read-only view of a physical (paper-based) exam or assignment block: its
/// name, due date/time and description. There is nothing to submit — the
/// lecturer imports marks afterwards.
class PhysicalAssessmentCard extends StatelessWidget {
  final ContentBlock block;

  const PhysicalAssessmentCard({super.key, required this.block});

  static String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final isExam = block.type == ContentBlockType.physicalExam;
    final due = block.dueDate;
    final fallback = isExam ? 'Physical Exam' : 'Physical Assignment';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(block.title?.isNotEmpty == true ? block.title! : fallback, style: FacultyTypography.bodySm(color: FacultyColors.onSurface)),
        Text(
          due == null
              ? 'Paper-based'
              : 'Paper-based • Due ${due.year}-${_two(due.month)}-${_two(due.day)} ${_two(due.hour)}:${_two(due.minute)}',
          style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant),
        ),
        if (block.description?.isNotEmpty == true) ...[
          const SizedBox(height: 2),
          Text(block.description!, style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant)),
        ],
      ],
    );
  }
}
