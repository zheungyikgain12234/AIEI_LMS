import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_app_settings_repository_impl.dart';
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
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _numericSettings = numericSettings;
      _isLoading = false;
    });
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
        ],
      ),
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
            description: 'Removes the inline "Mark Assignment"/"Mark Exam" buttons from the Syllabus editor\'s content rows — the faculty sidebar\'s "Grading & Submissions" entry becomes the only way to grade.',
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
            ],
          ),
        ),
      ),
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
