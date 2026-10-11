import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'faculty_sidebar.dart' show FacultyNavDestination;

/// Shared mobile (< 700px) bottom tab bar for the Faculty Portal's root
/// screens (My Courses / Grading / Students) — mirrors [FacultySidebar] but
/// as a bottom nav, matching the Stitch mobile mockups.
class FacultyMobileBottomNav extends StatelessWidget {
  final FacultyNavDestination selected;
  final ValueChanged<FacultyNavDestination> onDestinationSelected;

  const FacultyMobileBottomNav({
    super.key,
    required this.selected,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: const BoxDecoration(
          color: FacultyColors.surfaceContainerLowest,
          boxShadow: [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, -1))],
        ),
        child: Row(
          children: [
            Expanded(
              child: _item(
                icon: Icons.menu_book_outlined,
                label: 'My Courses',
                dest: FacultyNavDestination.myCourses,
              ),
            ),
            Expanded(
              child: _item(
                icon: Icons.assignment_turned_in_outlined,
                label: 'Grading & Submissions',
                dest: FacultyNavDestination.gradingAndSubmissions,
              ),
            ),
            Expanded(
              child: _item(
                icon: Icons.meeting_room_outlined,
                label: 'Physical Class Attendance',
                dest: FacultyNavDestination.physicalClassAttendance,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item({required IconData icon, required String label, required FacultyNavDestination dest}) {
    final active = selected == dest;
    final color = active ? FacultyColors.primary : FacultyColors.onSurfaceVariant;
    return InkWell(
      onTap: () => onDestinationSelected(dest),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: FacultyTypography.labelXs(color: color).copyWith(fontWeight: active ? FontWeight.w700 : FontWeight.w400, fontSize: 10, height: 1.1),
            ),
          ),
        ],
      ),
    );
  }
}
