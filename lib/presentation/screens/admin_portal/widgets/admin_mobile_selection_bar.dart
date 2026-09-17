import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';

/// Shared "N selected — Delete" bar shown above a mobile card list once the
/// admin has checked at least one row, matching the desktop bulk-actions bar.
Widget adminMobileSelectionBar({
  required int count,
  required VoidCallback onDeselectAll,
  required VoidCallback onDelete,
  String itemLabel = 'item',
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12)),
    child: Row(
      children: [
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text('$count $itemLabel${count == 1 ? '' : 's'} selected', style: AdminTypography.titleSm()),
              GestureDetector(
                onTap: onDeselectAll,
                child: Text('Deselect all', style: AdminTypography.labelMd(color: AdminColors.secondary)),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, size: 16),
          label: const Text('Delete'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AdminColors.error,
            backgroundColor: AdminColors.errorContainer,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: AdminTypography.labelSm(),
          ),
        ),
      ],
    ),
  );
}
