String _two(int n) => n.toString().padLeft(2, '0');

/// The one date format used everywhere in the app, e.g. "05/01/2026"
/// (DD/MM/YYYY), without pulling in the `intl` package.
String formatDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

/// 12-hour clock time, e.g. "3:30 PM".
String _formatTime12(DateTime dt) {
  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final period = dt.hour < 12 ? 'AM' : 'PM';
  return '$hour12:${_two(dt.minute)} $period';
}

/// Formats a due date/time, e.g. "05/01/2026, 3:30 PM".
String formatDueDate(DateTime dt) => '${formatDate(dt)}, ${_formatTime12(dt)}';

/// "05/01/2026, 9:00 AM – 12:00 PM" for a same-day range, otherwise both
/// full date/times.
String formatDateRange(DateTime start, DateTime? end) {
  if (end == null) return formatDueDate(start);
  final sameDay = start.year == end.year && start.month == end.month && start.day == end.day;
  if (!sameDay) return '${formatDueDate(start)} – ${formatDueDate(end)}';
  return '${formatDueDate(start)} – ${_formatTime12(end)}';
}
