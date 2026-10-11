import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/core/utils/csv_parser.dart';
import 'package:stitch_aiei_lms/core/utils/file_download.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_students_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturer_syllabus_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_submission_grading_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/content_block.dart';
import 'package:stitch_aiei_lms/domain/models/content_block_submission.dart';
import 'package:stitch_aiei_lms/domain/models/roster_student.dart';
import 'widgets/faculty_mobile_top_bar.dart';

// ---------------------------------------------------------------------------
// ImportMarksScreen — marks for a physical (paper-based) exam/assignment.
// The lecturer downloads the class's student list as a CSV template, fills in
// each student's marks (0 for an absent student — blank means "not marked
// yet"), and imports it back. Each imported mark is stored as a `graded`
// content_block_submissions row, so the Student Directory picks it up like
// any other graded assessment. A student with no mark yet keeps the item on
// the Grading and Submissions list.
// ---------------------------------------------------------------------------
class ImportMarksScreen extends StatefulWidget {
  final String contentBlockId;
  final String sectionId;
  final String title;

  const ImportMarksScreen({super.key, required this.contentBlockId, required this.sectionId, required this.title});

  @override
  State<ImportMarksScreen> createState() => _ImportMarksScreenState();
}

class _ImportMarksScreenState extends State<ImportMarksScreen> {
  final _rosterRepository = SupabaseAdminStudentsRepositoryImpl(Supabase.instance.client);
  final _gradingRepository = SupabaseSubmissionGradingRepositoryImpl(Supabase.instance.client);
  final _syllabusRepository = SupabaseLecturerSyllabusRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  bool _importing = false;
  List<RosterStudent> _roster = const [];
  Map<String, ContentBlockSubmission> _submissions = const {};
  ContentBlock? _block;

