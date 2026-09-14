import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';

enum AdminNavDestination { manageLecturers, lecturerAllocation, manageStudents, courseEnrollment }

class AdminSidebar extends StatelessWidget {
  final AdminNavDestination selected;
  final ValueChanged<AdminNavDestination>? onDestinationSelected;

  const AdminSidebar({super.key, required this.selected, this.onDestinationSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      decoration: const BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(1, 0))],
      ),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('ACADEMIC OPERATIONS', style: AdminTypography.labelSm()),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NavItem(
                  icon: Icons.badge_outlined,
                  label: 'Manage Lecturers',
                  isSelected: selected == AdminNavDestination.manageLecturers,
                  onTap: () => onDestinationSelected?.call(AdminNavDestination.manageLecturers),
                ),
                _NavItem(
                  icon: Icons.assignment_ind_outlined,
                  label: 'Lecturer Allocation',
                  isSelected: selected == AdminNavDestination.lecturerAllocation,
                  onTap: () => onDestinationSelected?.call(AdminNavDestination.lecturerAllocation),
                ),
                _NavItem(
                  icon: Icons.groups_outlined,
                  label: 'Manage Students',
                  isSelected: selected == AdminNavDestination.manageStudents,
                  onTap: () => onDestinationSelected?.call(AdminNavDestination.manageStudents),
                ),
                _NavItem(
                  icon: Icons.school_outlined,
                  label: 'Course Enrollment',
                  isSelected: selected == AdminNavDestination.courseEnrollment,
                  onTap: () => onDestinationSelected?.call(AdminNavDestination.courseEnrollment),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: AdminColors.secondary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Academic Year 2024–2025', style: AdminTypography.labelSm(color: AdminColors.onSurface)),
                        Text('Admin Console Active', style: AdminTypography.labelSm()),
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

  const _NavItem({required this.icon, required this.label, required this.isSelected, this.onTap});

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;
    final bg = selected ? AdminColors.primaryContainer : (_hovered ? AdminColors.surfaceContainerLow : Colors.transparent);
    final fg = selected ? AdminColors.onSecondary : AdminColors.onSurfaceVariant;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(widget.icon, size: 20, color: fg),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: AdminTypography.bodyMd(color: fg).copyWith(fontWeight: selected ? FontWeight.w600 : FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
