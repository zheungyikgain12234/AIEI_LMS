import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/session/app_session.dart';
import 'package:stitch_aiei_lms/domain/models/course_section.dart';
import 'package:stitch_aiei_lms/domain/models/lecturer.dart';
import 'package:stitch_aiei_lms/domain/repositories/lecturers_repository.dart';

class SupabaseLecturersRepositoryImpl implements LecturersRepository {
  SupabaseLecturersRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Lecturer>> getLecturers() async {
    final rows = await _client.from('lecturers').select().order('name');
    return [for (final row in rows as List) Lecturer.fromMap(row as Map<String, dynamic>)];
  }

  @override
  Future<Lecturer> getLecturerById(String id) async {
    final row = await _client.from('lecturers').select().eq('id', id).single();
    return Lecturer.fromMap(row);
  }

  @override
  Future<Map<String, List<String>>> getLecturerCourseCodes() async {
    final rows = await _client.from('lecturer_courses').select('lecturer_id, courses(course_code)');
    final result = <String, List<String>>{};
    for (final row in rows as List) {
      final lecturerId = row['lecturer_id'] as String;
      final code = displayCode((row['courses'] as Map<String, dynamic>)['course_code'] as String);
      result.putIfAbsent(lecturerId, () => []).add(code);
    }
    return result;
  }

  /// Turns the lecturer code an admin typed (without the tenant prefix) into
  /// the stored, tenant-prefixed code, after checking a lecturer really has
  /// it. Blank means "no override" and returns null.
  Future<String?> _resolveOverrideCode(String? typed) async {
    final trimmed = typed?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final stored = '${tenantPrefix()}$trimmed';
    final rows = await _client.from('lecturers').select('lecturer_code').ilike('lecturer_code', stored).limit(1);
    if ((rows as List).isEmpty) throw StateError('No lecturer has the code "$trimmed".');
    return rows.first['lecturer_code'] as String;
  }

  static const _sectionSelect ='*, courses(course_code, course_title), lecturers(name), cohorts(code, name, year)';

  @override
  Future<List<CourseSection>> getAllSections() async {
    final rows = await _client.from('course_sections').select(_sectionSelect).order('section_code');
    final counts = await _enrolledCountsBySection();
    return [
      for (final row in rows as List)
        CourseSection.fromMap(row as Map<String, dynamic>, enrolledCount: counts[row['id'] as String] ?? 0),
    ];
  }

  @override
  Future<CourseSection> getSectionById(String id) async {
    final row = await _client.from('course_sections').select(_sectionSelect).eq('id', id).single();
    final enrolled = await _client.from('student_courses').select('student_id').eq('section_id', id);
    return CourseSection.fromMap(row, enrolledCount: (enrolled as List).length);
  }

  /// Resolves a cohort's display name to its `cohorts.id` — `course_sections`
  /// stores `cohort_id` (a proper FK), but callers throughout the app still
  /// pass/compare cohorts by name, so this is the one place that bridges the
  /// two. Returns `null` if no cohort matches (e.g. an empty/blank name).
  Future<String?> _cohortIdForName(String name) async {
    if (name.isEmpty) return null;
    final row = await _client.from('cohorts').select('id').eq('name', name).maybeSingle();
    return row?['id'] as String?;
  }

