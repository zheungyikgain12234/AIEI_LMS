import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/delete_dependent.dart';

/// The lookup lists whose rows other records point at (see schema.sql).
enum MasterKind { department, programTrack, cohort, lecturerDepartment, specialization, role }

/// A column that references a lookup row. [byName] columns store the row's
/// `name`; the rest store its `id`. [nullable] columns may be cleared.
class _Ref {
  const _Ref(this.table, this.column, this.byName, this.plural, this.title, this.subtitle, {this.clearLabel});
  final String table;
  final String column;
  final bool byName;
  final String plural;
  final String title;
  final String subtitle;
  final String? clearLabel;
  String get kind => '$table.$column';
}

const _masterTables = {
  MasterKind.department: 'departments',
  MasterKind.programTrack: 'program_tracks',
  MasterKind.cohort: 'cohorts',
  MasterKind.lecturerDepartment: 'lecturer_departments',
  MasterKind.specialization: 'specializations',
  MasterKind.role: 'roles',
};

// Students keep department/role (Internal) or program_track (External) by a
// check constraint, so those can only be moved, never cleared.
const _masterRefs = {
  MasterKind.department: [_Ref('students', 'department', true, 'Students', 'name', 'student_code')],
  MasterKind.programTrack: [_Ref('students', 'program_track', true, 'Students', 'name', 'student_code')],
  MasterKind.cohort: [
    _Ref('students', 'cohort', true, 'Students', 'name', 'student_code', clearLabel: 'Clear cohort'),
    _Ref('course_sections', 'cohort_id', false, 'Classes', 'section_code', 'term', clearLabel: 'Remove cohort from class'),
  ],
  MasterKind.lecturerDepartment: [_Ref('lecturers', 'department', true, 'Lecturers', 'name', 'lecturer_code')],
  MasterKind.specialization: [_Ref('lecturers', 'specialization', true, 'Lecturers', 'name', 'lecturer_code')],
  MasterKind.role: [
    _Ref('students', 'role', true, 'Students', 'name', 'student_code'),
    _Ref('enrollment_candidates', 'role', true, 'Enrolment requests', 'student_name', 'student_email', clearLabel: 'Clear role'),
  ],
};

/// Finds the records that depend on rows about to be deleted and applies the
/// admin's per-record decisions (reassign or the "none" action) before the
/// delete itself, so nothing is orphaned or silently cascaded away.
class SupabaseAdminRelationalDelete {
  SupabaseAdminRelationalDelete(this._client);

  final SupabaseClient _client;

  List<Map<String, dynamic>> _rows(dynamic r) => [for (final x in r as List) x as Map<String, dynamic>];

  // ── Lookup lists (departments, tracks, cohorts, ...) ──────────────────

  Future<List<DeleteDependent>> masterDependents(MasterKind kind, List<String> ids) async {
    final table = _masterTables[kind]!;
    final all = _rows(await _client.from(table).select('id, name').order('name'));
    final deleting = all.where((r) => ids.contains(r['id'])).toList();
    final keep = all.where((r) => !ids.contains(r['id'])).toList();
    final result = <DeleteDependent>[];
    for (final ref in _masterRefs[kind]!) {
      final values = [for (final r in deleting) r[ref.byName ? 'name' : 'id'] as String];
      final rows = _rows(await _client.from(ref.table).select('*').inFilter(ref.column, values));
      for (final row in rows) {
        result.add(DeleteDependent(
          kind: ref.kind,
          kindPlural: ref.plural,
          id: '${row['id']}',
          title: '${row[ref.title]}',
          subtitle: '${row[ref.subtitle] ?? ''}',
          targets: [for (final k in keep) (k[ref.byName ? 'name' : 'id'] as String, k['name'] as String)],
          noneLabel: ref.clearLabel,
          noneVerb: 'cleared',
        ));
      }
    }
    return result;
  }

  Future<void> deleteMaster(MasterKind kind, List<String> ids, List<DeleteDecision> decisions) async {
    for (final ref in _masterRefs[kind]!) {
      await _applyUpdates(ref.table, ref.column, decisions.where((d) => d.kind == ref.kind));
    }
    await _client.from(_masterTables[kind]!).delete().inFilter('id', ids);
  }

  /// Sets [column] on each decided row: the target for reassignments, null
  /// for the none action. Rows sharing a target are updated in one call.
  Future<void> _applyUpdates(String table, String column, Iterable<DeleteDecision> decisions) async {
    final byTarget = <String?, List<String>>{};
    for (final d in decisions) {
      byTarget.putIfAbsent(d.targetId, () => []).add(d.id);
    }
    for (final e in byTarget.entries) {
      await _client.from(table).update({column: e.key}).inFilter('id', e.value);
    }
  }

  // ── Lecturers ─────────────────────────────────────────────────────────

