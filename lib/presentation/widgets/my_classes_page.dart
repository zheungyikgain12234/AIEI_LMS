import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';

/// Mobile (≤ 900px) full-screen host for the "My active classes" + calendar
/// panel that lives in the desktop sidebar — opened from the top bar's
/// calendar button, since the mobile layout has no sidebar.
class MyClassesPage extends StatelessWidget {
  final Widget panel;

  const MyClassesPage({super.key, required this.panel});

  static void open(BuildContext context, Widget panel) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MyClassesPage(panel: panel)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFE7FA),
      appBar: AppBar(
        backgroundColor: AdminColors.navSurface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.onSurface,
        title: Text('My Classes & Calendar', style: AppTypography.labelLg()),
      ),
      body: panel,
    );
  }
}
