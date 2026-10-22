import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';

/// The one "nothing matched" message every admin list/table shows for an
/// empty search result, with a link that clears the search box and puts the
/// typing cursor back in it.
class AdminNoResults extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const AdminNoResults({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('No items matches your query.', style: AdminTypography.bodyMd()),
        if (controller.text.isNotEmpty) ...[
          const SizedBox(height: 4),
          InkWell(
            onTap: () {
              controller.clear();
              focusNode.requestFocus();
            },
            child: Text(
              'Clear search query',
              style: AdminTypography.bodyMd(color: AdminColors.primaryContainer)
                  .copyWith(
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}
