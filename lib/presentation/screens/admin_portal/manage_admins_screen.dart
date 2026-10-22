import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/presentation/widgets/skeleton.dart';
import 'package:stitch_aiei_lms/core/theme/ui_contrast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'package:stitch_aiei_lms/core/utils/app_snackbar.dart';
import 'package:stitch_aiei_lms/core/utils/error_messages.dart';
import 'package:stitch_aiei_lms/core/utils/refresh_on_return.dart';
import 'package:stitch_aiei_lms/data/repositories/supabase_admin_users_repository_impl.dart';
import 'package:stitch_aiei_lms/domain/models/admin_user.dart';
import 'widgets/admin_field_error.dart';
import 'widgets/admin_field_label.dart';
import 'widgets/admin_form_dialog.dart';
import 'widgets/admin_mobile_top_bar.dart';
import 'widgets/admin_nav.dart';
import 'widgets/admin_no_results.dart';
import 'widgets/admin_row_action.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_sidebar.dart';

// ---------------------------------------------------------------------------
// ManageAdminsScreen — Admin Portal users (`admins` table): name, email and
// username. The signed-in admin (DemoIdentity.adminId) can't be deleted.
// ---------------------------------------------------------------------------
class ManageAdminsScreen extends StatefulWidget {
  const ManageAdminsScreen({super.key});

