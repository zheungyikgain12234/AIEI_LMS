import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';
import 'package:stitch_aiei_lms/presentation/screens/login/login_screen.dart';

class PortalHeader extends StatelessWidget implements PreferredSizeWidget {
  final ValueChanged<String>? onSearch;

  const PortalHeader({
    super.key,
    this.onSearch,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: AppColors.surfaceContainer,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Logo & Portal Badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuDCaMBS-U4oFSVROHoDpAiGwvpOy1ivvJGSI_WfY0WX7QoRM-fyACYsDXamVpuy9nPp4DS3CZS5Id-vsuIkd0IFETOltui-g18k3ZBnLHM1PY4o6wE9LeNHbGeuIBBYIVzFUtG1JDowy2iHIYlvr9T8QTrZSotsTanHF_Cc5uzgEJpX3htWp4qlZ2-oqutU_ei1cNZGJhEaiBobBpOspNBtvF96qnHxoXh2QI6_aQoJfzsJW49NLMxIIM7emyAqSTeeWw',
                height: 32,
                errorBuilder: (context, error, stackTrace) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'AIEI',
                    style: AppTypography.headlineSm(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  'STUDENT PORTAL',
                  style: AppTypography.labelSm(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 32),

          // Central Search Input
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 576),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    onChanged: onSearch,
                    style: AppTypography.bodySm(color: AppColors.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Search courses, lessons and certifications',
                      hintStyle: AppTypography.bodySm(
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 18,
                        color: AppColors.onSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 24),

          // Notification Bell
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_outlined,
                  size: 22,
                  color: AppColors.onSurfaceVariant,
                ),
                tooltip: 'Notifications',
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),

          // User Profile Info — tap to sign out back to Login
          GestureDetector(
            onTap: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            ),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Alex Chen',
                        style: AppTypography.labelMd(color: AppColors.onSurface),
                      ),
                      Text(
                        'Product Analyst • Operations',
                        style: AppTypography.bodySm(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.onPrimary,
                      size: 20,
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
