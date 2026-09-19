import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';

/// Page-size choices offered by every paginated admin table.
const List<int> adminPageSizeOptions = [10, 20, 50];

/// Real, data-driven pagination footer for admin data tables — replaces the
/// old static "[1, 2, 3]" placeholder page links. Shows "Showing X-Y of Z",
/// a page-size selector (10/20/50), and prev/next + numbered page buttons,
/// all wired to actual item counts (no fake pages beyond what the data has).
class AdminPagination extends StatelessWidget {
  final int totalItems;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;
  final String itemLabel;

  const AdminPagination({
    super.key,
    required this.totalItems,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    required this.onPageSizeChanged,
    this.itemLabel = 'item',
  });

  int get _pageCount => totalItems == 0 ? 1 : (totalItems / pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    final start = totalItems == 0 ? 0 : (page - 1) * pageSize + 1;
    final end = (page * pageSize).clamp(0, totalItems);
    final pageCount = _pageCount;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              totalItems == 0 ? 'Showing 0 of 0 $itemLabel${totalItems == 1 ? '' : 's'}' : 'Showing $start–$end of $totalItems $itemLabel${totalItems == 1 ? '' : 's'}',
              style: AdminTypography.bodySm(),
            ),
            _pageSizeDropdown(),
          ],
        ),
        if (pageCount > 1) _pageControls(pageCount),
      ],
    );
  }

  Widget _pageSizeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: pageSize,
          isDense: true,
          style: AdminTypography.labelSm(color: AdminColors.onSurface),
          items: [for (final s in adminPageSizeOptions) DropdownMenuItem(value: s, child: Text('$s / page'))],
          onChanged: (v) {
            if (v != null) onPageSizeChanged(v);
          },
        ),
      ),
    );
  }

  Widget _pageControls(int pageCount) {
    // Show at most 5 numbered buttons, centered on the current page.
    var lo = (page - 2).clamp(1, pageCount);
    var hi = (lo + 4).clamp(1, pageCount);
    lo = (hi - 4).clamp(1, pageCount);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _navButton(Icons.chevron_left, enabled: page > 1, onTap: () => onPageChanged(page - 1)),
        for (var p = lo; p <= hi; p++) _pageButton(p),
        _navButton(Icons.chevron_right, enabled: page < pageCount, onTap: () => onPageChanged(page + 1)),
      ],
    );
  }

  Widget _navButton(IconData icon, {required bool enabled, required VoidCallback onTap}) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 18),
      color: AdminColors.onSurfaceVariant,
      disabledColor: AdminColors.outline,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    );
  }

  Widget _pageButton(int p) {
    final active = p == page;
    return InkWell(
      onTap: active ? null : () => onPageChanged(p),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AdminColors.primaryContainer : AdminColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$p',
          style: AdminTypography.labelSm(color: active ? Colors.white : AdminColors.onSurface).copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
