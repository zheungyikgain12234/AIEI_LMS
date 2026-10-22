import 'package:stitch_aiei_lms/core/session/app_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/domain/models/delete_dependent.dart';

/// The lookup lists whose rows other records point at (see schema.sql).
enum MasterKind {
  department,
  programme,
  programTrack,
  semester,
  lecturerDepartment,
  specialization,
  role,
}

/// A column that references a lookup row. [byName] columns store the row's
/// `name`; the rest store its `id`.
class _Ref {
  const _Ref(
    this.table,
    this.column,
    this.byName,
    this.plural,
    this.title,
    this.subtitle,
  );
  final String table;
  final String column;
  final bool byName;
  final String plural;
  final String title;
  final String subtitle;
  String get kind => '$table.$column';
}

const _masterTables = {
  MasterKind.department: 'departments',
  MasterKind.programme: 'programmes',
  MasterKind.programTrack: 'program_tracks',
  MasterKind.semester: 'semesters',
  MasterKind.lecturerDepartment: 'lecturer_departments',
  MasterKind.specialization: 'specializations',
  MasterKind.role: 'roles',
};

// Students keep department/role (Internal) or program_track (External) by a
// check constraint, so those can only be moved, never cleared. Semesters are
// deleted together with their classes instead (see [deleteSemesters]).
const _masterRefs = <MasterKind, List<_Ref>>{
  MasterKind.department: [
    _Ref('students', 'department', true, 'Students', 'name', 'student_code'),
  ],
  MasterKind.programTrack: [
    _Ref('students', 'program_track', true, 'Students', 'name', 'student_code'),
  ],
  // Public students store their programme; programme_tracks link rows cascade.
  MasterKind.programme: [
    _Ref('students', 'programme', true, 'Students', 'name', 'student_code'),
  ],
  MasterKind.semester: <_Ref>[],
  MasterKind.lecturerDepartment: [
    _Ref('lecturers', 'department', true, 'Lecturers', 'name', 'lecturer_code'),
  ],
  // Lecturers hold several competencies through lecturer_competencies link
  // rows, which cascade.
  MasterKind.specialization: <_Ref>[],
  MasterKind.role: [
    _Ref('students', 'role', true, 'Students', 'name', 'student_code'),
  ],
};

/// Finds the records that depend on rows about to be deleted and applies the
/// admin's per-record decisions (reassign or the "none" action) before the
/// delete itself, so nothing is orphaned or silently cascaded away.
class SupabaseAdminRelationalDelete {
  SupabaseAdminRelationalDelete(this._client);

  final SupabaseClient _client;

  List<Map<String, dynamic>> _rows(dynamic r) => [
    for (final x in r as List) x as Map<String, dynamic>,
  ];

  // ── Lookup lists (departments, tracks, semesters, ...) ──────────────────

  Future<List<DeleteDependent>> masterDependents(
    MasterKind kind,
    List<String> ids,
  ) async {
    final table = _masterTables[kind]!;
    final all = _rows(
      await _client.from(table).select('id, name').order('name'),
    );
    final deleting = all.where((r) => ids.contains(r['id'])).toList();
    final keep = all.where((r) => !ids.contains(r['id'])).toList();
    final result = <DeleteDependent>[];
    for (final ref in _masterRefs[kind]!) {
      final values = [
        for (final r in deleting) r[ref.byName ? 'name' : 'id'] as String,
      ];
      final rows = _rows(
        await _client.from(ref.table).select('*').inFilter(ref.column, values),
      );
      for (final row in rows) {
        result.add(
          DeleteDependent(
            kind: ref.kind,
            kindPlural: ref.plural,
            id: '${row['id']}',
            title: '${row[ref.title]}',
            subtitle: '${row[ref.subtitle] ?? ''}',
            targets: [
              for (final k in keep)
                (k[ref.byName ? 'name' : 'id'] as String, k['name'] as String),
            ],
          ),
        );
      }
    }
    return result;
  }

