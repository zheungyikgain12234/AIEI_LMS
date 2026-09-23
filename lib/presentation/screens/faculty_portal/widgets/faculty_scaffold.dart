import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'faculty_header.dart';
import 'faculty_sidebar.dart';

/// Shared header + sidebar shell used by every Faculty Portal screen, mirroring
/// the layout markup repeated across all Stitch faculty mockups.
class FacultyScaffold extends StatelessWidget {
  final FacultyNavDestination selected;
  final ValueChanged<FacultyNavDestination> onDestinationSelected;
  final Widget body;
  final int? pendingCount;

  const FacultyScaffold({
    super.key,
    required this.selected,
    required this.onDestinationSelected,
    required this.body,
    this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: const FacultyHeader(),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FacultySidebar(
            selected: selected,
            pendingCount: pendingCount,
            onDestinationSelected: onDestinationSelected,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1600),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: body,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
