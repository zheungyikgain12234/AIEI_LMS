import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';

/// Compact mobile (< 700px) app bar for the student portal's bottom-nav
/// tab pages — logo, role badge, notification bell, avatar. Replaces the
/// desktop `PortalHeader` (which is too wide for narrow screens).
class MobileTopBar extends StatelessWidget implements PreferredSizeWidget {
  const MobileTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 1))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuDCaMBS-U4oFSVROHoDpAiGwvpOy1ivvJGSI_WfY0WX7QoRM-fyACYsDXamVpuy9nPp4DS3CZS5Id-vsuIkd0IFETOltui-g18k3ZBnLHM1PY4o6wE9LeNHbGeuIBBYIVzFUtG1JDowy2iHIYlvr9T8QTrZSotsTanHF_Cc5uzgEJpX3htWp4qlZ2-oqutU_ei1cNZGJhEaiBobBpOspNBtvF96qnHxoXh2QI6_aQoJfzsJW49NLMxIIM7emyAqSTeeWw',
              height: 24,
              errorBuilder: (context, error, stackTrace) => Text('AIEI', style: AppTypography.headlineSm(color: AppColors.primary)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(9999)),
              child: Text('STUDENT', style: AppTypography.labelSm(color: AppColors.secondary)),
            ),
            const Spacer(),
            Stack(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_outlined, color: AppColors.onSurfaceVariant),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: AppColors.surfaceContainerHigh, shape: BoxShape.circle),
              child: const Icon(Icons.person, size: 18, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
