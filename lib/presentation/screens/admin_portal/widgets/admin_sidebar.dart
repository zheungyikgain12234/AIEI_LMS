import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';

enum AdminNavDestination {
  manageLecturers,
  lecturerAllocation,
  manageStudents,
  manageCourses,
  manageClasses,
  manageBadges,
  roleCourseMapping,
  courseEnrollment,
  manageDepartments,
  manageProgramTracks,
  manageCohorts,
  manageLecturerDepartments,
  manageSpecializations,
  manageRoles,
}

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
    return Container(
      width: 256,
      decoration: const BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(1, 0),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'ACADEMIC OPERATIONS',
                      style: AdminTypography.labelSm(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _NavItem(
                          icon: Icons.badge_outlined,
                          label: 'Manage and Assign Lecturers',
                          isSelected:
                              selected == AdminNavDestination.manageLecturers,
                          onTap: () => onDestinationSelected?.call(
                            AdminNavDestination.manageLecturers,
                          ),
                        ),
                        _NavItem(
                          icon: Icons.groups_outlined,
                          label: 'Manage and Enroll Students',
                          isSelected:
                              selected == AdminNavDestination.manageStudents,
                          onTap: () => onDestinationSelected?.call(
                            AdminNavDestination.manageStudents,
                          ),
                        ),
                        _NavItem(
                          icon: Icons.menu_book_outlined,
                          label: 'Manage Courses',
                          isSelected:
                              selected == AdminNavDestination.manageCourses,
                          onTap: () => onDestinationSelected?.call(
                            AdminNavDestination.manageCourses,
                          ),
                        ),
                        _NavItem(
                          icon: Icons.event_note_outlined,
                          label: 'Manage Classes',
                          isSelected:
                              selected == AdminNavDestination.manageClasses,
                          onTap: () => onDestinationSelected?.call(
                            AdminNavDestination.manageClasses,
                          ),
                        ),
                        _NavItem(
                          icon: Icons.military_tech_outlined,
                          label: 'Manage Badges',
                          isSelected:
                              selected == AdminNavDestination.manageBadges,
                          onTap: () => onDestinationSelected?.call(
                            AdminNavDestination.manageBadges,
                          ),
                        ),
                        _NavItem(
                          icon: Icons.swap_horiz_outlined,
                          label: 'Role ↔ Course Mapping',
                          isSelected:
                              selected == AdminNavDestination.roleCourseMapping,
                          onTap: () => onDestinationSelected?.call(
                            AdminNavDestination.roleCourseMapping,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'MASTER DATA',
                      style: AdminTypography.labelSm(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _NavItem(
                          icon: Icons.apartment_outlined,
                          label: 'Manage Departments',
                          isSelected:
                              selected == AdminNavDestination.manageDepartments,
                          onTap: () => onDestinationSelected?.call(
                            AdminNavDestination.manageDepartments,
                          ),
                        ),
                        _NavItem(
                          icon: Icons.alt_route_outlined,
                          label: 'Manage Program Tracks',
                          isSelected:
                              selected ==
                              AdminNavDestination.manageProgramTracks,
                          onTap: () => onDestinationSelected?.call(
                            AdminNavDestination.manageProgramTracks,
                          ),
                        ),
                        _NavItem(
                          icon: Icons.hub_outlined,
                          label: 'Manage Cohorts',
                          isSelected:
                              selected == AdminNavDestination.manageCohorts,
                          onTap: () => onDestinationSelected?.call(
                            AdminNavDestination.manageCohorts,
                          ),
                        ),
                        _NavItem(
                          icon: Icons.corporate_fare_outlined,
                          label: 'Manage Lecturer Depts',
                          isSelected:
                              selected ==
                              AdminNavDestination.manageLecturerDepartments,
                          onTap: () => onDestinationSelected?.call(
                            AdminNavDestination.manageLecturerDepartments,
                          ),
                        ),
                        _NavItem(
                          icon: Icons.psychology_outlined,
                          label: 'Manage Specialization',
                          isSelected:
                              selected ==
                              AdminNavDestination.manageSpecializations,
                          onTap: () => onDestinationSelected?.call(
                            AdminNavDestination.manageSpecializations,
                          ),
                        ),
                        _NavItem(
                          icon: Icons.work_outline,
                          label: 'Manage Roles',
                          isSelected:
                              selected == AdminNavDestination.manageRoles,
                          onTap: () => onDestinationSelected?.call(
                            AdminNavDestination.manageRoles,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AdminColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified,
                    color: AdminColors.secondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Academic Year 2024–2025',
                          style: AdminTypography.labelSm(
                            color: AdminColors.onSurface,
                          ),
                        ),
                        Text(
                          'Admin Console Active',
                          style: AdminTypography.labelSm(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.onTap,
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
        : (_hovered ? AdminColors.surfaceContainerLow : Colors.transparent);
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
            ],
          ),
        ),
      ),
    );
  }
}
