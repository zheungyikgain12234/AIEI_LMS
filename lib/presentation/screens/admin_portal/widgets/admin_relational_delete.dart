import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/domain/models/delete_dependent.dart';

import 'admin_searchable_dropdown.dart';

/// Runs the whole relational delete flow: when records depend on what is
/// being deleted, asks what to do with each one, then asks for a final
/// confirmation, calls [perform], and shows a "deleted" snackbar. Returns
/// true when the delete went through.
Future<bool> runRelationalDelete(
  BuildContext context, {
  required String noun,
  required int count,
  required List<DeleteDependent> dependents,
  required Future<void> Function(List<DeleteDecision> decisions) perform,
  String? message,
  String? note,
  String? pluralNoun,
  String? deletedMessage,
}) async {
  final plural = count == 1 ? noun : (pluralNoun ?? '${noun}s');
  var decisions = const <DeleteDecision>[];
  if (dependents.isEmpty) {
    final ok = await _confirm(
      context,
      title: 'Delete $plural?',
      body:
          message ??
          'This will permanently delete $count $plural.${note == null ? '' : ' $note'} This cannot be undone.',
      action: 'Delete',
    );
    if (ok != true || !context.mounted) return false;
  } else {
    final picked = await showDialog<List<DeleteDecision>>(
      context: context,
      builder: (_) =>
          _DependentsDialog(noun: plural, dependents: dependents, note: note),
    );
    if (picked == null || !context.mounted) return false;
    decisions = picked;
    final ok = await _confirm(
      context,
      title: 'Confirm deletion',
      body:
          'You are about to delete $count $plural.\n${_summary(dependents, decisions)}${note == null ? '' : '\n$note'}\nThis cannot be undone.',
      action: 'Confirm & delete',
      cancel: 'Back',
    );
    if (ok != true || !context.mounted) return false;
  }
  final messenger = ScaffoldMessenger.of(context);
  await perform(decisions);
  messenger.showSnackBar(
    SnackBar(content: Text(deletedMessage ?? '$count $plural deleted')),
  );
  return true;
}

String _summary(
  List<DeleteDependent> dependents,
  List<DeleteDecision> decisions,
) {
  final byKey = {for (final d in decisions) '${d.kind}/${d.id}': d};
  final lines = <String>[];
  final kinds = <String>[];
  for (final d in dependents) {
    if (!kinds.contains(d.kind)) kinds.add(d.kind);
  }
  for (final kind in kinds) {
    final items = dependents.where((d) => d.kind == kind).toList();
    final moved = items
        .where((d) => byKey['$kind/${d.id}']?.targetId != null)
        .length;
    final rest = items.length - moved;
    final parts = [
      if (moved > 0) '$moved reassigned',
      if (rest > 0)
        '$rest ${items.firstWhere((d) => byKey['$kind/${d.id}']?.targetId == null).noneVerb}',
    ];
    lines.add(
      '• ${items.length} ${items.first.kindPlural}: ${parts.join(', ')}',
    );
  }
  return lines.join('\n');
}

Future<bool?> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
  String cancel = 'Cancel',
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AdminColors.error),
          child: Text(action),
        ),
      ],
    ),
  );
}

class _DependentsDialog extends StatefulWidget {
  const _DependentsDialog({
    required this.noun,
    required this.dependents,
    this.note,
  });

  final String? note;
  final String noun;
  final List<DeleteDependent> dependents;

  @override
  State<_DependentsDialog> createState() => _DependentsDialogState();
}

class _DependentsDialogState extends State<_DependentsDialog> {
  static const _none = '__none__';

  // '$kind/$id' -> target id, or [_none]. Missing = not decided yet.
  final Map<String, String> _choices = {};

  String _key(DeleteDependent d) => '${d.kind}/${d.id}';

