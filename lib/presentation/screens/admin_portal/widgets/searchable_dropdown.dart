import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';

String _labelOf<T>(DropdownMenuItem<T> item) {
  final child = item.child;
  if (child is Text) return child.data ?? child.textSpan?.toPlainText() ?? '${item.value}';
  return '${item.value}';
}

Future<T?> _showSearchDialog<T>(BuildContext context, List<DropdownMenuItem<T>> items, T? current) {
  return showDialog<T>(
    context: context,
    builder: (ctx) {
      var query = '';
      return StatefulBuilder(
        builder: (ctx, setState) {
          final q = query.trim().toLowerCase();
          final filtered = q.isEmpty ? items : items.where((i) => _labelOf(i).toLowerCase().contains(q)).toList();
          return Dialog(
            backgroundColor: AdminColors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420, maxHeight: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      autofocus: true,
                      onChanged: (v) => setState(() => query = v),
                      style: AdminTypography.bodyMd(color: AdminColors.onSurface),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: AdminColors.surfaceContainerLow,
                        hintText: 'Search...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  Flexible(
                    child: filtered.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text('No matches', style: AdminTypography.bodySm(color: AdminColors.outline)),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final item = filtered[i];
                              final selected = item.value == current;
                              return InkWell(
                                onTap: item.enabled ? () => Navigator.of(ctx).pop(item.value) : null,
                                child: Container(
                                  color: selected ? AdminColors.surfaceContainerHigh : null,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  alignment: Alignment.centerLeft,
                                  child: DefaultTextStyle(
                                    style: AdminTypography.bodyMd(color: AdminColors.onSurface),
                                    child: item.child,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// Drop-in replacement for [DropdownButton] whose menu opens a searchable list.
class SearchableDropdownButton<T> extends StatelessWidget {
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final Widget? hint;
  final TextStyle? style;
  final Widget? icon;
  final bool isDense;
  final bool isExpanded;

  const SearchableDropdownButton({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.hint,
    this.style,
    this.icon,
    this.isDense = false,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null && items.isNotEmpty;
    final selected = items.where((i) => i.value == value).firstOrNull;
    final display = selected?.child ?? hint ?? const SizedBox.shrink();
    final textStyle = style ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final row = Row(
      mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (isExpanded) Expanded(child: display) else Flexible(child: display),
        const SizedBox(width: 8),
        icon ?? const Icon(Icons.arrow_drop_down, color: AdminColors.onSurfaceVariant),
      ],
    );
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled
            ? () async {
                final picked = await _showSearchDialog<T>(context, items, value);
                if (picked != null) onChanged!(picked);
              }
            : null,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: isDense ? 0 : 12),
          child: DefaultTextStyle(style: textStyle, child: row),
        ),
      ),
    );
  }
}

/// Drop-in replacement for [DropdownButtonFormField] with a searchable menu.
class SearchableDropdownFormField<T> extends FormField<T> {
  SearchableDropdownFormField({
    super.key,
    required List<DropdownMenuItem<T>> items,
    T? initialValue,
    ValueChanged<T?>? onChanged,
    Widget? hint,
    TextStyle? style,
    Widget? icon,
    bool isDense = true,
    bool isExpanded = false,
    InputDecoration decoration = const InputDecoration(),
    super.validator,
  }) : super(
          initialValue: initialValue,
          builder: (field) {
            final state = field as _SearchableDropdownFormFieldState<T>;
            return InputDecorator(
              decoration: decoration.copyWith(errorText: field.errorText),
              isEmpty: false,
              child: SearchableDropdownButton<T>(
                items: items,
                value: state.value,
                hint: hint,
                style: style,
                icon: icon,
                isDense: true,
                isExpanded: isExpanded,
                onChanged: onChanged == null
                    ? null
                    : (v) {
                        state.didChange(v);
                        onChanged(v);
                      },
              ),
            );
          },
        );

  @override
  FormFieldState<T> createState() => _SearchableDropdownFormFieldState<T>();
}

class _SearchableDropdownFormFieldState<T> extends FormFieldState<T> {
  @override
  void didUpdateWidget(SearchableDropdownFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      setValue(widget.initialValue);
    }
  }
}
