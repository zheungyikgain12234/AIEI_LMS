import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/session/app_session.dart' show displayCode;
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/core/theme/ui_contrast.dart';
import 'package:stitch_aiei_lms/core/utils/app_snackbar.dart';
import 'package:stitch_aiei_lms/core/utils/date_format.dart';
import 'package:stitch_aiei_lms/core/utils/refresh_on_return.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_grade_distribution_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/grade_distribution.dart';
import 'package:stitch_aiei_lms/presentation/screens/faculty_portal/widgets/faculty_dialog.dart';
import 'package:stitch_aiei_lms/presentation/widgets/skeleton.dart';

import 'widgets/admin_mobile_top_bar.dart';
import 'widgets/admin_nav.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';

// ---------------------------------------------------------------------------
// GradeApprovalsScreen — requests from lecturers whose class's grades go over
// the grade distribution limits (Settings > Grade Distribution Limits) and who
// want the distribution approved as it is. Approving lets the class's current
// grades stand; rejecting sends the lecturer back to moderate them.
// ---------------------------------------------------------------------------
class GradeApprovalsScreen extends StatefulWidget {
  const GradeApprovalsScreen({super.key});

  @override
  State<GradeApprovalsScreen> createState() => _GradeApprovalsScreenState();
}

class _GradeApprovalsScreenState extends State<GradeApprovalsScreen>
    with RefreshOnReturn<GradeApprovalsScreen> {
  @override
  void onReturnedTo() => _load();

  final _repository = SupabaseGradeDistributionRepositoryImpl(
    Supabase.instance.client,
  );
  bool _isLoading = true;
  bool _pendingOnly = true;
  List<GradeDistributionRequest> _requests = const [];
  GradeDistributionRules _rules = GradeDistributionRules.defaults;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final requests = await _repository.listRequests();
      final rules = await _repository.getRules();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _rules = rules;
      });
    } catch (e) {
      debugPrint('Grade approvals failed to load: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _handleNav(AdminNavDestination dest) =>
      handleAdminNav(context, AdminNavDestination.gradeApprovals, dest);

  List<GradeDistributionRequest> get _visible =>
      _pendingOnly ? _requests.where((r) => r.isPending).toList() : _requests;

  Future<void> _decide(
    GradeDistributionRequest r, {
    required bool approve,
  }) async {
    final noteController = TextEditingController();
    String? error;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => FacultyDialog(
          title: approve
              ? 'Approve this distribution?'
              : 'Reject this distribution?',
          subtitle: approve
              ? '${r.courseTitle ?? 'This class'} keeps its grades as they are. If the lecturer later raises more grades, they will need to ask again.'
              : 'The lecturer will be asked to moderate the grades to fit the limits.',
          confirmLabel: approve ? 'Approve' : 'Reject',
          destructive: !approve,
          onConfirm: () {
            if (!approve && noteController.text.trim().isEmpty) {
              setDialogState(
                () => error = 'Please give a reason for rejecting.',
              );
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
            hint: approve ? 'Optional' : 'Tell the lecturer what to change',
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
      await _repository.decide(r.id, approved: approve, note: note);
      if (!mounted) return;
      showSuccessSnackBar(
        context,
        approve ? 'Distribution approved.' : 'Distribution rejected.',
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save the decision: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width <= 900;
    if (mobile) {
      return Scaffold(
        backgroundColor: AdminColors.background,
        appBar: const AdminMobileTopBar.detail(title: 'Grade Approvals'),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _content(),
          ),
        ),
      );
    }
    return AdminScaffold(
      selected: AdminNavDestination.gradeApprovals,
      onDestinationSelected: _handleNav,
      body: _content(),
    );
  }

  Widget _content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Grade Approvals', style: AdminTypography.headlineLg()),
        const SizedBox(height: 2),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            'When a class gives more top grades than the limits in Settings allow, the lecturer can ask you to approve it. '
            'Approve to let the grades stand, or reject to send them back to moderate.',
            style: AdminTypography.bodyMd(),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(
                'Waiting (${_requests.where((r) => r.isPending).length})',
              ),
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
          const SkeletonCard(rows: 3, rowHeight: 120, withSearchBar: false)
        else if (_visible.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AdminColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: UiContrast.divider),
            ),
            child: Text(
              _pendingOnly
                  ? 'No distributions are waiting for approval.'
                  : 'No approval requests yet.',
              textAlign: TextAlign.center,
              style: AdminTypography.bodyMd(),
            ),
          )
        else
          for (final r in _visible) ...[
            _requestCard(r),
            const SizedBox(height: 14),
          ],
      ],
    );
  }

  Widget _statusPill(GradeDistributionRequest r) {
    final (label, bg, fg) = r.isPending
        ? ('Waiting', const Color(0xFFFEF3C7), const Color(0xFF92400E))
        : r.isApproved
        ? ('Approved', const Color(0xFFDCFCE7), const Color(0xFF166534))
        : (
            'Rejected',
            AdminColors.errorContainer,
            AdminColors.onErrorContainer,
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: AdminTypography.labelMd(color: fg)
            .copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _requestCard(GradeDistributionRequest r) {
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
                    Text(
                      r.courseTitle ?? 'Course',
                      style: AdminTypography.titleMd(),
                    ),
                    Text(
                      '${r.classCode == null ? '' : '${displayCode(r.classCode!)} • '}${r.lecturerName ?? 'Lecturer'} • sent ${formatDate(r.createdAt)}',
                      style: AdminTypography.bodySm(),
                    ),
                  ],
                ),
              ),
              _statusPill(r),
            ],
          ),
          const SizedBox(height: 14),
          _distributionSection(r),
          const SizedBox(height: 14),
          Text('Lecturer\'s reason', style: AdminTypography.labelMd()),
          const SizedBox(height: 4),
          Text(
            r.justification.isEmpty ? '—' : r.justification,
            style: AdminTypography.bodyMd(color: AdminColors.onSurface),
          ),
          if (!r.isPending && (r.adminNote ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Your note', style: AdminTypography.labelMd()),
            const SizedBox(height: 4),
            Text(
              r.adminNote!,
              style: AdminTypography.bodyMd(color: AdminColors.onSurface),
            ),
          ],
          if (r.isPending) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _decide(r, approve: false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminColors.error,
                    side: const BorderSide(color: AdminColors.error),
                  ),
                  child: const Text('Reject', textAlign: TextAlign.center),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _decide(r, approve: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primaryContainer,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: const Text('Approve', textAlign: TextAlign.center),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Total students, the class's score statistics (when the request carries
  /// them), then the distribution table.
  Widget _distributionSection(GradeDistributionRequest r) {
    final stats = r.stats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total students: ${r.enrolledCount}',
          style: AdminTypography.titleSm(color: AdminColors.onSurface),
        ),
        const SizedBox(height: 12),
        Text('Grade Statistics', style: AdminTypography.labelMd()),
        const SizedBox(height: 6),
        _panel(
          Column(
            children: [
              _row(const ['Final', 'Marks', 'Grade'], header: true),
              _row([
                'Average',
                stats == null ? '—' : stats.average.toStringAsFixed(2),
                stats?.averageGrade ?? '—',
              ]),
              _row([
                'Maximum',
                stats == null ? '—' : _score(stats.maximum),
                stats?.maximumGrade ?? '—',
              ]),
              _row([
                'Minimum',
                stats == null ? '—' : _score(stats.minimum),
                stats?.minimumGrade ?? '—',
              ]),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('Grade Distribution Table', style: AdminTypography.labelMd()),
        const SizedBox(height: 6),
        _distributionTable(r),
      ],
    );
  }

  bool get _compact => MediaQuery.of(context).size.width <= 900;

  Widget _panel(Widget child) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: UiContrast.fieldFill,
      borderRadius: BorderRadius.circular(10),
    ),
    padding: EdgeInsets.symmetric(horizontal: _compact ? 10 : 14, vertical: 8),
    child: child,
  );

  /// Cells wrap onto a second line instead of overflowing, and shrink a little
  /// on small screens.
  Widget _row(
    List<String> cells, {
    bool header = false,
    bool over = false,
    List<int>? flex,
  }) {
    var style = header
        ? AdminTypography.labelMd().copyWith(fontWeight: FontWeight.w700)
        : AdminTypography.bodyMd(
            color: over ? AdminColors.error : AdminColors.onSurface,
          );
    if (_compact) style = style.copyWith(fontSize: 16);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: flex?[i] ?? 1,
              child: Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                child: Text(
                  cells[i],
                  textAlign: i == 0 ? TextAlign.left : TextAlign.right,
                  style: style,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// One row per grade (A+ down to F): its own count and percent of the class,
  /// the running total (accum.), and the limit it is checked against.
  Widget _distributionTable(GradeDistributionRequest r) {
    const flex = [3, 4, 3, 2, 2];
    final total = r.enrolledCount;
    String pct(int n) =>
        total == 0 ? '0%' : '${(n * 100 / total).toStringAsFixed(1)}%';
    final bands = GradeBandLimit.values;
    return _panel(
      Column(
        children: [
          _row(
            const ['Grade', 'Limit', 'Student Count', 'Percent', 'Accum.'],
            header: true,
            flex: flex,
          ),
          for (var i = 0; i < bands.length; i++)
            Builder(
              builder: (context) {
                final band = bands[i];
                final cumulative = r.counts[band.name] ?? 0;
                final own =
                    cumulative -
                    (i == 0 ? 0 : (r.counts[bands[i - 1].name] ?? 0));
                final percent = _rules.percentFor(band);
                final allowed = GradeDistributionRules.allowedCount(
                  percent,
                  total,
                );
                final over = allowed != null && cumulative > allowed;
                return _row(
                  [
                    band.label,
                    allowed == null
                        ? 'no limit'
                        : '$allowed (${_pct(percent!)}%)',
                    '$own',
                    pct(own),
                    pct(cumulative),
                  ],
                  over: over,
                  flex: flex,
                );
              },
            ),
        ],
      ),
    );
  }

  static String _score(double v) =>
      v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  static String _pct(double v) =>
      v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toString();
}
