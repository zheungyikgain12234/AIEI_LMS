import 'package:flutter/material.dart';

const _successColor = Color(0xFF1B7F4B);

/// Shows the app-wide green "success" snackbar (check icon + [message]) —
/// use after any save/create/update/delete/submit completes, so every
/// portal confirms success the same way. Replaces any snackbar already on
/// screen so rapid actions don't queue up.
void showSuccessSnackBar(BuildContext context, String message) => showSuccessSnackBarOn(ScaffoldMessenger.of(context), message);

/// Same as [showSuccessSnackBar] for a [ScaffoldMessengerState] captured
/// before an `await`, when the originating context may no longer be valid.
void showSuccessSnackBarOn(ScaffoldMessengerState messenger, String message) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: _successColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
}
