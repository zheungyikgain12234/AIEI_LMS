import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_typography.dart';

/// One class as the calendar needs it: which weekday and time it meets, where,
/// and the date range it runs over.
class CalendarClass {
  final String title;

  /// 1 = Monday … 7 = Sunday; null when the class has no fixed day.
  final int? weekday;
  final String? startTime;
  final String? endTime;

  /// A room, or "Online"; empty when unknown.
  final String where;
  final DateTime? startDate;
  final DateTime? endDate;

  const CalendarClass({
    required this.title,
    required this.weekday,
    this.startTime,
    this.endTime,
    this.where = '',
    this.startDate,
    this.endDate,
  });

  /// 1–7 from a day name such as "Thursday" or "Thu"; null if unrecognised.
  static int? weekdayFromName(String? name) {
    const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    if (name == null || name.trim().length < 3) return null;
    final i = days.indexOf(name.trim().substring(0, 3).toLowerCase());
    return i < 0 ? null : i + 1;
  }

  /// Reads a schedule line such as "Thu 14:00–17:00 • Room 204" (or
  /// "Thursday 09:00–11:00 • Online").
  factory CalendarClass.fromScheduleText({
    required String title,
    required String scheduleText,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final parts = scheduleText.split(' • ');
    final dayTime = parts.first.trim();
    final times = RegExp(r'(\d{1,2}:\d{2})\s*[–-]\s*(\d{1,2}:\d{2})').firstMatch(dayTime);
    return CalendarClass(
      title: title,
      weekday: weekdayFromName(dayTime.split(' ').first),
      startTime: times?.group(1),
      endTime: times?.group(2),
      where: parts.length > 1 ? parts.sublist(1).join(' • ').trim() : '',
      startDate: startDate,
      endDate: endDate,
    );
  }
}

/// A month calendar on a blue background. Every day a class meets is
/// highlighted in green — the class's weekday, repeating every week, but only
/// between the class's own start and end dates. Hovering a highlighted day
/// shows the date, time and class.
class ClassCalendar extends StatefulWidget {
  final List<CalendarClass> classes;

  const ClassCalendar({super.key, required this.classes});

  @override
  State<ClassCalendar> createState() => _ClassCalendarState();
}

class _ClassCalendarState extends State<ClassCalendar> {
  static const _blue = Color(0xFF2F62C4);
  static const _green = Color(0xFF2E9E5B);
  static const _weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  static String _hhmm(String? t) => t == null || t.length < 5 ? '' : t.substring(0, 5);

  /// The classes that meet on [day]: its weekday matches and the day lies
  /// within the class's date range. A class without both dates is not shown.
  List<CalendarClass> _meeting(DateTime day) {
    return [
      for (final c in widget.classes)
        if (c.weekday != null &&
            c.startDate != null &&
            c.endDate != null &&
            c.weekday == day.weekday &&
            !day.isBefore(c.startDate!) &&
            !day.isAfter(c.endDate!))
          c,
    ];
  }

  String _tooltip(DateTime day, List<CalendarClass> classes) {
    final date = '${_weekdayNames[day.weekday - 1].substring(0, 3)}, ${day.day} ${_monthNames[day.month - 1].substring(0, 3)} ${day.year}';
    final lines = [
      for (final c in classes)
        '${_hhmm(c.startTime)}${c.endTime == null ? '' : '–${_hhmm(c.endTime)}'}  ${c.title}${c.where.isEmpty ? '' : ' (${c.where})'}',
    ];
    return '$date\n${lines.join('\n')}';
  }

  void _shift(int months) => setState(() => _month = DateTime(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = first.weekday - 1; // Monday-first grid
    final cellCount = ((leading + daysInMonth + 6) ~/ 7) * 7;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            children: [
              _arrow(Icons.chevron_left, () => _shift(-1)),
              Expanded(
                child: Text(
                  '${_monthNames[_month.month - 1]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelMd(color: Colors.white).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _arrow(Icons.chevron_right, () => _shift(1)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final letter in _weekdayLetters)
                Expanded(
                  child: Center(child: Text(letter, style: AppTypography.labelSm(color: Colors.white70).copyWith(fontWeight: FontWeight.w600))),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var row = 0; row < cellCount ~/ 7; row++)
            Row(
              children: [
                for (var col = 0; col < 7; col++) Expanded(child: _cell(row * 7 + col - leading + 1, daysInMonth, today)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: const EdgeInsets.all(2), child: Icon(icon, size: 20, color: Colors.white)),
      );

  Widget _cell(int dayNumber, int daysInMonth, DateTime today) {
    if (dayNumber < 1 || dayNumber > daysInMonth) return const SizedBox(height: 30);
    final day = DateTime(_month.year, _month.month, dayNumber);
    final classes = _meeting(day);
    final highlighted = classes.isNotEmpty;
    final isToday = day == today;
    final cell = Container(
      height: 26,
      margin: const EdgeInsets.all(2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: highlighted ? _green : Colors.transparent,
        shape: BoxShape.circle,
        border: isToday ? Border.all(color: Colors.white, width: 1.5) : null,
      ),
      child: Text(
        '$dayNumber',
        style: AppTypography.labelSm(color: Colors.white).copyWith(fontWeight: highlighted || isToday ? FontWeight.w700 : FontWeight.w400),
      ),
    );
    if (!highlighted) return SizedBox(height: 30, child: cell);
    return SizedBox(
      height: 30,
      child: Tooltip(
        message: _tooltip(day, classes),
        waitDuration: const Duration(milliseconds: 150),
        preferBelow: false,
        child: MouseRegion(cursor: SystemMouseCursors.click, child: cell),
      ),
    );
  }
}