  double get _maxMarks => _block?.maxMarks ?? 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final roster = await _rosterRepository.getSectionRoster(widget.sectionId);
    final submissions = await _gradingRepository.getRosterSubmissions(widget.contentBlockId);
    final block = await _syllabusRepository.getContentBlock(widget.contentBlockId);
    if (!mounted) return;
    final sortedRoster = [...roster];
    sortedRoster.sort((a, b) => a.studentCode.toLowerCase().compareTo(b.studentCode.toLowerCase()));
    setState(() {
      _roster = sortedRoster;
      _submissions = submissions;
      _block = block;
      _isLoading = false;
    });
  }

  double? _marksFor(RosterStudent s) {
    final sub = _submissions[s.studentId];
    return sub != null && sub.isGraded ? sub.totalScore : null;
  }

  int get _missingCount => _roster.where((s) => _marksFor(s) == null).length;

  static String _fmt(double v) => v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toString();

  void _snack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _downloadTemplate() async {
    final lines = [
      '# Fill in the marks column. Marks must be between 0 and ${_fmt(_maxMarks)}. Enter 0 for an absent student - leave blank only if not marked yet.',
      '# Do not change studentCode. Lines starting with # are ignored.',
      'studentCode,name,marks',
      for (final s in _roster) '${csvEscape(s.studentCode)},${csvEscape(s.name)},${_marksFor(s) == null ? '' : _fmt(_marksFor(s)!)}',
    ];
    final bytes = Uint8List.fromList(utf8.encode('${lines.join('\n')}\n'));
    final fileName = '${widget.title.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}_marks.csv';
    try {
      if (supportsBrowserDownload) {
        downloadBytes(fileName, bytes);
        if (!mounted) return;
        _snack('Template downloaded.');
        return;
      }
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save marks template',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes,
      );
      if (path == null) return;
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        await File(path.toLowerCase().endsWith('.csv') ? path : '$path.csv').writeAsBytes(bytes);
      }
      if (!mounted) return;
      _snack('Template saved.');
    } catch (e) {
      if (!mounted) return;
      _snack('Could not save template: $e');
    }
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv'], withData: true);
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) return;

    final rows = parseCsv(utf8.decode(bytes)).where((r) => !r.first.trimLeft().startsWith('#')).toList();
    if (rows.length < 2) {
      _snack('CSV has no data rows.');
      return;
    }
    final header = rows.first.map((h) => h.trim().toLowerCase()).toList();
    final iCode = header.indexOf('studentcode');
    final iMarks = header.indexOf('marks');
    if (iCode == -1 || iMarks == -1) {
      _snack('CSV must have studentCode and marks columns — download the template to start.');
      return;
    }

    final studentByCode = {for (final s in _roster) s.studentCode.trim().toLowerCase(): s};
    final errors = <String>[];
    final toSave = <(RosterStudent, double)>[];
    var skippedBlank = 0;
    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      String cell(int i) => i < row.length ? row[i].trim() : '';
      final code = cell(iCode);
      final raw = cell(iMarks);
      if (code.isEmpty) continue;
      final student = studentByCode[code.toLowerCase()];
      if (student == null) {
        errors.add('Row ${r + 1}: "$code" is not enrolled in this class.');
        continue;
      }
      if (raw.isEmpty) {
        skippedBlank++;
        continue;
      }
      final marks = double.tryParse(raw);
      if (marks == null) {
        errors.add('Row ${r + 1} ($code): "$raw" is not a number.');
        continue;
      }
      if (marks < 0 || marks > _maxMarks) {
        errors.add('Row ${r + 1} ($code): $raw is outside 0–${_fmt(_maxMarks)}.');
        continue;
      }
      toSave.add((student, marks));
    }

    setState(() => _importing = true);
    var saved = 0;
    for (final (student, marks) in toSave) {
      try {
        await _gradingRepository.saveGrade(
          contentBlockId: widget.contentBlockId,
          studentId: student.studentId,
          marks: const {},
          totalScore: marks,
          gradedByLecturerId: DemoIdentity.lecturerId,
        );
        saved++;
      } catch (e) {
        errors.add('${student.studentCode}: $e');
      }
    }
    if (!mounted) return;
    setState(() => _importing = false);
    await _load();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import complete'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$saved mark${saved == 1 ? '' : 's'} saved.'
                    '${skippedBlank > 0 ? ' $skippedBlank blank row${skippedBlank == 1 ? '' : 's'} skipped (not marked yet).' : ''}'
                    '${errors.isEmpty ? '' : ' ${errors.length} row${errors.length == 1 ? '' : 's'} failed.'}'),
                if (errors.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final e in errors) Text(e, style: FacultyTypography.bodySm(color: FacultyColors.error)),
                ],
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final missing = _missingCount;
    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: FacultyMobileTopBar(title: widget.title),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Import Marks', style: FacultyTypography.headlineMd()),
                  const SizedBox(height: 4),
                  Text(
                    'Download the student list, fill in each student\'s marks out of ${_fmt(_maxMarks)} (enter 0 for an absent student), then import the file.',
                    style: FacultyTypography.bodySm(),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _roster.isEmpty ? null : _downloadTemplate,
                        icon: const Icon(Icons.download_outlined, size: 18),
                        label: const Text('Download CSV Template'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _importing || _roster.isEmpty ? null : _importCsv,
                        icon: _importing
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.upload_file_outlined, size: 18),
                        label: const Text('Import Marks CSV'),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: missing == 0 ? FacultyColors.surfaceContainer : FacultyColors.errorContainer,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          missing == 0 ? 'All students marked' : '$missing without marks',
                          style: FacultyTypography.labelXs(color: missing == 0 ? FacultyColors.onSurface : FacultyColors.error).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: FacultyColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
                    ),
                    child: _roster.isEmpty
                        ? Padding(padding: const EdgeInsets.all(24), child: Text('No students are enrolled in this class.', style: FacultyTypography.bodyMd()))
                        : Column(children: [_headerRow(), for (final s in _roster) _studentRow(s)]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerRow() {
    final style = FacultyTypography.labelXs().copyWith(fontWeight: FontWeight.w700);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: FacultyColors.surfaceContainerLow,
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('STUDENT CODE', style: style)),
          Expanded(flex: 4, child: Text('STUDENT', style: style)),
          Expanded(flex: 2, child: Text('MARKS (/${_fmt(_maxMarks)})', textAlign: TextAlign.right, style: style)),
        ],
      ),
    );
  }

  Widget _studentRow(RosterStudent s) {
    final marks = _marksFor(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: FacultyColors.surfaceContainerLow))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(s.studentCode, style: FacultyTypography.bodySm(color: FacultyColors.secondary), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 4, child: Text(s.name, style: FacultyTypography.bodyMd(color: FacultyColors.onSurface), overflow: TextOverflow.ellipsis)),
          Expanded(
            flex: 2,
            child: Text(
              marks == null ? 'No marks yet' : _fmt(marks),
              textAlign: TextAlign.right,
              style: marks == null
                  ? FacultyTypography.labelXs(color: FacultyColors.error)
                  : FacultyTypography.titleSm(color: FacultyColors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
