import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/core/theme/ui_contrast.dart';
import 'package:stitch_aiei_lms/core/utils/app_snackbar.dart';
import 'package:stitch_aiei_lms/core/utils/refresh_on_return.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_master_data_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_programme_track_mapping_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_programmes_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/program_track.dart';
import 'package:stitch_aiei_lms/domain/models/programme.dart';
import 'package:stitch_aiei_lms/presentation/widgets/skeleton.dart';
import 'widgets/admin_inline_label.dart';
import 'widgets/admin_mobile_top_bar.dart';
import 'widgets/admin_nav.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/searchable_dropdown.dart';

// ---------------------------------------------------------------------------
// ProgrammeTrackMappingScreen — "which tracks belong to a given programme?"
// External (public) students are grouped by programme through their track;
// the track's courses are then set in Track ↔ Course Mapping. Pick a
// programme, then check/uncheck tracks; each toggle is saved immediately to
// `programme_tracks`. A programme has many tracks, and a track can sit under
// more than one programme.
// ---------------------------------------------------------------------------
class ProgrammeTrackMappingScreen extends StatefulWidget {
  const ProgrammeTrackMappingScreen({super.key});

  @override
  State<ProgrammeTrackMappingScreen> createState() => _ProgrammeTrackMappingScreenState();
}

class _ProgrammeTrackMappingScreenState extends State<ProgrammeTrackMappingScreen> with RefreshOnReturn<ProgrammeTrackMappingScreen> {
  @override
  void onReturnedTo() => _load();

  final _programmesRepository = SupabaseProgrammesRepositoryImpl(Supabase.instance.client);
  final _masterDataRepository = SupabaseAdminMasterDataRepositoryImpl(Supabase.instance.client);
  final _mappingRepository = SupabaseProgrammeTrackMappingRepositoryImpl(Supabase.instance.client);

  bool _isLoading = true;
  String? _error;
  List<Programme> _programmes = [];
  List<ProgramTrack> _tracks = [];
  String? _selectedProgrammeId;

  /// Track ids under the selected programme.
  Set<String> _mappedTrackIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final programmes = await _programmesRepository.getProgrammes();
      final tracks = await _masterDataRepository.getProgramTracks();
      if (!mounted) return;
      setState(() {
        _programmes = programmes;
        _tracks = tracks;
        _selectedProgrammeId ??= programmes.isEmpty ? null : programmes.first.id;
        _error = null;
        _isLoading = false;
      });
      if (_selectedProgrammeId != null) await _loadMapping(_selectedProgrammeId!);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load: $e\n\nIf this mentions "programme_tracks", run the updated schema.sql (and seed.sql) against this project\'s Supabase instance.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMapping(String programmeId) async {
    final ids = await _mappingRepository.getTrackIdsForProgramme(programmeId);
    if (!mounted || _selectedProgrammeId != programmeId) return;
    setState(() => _mappedTrackIds = ids);
  }

  void _handleNav(AdminNavDestination dest) => handleAdminNav(context, AdminNavDestination.programmeTrackMapping, dest);

  Future<void> _toggleTrack(String trackId, bool allowed) async {
    final programmeId = _selectedProgrammeId;
    if (programmeId == null) return;
    setState(() => allowed ? _mappedTrackIds.add(trackId) : _mappedTrackIds.remove(trackId));
    try {
      await _mappingRepository.setTrackForProgramme(programmeId, trackId, allowed);
      if (mounted) showSuccessSnackBar(context, 'Mapping updated.');
    } catch (e) {
      if (!mounted) return;
      setState(() => allowed ? _mappedTrackIds.remove(trackId) : _mappedTrackIds.add(trackId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update mapping: $e'), backgroundColor: AdminColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width <= 900;
    if (_isLoading) {
      return mobile ? const SkeletonScaffold() : AdminScaffold(selected: AdminNavDestination.programmeTrackMapping, onDestinationSelected: _handleNav, body: const SkeletonPage());
    }
    if (mobile) {
      return Scaffold(
        backgroundColor: AdminColors.background,
        appBar: const AdminMobileTopBar.detail(title: 'Programme ↔ Track Mapping'),
        body: SafeArea(top: false, child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: _content())),
      );
    }
    return AdminScaffold(selected: AdminNavDestination.programmeTrackMapping, onDestinationSelected: _handleNav, body: _content());
  }

  Widget _content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Programme ↔ Track Mapping', style: AdminTypography.headlineLg()),
        const SizedBox(height: 2),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            'Public students are grouped by programme. Choose which tracks sit under each programme (a track can sit under more than one); '
            'the courses of a track are then set in Track ↔ Course Mapping.',
            style: AdminTypography.bodyMd(),
          ),
        ),
        const SizedBox(height: 20),
        if (_error != null)
          Text(_error!, style: AdminTypography.bodyMd(color: AdminColors.error))
        else if (_programmes.isEmpty)
          Text('No programmes exist yet. Create one from Manage Programmes first.', style: AdminTypography.bodyMd(color: AdminColors.error))
        else ...[
          _programmeSelector(),
          const SizedBox(height: 20),
          _tracksCard(),
        ],
      ],
    );
  }

  Widget _programmeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      child: AdminInlineLabel(
        label: 'Programme',
        field: SearchableDropdownFormField<String>(
              initialValue: _selectedProgrammeId,
              isExpanded: true,
              style: AdminTypography.bodyMd(color: AdminColors.onSurface),
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
              items: [for (final p in _programmes) DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis))],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selectedProgrammeId = v);
                _loadMapping(v);
              },
            ),
      ),
    );
  }

  Widget _tracksCard() {
    final tracks = [..._tracks]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final mappedHere = tracks.where((t) => _mappedTrackIds.contains(t.id)).length;
    final selectedName = _programmes.where((p) => p.id == _selectedProgrammeId).map((p) => p.name).firstOrNull ?? 'this programme';
    return Container(
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (tracks.isEmpty)
            Padding(padding: const EdgeInsets.all(32), child: Text('No tracks exist yet. Create one from Manage Tracks first.', style: AdminTypography.bodyMd()))
          else
            for (final t in tracks) _trackRow(t),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('$mappedHere of ${tracks.length} tracks in $selectedName', style: AdminTypography.bodySm()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trackRow(ProgramTrack t) {
    final here = _mappedTrackIds.contains(t.id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: UiContrast.divider))),
      child: Row(
        children: [
          Checkbox(
            value: here,
            onChanged: (v) => _toggleTrack(t.id, v ?? false),
            activeColor: AdminColors.primaryContainer,
          ),
          Expanded(
            child: Text(t.name, style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
