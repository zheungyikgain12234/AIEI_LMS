import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'admin_header.dart';
import 'admin_sidebar.dart';

/// Shared header + sidebar shell used by every Admin Portal screen, mirroring
/// the layout markup repeated across all Stitch admin mockups.
class AdminScaffold extends StatelessWidget {
  final AdminNavDestination selected;
  final ValueChanged<AdminNavDestination> onDestinationSelected;
  final Widget body;
  final double maxWidth;

  const AdminScaffold({
    super.key,
    required this.selected,
    required this.onDestinationSelected,
    required this.body,
    this.maxWidth = 1600,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AdminHeader(onSearch: (_) {}),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminSidebar(selected: selected, onDestinationSelected: onDestinationSelected),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: body,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
