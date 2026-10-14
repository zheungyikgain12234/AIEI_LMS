import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'admin_nav.dart';
import 'admin_sidebar.dart';
import 'pending_syllabus_badge.dart';

/// The mobile "More" sheet — every entry of the desktop sidebar (same
/// sections, same labels, same order) except the three that already have
/// their own [AdminMobileBottomNav] tab (Lecturers / Students / Courses).
Future<void> showAdminMoreMenu(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AdminColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: AdminColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(9999)),
                ),
              ),
              _section('MASTER DATA'),
              _tile(context, sheetContext, Icons.hub_outlined, 'Manage Cohorts', AdminNavDestination.manageCohorts),
              _tile(context, sheetContext, Icons.apartment_outlined, 'Manage Student Depts', AdminNavDestination.manageDepartments),
              _tile(context, sheetContext, Icons.workspace_premium_outlined, 'Manage Programmes', AdminNavDestination.manageProgrammes),
              _tile(context, sheetContext, Icons.alt_route_outlined, 'Manage Programme Tracks', AdminNavDestination.manageProgramTracks),
              _tile(context, sheetContext, Icons.work_outline, 'Manage Roles', AdminNavDestination.manageRoles),
              _tile(context, sheetContext, Icons.corporate_fare_outlined, 'Manage Lecturer Depts', AdminNavDestination.manageLecturerDepartments),
              _tile(context, sheetContext, Icons.psychology_outlined, 'Manage Specialisation', AdminNavDestination.manageSpecializations),
              _tile(context, sheetContext, Icons.sell_outlined, 'Manage Course Tags', AdminNavDestination.manageCourseTags),
              _tile(context, sheetContext, Icons.military_tech_outlined, 'Manage Badges', AdminNavDestination.manageBadgeCatalog),
              _tile(context, sheetContext, Icons.view_module_outlined, 'Manage Module Lists', AdminNavDestination.manageModuleLists),
              _tile(context, sheetContext, Icons.fact_check_outlined, 'Manage Syllabi', AdminNavDestination.manageSyllabi),
              _section('ACADEMIC OPERATIONS'),
              _tile(context, sheetContext, Icons.school_outlined, 'Programme ↔ Course Mapping', AdminNavDestination.programmeCourseMapping),
              _tile(context, sheetContext, Icons.alt_route, 'Track ↔ Course Mapping', AdminNavDestination.trackCourseMapping),
              _tile(context, sheetContext, Icons.swap_horiz_outlined, 'Role ↔ Course Mapping', AdminNavDestination.roleCourseMapping),
              _tile(context, sheetContext, Icons.account_tree_outlined, 'Department ↔ Course Mapping', AdminNavDestination.departmentCourseMapping),
              _tile(context, sheetContext, Icons.psychology_alt_outlined, 'Specialisation ↔ Course Mapping', AdminNavDestination.specializationCourseMapping),
              _tile(context, sheetContext, Icons.military_tech_outlined, 'Badge ↔ Course Mapping', AdminNavDestination.badgeCourseMapping),
              _tile(context, sheetContext, Icons.event_note_outlined, 'Manage Classes', AdminNavDestination.manageClasses),
              _tile(context, sheetContext, Icons.military_tech_outlined, 'Manage Badge Award', AdminNavDestination.manageBadges),
              _section('SYSTEM'),
              _tile(context, sheetContext, Icons.admin_panel_settings_outlined, 'Manage Admin', AdminNavDestination.manageAdmins),
              _tile(context, sheetContext, Icons.settings_outlined, 'Settings', AdminNavDestination.settings),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _section(String label) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
    child: Text(label, style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant)),
  );
}

Widget _tile(BuildContext pageContext, BuildContext sheetContext, IconData icon, String label, AdminNavDestination dest) {
  return ListTile(
    leading: Icon(icon, color: AdminColors.onSurfaceVariant),
    title: Text(label, style: AdminTypography.bodyMd(color: AdminColors.onSurface)),
    trailing: dest == AdminNavDestination.manageSyllabi ? const PendingSyllabusDot() : null,
    onTap: () {
      Navigator.of(sheetContext).pop();
      // `lecturerAllocation` isn't in the menu, so it never equals [dest] and
      // the push always happens.
      handleAdminNav(pageContext, AdminNavDestination.lecturerAllocation, dest);
    },
  );
}
