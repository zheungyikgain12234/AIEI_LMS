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

/// "Jan 5, 2026, 9:00 AM – 12:00 PM" for a same-day range, otherwise both
/// full date/times.
String formatDateRange(DateTime start, DateTime? end) {
  if (end == null) return formatDueDate(start);
  final sameDay = start.year == end.year && start.month == end.month && start.day == end.day;
  if (!sameDay) return '${formatDueDate(start)} – ${formatDueDate(end)}';
  final endText = formatDueDate(end);
  return '${formatDueDate(start)} – ${endText.substring(endText.indexOf(',', endText.indexOf(',') + 1) + 2)}';
}
