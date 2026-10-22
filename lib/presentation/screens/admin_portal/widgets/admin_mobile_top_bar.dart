import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/presentation/screens/login/login_screen.dart';

/// Compact mobile (≤ 900px) app bar for the Admin Portal.
///
/// Two variants mirror the Stitch mobile mockups:
/// - `AdminMobileTopBar.root(title: ...)`: logo + ADMIN badge on the left, avatar
///   on the right — used on
///   the bottom-nav root tabs (Lecturers, Students, Semesters, Enroll).
/// - `AdminMobileTopBar.detail(title: ...)`: back arrow on the left,
///   ADMIN badge + logo on the right — used on drill-in screens (Lecturer
///   Allocation Detail).
class AdminMobileTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// Kept for the call sites, but not shown: every page already has its own heading.
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
        color: AdminColors.navSurface,
        border: Border(bottom: BorderSide(color: AdminColors.navBorder)),
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
          child: Text('ADMIN', style: AdminTypography.labelSm(color: AdminColors.secondary).copyWith(fontWeight: FontWeight.w700)),
        ),
        const Spacer(),
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
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
          child: Text('ADMIN', style: AdminTypography.labelSm(color: AdminColors.secondary).copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        _logo(),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _logo() {
    return Image.asset(
      'assets/images/aiei_logo.png',
      height: 24,
    );
  }
}
