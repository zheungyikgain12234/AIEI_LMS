import 'package:stitch_aiei_lms/core/utils/date_format.dart';
import 'package:stitch_aiei_lms/domain/models/course_section.dart';

String _trim(String time) => time.length >= 5 ? time.substring(0, 5) : time;

/// The class's schedule as set by the admin when the class was created, as one
/// line of text: "Thu • 09:00–11:00 • Room 204 • 13/01/2025 to 18/12/2026".
/// Parts that were never set are left out. Returns "Schedule TBD" when nothing
/// is set.
String classScheduleText(CourseSection s) {
  final parts = <String>[
    if (s.dayOfWeek != null) s.dayOfWeek!.substring(0, 3),
    if (s.startTime != null && s.endTime != null) '${_trim(s.startTime!)}–${_trim(s.endTime!)}',
    if (s.deliveryMode == 'online') 'Online' else if (s.location != null && s.location!.isNotEmpty) s.location!,
    if (s.startDate != null && s.endDate != null)
      '${formatDate(s.startDate!)} to ${formatDate(s.endDate!)}'
    else if (s.startDate != null)
      'From ${formatDate(s.startDate!)}',
  ];
  return parts.isEmpty ? 'Schedule TBD' : parts.join(' • ');
}

/// Just the weekday and time of the class: "Thu • 09:00–11:00". Null when the
/// admin never set either.
String? classDayTimeText({String? dayOfWeek, String? startTime, String? endTime}) {
  final parts = <String>[
    if (dayOfWeek != null && dayOfWeek.length >= 3) dayOfWeek.substring(0, 3),
    if (startTime != null && endTime != null) '${_trim(startTime)}–${_trim(endTime)}',
  ];
  return parts.isEmpty ? null : parts.join(' • ');
}
