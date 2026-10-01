import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';

/// Dropdown of every tag across the given courses, led by an "All Tags"
/// entry that clears the filter. These are the real, admin-managed Course
/// Tags, not a fixed set of category labels.
class TagsFilterRow extends StatelessWidget {
  final List<String> tags;
  final String? selectedTag;
  final ValueChanged<String?> onSelectTag;
  final bool expand;

  const TagsFilterRow({
    super.key,
    required this.tags,
    required this.selectedTag,
    required this.onSelectTag,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: tags.contains(selectedTag) ? selectedTag : null,
          isExpanded: expand,
          icon: const Icon(Icons.expand_more, size: 18, color: AppColors.outline),
          borderRadius: BorderRadius.circular(8),
          style: AppTypography.labelMd(color: AppColors.onSurface),
          onChanged: onSelectTag,
          items: [
            DropdownMenuItem<String?>(value: null, child: Text('All Tags', style: AppTypography.labelMd(color: AppColors.onSurface))),
            for (final tag in tags)
              DropdownMenuItem<String?>(value: tag, child: Text(tag, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
