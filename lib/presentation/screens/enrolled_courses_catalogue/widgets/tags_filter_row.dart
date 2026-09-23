import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';

/// Horizontally scrollable row of every tag across the student's enrolled
/// courses, led by an "All Courses" chip — tapping a tag filters the course
/// grid to it; tapping "All Courses" (or the already-selected tag again)
/// clears the filter. These are the real, admin-managed Course Tags, not a
/// fixed set of category labels.
class TagsFilterRow extends StatelessWidget {
  final List<String> tags;
  final String? selectedTag;
  final ValueChanged<String?> onSelectTag;

  const TagsFilterRow({
    super.key,
    required this.tags,
    required this.selectedTag,
    required this.onSelectTag,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tags.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _TagChip(
              label: 'All Courses',
              icon: Icons.apps,
              isSelected: selectedTag == null,
              onTap: () => onSelectTag(null),
            );
          }
          final tag = tags[index - 1];
          return _TagChip(
            label: tag,
            isSelected: tag == selectedTag,
            onTap: () => onSelectTag(tag),
          );
        },
      ),
    );
  }
}

class _TagChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TagChip({required this.label, this.icon = Icons.sell_outlined, required this.isSelected, required this.onTap});

  @override
  State<_TagChip> createState() => _TagChipState();
}

class _TagChipState extends State<_TagChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;
    final bg = selected
        ? AppColors.secondary
        : (_hovered ? AppColors.surfaceContainerLow : AppColors.surfaceContainerLowest);
    final fg = selected ? AppColors.onSecondary : AppColors.onSurfaceVariant;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(9999),
            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(widget.label, style: AppTypography.labelMd(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}
