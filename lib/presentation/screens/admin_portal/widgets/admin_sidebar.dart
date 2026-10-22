import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'pending_syllabus_badge.dart';

enum AdminNavDestination {
  manageLecturers,
  lecturerAllocation,
  manageStudents,
  manageCourses,
  manageClasses,
  manageBadges,
  roleCourseMapping,
  departmentCourseMapping,
  programmeTrackMapping,
  trackCourseMapping,
  badgeCourseMapping,
  specializationCourseMapping,
  courseEnrollment,
  manageDepartments,
  manageProgrammes,
  manageProgramTracks,
  manageSemesters,
  manageLecturerDepartments,
  manageSpecializations,
  manageRoles,
  manageBadgeCatalog,
  manageCourseTags,
  manageModuleLists,
  manageSyllabi,
  gradeApprovals,
  badgeApprovals,
  manageAdmins,
  settings,
}

/// One entry of the admin menu.
class AdminMenuItem {
  final IconData icon;
  final String label;
  final AdminNavDestination destination;

  const AdminMenuItem(this.icon, this.label, this.destination);
}

/// A titled group of related menu entries.
class AdminMenuGroup {
  final String title;

  /// A soft background tint that sets the group apart from its neighbours.
  final Color tint;
  final List<AdminMenuItem> items;

  const AdminMenuGroup(this.title, this.tint, this.items);
}

/// The admin menu, grouped by who/what it is about. The desktop sidebar and
/// the mobile "More" sheet both render this, so they always match: within a
/// group the lists come first, then the mappings to courses, then the page
/// where the records are managed day to day.
const adminMenuGroups = <AdminMenuGroup>[
  AdminMenuGroup('LECTURERS', Color(0xFFEAF1FB), [
    AdminMenuItem(Icons.corporate_fare_outlined, 'Manage Lecturer Depts', AdminNavDestination.manageLecturerDepartments),
    AdminMenuItem(Icons.psychology_outlined, 'Manage Teaching Competencies', AdminNavDestination.manageSpecializations),
    AdminMenuItem(Icons.psychology_alt_outlined, 'Teaching Competency ↔ Course Mapping', AdminNavDestination.specializationCourseMapping),
    AdminMenuItem(Icons.badge_outlined, 'Manage and Assign Lecturers', AdminNavDestination.manageLecturers),
  ]),
  AdminMenuGroup('COURSES & CLASSES', Color(0xFFEAF5EE), [
    AdminMenuItem(Icons.sell_outlined, 'Manage Course Tags', AdminNavDestination.manageCourseTags),
    AdminMenuItem(Icons.view_module_outlined, 'Manage Module Lists', AdminNavDestination.manageModuleLists),
    AdminMenuItem(Icons.menu_book_outlined, 'Manage Courses', AdminNavDestination.manageCourses),
    AdminMenuItem(Icons.event_note_outlined, 'Manage Classes', AdminNavDestination.manageClasses),
    AdminMenuItem(Icons.fact_check_outlined, 'Manage Syllabi', AdminNavDestination.manageSyllabi),
  ]),
  AdminMenuGroup('STUDENTS', Color(0xFFFFF4E2), [
    AdminMenuItem(Icons.hub_outlined, 'Manage Semesters', AdminNavDestination.manageSemesters),
    AdminMenuItem(Icons.groups_outlined, 'Manage and Enrol Students', AdminNavDestination.manageStudents),
  ]),
  AdminMenuGroup('PUBLIC STUDENTS', Color(0xFFF1ECFA), [
    AdminMenuItem(Icons.workspace_premium_outlined, 'Manage Programmes', AdminNavDestination.manageProgrammes),
    AdminMenuItem(Icons.alt_route_outlined, 'Manage Tracks', AdminNavDestination.manageProgramTracks),
    AdminMenuItem(Icons.account_tree_outlined, 'Programme ↔ Track Mapping', AdminNavDestination.programmeTrackMapping),
    AdminMenuItem(Icons.alt_route, 'Track ↔ Course Mapping', AdminNavDestination.trackCourseMapping),
  ]),
  AdminMenuGroup('STAFF STUDENTS', Color(0xFFE6F4F4), [
    AdminMenuItem(Icons.apartment_outlined, 'Manage Staff Depts', AdminNavDestination.manageDepartments),
    AdminMenuItem(Icons.work_outline, 'Manage Staff Roles', AdminNavDestination.manageRoles),
    AdminMenuItem(Icons.account_tree_outlined, 'Staff Depts ↔ Course Mapping', AdminNavDestination.departmentCourseMapping),
    AdminMenuItem(Icons.swap_horiz_outlined, 'Staff Role ↔ Course Mapping', AdminNavDestination.roleCourseMapping),
  ]),
  AdminMenuGroup('GRADES & BADGES', Color(0xFFFBEDEF), [
    AdminMenuItem(Icons.rule_outlined, 'Grade Approvals', AdminNavDestination.gradeApprovals),
    AdminMenuItem(Icons.military_tech_outlined, 'Manage Badges', AdminNavDestination.manageBadgeCatalog),
    AdminMenuItem(Icons.military_tech_outlined, 'Badge ↔ Course Mapping', AdminNavDestination.badgeCourseMapping),
    AdminMenuItem(Icons.approval_outlined, 'Badge Approvals', AdminNavDestination.badgeApprovals),
    AdminMenuItem(Icons.workspace_premium, 'Manage Badge Award', AdminNavDestination.manageBadges),
  ]),
  AdminMenuGroup('SYSTEM', Color(0xFFF0F1F3), [
    AdminMenuItem(Icons.admin_panel_settings_outlined, 'Manage Admin', AdminNavDestination.manageAdmins),
    AdminMenuItem(Icons.settings_outlined, 'Settings', AdminNavDestination.settings),
  ]),
];

class AdminSidebar extends StatelessWidget {
  final AdminNavDestination selected;
  final ValueChanged<AdminNavDestination>? onDestinationSelected;

  const AdminSidebar({
    super.key,
    required this.selected,
    this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PendingSyllabusRefresher(
      child: Container(
        width: 256,
        decoration: const BoxDecoration(
          color: AdminColors.navSurface,
          border: Border(right: BorderSide(color: AdminColors.navBorder)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(1, 0),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final group in adminMenuGroups)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
                  decoration: BoxDecoration(color: group.tint, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: Text(group.title, style: AdminTypography.labelSm()),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final item in group.items)
                              _NavItem(
                                icon: item.icon,
                                label: item.label,
                                trailing: item.destination == AdminNavDestination.manageSyllabi ? const PendingSyllabusDot() : null,
                                isSelected: selected == item.destination,
                                onTap: () => onDestinationSelected?.call(item.destination),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.onTap,
    this.trailing,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;
    final bg = selected
        ? AdminColors.primaryContainer
        : (_hovered ? Colors.white : Colors.transparent);
    final fg = selected
        ? AdminColors.onSecondary
        : AdminColors.onSurfaceVariant;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 20, color: fg),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: AdminTypography.bodyMd(color: fg).copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (widget.trailing != null) ...[const SizedBox(width: 8), widget.trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