  Future<List<DeleteDependent>> lecturerDependents(List<String> ids) async {
    final others = _rows(await _client.from('lecturers').select('id, name').order('name'))
        .where((l) => !ids.contains(l['id']))
        .toList();
    final targets = [for (final l in others) (l['id'] as String, l['name'] as String)];
    final sections = _rows(await _client
        .from('course_sections')
        .select('id, section_code, term, courses(course_code, course_title)')
        .inFilter('lecturer_id', ids));
    final announcements = _rows(await _client
        .from('course_announcements')
        .select('id, title, course_sections(section_code)')
        .inFilter('lecturer_id', ids));
    return [
      for (final s in sections)
        DeleteDependent(
          kind: 'sections',
          kindPlural: 'Classes',
          id: s['id'] as String,
          title: '${s['section_code']}',
          subtitle: '${(s['courses'] as Map?)?['course_code'] ?? ''} • ${s['term']}',
          targets: targets,
          noneLabel: 'Leave class without a lecturer',
          noneVerb: 'unassigned',
        ),
      for (final a in announcements)
        DeleteDependent(
          kind: 'announcements',
          kindPlural: 'Announcements',
          id: a['id'] as String,
          title: '${a['title']}',
          subtitle: '${(a['course_sections'] as Map?)?['section_code'] ?? ''}',
          targets: targets,
          noneLabel: 'Delete this announcement',
        ),
    ];
  }

  Future<void> deleteLecturers(List<String> ids, List<DeleteDecision> decisions) async {
    await _applyUpdates('course_sections', 'lecturer_id', decisions.where((d) => d.kind == 'sections'));
    final ann = decisions.where((d) => d.kind == 'announcements');
    await _applyUpdates('course_announcements', 'lecturer_id', ann.where((d) => d.targetId != null));
    final dropped = [for (final d in ann) if (d.targetId == null) d.id];
    if (dropped.isNotEmpty) await _client.from('course_announcements').delete().inFilter('id', dropped);
    // Grader references have no ON DELETE action; keep the grades, drop the name.
    await _client.from('content_block_submissions').update({'graded_by': null}).inFilter('graded_by', ids);
    await _client.from('student_materials').update({'graded_by': null}).inFilter('graded_by', ids);
    await _client.from('lecturers').delete().inFilter('id', ids);
  }

  // ── Course tags ───────────────────────────────────────────────────────

  Future<List<DeleteDependent>> tagDependents(List<String> ids) async {
    final tags = _rows(await _client.from('tags').select('id, label').order('label'));
    final keep = tags.where((t) => !ids.contains(t['id'])).toList();
    final links = _rows(await _client
        .from('course_tags')
        .select('course_id, tag_id, courses(course_code, course_title)')
        .inFilter('tag_id', ids));
    final courseIds = {for (final l in links) l['course_id'] as String};
    final existing = courseIds.isEmpty
        ? <Map<String, dynamic>>[]
        : _rows(await _client.from('course_tags').select('course_id, tag_id').inFilter('course_id', courseIds.toList()));
    final seen = <String>{};
    final result = <DeleteDependent>[];
    for (final l in links) {
      final courseId = l['course_id'] as String;
      if (!seen.add(courseId)) continue;
      final has = {for (final e in existing) if (e['course_id'] == courseId) e['tag_id'] as String};
      final course = l['courses'] as Map?;
      result.add(DeleteDependent(
        kind: 'course_tags',
        kindPlural: 'Courses',
        id: courseId,
        title: '${course?['course_code'] ?? ''}',
        subtitle: '${course?['course_title'] ?? ''}',
        targets: [for (final t in keep) if (!has.contains(t['id'])) (t['id'] as String, t['label'] as String)],
        noneLabel: 'Just remove the tag',
        noneVerb: 'untagged',
      ));
    }
    return result;
  }

  Future<void> deleteTags(List<String> ids, List<DeleteDecision> decisions) async {
    final links = [
      for (final d in decisions)
        if (d.targetId != null) {'course_id': d.id, 'tag_id': d.targetId},
    ];
    if (links.isNotEmpty) await _client.from('course_tags').upsert(links);
    await _client.from('tags').delete().inFilter('id', ids);
  }

  // ── Classes (course_sections) ─────────────────────────────────────────

  Future<List<DeleteDependent>> sectionDependents(List<String> ids) async {
    final sections = _rows(await _client.from('course_sections').select('id, course_id, section_code'));
    final enrolled = _rows(await _client
        .from('student_courses')
        .select('student_id, course_id, section_id, students(name, student_code), courses(course_code)')
        .inFilter('section_id', ids));
    return [
      for (final e in enrolled)
        DeleteDependent(
          kind: 'enrolments',
          kindPlural: 'Enrolled students',
          id: '${e['student_id']}|${e['course_id']}',
          title: '${(e['students'] as Map?)?['name'] ?? ''}',
          subtitle: '${(e['students'] as Map?)?['student_code'] ?? ''} • ${(e['courses'] as Map?)?['course_code'] ?? ''}',
          targets: [
            for (final s in sections)
              if (s['course_id'] == e['course_id'] && !ids.contains(s['id'])) (s['id'] as String, s['section_code'] as String),
          ],
          noneLabel: 'Keep enrolled, no class',
          noneVerb: 'left without a class',
        ),
    ];
  }

