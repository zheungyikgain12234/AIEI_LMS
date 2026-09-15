import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';

/// Shared bottom navigation bar for the mobile (< 700px) student layout —
/// replaces the desktop `PortalSidebar` on narrow screens.
class MobileBottomNav extends StatelessWidget {
  final int selectedIndex; // 0 = My Courses, 1 = Certifications & Badges
  final ValueChanged<int> onTap;

  const MobileBottomNav({super.key, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          boxShadow: [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, -1))],
        ),
        child: Row(
          children: [
            Expanded(child: _item(Icons.menu_book, 'My Courses', 0)),
            Expanded(child: _item(Icons.verified_outlined, 'Certifications & Badges', 1)),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, int index) {
    final active = selectedIndex == index;
    final color = active ? AppColors.secondary : AppColors.onSurfaceVariant;
    return InkWell(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSm(color: color).copyWith(fontWeight: active ? FontWeight.w700 : FontWeight.w400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
