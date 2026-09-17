import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';

/// The root mobile (< 700px) bottom-nav destinations for the Admin Portal —
/// mirrors the top of the desktop sidebar. Everything else in the sidebar
/// (Manage Classes, Manage Badges, Course Enrollment, Enroll Students, and
/// the Master Data lookup screens) is reached via the "More" button, which
/// opens [showAdminMoreMenu] instead of holding its own persistent tab —
/// there isn't room in a 4-icon bar for all of it.
enum AdminMobileTab { lecturers, students, courses }

/// Shared mobile (< 700px) bottom tab bar for the Admin Portal's root
/// screens (Lecturers / Students / Courses), plus a "More" launcher.
class AdminMobileBottomNav extends StatelessWidget {
  final AdminMobileTab selected;
  final ValueChanged<AdminMobileTab> onTap;
  final VoidCallback onMore;

  const AdminMobileBottomNav({super.key, required this.selected, required this.onTap, required this.onMore});

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
            Expanded(child: _item(Icons.groups_outlined, 'Students', AdminMobileTab.students)),
            Expanded(child: _item(Icons.menu_book_outlined, 'Courses', AdminMobileTab.courses)),
            Expanded(child: _moreItem()),
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

  Widget _moreItem() {
    return InkWell(
      onTap: onMore,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.more_horiz, size: 22, color: AdminColors.onSurfaceVariant),
          const SizedBox(height: 2),
          Text(
            'More',
            style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
