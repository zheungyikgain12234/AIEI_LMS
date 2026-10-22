import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';

/// A dropdown-style form field whose menu has a filter text box. [options]
/// are (value, label) pairs; typing narrows the list by label.
class AdminSearchableDropdown extends FormField<String> {
  AdminSearchableDropdown({
    super.key,
    required List<(String, String)> options,
    required String hint,
    required ValueChanged<String?> onChanged,
    super.initialValue,
    super.validator,
    bool filled = true,
  }) : super(
         builder: (state) {
           final context = state.context;
           String? label;
           for (final o in options) {
             if (o.$1 == state.value) label = o.$2;
           }
           return InkWell(
             borderRadius: BorderRadius.circular(10),
             onTap: () async {
               final picked = await showDialog<String>(
                 context: context,
                 builder: (_) => _SearchDialog(
                   options: options,
                   selected: state.value,
                   title: hint,
                 ),
               );
               if (picked == null) return;
               state.didChange(picked);
               onChanged(picked);
             },
             child: InputDecorator(
               isEmpty: label == null,
               decoration: InputDecoration(
                 isDense: true,
                 filled: filled,
                 border: filled
                     ? OutlineInputBorder(
                         borderRadius: BorderRadius.circular(10),
                         borderSide: BorderSide.none,
                       )
                     : const OutlineInputBorder(),
                 contentPadding: const EdgeInsets.symmetric(
                   horizontal: 12,
                   vertical: 14,
                 ),
                 errorText: state.errorText,
                 suffixIcon: const Icon(
                   Icons.expand_more,
                   size: 18,
                   color: AdminColors.onSurfaceVariant,
                 ),
               ),
               child: Text(
                 label ?? hint,
                 overflow: TextOverflow.ellipsis,
                 style: label == null
                     ? AdminTypography.bodySm(color: AdminColors.outline)
                     : AdminTypography.bodyMd(color: AdminColors.onSurface),
               ),
             ),
           );
         },
       );
}

class _SearchDialog extends StatefulWidget {
  const _SearchDialog({
    required this.options,
    required this.selected,
    required this.title,
  });

  final List<(String, String)> options;
  final String? selected;
  final String title;

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final matches = [
      for (final o in widget.options)
        if (o.$2.toLowerCase().contains(_query)) o,
    ];
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                autofocus: true,
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Filter...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Flexible(
              child: matches.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No matches.',
                        style: AdminTypography.bodyMd(),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final o in matches)
                          ListTile(
                            dense: true,
                            selected: o.$1 == widget.selected,
                            title: Text(o.$2, overflow: TextOverflow.ellipsis),
                            onTap: () => Navigator.of(context).pop(o.$1),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
