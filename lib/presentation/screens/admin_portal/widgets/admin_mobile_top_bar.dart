import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/presentation/screens/login/login_screen.dart';

/// Compact mobile (< 700px) app bar for the Admin Portal.
///
/// Two variants mirror the Stitch mobile mockups:
/// - `AdminMobileTopBar.root(title: ...)`: logo + ADMIN badge + "/" + section
///   title on the left, search/notification/avatar on the right — used on
///   the bottom-nav root tabs (Lecturers, Students, Cohorts, Enroll).
/// - `AdminMobileTopBar.detail(title: ...)`: back arrow + title on the left,
///   ADMIN badge + logo on the right — used on drill-in screens (Lecturer
///   Allocation Detail).
class AdminMobileTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isRoot;
  final VoidCallback? onBack;

  const AdminMobileTopBar.root({super.key, required this.title})
      : isRoot = true,
        onBack = null;

  const AdminMobileTopBar.detail({super.key, required this.title, this.onBack}) : isRoot = false;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 1))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SafeArea(
        bottom: false,
        child: isRoot ? _buildRoot(context) : _buildDetail(context),
      ),
    );
  }

  Widget _buildRoot(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 4),
        _logo(),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: AdminColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(6)),
          child: Text('ADMIN', style: AdminTypography.labelSm(color: AdminColors.secondary).copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 6),
        Text('/', style: AdminTypography.bodySm(color: AdminColors.outlineVariant)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: AdminTypography.titleSm(color: AdminColors.onSurface),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.search, color: AdminColors.onSurfaceVariant),
          tooltip: 'Search portal',
        ),
        Stack(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_outlined, color: AdminColors.onSurfaceVariant),
              tooltip: 'Operations alerts',
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AdminColors.secondary, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          ),
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(color: AdminColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.person, color: AdminColors.onPrimary, size: 18),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildDetail(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack ?? () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: AdminColors.onSurface),
        ),
        Expanded(
          child: Text(
            title,
            style: AdminTypography.titleSm(color: AdminColors.onSurface),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: AdminColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(6)),
          child: Text('ADMIN', style: AdminTypography.labelSm(color: AdminColors.secondary).copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        _logo(),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _logo() {
    return Image.network(
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDCaMBS-U4oFSVROHoDpAiGwvpOy1ivvJGSI_WfY0WX7QoRM-fyACYsDXamVpuy9nPp4DS3CZS5Id-vsuIkd0IFETOltui-g18k3ZBnLHM1PY4o6wE9LeNHbGeuIBBYIVzFUtG1JDowy2iHIYlvr9T8QTrZSotsTanHF_Cc5uzgEJpX3htWp4qlZ2-oqutU_ei1cNZGJhEaiBobBpOspNBtvF96qnHxoXh2QI6_aQoJfzsJW49NLMxIIM7emyAqSTeeWw',
      height: 24,
      errorBuilder: (context, error, stackTrace) => Text('AIEI', style: AdminTypography.titleSm(color: AdminColors.primary)),
    );
  }
}
