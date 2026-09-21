const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Formats a due date/time without pulling in the `intl` package, e.g.
/// "Jan 5, 2026, 3:30 PM".
String formatDueDate(DateTime dt) {
  final month = _months[dt.month - 1];
  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour < 12 ? 'AM' : 'PM';
  return '$month ${dt.day}, ${dt.year}, $hour12:$minute $period';
}