  @override
  Widget build(BuildContext context) {
    final deps = widget.dependents;
    final undecided = deps.where((d) => !_choices.containsKey(_key(d))).length;
    final rows = <Widget>[];
    String? lastKind;
    for (final d in deps) {
      if (d.kind != lastKind) {
        rows.add(const SizedBox(height: 16));
        rows.add(
          Text(
            d.kindPlural.toUpperCase(),
            style: AdminTypography.labelSm(color: AdminColors.onSurfaceVariant),
          ),
        );
        lastKind = d.kind;
      }
      rows.addAll([
        const SizedBox(height: 12),
        Text(d.title, style: AdminTypography.titleSm()),
        if (d.subtitle.isNotEmpty)
          Text(d.subtitle, style: AdminTypography.labelSm()),
        const SizedBox(height: 4),
        if (d.noneLabel == null && d.targets.isEmpty)
          Text(
            'Nothing to reassign this to — create another one first.',
            style: AdminTypography.bodySm(color: AdminColors.error),
          )
        else
          AdminSearchableDropdown(
            key: ValueKey(_key(d)),
            initialValue: _choices[_key(d)],
            hint: 'Choose action',
            filled: false,
            options: [
              if (d.noneLabel != null) (_none, d.noneLabel!),
              for (final t in d.targets) (t.$1, 'Reassign to ${t.$2}'),
            ],
            onChanged: (v) => setState(() => _choices[_key(d)] = v!),
          ),
      ]);
    }
    return AlertDialog(
      title: Text('Delete ${widget.noun}?'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${deps.length} linked record${deps.length == 1 ? '' : 's'} still depend${deps.length == 1 ? 's' : ''} on the selected ${widget.noun}. Choose what happens to each one.${widget.note == null ? '' : ' ${widget.note}'}',
              ),
              ...rows,
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: undecided == 0
              ? () => Navigator.of(context).pop([
                  for (final d in deps)
                    DeleteDecision(
                      d.kind,
                      d.id,
                      _choices[_key(d)] == _none ? null : _choices[_key(d)],
                    ),
                ])
              : null,
          style: FilledButton.styleFrom(backgroundColor: AdminColors.error),
          child: Text(
            undecided == 0 ? 'Continue' : '$undecided left to decide',
          ),
        ),
      ],
    );
  }
}

/// Destructive delete that makes the admin type each name before it enables
/// the button. Shows [warning] above the fields, runs [perform], then shows
/// the "deleted" snackbar. Returns true when the delete went through.
Future<bool> runTypedNameDelete(
  BuildContext context, {
  required String noun,
  required List<String> names,
  required String warning,
  required Future<void> Function() perform,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => _TypedNameDialog(noun: noun, names: names, warning: warning),
  );
  if (ok != true || !context.mounted) return false;
  final messenger = ScaffoldMessenger.of(context);
  await perform();
  messenger.showSnackBar(SnackBar(content: Text('${names.length} ${names.length == 1 ? noun : '${noun}s'} deleted')));
  return true;
}

class _TypedNameDialog extends StatefulWidget {
  const _TypedNameDialog({required this.noun, required this.names, required this.warning});

  final String noun;
  final List<String> names;
  final String warning;

  @override
  State<_TypedNameDialog> createState() => _TypedNameDialogState();
}

class _TypedNameDialogState extends State<_TypedNameDialog> {
  late final List<TextEditingController> _controllers = [for (final _ in widget.names) TextEditingController()];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _matches => [for (var i = 0; i < widget.names.length; i++) _controllers[i].text.trim() == widget.names[i]].every((m) => m);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Delete ${widget.names.length == 1 ? widget.noun : '${widget.noun}s'}?'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AdminColors.errorContainer, borderRadius: BorderRadius.circular(8)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.warning_amber_rounded, size: 20, color: AdminColors.error),
                  const SizedBox(width: 8),
                  Expanded(child: Text(widget.warning, style: AdminTypography.bodySm(color: AdminColors.onErrorContainer))),
                ]),
              ),
              for (var i = 0; i < widget.names.length; i++) ...[
                const SizedBox(height: 16),
                Text.rich(TextSpan(text: 'Type ', children: [
                  TextSpan(text: widget.names[i], style: const TextStyle(fontWeight: FontWeight.w700)),
                  const TextSpan(text: ' to confirm'),
                ])),
                const SizedBox(height: 6),
                TextField(
                  controller: _controllers[i],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          onPressed: _matches ? () => Navigator.of(context).pop(true) : null,
          style: FilledButton.styleFrom(backgroundColor: AdminColors.error),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
