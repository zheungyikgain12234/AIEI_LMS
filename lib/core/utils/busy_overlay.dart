import 'package:flutter/material.dart';

/// Runs [action] behind a blocking "working…" dialog so the user can see
/// something is happening during slow server work (imports, bulk updates,
/// cascading deletes, submissions) and can't trigger it twice. The dialog
/// always closes — also when [action] throws, which is rethrown to the caller.
Future<T> runWithBusy<T>(BuildContext context, String message, Future<T> Function() action) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => PopScope(
      canPop: false,
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
              const SizedBox(width: 20),
              Flexible(child: Text(message)),
            ],
          ),
        ),
      ),
    ),
  );
  try {
    return await action();
  } finally {
    if (navigator.mounted) navigator.pop();
  }
}
