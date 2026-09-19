import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch_aiei_lms/core/session/app_session.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/presentation/screens/login/login_screen.dart';

class AdminHeader extends ConsumerWidget implements PreferredSizeWidget {
  final ValueChanged<String>? onSearch;

  const AdminHeader({super.key, this.onSearch});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionProvider);
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 1))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuDCaMBS-U4oFSVROHoDpAiGwvpOy1ivvJGSI_WfY0WX7QoRM-fyACYsDXamVpuy9nPp4DS3CZS5Id-vsuIkd0IFETOltui-g18k3ZBnLHM1PY4o6wE9LeNHbGeuIBBYIVzFUtG1JDowy2iHIYlvr9T8QTrZSotsTanHF_Cc5uzgEJpX3htWp4qlZ2-oqutU_ei1cNZGJhEaiBobBpOspNBtvF96qnHxoXh2QI6_aQoJfzsJW49NLMxIIM7emyAqSTeeWw',
                height: 32,
                errorBuilder: (context, error, stackTrace) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AdminColors.primary, borderRadius: BorderRadius.circular(6)),
                  child: Text('AIEI', style: AdminTypography.titleMd(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AdminColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(9999)),
                child: Text('ADMIN PORTAL', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant)),
              ),
            ],
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
                  child: TextField(
                    onChanged: onSearch,
                    style: AdminTypography.bodySm(color: AdminColors.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Search instructors, students, courses, cohorts...',
                      hintStyle: AdminTypography.bodySm(color: AdminColors.outline),
                      prefixIcon: const Icon(Icons.search, size: 18, color: AdminColors.onSurfaceVariant),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AdminColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(9999)),
            child: Text(
              '${session.username} · ${session.tenantId}',
              style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 16),
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined, size: 22, color: AdminColors.onSurfaceVariant),
                tooltip: 'Notifications',
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AdminColors.error, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
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
                      Text('Marcus Vance', style: AdminTypography.titleSm(color: AdminColors.onSurface)),
                      Text('Chief Academic Administrator', style: AdminTypography.labelSm()),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(color: AdminColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.person, color: AdminColors.onPrimary, size: 20),
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
