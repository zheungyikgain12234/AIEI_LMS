import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';

enum FacultyNavDestination { myCourses, gradingAndSubmissions }

class FacultySidebar extends StatelessWidget {
  final FacultyNavDestination selected;
  final ValueChanged<FacultyNavDestination>? onDestinationSelected;
  final int? pendingCount;

  const FacultySidebar({
    super.key,
    this.selected = FacultyNavDestination.myCourses,
    this.onDestinationSelected,
    this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(1, 0))],
      ),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NavItem(
                  icon: Icons.auto_stories_outlined,
                  label: 'My Courses',
                  isSelected: selected == FacultyNavDestination.myCourses,
                  onTap: () => onDestinationSelected?.call(FacultyNavDestination.myCourses),
                ),
                const SizedBox(height: 4),
                _NavItem(
                  icon: Icons.assignment_turned_in_outlined,
                  label: 'Grading & Submissions',
                  isSelected: selected == FacultyNavDestination.gradingAndSubmissions,
                  trailing: pendingCount,
                  onTap: () => onDestinationSelected?.call(FacultyNavDestination.gradingAndSubmissions),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final int? trailing;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.trailing,
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
        ? FacultyColors.primaryContainer
        : (_hovered ? FacultyColors.surfaceContainerHigh : Colors.transparent);
    final fg = selected ? FacultyColors.onPrimaryContainer : FacultyColors.onSurfaceVariant;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(widget.icon, size: 20, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: FacultyTypography.bodyMd(color: fg).copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (widget.trailing != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white.withValues(alpha: 0.2) : FacultyColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.trailing}',
                    style: FacultyTypography.labelXs(
                      color: selected ? FacultyColors.onPrimaryContainer : FacultyColors.primary,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
