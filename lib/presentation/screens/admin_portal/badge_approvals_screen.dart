import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/core/theme/ui_contrast.dart';
import 'package:stitch_aiei_lms/core/utils/app_snackbar.dart';
import 'package:stitch_aiei_lms/core/utils/date_format.dart';
import 'package:stitch_aiei_lms/core/utils/refresh_on_return.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_app_settings_repository_impl.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_badge_approvals_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/badge_award_request.dart';
import 'package:stitch_aiei_lms/domain/repositories/app_settings_repository.dart';
import 'package:stitch_aiei_lms/presentation/screens/faculty_portal/widgets/faculty_dialog.dart';
import 'package:stitch_aiei_lms/presentation/widgets/skeleton.dart';
import 'widgets/admin_mobile_top_bar.dart';
import 'widgets/admin_nav.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';

// ---------------------------------------------------------------------------
// BadgeApprovalsScreen — students whose final score in a course is above the
// course passing mark (Settings) and who are waiting for the course's badge.
// Badges are never granted automatically: approving here is what grants one.
// ---------------------------------------------------------------------------
class BadgeApprovalsScreen extends StatefulWidget {
  const BadgeApprovalsScreen({super.key});

  @override
  State<BadgeApprovalsScreen> createState() => _BadgeApprovalsScreenState();
}

class _BadgeApprovalsScreenState extends State<BadgeApprovalsScreen> with RefreshOnReturn<BadgeApprovalsScreen> {
  @override
  void onReturnedTo() => _load();

  final _repository = SupabaseBadgeApprovalsRepositoryImpl(Supabase.instance.client);
  final _settings = SupabaseAppSettingsRepositoryImpl(Supabase.instance.client);
  bool _isLoading = true;
  bool _pendingOnly = true;
  List<BadgeAwardRequest> _requests = const [];
  double _passingMark = AppSettingKeys.defaultCoursePassingMark;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final requests = await _repository.listRequests();
      final numeric = await _settings.getNumericSettings();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _passingMark = numeric[AppSettingKeys.coursePassingMark] ?? AppSettingKeys.defaultCoursePassingMark;
      });
    } catch (e) {
      debugPrint('Badge approvals failed to load: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _handleNav(AdminNavDestination dest) => handleAdminNav(context, AdminNavDestination.badgeApprovals, dest);

  List<BadgeAwardRequest> get _visible => _pendingOnly ? _requests.where((r) => r.isPending).toList() : _requests;

  Future<void> _decide(BadgeAwardRequest r, {required bool approve}) async {
    final noteController = TextEditingController();
    String? error;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => FacultyDialog(
          title: approve ? 'Approve this badge?' : 'Reject this badge?',
          subtitle: approve
              ? '${r.studentName} will be awarded "${r.badgeTitle}" for ${r.courseTitle}.'
              : '${r.studentName} will not receive "${r.badgeTitle}".',
          confirmLabel: approve ? 'Approve' : 'Reject',
          destructive: !approve,
          onConfirm: () {
            if (!approve && noteController.text.trim().isEmpty) {
              setDialogState(() => error = 'Please give a reason for rejecting.');
              return;
            }
            Navigator.of(ctx).pop(true);
          },
          child: FacultyFormField(
            controller: noteController,
            label: approve ? 'Remarks' : 'Reject reason',
            required: !approve,
            maxLines: 3,
            errorText: error,
            hint: approve ? 'Optional' : 'Why is the badge not being granted?',
            onChanged: (_) {
              if (error != null) setDialogState(() => error = null);
            },
          ),
        ),
      ),
    );
    final note = noteController.text;
    noteController.dispose();
    if (confirmed != true || !mounted) return;
    try {
      await _repository.decide(r, approved: approve, note: note);
      if (!mounted) return;
      showSuccessSnackBar(context, approve ? 'Badge approved.' : 'Badge rejected.');
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save the decision: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width <= 900;
    if (mobile) {
      return Scaffold(
        backgroundColor: AdminColors.background,
        appBar: const AdminMobileTopBar.detail(title: 'Badge Approvals'),
        body: SafeArea(top: false, child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: _content())),
      );
    }
    return AdminScaffold(selected: AdminNavDestination.badgeApprovals, onDestinationSelected: _handleNav, body: _content());
  }

  String _mark(double v) => v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Widget _content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Badge Approvals', style: AdminTypography.headlineLg()),
        const SizedBox(height: 2),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            'Badges are not granted automatically. A student appears here once their final score in a course is above '
            'the passing mark (${_mark(_passingMark)}%, set in Settings). Approve to grant the badge.',
            style: AdminTypography.bodyMd(),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text('Waiting (${_requests.where((r) => r.isPending).length})'),
              selected: _pendingOnly,
              onSelected: (_) => setState(() => _pendingOnly = true),
            ),
            ChoiceChip(
              label: Text('All (${_requests.length})'),
              selected: !_pendingOnly,
              onSelected: (_) => setState(() => _pendingOnly = false),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const SkeletonCard(rows: 3, rowHeight: 100, withSearchBar: false)
        else if (_visible.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: AdminColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: UiContrast.divider)),
            child: Text(
              _pendingOnly ? 'No badges are waiting for approval.' : 'No badge requests yet.',
              textAlign: TextAlign.center,
              style: AdminTypography.bodyMd(),
            ),
          )
        else
          for (final r in _visible) ...[_requestCard(r), const SizedBox(height: 14)],
      ],
    );
  }

  Widget _statusPill(BadgeAwardRequest r) {
    final (label, bg, fg) = r.isPending
        ? ('Waiting', const Color(0xFFFEF3C7), const Color(0xFF92400E))
        : r.isApproved
            ? ('Approved', const Color(0xFFDCFCE7), const Color(0xFF166534))
            : ('Rejected', AdminColors.errorContainer, AdminColors.onErrorContainer);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9999)),
      child: Text(label, style: AdminTypography.labelMd(color: fg).copyWith(fontWeight: FontWeight.w700)),
    );
  }

  Widget _requestCard(BadgeAwardRequest r) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UiContrast.divider),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.studentName, style: AdminTypography.titleMd()),
                    Text('${r.courseCode} • ${r.courseTitle}', style: AdminTypography.bodySm()),
                  ],
                ),
              ),
              _statusPill(r),
            ],
          ),
          const SizedBox(height: 12),
          Text('Badge: ${r.badgeTitle}', style: AdminTypography.bodyMd(color: AdminColors.onSurface)),
          const SizedBox(height: 2),
          Text(
            'Final score ${_mark(r.finalScore)}% (passing mark ${_mark(_passingMark)}%) • raised ${formatDate(r.createdAt)}',
            style: AdminTypography.bodySm(),
          ),
          if (!r.isPending && (r.adminNote ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(r.isApproved ? 'Remarks' : 'Reject reason', style: AdminTypography.labelMd()),
            const SizedBox(height: 4),
            Text(r.adminNote!, style: AdminTypography.bodyMd(color: AdminColors.onSurface)),
          ],
          if (r.isPending) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _decide(r, approve: false),
                  style: OutlinedButton.styleFrom(foregroundColor: AdminColors.error, side: const BorderSide(color: AdminColors.error)),
                  child: const Text('Reject', textAlign: TextAlign.center),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _decide(r, approve: true),
                  style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primaryContainer, foregroundColor: Colors.white, elevation: 0),
                  child: const Text('Approve', textAlign: TextAlign.center),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
