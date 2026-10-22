import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/widgets/student_schedule_sidebar.dart';
import 'package:stitch_aiei_lms/presentation/screens/login/login_screen.dart';
import 'package:stitch_aiei_lms/presentation/widgets/my_classes_page.dart';

/// Compact mobile (≤ 900px) app bar for the student portal's bottom-nav
/// tab pages — logo, role badge, avatar. Replaces the
/// desktop `PortalHeader` (which is too wide for narrow screens).
class MobileTopBar extends StatelessWidget implements PreferredSizeWidget {
  const MobileTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AdminColors.navSurface,
        border: Border(bottom: BorderSide(color: AdminColors.navBorder)),
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 1))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Image.asset('assets/images/aiei_logo.png', height: 24),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(9999)),
              child: Text('STUDENT', style: AppTypography.labelSm(color: AppColors.secondary)),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'My classes & calendar',
              onPressed: () => MyClassesPage.open(context, const StudentScheduleSidebar()),
              icon: const Icon(Icons.calendar_month_outlined, color: AppColors.onSurfaceVariant),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              ),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(color: AppColors.surfaceContainerHigh, shape: BoxShape.circle),
                child: const Icon(Icons.person, size: 18, color: AppColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
