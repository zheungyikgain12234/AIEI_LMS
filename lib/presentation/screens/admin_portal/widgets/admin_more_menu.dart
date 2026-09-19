import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import '../manage_classes_screen.dart';
import '../manage_badges_screen.dart';
import '../role_course_mapping_screen.dart';
import '../department_course_mapping_screen.dart';
import '../track_course_mapping_screen.dart';
import '../course_enrollment_screen.dart';
import '../manage_departments_screen.dart';
import '../manage_program_tracks_screen.dart';
import '../manage_cohorts_screen.dart';
import '../manage_lecturer_departments_screen.dart';
import '../manage_specializations_screen.dart';
import '../manage_roles_screen.dart';

/// The mobile "More" sheet — everything in the desktop sidebar that doesn't
/// fit as its own [AdminMobileBottomNav] tab. Master Data collapses into a
/// single expandable row rather than 5 separate entries.
Future<void> showAdminMoreMenu(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AdminColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: AdminColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(9999)),
            ),
            _tile(context, sheetContext, Icons.event_note_outlined, 'Manage Classes', (ctx) => const ManageClassesScreen()),
            _tile(context, sheetContext, Icons.military_tech_outlined, 'Badge Award Management', (ctx) => const ManageBadgesScreen()),
            _tile(context, sheetContext, Icons.swap_horiz_outlined, 'Role ↔ Course Mapping', (ctx) => const RoleCourseMappingScreen()),
            _tile(context, sheetContext, Icons.account_tree_outlined, 'Department ↔ Course Mapping', (ctx) => const DepartmentCourseMappingScreen()),
            _tile(context, sheetContext, Icons.alt_route, 'Track ↔ Course Mapping', (ctx) => const TrackCourseMappingScreen()),
            _tile(context, sheetContext, Icons.school_outlined, 'Course Enrollment', (ctx) => const CourseEnrollmentScreen()),
            ExpansionTile(
              leading: const Icon(Icons.dataset_outlined, color: AdminColors.onSurfaceVariant),
              title: Text('Master Data', style: AdminTypography.bodyMd(color: AdminColors.onSurface)),
              childrenPadding: const EdgeInsets.only(left: 12),
              children: [
                _tile(context, sheetContext, Icons.apartment_outlined, 'Manage Departments', (ctx) => const ManageDepartmentsScreen()),
                _tile(context, sheetContext, Icons.alt_route_outlined, 'Manage Program Tracks', (ctx) => const ManageProgramTracksScreen()),
                _tile(context, sheetContext, Icons.hub_outlined, 'Manage Cohorts', (ctx) => const ManageCohortsScreen()),
                _tile(context, sheetContext, Icons.corporate_fare_outlined, 'Manage Lecturer Depts', (ctx) => const ManageLecturerDepartmentsScreen()),
                _tile(context, sheetContext, Icons.psychology_outlined, 'Manage Specialization', (ctx) => const ManageSpecializationsScreen()),
                _tile(context, sheetContext, Icons.work_outline, 'Manage Roles', (ctx) => const ManageRolesScreen()),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _tile(BuildContext pageContext, BuildContext sheetContext, IconData icon, String label, Widget Function(BuildContext) builder) {
  return ListTile(
    leading: Icon(icon, color: AdminColors.onSurfaceVariant),
    title: Text(label, style: AdminTypography.bodyMd(color: AdminColors.onSurface)),
    onTap: () {
      Navigator.of(sheetContext).pop();
      Navigator.of(pageContext).push(MaterialPageRoute(builder: builder));
    },
  );
}