  Future<void> deleteMaster(
    MasterKind kind,
    List<String> ids,
    List<DeleteDecision> decisions,
  ) async {
    if (kind == MasterKind.semester) return deleteSemesters(ids);
    for (final ref in _masterRefs[kind]!) {
      await _applyUpdates(
        ref.table,
        ref.column,
        decisions.where((d) => d.kind == ref.kind),
      );
    }
    await _client.from(_masterTables[kind]!).delete().inFilter('id', ids);
  }

  /// Sets [column] on each decided row: the target for reassignments, null
  /// for the none action. Rows sharing a target are updated in one call.
  Future<void> _applyUpdates(
    String table,
    String column,
    Iterable<DeleteDecision> decisions,
  ) async {
    final byTarget = <String?, List<String>>{};
    for (final d in decisions) {
      byTarget.putIfAbsent(d.targetId, () => []).add(d.id);
    }
    for (final e in byTarget.entries) {
      await _client.from(table).update({column: e.key}).inFilter('id', e.value);
    }
  }

  // ── Semesters ───────────────────────────────────────────────────────────

  /// Counts what deleting these semesters takes with it, for the warning text.
  Future<({int classes, int enrolments})> semesterImpact(List<String> ids) async {
    final sections = _rows(
      await _client
          .from('course_sections')
          .select('id')
          .inFilter('semester_id', ids),
    );
    final sectionIds = [for (final x in sections) x['id'] as String];
    final enrolments = sectionIds.isEmpty
        ? 0
        : (await _client
                      .from('student_courses')
                      .select('student_id')
                      .inFilter('section_id', sectionIds)
                  as List)
              .length;
    return (classes: sections.length, enrolments: enrolments);
  }

  /// Deletes the semesters together with their classes and those classes'
  /// enrolments. Students merely lose their semester label.
  Future<void> deleteSemesters(List<String> ids) async {
    final sections = _rows(
      await _client
          .from('course_sections')
          .select('id')
          .inFilter('semester_id', ids),
    );
    final sectionIds = [for (final x in sections) x['id'] as String];
    if (sectionIds.isNotEmpty) {
      await _client
          .from('student_courses')
          .delete()
          .inFilter('section_id', sectionIds);
      await _client.from('course_sections').delete().inFilter('id', sectionIds);
    }
    final names = _rows(
      await _client.from('semesters').select('name').inFilter('id', ids),
    );
    await _client.from('students').update({'semester': null}).inFilter('semester', [
      for (final n in names) n['name'] as String,
    ]);
    await _client.from('semesters').delete().inFilter('id', ids);
  }

  // ── Course tags ───────────────────────────────────────────────────────

  Future<List<DeleteDependent>> tagDependents(List<String> ids) async {
    final tags = _rows(
      await _client.from('tags').select('id, label').order('label'),
    );
    final keep = tags.where((t) => !ids.contains(t['id'])).toList();
    final links = _rows(
      await _client
          .from('course_tags')
          .select('course_id, tag_id, courses(course_code, course_title)')
          .inFilter('tag_id', ids),
    );
    final courseIds = {for (final l in links) l['course_id'] as String};
    final existing = courseIds.isEmpty
        ? <Map<String, dynamic>>[]
        : _rows(
            await _client
                .from('course_tags')
                .select('course_id, tag_id')
                .inFilter('course_id', courseIds.toList()),
          );
    final seen = <String>{};
    final result = <DeleteDependent>[];
    for (final l in links) {
      final courseId = l['course_id'] as String;
      if (!seen.add(courseId)) continue;
      final has = {
        for (final e in existing)
          if (e['course_id'] == courseId) e['tag_id'] as String,
      };
      final course = l['courses'] as Map?;
      result.add(
        DeleteDependent(
          kind: 'course_tags',
          kindPlural: 'Courses',
          id: courseId,
          title: displayCode((course?['course_code'] as String?) ?? ''),
          subtitle: '${course?['course_title'] ?? ''}',
          targets: [
            for (final t in keep)
              if (!has.contains(t['id']))
                (t['id'] as String, t['label'] as String),
          ],
        ),
      );
    }
    return result;
  }

