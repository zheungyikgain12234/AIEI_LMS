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
  final Set<String> _saving = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final settings = await _repository.getSettings();
    if (!mounted) return;
    setState(() {
      _settings = settings;
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