  Future<void> deleteSections(List<String> ids, List<DeleteDecision> decisions) async {
    for (final d in decisions) {
      if (d.targetId == null) continue;
      final parts = d.id.split('|');
      await _client.from('student_courses').update({'section_id': d.targetId}).eq('student_id', parts[0]).eq('course_id', parts[1]);
    }
    await _client.from('course_sections').delete().inFilter('id', ids);
  }

  // ── Courses ───────────────────────────────────────────────────────────

  Future<List<DeleteDependent>> courseDependents(List<String> ids) async {
    final courses = _rows(await _client.from('courses').select('id, course_code, course_title').order('course_code'));
    final keep = [for (final c in courses) if (!ids.contains(c['id'])) c];
    (String, String) label(Map<String, dynamic> c) => (c['id'] as String, '${c['course_code']} • ${c['course_title']}');

    final enrolments = _rows(await _client
        .from('student_courses')
        .select('student_id, course_id, students(name, student_code), courses(course_code)')
        .inFilter('course_id', ids));
    final studentIds = {for (final e in enrolments) '${e['student_id']}'};
    final theirs = studentIds.isEmpty
        ? <Map<String, dynamic>>[]
        : _rows(await _client.from('student_courses').select('student_id, course_id').inFilter('student_id', studentIds.toList()));
    final awards = _rows(await _client
        .from('badge_awards')
        .select('id, student_id, students(name), courses(course_code), certifications(title)')
        .inFilter('course_id', ids));
    return [
      for (final e in enrolments)
        DeleteDependent(
          kind: 'enrolments',
          kindPlural: 'Enrolled students',
          id: '${e['student_id']}|${e['course_id']}',
          title: '${(e['students'] as Map?)?['name'] ?? ''}',
          subtitle: '${(e['students'] as Map?)?['student_code'] ?? ''} • ${(e['courses'] as Map?)?['course_code'] ?? ''}',
          targets: [
            for (final c in keep)
              if (!theirs.any((t) => '${t['student_id']}' == '${e['student_id']}' && t['course_id'] == c['id'])) label(c),
          ],
          noneLabel: 'Remove enrolment',
          noneVerb: 'removed',
        ),
      for (final a in awards)
        DeleteDependent(
          kind: 'awards',
          kindPlural: 'Badge awards',
          id: a['id'] as String,
          title: '${(a['students'] as Map?)?['name'] ?? ''}',
          subtitle: '${(a['certifications'] as Map?)?['title'] ?? ''} • ${(a['courses'] as Map?)?['course_code'] ?? ''}',
          targets: [for (final c in keep) label(c)],
          noneLabel: 'Delete this award',
        ),
    ];
  }

  Future<void> deleteCourses(List<String> ids, List<DeleteDecision> decisions) async {
    for (final d in decisions.where((d) => d.kind == 'enrolments' && d.targetId != null)) {
      final parts = d.id.split('|');
      await _client
          .from('student_courses')
          .update({'course_id': d.targetId, 'section_id': null})
          .eq('student_id', parts[0])
          .eq('course_id', parts[1]);
    }
    final awards = decisions.where((d) => d.kind == 'awards');
    await _applyUpdates('badge_awards', 'course_id', awards.where((d) => d.targetId != null));
    final dropped = [for (final d in awards) if (d.targetId == null) d.id];
    if (dropped.isNotEmpty) await _client.from('badge_awards').delete().inFilter('id', dropped);
    await _client.from('courses').delete().inFilter('id', ids);
  }

  /// Human-readable list of what else disappears with these courses.
  Future<String?> courseCascadeNote(List<String> ids) async {
    final classes = (await _client.from('course_sections').select('id').inFilter('course_id', ids) as List).length;
    return classes == 0 ? null : 'Its $classes class${classes == 1 ? '' : 'es'}, with their modules, content and announcements, will be deleted too.';
  }

  // ── Students ──────────────────────────────────────────────────────────

  /// Students have nothing to be reassigned to; list what goes with them.
  Future<String?> studentCascadeNote(List<String> ids) async {
    final enrolments = (await _client.from('student_courses').select('course_id').inFilter('student_id', ids) as List).length;
    final awards = (await _client.from('badge_awards').select('id').inFilter('student_id', ids) as List).length;
    if (enrolments == 0 && awards == 0) return null;
    return 'This also deletes their $enrolments course enrolment${enrolments == 1 ? '' : 's'}, $awards badge award${awards == 1 ? '' : 's'}, and all progress and submissions.';
  }
}
