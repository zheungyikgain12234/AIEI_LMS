import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_app_settings_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/grade_scale.dart';
import 'package:stitch_aiei_lms/domain/repositories/app_settings_repository.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_mobile_top_bar.dart';
import 'widgets/admin_nav.dart';

// ---------------------------------------------------------------------------
// AdminSettingsScreen — global, admin-toggleable feature flags
// (`app_settings` table): exam single-attempt enforcement, and whether the
// Syllabus editor shows inline "Mark Assignment"/"Mark Exam" buttons.
// ---------------------------------------------------------------------------
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _repository = SupabaseAppSettingsRepositoryImpl(Supabase.instance.client);
  bool _isLoading = true;
  Map<String, bool> _settings = {};
  Map<String, double?> _numericSettings = {};
  GradeScale _gradeScale = GradeScale.defaultScale;
  final Set<String> _saving = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final settings = await _repository.getSettings();
    final numericSettings = await _repository.getNumericSettings();
    final gradeScale = await _repository.getGradeScale();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _numericSettings = numericSettings;
      _gradeScale = gradeScale;
      _isLoading = false;
    });
  }

  Future<void> _saveGradeScale(GradeScale scale) async {
    try {
      await _repository.saveGradeScale(scale);
      if (!mounted) return;
      setState(() => _gradeScale = scale);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grade scale saved.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save grade scale: $e')));
    }
  }

  void _handleNav(AdminNavDestination dest) => handleAdminNav(context, AdminNavDestination.settings, dest);

  Future<void> _toggle(String key, bool value) async {
    setState(() {
      _settings = {..._settings, key: value};
      _saving.add(key);
    });
    try {
      await _repository.updateSetting(key, value);
    } finally {
      if (mounted) setState(() => _saving.remove(key));
    }
  }

  Future<void> _saveNumeric(String key, double? value) async {
    setState(() {
      _numericSettings = {..._numericSettings, key: value};
      _saving.add(key);
    });
    try {
      await _repository.updateNumericSetting(key, value);
    } finally {
      if (mounted) setState(() => _saving.remove(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (MediaQuery.of(context).size.width < 700) {
      return _buildMobileScaffold(context);
    }
    return AdminScaffold(
      selected: AdminNavDestination.settings,
      onDestinationSelected: _handleNav,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: AdminTypography.headlineLg()),
          const SizedBox(height: 2),
          Text('Global feature flags applied across every course and portal.', style: AdminTypography.bodyMd()),
          const SizedBox(height: 20),
          _settingsCard(),
          const SizedBox(height: 20),
          _gradeScaleCard(),
        ],
      ),
    );
  }

  Widget _gradeScaleCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      padding: const EdgeInsets.all(16),
      child: _GradeScaleEditor(scale: _gradeScale, onSave: _saveGradeScale),
    );
  }

  Widget _settingsCard() {
    return Container(
      decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)]),
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          _settingRow(
            title: 'Single Exam Attempt',
            description: 'Students may submit each exam/quiz at most once — the exam answering screen blocks re-entry once a submission exists.',
            settingKey: AppSettingKeys.singleExamAttempt,
          ),
          const Divider(height: 1, color: AdminColors.surfaceContainer),
          _settingRow(
            title: 'Hide Mark Buttons in Syllabus Editor',
            description: 'Removes the inline "Mark Assignment"/"Mark Exam"/"Import Marks" buttons from the Syllabus editor\'s content rows — the faculty sidebar\'s "Grading & Submissions" entry becomes the only way to grade.',
            settingKey: AppSettingKeys.hideMarkButtonsInSyllabus,
          ),
          const Divider(height: 1, color: AdminColors.surfaceContainer),
          _settingRow(
            title: 'Allow Lecturers to Reset Exam Attempts',
            description: 'Adds a control to the exam editor\'s "Manage Contents" page letting lecturers type in a student\'s code to clear that student\'s submission, so they can attempt the exam again.',
            settingKey: AppSettingKeys.allowLecturerExamReset,
          ),
          const Divider(height: 1, color: AdminColors.surfaceContainer),
          _settingRow(
            title: 'Lock Modules for Lecturers',
            description: 'Lecturers can no longer add, rename, delete or rearrange a class\'s modules in the Syllabus editor — only admins define them when creating the class. Sessions and their content stay fully editable.',
            settingKey: AppSettingKeys.lockModulesForLecturers,
          ),
          const Divider(height: 1, color: AdminColors.surfaceContainer),
          _numericSettingRow(
            title: 'Max Moderated Score',
            description: 'Caps how many points a lecturer may add at once via the Student Directory\'s "MODERATED SCORE" bulk "Apply All" input. Leave blank for no limit.',
            settingKey: AppSettingKeys.maxModeratedScore,
          ),
        ],
      ),
    );
  }

  Widget _settingRow({required String title, required String description, required String settingKey}) {
    final value = _settings[settingKey] ?? false;
    final saving = _saving.contains(settingKey);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AdminTypography.titleSm(color: AdminColors.onSurface)),
                const SizedBox(height: 4),
                Text(description, style: AdminTypography.bodySm(color: AdminColors.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (saving)
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          else
            Switch(
              value: value,
              onChanged: (v) => _toggle(settingKey, v),
              activeThumbColor: AdminColors.primaryContainer,
            ),
        ],
      ),
    );
  }

  Widget _numericSettingRow({required String title, required String description, required String settingKey}) {
    final saving = _saving.contains(settingKey);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AdminTypography.titleSm(color: AdminColors.onSurface)),
                const SizedBox(height: 4),
                Text(description, style: AdminTypography.bodySm(color: AdminColors.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (saving)
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          else
            _NumericSettingInput(
              key: ValueKey(settingKey),
              value: _numericSettings[settingKey],
              onSave: (value) => _saveNumeric(settingKey, value),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: const AdminMobileTopBar.detail(title: 'Settings'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Global feature flags applied across every course and portal.', style: AdminTypography.bodyMd()),
              const SizedBox(height: 16),
              _settingsCard(),
              const SizedBox(height: 16),
              _gradeScaleCard(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Editor for the grade scale, shown lowest to highest as plain ranges
/// (e.g. "D  50 – 55"). Only each grade's starting score is editable; the end
/// of a range is derived from the next grade's start, so ranges can never
/// overlap or leave gaps. The lowest grade always starts at 0 and the top
/// grade ends at 100. Saving is blocked unless the starts strictly increase.
class _GradeScaleEditor extends StatefulWidget {
  final GradeScale scale;
  final Future<void> Function(GradeScale) onSave;

  const _GradeScaleEditor({required this.scale, required this.onSave});

  @override
  State<_GradeScaleEditor> createState() => _GradeScaleEditorState();
}

class _GradeScaleEditorState extends State<_GradeScaleEditor> {
  late List<GradeBand> _bands = widget.scale.bands;
  late List<TextEditingController> _controllers = _controllersFor(_bands);
  String? _error;
  bool _saving = false;

  List<TextEditingController> _controllersFor(List<GradeBand> bands) =>
      [for (final b in bands) TextEditingController(text: _fmt(b.minScore))];

  static String _fmt(double v) => v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _reset() {
    for (final c in _controllers) {
      c.dispose();
    }
    setState(() {
      _bands = GradeScale.defaultScale.bands;
      _controllers = _controllersFor(_bands);
      _error = null;
    });
  }

  double? _startOf(int i) => double.tryParse(_controllers[i].text.trim());

  /// "55" for a whole-number boundary (next start − 1), otherwise the exact
  /// value just below the next start; the top grade ends at 100.
  String _endLabel(int i) {
    if (i == _bands.length - 1) return '100';
    final next = _startOf(i + 1);
    if (next == null) return '?';
    final end = next == next.truncateToDouble() ? next - 1 : next;
    return _fmt(end);
  }

  Future<void> _save() async {
    final edited = <GradeBand>[];
    for (var i = 0; i < _bands.length; i++) {
      final value = i == 0 ? 0.0 : _startOf(i);
      if (value == null) {
        setState(() => _error = 'Enter a starting score for every grade.');
        return;
      }
      if (i > 0 && value <= edited.last.minScore) {
        setState(() => _error = '${_bands[i].letter} must start higher than ${_bands[i - 1].letter}.');
        return;
      }
      if (value > 100) {
        setState(() => _error = 'Scores cannot exceed 100.');
        return;
      }
      edited.add(GradeBand(_bands[i].letter, value));
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    await widget.onSave(GradeScale(edited));
    if (mounted) setState(() => _saving = false);
  }

  Widget _scoreInput(int i) {
    return SizedBox(
      width: 64,
      child: TextField(
        controller: _controllers[i],
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: AdminTypography.bodySm(color: AdminColors.onSurface),
        onChanged: (_) => setState(() => _error = null),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AdminColors.surfaceContainerLow,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Grade Scale', style: AdminTypography.titleSm(color: AdminColors.onSurface)),
        const SizedBox(height: 4),
        Text(
          'Letter grades shown in the Student Directory. Set the lowest score each grade starts at — it runs until the next grade begins.',
          style: AdminTypography.bodySm(color: AdminColors.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _bands.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(width: 40, child: Text(_bands[i].letter, style: AdminTypography.titleSm(color: AdminColors.onSurface))),
                if (i == 0)
                  SizedBox(width: 64, child: Text('0', textAlign: TextAlign.center, style: AdminTypography.bodySm(color: AdminColors.onSurface)))
                else
                  _scoreInput(i),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('to', style: AdminTypography.bodySm(color: AdminColors.onSurfaceVariant)),
                ),
                SizedBox(width: 40, child: Text(_endLabel(i), textAlign: TextAlign.center, style: AdminTypography.bodySm(color: AdminColors.onSurface))),
              ],
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: AdminTypography.bodySm(color: AdminColors.error)),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.primaryContainer,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Grade Scale'),
            ),
            const SizedBox(width: 8),
            TextButton(onPressed: _saving ? null : _reset, child: const Text('Reset to Default')),
          ],
        ),
      ],
    );
  }
}

/// Text field + save button for one numeric setting — blank commits null
/// ("no limit"). Keeps its own draft text so typing doesn't fight the
/// parent's rebuild-on-save until the value is actually committed.
class _NumericSettingInput extends StatefulWidget {
  final double? value;
  final ValueChanged<double?> onSave;

  const _NumericSettingInput({super.key, required this.value, required this.onSave});

  @override
  State<_NumericSettingInput> createState() => _NumericSettingInputState();
}

class _NumericSettingInputState extends State<_NumericSettingInput> {
  late final TextEditingController _controller = TextEditingController(text: widget.value?.toString() ?? '');
  bool _dirty = false;

  @override
  void didUpdateWidget(covariant _NumericSettingInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dirty && oldWidget.value != widget.value) {
      _controller.text = widget.value?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    final value = text.isEmpty ? null : double.tryParse(text);
    if (text.isNotEmpty && value == null) return;
    setState(() => _dirty = false);
    widget.onSave(value);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 90,
          child: TextField(
            controller: _controller,
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AdminTypography.bodySm(color: AdminColors.onSurface),
            onChanged: (_) => setState(() => _dirty = true),
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AdminColors.surfaceContainerLow,
              hintText: 'No limit',
              hintStyle: AdminTypography.labelSm(color: AdminColors.outline),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: _save,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _dirty ? AdminColors.primaryContainer : AdminColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.check, size: 16, color: AdminColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
