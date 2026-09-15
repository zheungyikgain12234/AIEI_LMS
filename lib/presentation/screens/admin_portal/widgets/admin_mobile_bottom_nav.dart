import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';

/// The 4 mobile bottom-nav destinations for the Admin Portal. This is
/// distinct from [AdminNavDestination] (used by the desktop sidebar) because
/// on mobile "Course Enrollment" splits into two separate tabs — Cohorts
/// (`CourseEnrollmentScreen`) and Enroll (`EnrollStudentsScreen`) — matching
/// the Stitch mobile mockups' bottom nav exactly.
enum AdminMobileTab { lecturers, students, cohorts, enroll }

/// Shared mobile (< 700px) bottom tab bar for the Admin Portal's root
/// screens (Lecturers / Students / Cohorts / Enroll).
class AdminMobileBottomNav extends StatelessWidget {
  final AdminMobileTab selected;
  final ValueChanged<AdminMobileTab> onTap;

  const AdminMobileBottomNav({super.key, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: const BoxDecoration(
          color: AdminColors.surfaceContainerLowest,
          boxShadow: [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, -1))],
        ),
        child: Row(
          children: [
            Expanded(child: _item(Icons.badge_outlined, 'Lecturers', AdminMobileTab.lecturers)),
            Expanded(child: _item(Icons.school_outlined, 'Students', AdminMobileTab.students)),
            Expanded(child: _item(Icons.hub_outlined, 'Cohorts', AdminMobileTab.cohorts)),
            Expanded(child: _item(Icons.how_to_reg_outlined, 'Enroll', AdminMobileTab.enroll)),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, AdminMobileTab tab) {
    final active = selected == tab;
    final color = active ? AdminColors.secondary : AdminColors.onSurfaceVariant;
    return InkWell(
      onTap: () => onTap(tab),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: AdminTypography.labelSm(color: color).copyWith(fontWeight: active ? FontWeight.w700 : FontWeight.w400),
          ),
        ],
      ),
    );
  }
}