  Future<void> deleteTags(
    List<String> ids,
    List<DeleteDecision> decisions,
  ) async {
    final links = [
      for (final d in decisions)
        if (d.targetId != null) {'course_id': d.id, 'tag_id': d.targetId},
    ];
    if (links.isNotEmpty) await _client.from('course_tags').upsert(links);
    await _client.from('tags').delete().inFilter('id', ids);
  }

  // ── Classes (course_sections) ─────────────────────────────────────────

  /// Students enrolled in a deleted class lose that enrolment too.
  Future<void> deleteSections(List<String> ids) async {
    await _client.from('student_courses').delete().inFilter('section_id', ids);
    await _client.from('course_sections').delete().inFilter('id', ids);
  }

  // ── Courses ───────────────────────────────────────────────────────────

  Future<List<DeleteDependent>> courseDependents(List<String> ids) async {
    final courses = _rows(
      await _client
          .from('courses')
          .select('id, course_code, course_title')
          .order('course_code'),
    );
    final keep = [
      for (final c in courses)
        if (!ids.contains(c['id'])) c,
    ];
    (String, String) label(Map<String, dynamic> c) =>
        (c['id'] as String, '${displayCode(c['course_code'] as String)} • ${c['course_title']}');

    final awards = _rows(
      await _client
          .from('badge_awards')
          .select(
            'id, student_id, students(name), courses(course_code), certifications(title)',
          )
          .inFilter('course_id', ids),
    );
    return [
      for (final a in awards)
        DeleteDependent(
          kind: 'awards',
          kindPlural: 'Badge awards',
          id: a['id'] as String,
          title: '${(a['students'] as Map?)?['name'] ?? ''}',
          subtitle:
              '${(a['certifications'] as Map?)?['title'] ?? ''} • ${displayCode(((a['courses'] as Map?)?['course_code'] as String?) ?? '')}',
          targets: [for (final c in keep) label(c)],
          noneLabel: 'Delete this award',
        ),
    ];
  }

  Future<void> deleteCourses(
    List<String> ids,
    List<DeleteDecision> decisions,
  ) async {
    final awards = decisions.where((d) => d.kind == 'awards');
    await _applyUpdates(
      'badge_awards',
      'course_id',
      awards.where((d) => d.targetId != null),
    );
    final dropped = [
      for (final d in awards)
        if (d.targetId == null) d.id,
    ];
    if (dropped.isNotEmpty)
      await _client.from('badge_awards').delete().inFilter('id', dropped);
    await _client.from('courses').delete().inFilter('id', ids);
  }

  /// Human-readable list of what else disappears with these courses.
  Future<String?> courseCascadeNote(List<String> ids) async {
    final classes =
        (await _client
                    .from('course_sections')
                    .select('id')
                    .inFilter('course_id', ids)
                as List)
            .length;
    return classes == 0
        ? 'All student enrolments will be deleted too.'
        : 'Its $classes class${classes == 1 ? '' : 'es'} (with modules, content and announcements) and all student enrolments will be deleted too.';
  }

  // ── Students ──────────────────────────────────────────────────────────

  /// Students have nothing to be reassigned to; list what goes with them.
  Future<String?> studentCascadeNote(List<String> ids) async {
    final enrolments =
        (await _client
                    .from('student_courses')
                    .select('course_id')
                    .inFilter('student_id', ids)
                as List)
            .length;
    final awards =
        (await _client
                    .from('badge_awards')
                    .select('id')
                    .inFilter('student_id', ids)
                as List)
            .length;
    if (enrolments == 0 && awards == 0) return null;
    return 'This also deletes their $enrolments course enrolment${enrolments == 1 ? '' : 's'}, $awards badge award${awards == 1 ? '' : 's'}, and all progress and submissions.';
  }
}
