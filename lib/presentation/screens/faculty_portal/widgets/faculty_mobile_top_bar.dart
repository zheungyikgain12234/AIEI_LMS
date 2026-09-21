import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/presentation/screens/login/login_screen.dart';

/// Compact mobile (< 700px) app bar for the Faculty Portal.
///
/// Two variants mirror the Stitch mobile mockups:
/// - `FacultyMobileTopBar(title: ...)`: back arrow + page title + avatar,
///   used on drill-in screens (course dashboard, curriculum, grading).
/// - `FacultyMobileTopBar.root()`: logo + FACULTY badge + notification bell +
///   avatar, used on the bottom-nav root tabs (My Courses, Students).
class FacultyMobileTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool isRoot;
  final VoidCallback? onBack;

  const FacultyMobileTopBar({super.key, required String this.title, this.onBack}) : isRoot = false;

  const FacultyMobileTopBar.root({super.key})
      : title = null,
        onBack = null,
        isRoot = true;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 1))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SafeArea(
        bottom: false,
        child: isRoot ? _buildRoot(context) : _buildDetail(context),
      ),
    );
  }

  Widget _buildDetail(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack ?? () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: FacultyColors.onSurface),
        ),
        Expanded(
          child: Text(
            title ?? '',
            style: FacultyTypography.titleSm(color: FacultyColors.onSurface),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: () => _goToLogin(context),
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(color: FacultyColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.person, color: FacultyColors.onPrimary, size: 18),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildRoot(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 4),
        Image.asset('assets/images/aiei_logo.png', height: 26),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: FacultyColors.primary, borderRadius: BorderRadius.circular(4)),
          child: Text('FACULTY', style: FacultyTypography.labelXs(color: Colors.white).copyWith(fontWeight: FontWeight.w700)),
        ),
        const Spacer(),
        Stack(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_outlined, color: FacultyColors.onSurfaceVariant),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: FacultyColors.error, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => _goToLogin(context),
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(color: FacultyColors.primary, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('SL', style: FacultyTypography.labelXs(color: Colors.white).copyWith(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  void _goToLogin(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
