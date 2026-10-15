import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';

/// Width of the rightmost "Action" column used by every admin list table.
const double kAdminActionColumnWidth = 64;

/// Header cell for the rightmost action column.
Widget adminActionHeader() => SizedBox(
      width: kAdminActionColumnWidth,
      child: Align(
        alignment: Alignment.centerRight,
        child: Text('Action', style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant)),
      ),
    );

/// The edit icon in the rightmost action column of a table row.
Widget adminEditAction(VoidCallback onTap) => SizedBox(
      width: kAdminActionColumnWidth,
      child: Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          onPressed: onTap,
          tooltip: 'Edit',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.edit_outlined, size: 20, color: AdminColors.onSurface),
        ),
      ),
    );

/// The "N selected · Deselect all" label shown on the left of a table's
/// selection bar (the Delete button sits on its right and only appears once
/// something is checked).
Widget adminSelectionSummary({required int count, required VoidCallback onDeselectAll, String? itemLabel}) {
  final text = itemLabel == null ? '$count selected' : '$count $itemLabel selected';
  return Row(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.check_box, size: 18, color: AdminColors.secondary),
    const SizedBox(width: 6),
    Text(text, style: AdminTypography.titleSm()),
    const SizedBox(width: 8),
    GestureDetector(
      onTap: onDeselectAll,
      child: Text('Deselect all', style: AdminTypography.labelMd(color: AdminColors.secondary)),
    ),
  ]);
}
