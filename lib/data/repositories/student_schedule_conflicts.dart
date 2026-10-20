import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/session/app_session.dart';

/// Minutes since midnight for a Postgres `time` (`"09:00:00"`) or `HH:mm`.
int _minutes(String hms) => int.parse(hms.substring(0, 2)) * 60 + int.parse(hms.substring(3, 5));

DateTime? _date(Object? value) => value == null ? null : DateTime.parse(value as String);

String _ymd(DateTime? d) => d == null ? '…' : d.toIso8601String().substring(0, 10);

/// Classes the given students are already enrolled in that clash with
/// [sectionId]: same day of week, overlapping time range and overlapping course
/// dates — the same rule used when assigning a lecturer. Returns, per student
/// id, a readable description of each clashing class; students with no clash
/// are absent. A class without a day/time yet (TBD) can't clash.
Future<Map<String, List<String>>> findStudentScheduleConflicts(
  SupabaseClient client, {
  required List<String> studentIds,
  required String sectionId,
}) async {
  if (studentIds.isEmpty) return {};
  final target = await client
      .from('course_sections')
      .select('day_of_week, start_time, end_time, start_date, end_date')
      .eq('id', sectionId)
      .single();
  final day = target['day_of_week'] as String?;
  final start = target['start_time'] as String?;
  final end = target['end_time'] as String?;
  if (day == null || start == null || end == null) return {};
  final newStart = _minutes(start);
  final newEnd = _minutes(end);
  final startDate = _date(target['start_date']);
  final endDate = _date(target['end_date']);

  final rows = await client
      .from('student_courses')
      .select('student_id, section_id, course_sections(section_code, day_of_week, start_time, end_time, start_date, end_date, status, courses(course_code))')
      .inFilter('student_id', studentIds)
      .neq('section_id', sectionId);
  final result = <String, List<String>>{};
  for (final row in rows as List) {
    final s = row['course_sections'] as Map<String, dynamic>?;
    if (s == null || s['day_of_week'] != day || s['status'] == 'cancelled') continue;
    final otherStart = s['start_time'] as String?;
    final otherEnd = s['end_time'] as String?;
    if (otherStart == null || otherEnd == null) continue;
    final timesOverlap = newStart < _minutes(otherEnd) && _minutes(otherStart) < newEnd;
    // Inclusive on both ends; a missing date means the class is open-ended.
    final otherStartDate = _date(s['start_date']);
    final otherEndDate = _date(s['end_date']);
    final datesOverlap = (startDate == null || otherEndDate == null || !startDate.isAfter(otherEndDate)) &&
        (endDate == null || otherStartDate == null || !otherStartDate.isAfter(endDate));
    if (!timesOverlap || !datesOverlap) continue;
    final code = displayCode((s['courses'] as Map<String, dynamic>?)?['course_code'] as String? ?? '');
    result.putIfAbsent((row['student_id'] as num).toString(), () => []).add(
          '${code.isEmpty ? '' : '$code '}${s['section_code']} ($day ${otherStart.substring(0, 5)}–${otherEnd.substring(0, 5)}, '
          '${_ymd(otherStartDate)} to ${_ymd(otherEndDate)})',
        );
  }
  return result;
}