  @override
  State<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends State<ManageAdminsScreen> with RefreshOnReturn<ManageAdminsScreen> {
  @override
  void onReturnedTo() => _load();

  final _repository = SupabaseAdminUsersRepositoryImpl(Supabase.instance.client);
  bool _isLoading = true;
  List<AdminUser> _admins = [];
  final Set<String> _selected = {};
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _query = _searchController.text.trim().toLowerCase()));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final admins = await _repository.getAdmins();
    if (!mounted) return;
    setState(() {
      _admins = admins;
      _isLoading = false;
    });
  }

  List<AdminUser> get _filtered {
    if (_query.isEmpty) return _admins;
    return _admins.where((a) => [a.name, a.email, a.username].any((v) => v.toLowerCase().contains(_query))).toList();
  }

  void _handleNav(AdminNavDestination dest) => handleAdminNav(context, AdminNavDestination.manageAdmins, dest);

  bool _isYou(AdminUser a) => a.id == DemoIdentity.adminId;

  Future<void> _openForm({AdminUser? admin}) async {
    final nameController = TextEditingController(text: admin?.name ?? '');
    final emailController = TextEditingController(text: admin?.email ?? '');
    final usernameController = TextEditingController(text: admin?.username ?? '');
    final errors = <String, String>{};
    String? serverError;
    var saving = false;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Widget field(String key, String label, TextEditingController c, String hint, {TextInputType? keyboardType}) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminFieldLabel(label),
                const SizedBox(height: 6),
                TextField(
                  controller: c,
                  keyboardType: keyboardType,
                  onChanged: (_) => setDialogState(() => errors.remove(key)),
                  style: AdminTypography.bodyMd(color: AdminColors.onSurface),
                  decoration: adminFormDecoration(hint: hint),
                ),
                AdminFieldError(errors[key]),
                const SizedBox(height: 14),
              ],
            );
          }

          return AdminFormDialog(
            title: admin == null ? 'Add Admin' : 'Edit Admin',
            maxWidth: 480,
            onCancel: saving ? null : () => Navigator.of(ctx).pop(false),
            submitChild: saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(admin == null ? 'Add Admin' : 'Save Changes'),
            onSubmit: saving
                ? null
                : () async {
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();
                    final username = usernameController.text.trim();
                    final found = <String, String>{};
                    if (name.isEmpty) found['name'] = 'Name is required.';
                    if (email.isEmpty) {
                      found['email'] = 'Email is required.';
                    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                      found['email'] = 'Enter a valid email address.';
                    }
                    if (username.isEmpty) {
                      found['username'] = 'Username is required.';
                    } else if (username.contains(RegExp(r'\s'))) {
                      found['username'] = 'Username cannot contain spaces.';
                    }
                    setDialogState(() {
                      errors
                        ..clear()
                        ..addAll(found);
                      serverError = null;
                    });
                    if (found.isNotEmpty) return;
                    setDialogState(() => saving = true);
                    try {
                      if (admin == null) {
                        await _repository.createAdmin(name: name, email: email, username: username);
                      } else {
                        await _repository.updateAdmin(admin.id, name: name, email: email, username: username);
                      }
                      if (!mounted) return;
                      showSuccessSnackBar(context, admin == null ? 'Admin added.' : 'Admin updated.');
                      if (ctx.mounted) Navigator.of(ctx).pop(true);
                    } on PostgrestException catch (e) {
                      final msg = e.message.toLowerCase();
                      setDialogState(() {
                        saving = false;
                        if (e.code == '23505' && msg.contains('username')) {
                          errors['username'] = 'This username is already in use.';
                        } else if (e.code == '23505' && msg.contains('email')) {
                          errors['email'] = 'This email is already in use.';
                        } else {
                          serverError = friendlyErrorMessage(e);
                        }
                      });
                    } catch (e) {
                      setDialogState(() {
                        saving = false;
                        serverError = friendlyErrorMessage(e);
                      });
                    }
                  },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                field('name', 'Name', nameController, 'Marcus Vance'),
                field('email', 'Email', emailController, 'name@aiei.edu', keyboardType: TextInputType.emailAddress),
                field('username', 'Username', usernameController, 'marcus.vance'),
                if (serverError != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AdminColors.errorContainer, borderRadius: BorderRadius.circular(8)),
                    child: Text(serverError!, style: AdminTypography.bodySm(color: AdminColors.onErrorContainer)),
                  ),
              ],
            ),
          );
        },
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameController.dispose();
      emailController.dispose();
      usernameController.dispose();
    });
    if (saved == true) _load();
  }

  Future<void> _deleteSelected() async {
    final targets = _admins.where((a) => _selected.contains(a.id)).toList();
    if (targets.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete admin${targets.length == 1 ? '' : 's'}?'),
        content: Text(targets.length == 1
            ? 'Delete ${targets.first.name}? This cannot be undone.'
            : 'Delete ${targets.length} admins? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', textAlign: TextAlign.center)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.error, foregroundColor: Colors.white),
            child: const Text('Delete', textAlign: TextAlign.center),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _repository.deleteAdmins([for (final a in targets) a.id]);
      if (!mounted) return;
      showSuccessSnackBar(context, 'Deleted.');
      setState(_selected.clear);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(e)), backgroundColor: AdminColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show the page frame straight away; only the content area is a placeholder.
      return MediaQuery.of(context).size.width <= 900 ? const SkeletonScaffold() : AdminScaffold(selected: AdminNavDestination.manageAdmins, onDestinationSelected: _handleNav, body: const SkeletonPage());
    }
    final visibleIds = {for (final r in _filtered) r.id};
    _selected.retainWhere(visibleIds.contains);
    if (MediaQuery.of(context).size.width <= 900) {
      return Scaffold(
        backgroundColor: AdminColors.background,
        appBar: const AdminMobileTopBar.detail(title: 'Manage Admin'),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_buildTopBar(), const SizedBox(height: 16), _buildListCard()],
            ),
          ),
        ),
      );
    }
    return AdminScaffold(
      selected: AdminNavDestination.manageAdmins,
      onDestinationSelected: _handleNav,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildTopBar(), const SizedBox(height: 20), _buildListCard()],
      ),
    );
  }

  Widget _buildTopBar() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage Admin', style: AdminTypography.headlineLg()),
            const SizedBox(height: 2),
            Text('The people who can sign in to this Admin Portal and manage the system. Add a new admin or remove someone who no longer needs access.', style: AdminTypography.bodyMd()),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Admin', textAlign: TextAlign.center),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.primaryContainer,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildListCard() {
    final admins = _filtered;
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              style: AdminTypography.bodySm(color: AdminColors.onSurface),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search admin by name, email or username...',
                prefixIcon: const Icon(Icons.search, size: 18, color: AdminColors.onSurfaceVariant),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_selected.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  adminSelectionSummary(count: _selected.length, onDeselectAll: () => setState(_selected.clear)),
                  OutlinedButton.icon(
                    onPressed: _deleteSelected,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete', textAlign: TextAlign.center),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminColors.error,
                      backgroundColor: AdminColors.errorContainer,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          if (admins.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: AdminNoResults(controller: _searchController, focusNode: _searchFocus),
            )
          else ...[
            _headerRow(),
            for (final a in admins) _row(a),
          ],
        ],
      ),
    );
  }

  Widget _headerRow() {
    // Each row is a stacked card on a phone, so there are no columns to label.
    if (MediaQuery.of(context).size.width <= 900) return const SizedBox.shrink();
    final style = AdminTypography.labelSm(color: AdminColors.onSurfaceVariant);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: UiContrast.divider))),
      child: Row(
        children: [
          const SizedBox(width: 40),
          Expanded(flex: 3, child: Text('Name', style: style)),
          Expanded(flex: 4, child: Text('Email', style: style)),
          Expanded(flex: 3, child: Text('Username', style: style)),
          adminActionHeader(),
        ],
      ),
    );
  }

  Widget _row(AdminUser a) {
    final selected = _selected.contains(a.id);
    final you = _isYou(a);
    if (MediaQuery.of(context).size.width <= 900) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: UiContrast.divider))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: selected,
              onChanged: you ? null : (v) => setState(() => v == true ? _selected.add(a.id) : _selected.remove(a.id)),
              activeColor: AdminColors.primaryContainer,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(you ? '${a.name} (You)' : a.name, style: AdminTypography.titleSm()),
                    Text(a.email, style: AdminTypography.bodySm(color: AdminColors.onSurface)),
                    Text('@${a.username}', style: AdminTypography.labelSm()),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: () => _openForm(admin: a),
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined, size: 20, color: AdminColors.onSurface),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: UiContrast.divider))),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Tooltip(
              message: you ? 'You are signed in as this admin, so it cannot be deleted.' : '',
              child: Checkbox(
                value: selected,
                onChanged: you ? null : (v) => setState(() => v == true ? _selected.add(a.id) : _selected.remove(a.id)),
                activeColor: AdminColors.primaryContainer,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(you ? '${a.name} (You)' : a.name, style: AdminTypography.titleSm(), overflow: TextOverflow.ellipsis),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(a.email, style: AdminTypography.bodySm(color: AdminColors.onSurface), overflow: TextOverflow.ellipsis),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(a.username, style: AdminTypography.bodySm(color: AdminColors.onSurface), overflow: TextOverflow.ellipsis),
            ),
          ),
          adminEditAction(() => _openForm(admin: a)),
        ],
      ),
    );
  }
}