  /// Number of `student_courses` rows per `section_id` — `enrolled_count` is
  /// derived, never stored, so every section listing recomputes it here.
  Future<Map<String, int>> _enrolledCountsBySection() async {
    final rows = await _client.from('student_courses').select('section_id').not('section_id', 'is', null);
    final counts = <String, int>{};
    for (final row in rows as List) {
      final sectionId = row['section_id'] as String;
      counts[sectionId] = (counts[sectionId] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<CourseSection> updateSection(
    String id, {
    DateTime? startDate,
    DateTime? endDate,
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    String? location,
    required int capacity,
    required String deliveryMode,
    required String cohort,
    required String status,
    required DateTime editStartAt,
    required DateTime editEndAt,
    String? editOverrideLecturerCode,
  }) async {
    final scheduleText = (dayOfWeek != null && startTime != null && endTime != null && location != null)
        ? '${dayOfWeek.substring(0, 3)} $startTime–$endTime • $location'
        : 'TBD';
    final cohortId = await _cohortIdForName(cohort);
    final overrideCode = await _resolveOverrideCode(editOverrideLecturerCode);
    final row = await _client
        .from('course_sections')
        .update({
          'start_date': startDate?.toIso8601String().substring(0, 10),
          'end_date': endDate?.toIso8601String().substring(0, 10),
          'day_of_week': dayOfWeek,
          'start_time': startTime,
          'end_time': endTime,
          'location': location,
          'schedule_text': scheduleText,
          'capacity': capacity,
          'delivery_mode': deliveryMode,
          'cohort_id': cohortId,
          'status': status,
          'edit_start_at': editStartAt.toUtc().toIso8601String(),
          'edit_end_at': editEndAt.toUtc().toIso8601String(),
          'edit_override_lecturer_code': overrideCode,
        })
        .eq('id', id)
        .select(_sectionSelect)
        .single();
    final enrolled = await _client.from('student_courses').select('student_id').eq('section_id', id);
    return CourseSection.fromMap(row, enrolledCount: (enrolled as List).length);
  }

  @override
  Future<void> assignLecturerToSection(String sectionId, String lecturerId) async {
    final section = await _client
        .from('course_sections')
        .select('day_of_week, start_time, end_time, start_date, end_date')
        .eq('id', sectionId)
        .single();
    final day = section['day_of_week'] as String?;
    final start = section['start_time'] as String?;
    final end = section['end_time'] as String?;
    // A class with no day/time yet (TBD) can't clash with anything.
    if (day != null && start != null && end != null) {
      await _ensureNoScheduleConflict(
        lecturerId: lecturerId,
        dayOfWeek: day,
        startTime: start,
        endTime: end,
        startDate: _parseDate(section['start_date']),
        endDate: _parseDate(section['end_date']),
        excludeSectionId: sectionId,
      );
    }
    await _client.from('course_sections').update({'lecturer_id': lecturerId}).eq('id', sectionId);
  }

  DateTime? _parseDate(Object? value) => value == null ? null : DateTime.parse(value as String);

  /// Minutes since midnight for a Postgres `time` (`"09:00:00"`) or `HH:mm`.
  int _minutes(String hms) => int.parse(hms.substring(0, 2)) * 60 + int.parse(hms.substring(3, 5));

  @override
  Future<List<CourseSection>> findScheduleConflicts({
    required String lecturerId,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    DateTime? startDate,
    DateTime? endDate,
    String? excludeSectionId,
  }) async {
    var query = _client
        .from('course_sections')
        .select(_sectionSelect)
        .eq('lecturer_id', lecturerId)
        .eq('day_of_week', dayOfWeek)
        .neq('status', 'cancelled');
    if (excludeSectionId != null) query = query.neq('id', excludeSectionId);
    final rows = await query;

    final newStart = _minutes(startTime);
    final newEnd = _minutes(endTime);
    final conflicts = <CourseSection>[];
    for (final row in rows as List) {
      final s = CourseSection.fromMap(row as Map<String, dynamic>, enrolledCount: 0);
      if (s.startTime == null || s.endTime == null) continue;
      final timesOverlap = newStart < _minutes(s.endTime!) && _minutes(s.startTime!) < newEnd;
      // Inclusive on both ends; a missing date means the class is open-ended.
      final datesOverlap = (startDate == null || s.endDate == null || !startDate.isAfter(s.endDate!)) &&
          (endDate == null || s.startDate == null || !s.startDate!.isAfter(endDate));
      if (timesOverlap && datesOverlap) conflicts.add(s);
    }
    return conflicts;
  }

  Future<void> _ensureNoScheduleConflict({
    required String lecturerId,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    DateTime? startDate,
    DateTime? endDate,
    String? excludeSectionId,
  }) async {
    final conflicts = await findScheduleConflicts(
      lecturerId: lecturerId,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      startDate: startDate,
      endDate: endDate,
      excludeSectionId: excludeSectionId,
    );
    if (conflicts.isEmpty) return;
    String ymd(DateTime? d) => d == null ? '…' : d.toIso8601String().substring(0, 10);
    final details = conflicts
        .map((s) => '${s.courseCode} ${s.sectionCode} (${s.dayOfWeek} ${s.startTime!.substring(0, 5)}–${s.endTime!.substring(0, 5)}, '
            '${ymd(s.startDate)} to ${ymd(s.endDate)})')
        .join('; ');
    final who = conflicts.first.lecturerName ?? 'This lecturer';
    throw ScheduleConflictException('$who already teaches an overlapping class: $details. '
        'Choose a different day, time or course dates.');
  }

  @override
  Future<List<CourseSection>> getSectionsForLecturers(List<String> lecturerIds) async {
    if (lecturerIds.isEmpty) return [];
    final rows = await _client
        .from('course_sections')
        .select(_sectionSelect)
        .inFilter('lecturer_id', lecturerIds)
        .order('section_code');
    return [for (final row in rows as List) CourseSection.fromMap(row as Map<String, dynamic>, enrolledCount: 0)];
  }

  @override
  Future<Lecturer> createLecturer({
    required String name,
    required String title,
    required String lecturerCode,
    required String email,
    required String department,
    required String specialization,
    required int creditsMax,
    required String status,
    required bool accredited,
    required DateTime joinDate,
  }) async {
    final row = await _client
        .from('lecturers')
        .insert({
          'name': name,
          'title': title,
          'lecturer_code': lecturerCode,
          'email': email,
          'department': department,
          'specialization': specialization,
          'credits_max': creditsMax,
          'status': status,
          'accredited': accredited,
          'join_date': joinDate.toIso8601String().substring(0, 10),
        })
        .select()
        .single();
    return Lecturer.fromMap(row);
  }

  @override
  Future<Lecturer> updateLecturer(
    String id, {
    required String name,
    required String title,
    required String lecturerCode,
    required String email,
    required String department,
    required String specialization,
    required int creditsMax,
    required String status,
    required bool accredited,
    required DateTime joinDate,
  }) async {
    final row = await _client
        .from('lecturers')
        .update({
          'name': name,
          'title': title,
          'lecturer_code': lecturerCode,
          'email': email,
          'department': department,
          'specialization': specialization,
          'credits_max': creditsMax,
          'status': status,
          'accredited': accredited,
          'join_date': joinDate.toIso8601String().substring(0, 10),
        })
        .eq('id', id)
        .select()
        .single();
    return Lecturer.fromMap(row);
  }

  @override
  Future<void> deleteLecturers(List<String> ids) async {
    final orphaned = await getSectionsForLecturers(ids);
    if (orphaned.isNotEmpty) {
      throw StateError('${orphaned.length} class${orphaned.length == 1 ? ' is' : 'es are'} still assigned to these '
          'lecturers. Reassign them before deleting.');
    }
    await _client.from('lecturers').delete().inFilter('id', ids);
  }

  @override
  Future<List<String>> getAssignedCourseIds(String lecturerId) async {
    final rows = await _client.from('lecturer_courses').select('course_id').eq('lecturer_id', lecturerId);
    return [for (final row in rows as List) row['course_id'] as String];
  }

  @override
  Future<List<LecturerClassSlot>> getAssignedSchedules(String lecturerId) async {
    final rows = await _client
        .from('course_sections')
        .select('id, course_id, cohorts(name), section_code, day_of_week, start_time, end_time')
        .eq('lecturer_id', lecturerId);
    return [
      for (final row in rows as List)
        (
          id: row['id'] as String,
          courseId: row['course_id'] as String,
          cohort: (row['cohorts'] as Map<String, dynamic>?)?['name'] as String?,
          sectionCode: displayCode(row['section_code'] as String),
          dayOfWeek: row['day_of_week'] as String?,
          startTime: row['start_time'] as String?,
          endTime: row['end_time'] as String?,
        ),
    ];
  }

  @override
  Future<void> assignCoursesToLecturer(String lecturerId, List<String> courseIds) async {
    await _client.from('lecturer_courses').upsert(
      [for (final courseId in courseIds) {'lecturer_id': lecturerId, 'course_id': courseId}],
      onConflict: 'lecturer_id,course_id',
      ignoreDuplicates: true,
    );
  }

  @override
  Future<void> unassignCoursesFromLecturer(String lecturerId, List<String> courseIds) async {
    await _client.from('lecturer_courses').delete().eq('lecturer_id', lecturerId).inFilter('course_id', courseIds);
    await _client
        .from('course_sections')
        .update({'lecturer_id': null, 'status': 'scheduled'})
        .eq('lecturer_id', lecturerId)
        .inFilter('course_id', courseIds);
  }

  @override
  Future<void> unassignSection(String sectionId) async {
    final section = await _client.from('course_sections').select('course_id, lecturer_id').eq('id', sectionId).single();
    final lecturerId = section['lecturer_id'] as String?;
    final courseId = section['course_id'] as String;
    await _client.from('course_sections').update({'lecturer_id': null, 'status': 'scheduled'}).eq('id', sectionId);
    if (lecturerId == null) return;
    final remaining = await _client
        .from('course_sections')
        .select('id')
        .eq('lecturer_id', lecturerId)
        .eq('course_id', courseId);
    if ((remaining as List).isEmpty) {
      await _client.from('lecturer_courses').delete().eq('lecturer_id', lecturerId).eq('course_id', courseId);
    }
  }

  @override
  Future<CourseSection> createSectionForCourse({
    required String courseId,
    required String classCode,
    required String lecturerId,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    required String location,
    required int capacity,
    required String deliveryMode,
    required String cohort,
    DateTime? courseStartDate,
    DateTime? courseEndDate,
    required List<String> moduleNames,
    required DateTime editStartAt,
    required DateTime editEndAt,
  }) async {
    await _ensureNoScheduleConflict(
      lecturerId: lecturerId,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      startDate: courseStartDate,
      endDate: courseEndDate,
    );
    final dayAbbrev = dayOfWeek.substring(0, 3);
    final cohortId = await _cohortIdForName(cohort);
    final row = await _client
        .from('course_sections')
        .insert({
          'course_id': courseId,
          'section_code': classCode,
          'role_label': 'Primary Instructor',
          'term': 'Fall 2025',
          'schedule_text': '$dayAbbrev $startTime–$endTime • $location',
          'day_of_week': dayOfWeek,
          'start_time': startTime,
          'end_time': endTime,
          'location': location,
          'lecturer_id': lecturerId,
          'capacity': capacity,
          'delivery_mode': deliveryMode,
          'cohort_id': cohortId,
          'start_date': courseStartDate?.toIso8601String().substring(0, 10),
          'end_date': courseEndDate?.toIso8601String().substring(0, 10),
          'status': 'scheduled',
          'edit_start_at': editStartAt.toUtc().toIso8601String(),
          'edit_end_at': editEndAt.toUtc().toIso8601String(),
        })
        .select(_sectionSelect)
        .single();
    final sectionId = row['id'] as String;
    if (moduleNames.isNotEmpty) {
      await _client.from('course_modules').insert([
        for (var i = 0; i < moduleNames.length; i++) {'section_id': sectionId, 'module_name': moduleNames[i], 'module_sorting': i},
      ]);
    }
    return CourseSection.fromMap(row, enrolledCount: 0);
  }

  @override
  Future<void> deleteSections(List<String> sectionIds) async {
    await _client.from('course_sections').delete().inFilter('id', sectionIds);
  }
}
