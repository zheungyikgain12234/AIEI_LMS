import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';

import 'admin_nav.dart';
import 'admin_sidebar.dart';
import 'pending_syllabus_badge.dart';

/// Destinations that already have a tab in the bottom navigation.
const _inBottomNav = {
  AdminNavDestination.manageLecturers,
  AdminNavDestination.manageStudents,
  AdminNavDestination.manageCourses,
};

/// The mobile "More" sheet — the same groups and labels as the desktop sidebar
/// ([adminMenuGroups]), except the three entries that already have their own
/// [AdminMobileBottomNav] tab (Lecturers / Students / Courses).
Future<void> showAdminMoreMenu(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AdminColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AdminColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
              for (final group in adminMenuGroups)
                if (group.items.any(
                  (i) => !_inBottomNav.contains(i.destination),
                ))
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    padding: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: group.tint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _section(group.title),
                        for (final item in group.items)
                          if (!_inBottomNav.contains(item.destination))
                            _tile(
                              context,
                              sheetContext,
                              item.icon,
                              item.label,
                              item.destination,
                            ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _section(String label) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
    child: Text(
      label,
      style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant),
    ),
  );
}

Widget _tile(
  BuildContext pageContext,
  BuildContext sheetContext,
  IconData icon,
  String label,
  AdminNavDestination dest,
) {
  return ListTile(
    tileColor: Colors.transparent,
    leading: Icon(icon, color: AdminColors.onSurfaceVariant),
    title: Text(
      label,
      style: AdminTypography.bodyMd(color: AdminColors.onSurface),
    ),
    trailing: dest == AdminNavDestination.manageSyllabi
        ? const PendingSyllabusDot()
        : null,
    onTap: () {
      Navigator.of(sheetContext).pop();
      // `lecturerAllocation` isn't in the menu, so it never equals [dest] and
      // the push always happens.
      handleAdminNav(pageContext, AdminNavDestination.lecturerAllocation, dest);
    },
  );
}
