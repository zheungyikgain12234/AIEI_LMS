import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';

class PortalSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

  const PortalSidebar({
    super.key,
    this.selectedIndex = 0,
    this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      decoration: const BoxDecoration(
        color: AdminColors.navSurface,
        border: Border(
          right: BorderSide(
            color: AdminColors.navBorder,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Enrolled Courses Item (Active)
          _SidebarNavItem(
            title: 'My Enrolled Courses',
            isSelected: selectedIndex == 0,
            icon: Icons.auto_stories_outlined,
            onTap: () => onDestinationSelected?.call(0),
          ),
          const SizedBox(height: 6),
          // My Badges Item
          _SidebarNavItem(
            title: 'My Badges',
            isSelected: selectedIndex == 1,
            icon: Icons.military_tech_outlined,
            onTap: () => onDestinationSelected?.call(1),
          ),
          const SizedBox(height: 6),
          _SidebarNavItem(
            title: 'My Grades',
            isSelected: selectedIndex == 2,
            icon: Icons.grading_outlined,
            onTap: () => onDestinationSelected?.call(2),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final String title;
  final bool isSelected;
  final IconData icon;
  final VoidCallback? onTap;

  const _SidebarNavItem({
    required this.title,
    required this.isSelected,
    required this.icon,
    this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    // Matches the admin portal sidebar's selected / hover colours.
    final Color bgColor = isSelected
        ? AdminColors.primaryContainer
        : (_isHovered ? Colors.white : Colors.transparent);
    final Color textColor = isSelected ? AdminColors.onSecondary : AdminColors.onSurfaceVariant;
    final FontWeight fontWeight = isSelected ? FontWeight.w600 : FontWeight.w500;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: textColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  style: AppTypography.labelLg(color: textColor).copyWith(
                    fontWeight: fontWeight,
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
