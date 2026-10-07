import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/session/app_session.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/core/utils/error_messages.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_lecturers_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/course_section.dart';
import 'package:stitch_aiei_lms/domain/models/lecturer.dart';
import 'widgets/searchable_dropdown.dart';

// ---------------------------------------------------------------------------
// ReassignOrphanedClassesScreen — shown when lecturers selected for deletion
// still teach classes. Lists every class that would be orphaned, each with a
// searchable lecturer dropdown. The lecturers are only deleted once every
// class has been reassigned (each reassignment goes through the same
// schedule-overlap check as a normal assignment). Pops `true` once the
// lecturers have been deleted.
// ---------------------------------------------------------------------------
class ReassignOrphanedClassesScreen extends StatefulWidget {
  final List<Lecturer> lecturersToDelete;

  const ReassignOrphanedClassesScreen({super.key, required this.lecturersToDelete});

  @override
  State<ReassignOrphanedClassesScreen> createState() => _ReassignOrphanedClassesScreenState();
}

class _ReassignOrphanedClassesScreenState extends State<ReassignOrphanedClassesScreen> {
  final _repository = SupabaseLecturersRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  bool _isSubmitting = false;
  List<CourseSection> _orphaned = [];
  List<Lecturer> _candidates = [];
  final Map<String, String> _newLecturerBySection = {};
  final Map<String, String> _errorBySection = {};
  String? _loadError;

  Set<String> get _deletingIds => {for (final l in widget.lecturersToDelete) l.id};

  bool get _allChosen => _orphaned.isNotEmpty && _orphaned.every((s) => _newLecturerBySection.containsKey(s.id));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sections = await _repository.getSectionsForLecturers(_deletingIds.toList());
      final lecturers = await _repository.getLecturers();
      if (!mounted) return;
      setState(() {
        _orphaned = sections;
        _candidates = lecturers.where((l) => !_deletingIds.contains(l.id)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = friendlyErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  /// Reassigns the classes one by one (in order, so a later class is checked
  /// against earlier reassignments to the same lecturer), then deletes the
  /// lecturers only if nothing is left. Classes that fail — typically a
  /// schedule overlap — stay in the list with the reason shown.
  Future<void> _submit() async {
    if (!_allChosen || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _errorBySection.clear();
    });
    final remaining = <CourseSection>[];
    for (final section in _orphaned) {
      final newLecturerId = _newLecturerBySection[section.id]!;
      try {
        await _repository.assignLecturerToSection(section.id, newLecturerId);
        await _repository.assignCoursesToLecturer(newLecturerId, [section.courseId]);
      } catch (e) {
        remaining.add(section);
        _errorBySection[section.id] = friendlyErrorMessage(e);
      }
    }
    if (!mounted) return;
    if (remaining.isNotEmpty) {
      setState(() {
        _orphaned = remaining;
        _isSubmitting = false;
      });
      return;
    }
    try {
      await _repository.deleteLecturers(_deletingIds.toList());
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete lecturers: ${friendlyErrorMessage(e)}'), backgroundColor: AdminColors.error),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String _scheduleLabel(CourseSection s) {
    if (s.dayOfWeek == null || s.startTime == null || s.endTime == null) return 'Schedule TBD';
    final dates = s.startDate == null && s.endDate == null
        ? ''
        : ' • ${_ymd(s.startDate)} to ${_ymd(s.endDate)}';
    return '${s.dayOfWeek} ${s.startTime!.substring(0, 5)}–${s.endTime!.substring(0, 5)}$dates';
  }

  String _ymd(DateTime? d) => d == null ? '…' : d.toIso8601String().substring(0, 10);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: AdminColors.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AdminColors.onSurface,
        title: Text('Reassign Classes', style: AdminTypography.headlineSm()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(child: Text(_loadError!, style: AdminTypography.bodyMd(color: AdminColors.error)))
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildIntroCard(),
                          const SizedBox(height: 16),
                          for (final s in _orphaned) ...[
                            _buildClassCard(s),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 4),
                          _buildSubmitBar(),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildIntroCard() {
    final names = widget.lecturersToDelete.map((l) => l.name).join(', ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AdminColors.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$names ${widget.lecturersToDelete.length == 1 ? 'is' : 'are'} still assigned to '
              '${_orphaned.length} class${_orphaned.length == 1 ? '' : 'es'}. Pick a new lecturer for each class below — '
              'the lecturer${widget.lecturersToDelete.length == 1 ? '' : 's'} will only be deleted once every class is reassigned.',
              style: AdminTypography.bodySm(color: AdminColors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(CourseSection s) {
    final error = _errorBySection[s.id];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: error == null ? null : Border.all(color: AdminColors.error),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Flexible(
              child: Text('${s.courseCode} • ${s.courseTitle}', style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AdminColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(4)),
              child: Text(s.sectionCode, style: AdminTypography.labelSm(color: AdminColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 2),
          Text('${s.cohort ?? 'No cohort'} • ${_scheduleLabel(s)}', style: AdminTypography.labelSm()),
          Text('Currently: ${s.lecturerName ?? 'Unknown lecturer'}', style: AdminTypography.labelSm()),
          const SizedBox(height: 10),
          const Text('New lecturer'),
          const SizedBox(height: 6),
          SearchableDropdownFormField<String>(
            initialValue: _newLecturerBySection[s.id],
            isExpanded: true,
            style: AdminTypography.bodyMd(color: AdminColors.onSurface),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AdminColors.surfaceContainerLow,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            hint: Text('Search and select a lecturer', style: AdminTypography.bodySm(color: AdminColors.outline)),
            items: [
              for (final l in _candidates)
                DropdownMenuItem(
                  value: l.id,
                  child: Text('${l.name} (${displayCode(l.lecturerCode)}) • ${l.department}', overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (id) => setState(() {
              if (id == null) {
                _newLecturerBySection.remove(s.id);
              } else {
                _newLecturerBySection[s.id] = id;
              }
              _errorBySection.remove(s.id);
            }),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error, style: AdminTypography.bodySm(color: AdminColors.error)),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitBar() {
    final chosen = _orphaned.where((s) => _newLecturerBySection.containsKey(s.id)).length;
    final count = widget.lecturersToDelete.length;
    return Row(
      children: [
        Expanded(
          child: Text(
            _candidates.isEmpty
                ? 'No other lecturers exist to take these classes.'
                : '$chosen of ${_orphaned.length} classes have a new lecturer.',
            style: AdminTypography.bodySm(color: AdminColors.onSurfaceVariant),
          ),
        ),
        ElevatedButton(
          onPressed: _allChosen && !_isSubmitting ? _submit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.error,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSubmitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Reassign & Delete $count Lecturer${count == 1 ? '' : 's'}'),
        ),
      ],
    );
  }
}
