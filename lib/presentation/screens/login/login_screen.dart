import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stitch_aiei_lms/presentation/screens/enrolled_courses_catalogue/enrolled_courses_catalogue_screen.dart';
import 'package:stitch_aiei_lms/presentation/screens/faculty_portal/my_assigned_courses_screen.dart';
import 'package:stitch_aiei_lms/presentation/screens/admin_portal/manage_lecturers_screen.dart';

/// Design tokens for the Login screen (Stitch "AIEI LMS Login" mockup —
/// Tailwind slate/blue palette, distinct from the three portal design
/// systems since this screen sits outside all of them).
class _LoginColors {
  _LoginColors._();

  static const Color background = Color(0xFFF4F7FB);
  static const Color heroFrom = Color(0xFF0C1A30);
  static const Color heroVia = Color(0xFF102342);
  static const Color heroTo = Color(0xFF152E55);

  static const Color brandBlue = Color(0xFF1D63ED);
  static const Color indigo = Color(0xFF4F46E5);
  static const Color amber = Color(0xFFD97706);
  static const Color emerald = Color(0xFF059669);

  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50 = Color(0xFFF8FAFC);
}

class _RoleOption {
  final IconData icon;
  final String label;
  final String portalTitle;
  final String portalDescription;
  final Color accent;
  final Color accentBg;

  const _RoleOption({
    required this.icon,
    required this.label,
    required this.portalTitle,
    required this.portalDescription,
    required this.accent,
    required this.accentBg,
  });
}

const List<_RoleOption> _kRoles = [
  _RoleOption(
    icon: Icons.school_outlined,
    label: 'Student',
    portalTitle: 'Student Portal',
    portalDescription: 'Curricula, assessments, lab submissions & verified skill badges.',
    accent: _LoginColors.brandBlue,
    accentBg: Color(0xFFDBEAFE),
  ),
  _RoleOption(
    icon: Icons.badge_outlined,
    label: 'Faculty',
    portalTitle: 'Faculty Portal',
    portalDescription: 'Course cohorts, rapid grading, syllabus orchestration & evaluations.',
    accent: _LoginColors.indigo,
    accentBg: Color(0xFFE0E7FF),
  ),
  _RoleOption(
    icon: Icons.shield_outlined,
    label: 'Admin',
    portalTitle: 'Administrative Console',
    portalDescription: 'Lecturer allocations, student registrar & compliance certification.',
    accent: _LoginColors.amber,
    accentBg: Color(0xFFFEF3C7),
  ),
];

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _selectedRole = 0;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: 'alex.chen@enterprise.com');
    _passwordController = TextEditingController(text: 'password1234');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _openPortal(int roleIndex) {
    late final Widget screen;
    switch (roleIndex) {
      case 0:
        screen = const EnrolledCoursesCatalogueScreen();
        break;
      case 1:
        screen = const MyAssignedCoursesScreen();
        break;
      default:
        screen = const ManageLecturersScreen();
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  TextStyle _text({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = _LoginColors.slate900,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width < 700) {
      return _buildMobile(context);
    }
    return _buildDesktop(context);
  }

  // ── Shared bits ─────────────────────────────────────────────────────────

  Widget _statusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: _LoginColors.emerald, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'All Systems Operational',
              overflow: TextOverflow.ellipsis,
              style: _text(size: 11, weight: FontWeight.w500, color: _LoginColors.emerald),
            ),
          ),
        ],
      ),
    );
  }

  Widget _helpLink() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.help_outline, size: 16, color: _LoginColors.slate400),
        const SizedBox(width: 4),
        Text('Help & Support', style: _text(size: 12, weight: FontWeight.w500, color: _LoginColors.slate500)),
      ],
    );
  }

  Widget _logoBadge({double height = 24}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Image.network(
        'https://lh3.googleusercontent.com/aida-public/AB6AXuC4U1rOihgxAXZmk2W54YjqF3NHX0mjQU0Jl4ssvgGsJ2OkSN-1blmM6erHEi5koI8r8sslzy97G-AfN2Bh8MF6SKZ0Zg28VsqhwFxqntwBPnyAURZDdIupL3pJJqG5Uf_TdA0uhivCni6kVDVGSe-Tmycur2nXmYWgbKe3J3DUXekGSJ4geC8z76MGeLWN_Wjw6qw0hnEiTWId58WF7dV_GTg6QvE42meLlwC_p1JrIsTdKpaexZy8WVjCyqo_pxrJxg',
        height: height,
        errorBuilder: (context, error, stackTrace) => Text('AIEI', style: _text(size: 14, weight: FontWeight.w800, color: _LoginColors.slate900)),
      ),
    );
  }

  Widget _roleTabs({required bool compact}) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: _LoginColors.slate100, borderRadius: BorderRadius.circular(12), border: Border.all(color: _LoginColors.slate200)),
      child: Row(
        children: List.generate(_kRoles.length, (i) {
          final role = _kRoles[i];
          final selected = _selectedRole == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: EdgeInsets.symmetric(vertical: compact ? 10 : 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: selected ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 3, offset: Offset(0, 1))] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(role.icon, size: 15, color: selected ? _LoginColors.brandBlue : _LoginColors.slate500),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        role.label,
                        overflow: TextOverflow.ellipsis,
                        style: _text(size: 12, weight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? _LoginColors.brandBlue : _LoginColors.slate600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _emailField() {
    return TextField(
      controller: _emailController,
      style: _text(size: 14, color: _LoginColors.slate900),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text('@', style: _text(size: 15, weight: FontWeight.w700, color: _LoginColors.slate400)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        filled: true,
        fillColor: Colors.white,
        hintText: 'name@enterprise.com',
        hintStyle: _text(size: 14, color: _LoginColors.slate400),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _LoginColors.slate300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _LoginColors.slate300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _LoginColors.brandBlue, width: 2)),
      ),
    );
  }

  Widget _passwordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: _text(size: 14, color: _LoginColors.slate900, letterSpacing: 1.5),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline, size: 18, color: _LoginColors.slate400),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: _LoginColors.slate400),
        ),
        filled: true,
        fillColor: Colors.white,
        hintText: 'Enter your password',
        hintStyle: _text(size: 14, color: _LoginColors.slate400),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _LoginColors.slate300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _LoginColors.slate300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _LoginColors.brandBlue, width: 2)),
      ),
    );
  }

  Widget _rememberMeRow() {
    return Row(
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: Checkbox(
            value: _rememberMe,
            onChanged: (v) => setState(() => _rememberMe = v ?? true),
            activeColor: _LoginColors.brandBlue,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text('Keep me signed in on this workstation', style: _text(size: 12, color: _LoginColors.slate600), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _signInButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _openPortal(_selectedRole),
        style: ElevatedButton.styleFrom(
          backgroundColor: _LoginColors.brandBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sign In', style: _text(size: 14, weight: FontWeight.w700, color: Colors.white)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _roleGuidanceCard(_RoleOption role, {required bool dense}) {
    return Container(
      padding: EdgeInsets.all(dense ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _LoginColors.slate200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: role.accentBg, borderRadius: BorderRadius.circular(9)),
            alignment: Alignment.center,
            child: Icon(role.icon, size: 17, color: role.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role.portalTitle, style: _text(size: 13, weight: FontWeight.w700, color: _LoginColors.slate800)),
                const SizedBox(height: 3),
                Text(role.portalDescription, style: _text(size: 11.5, color: _LoginColors.slate500, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile layout ─────────────────────────────────────────────────────

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      backgroundColor: _LoginColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: _statusPill()),
                    const SizedBox(width: 8),
                    _helpLink(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_LoginColors.heroFrom, _LoginColors.heroVia, _LoginColors.heroTo],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 8))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _logoBadge(),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('ENTERPRISE LEARNING', style: _text(size: 10, weight: FontWeight.w700, color: const Color(0xFFCBD5E1), letterSpacing: 0.8), overflow: TextOverflow.ellipsis),
                                    Text('SYSTEM', style: _text(size: 9, weight: FontWeight.w400, color: const Color(0xFF94A3B8), letterSpacing: 1)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('Advance Your Career in AI & Enterprise Systems', style: _text(size: 20, weight: FontWeight.w700, color: Colors.white, height: 1.25)),
                          const SizedBox(height: 8),
                          Text(
                            'Unified access portal for corporate learners, faculty researchers, and academic administrators.',
                            style: _text(size: 12, color: const Color(0xFFCBD5E1), height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Login card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _LoginColors.slate200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sign in to your account', style: _text(size: 18, weight: FontWeight.w700, color: _LoginColors.slate900)),
                          const SizedBox(height: 4),
                          Text('Select your portal role to access your personalized workspace.', style: _text(size: 12, color: _LoginColors.slate500, height: 1.35)),
                          const SizedBox(height: 18),
                          Text('SELECT PORTAL ROLE', style: _text(size: 11, weight: FontWeight.w700, color: _LoginColors.slate500, letterSpacing: 0.6)),
                          const SizedBox(height: 8),
                          _roleTabs(compact: true),
                          const SizedBox(height: 18),
                          Text('Work Email / Institutional ID', style: _text(size: 12, weight: FontWeight.w700, color: _LoginColors.slate700)),
                          const SizedBox(height: 6),
                          _emailField(),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Password', style: _text(size: 12, weight: FontWeight.w700, color: _LoginColors.slate700)),
                              Text('Forgot password?', style: _text(size: 12, weight: FontWeight.w600, color: _LoginColors.brandBlue)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _passwordField(),
                          const SizedBox(height: 12),
                          _rememberMeRow(),
                          const SizedBox(height: 16),
                          _signInButton(),
                          const SizedBox(height: 20),
                          Container(height: 1, color: _LoginColors.slate200),
                          const SizedBox(height: 16),
                          _demoQuickAccess(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('PORTAL DIRECTORY & FEATURES', style: _text(size: 11, weight: FontWeight.w700, color: _LoginColors.slate500, letterSpacing: 0.6)),
                    const SizedBox(height: 10),
                    for (var i = 0; i < _kRoles.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _roleGuidanceCard(_kRoles[i], dense: true),
                    ],
                    const SizedBox(height: 24),
                    Container(height: 1, color: _LoginColors.slate200),
                    const SizedBox(height: 14),
                    Center(
                      child: Column(
                        children: [
                          Text('Academic Term: Fall 2025', style: _text(size: 11, weight: FontWeight.w600, color: _LoginColors.slate600), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Desktop layout ───────────────────────────────────────────────────

  Widget _buildDesktop(BuildContext context) {
    return Scaffold(
      backgroundColor: _LoginColors.background,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _logoBadge(height: 26),
                    const SizedBox(width: 12),
                    Container(width: 1, height: 18, color: _LoginColors.slate200),
                    const SizedBox(width: 12),
                    Text('ENTERPRISE LEARNING SYSTEM', style: _text(size: 11, weight: FontWeight.w700, color: _LoginColors.slate500, letterSpacing: 0.8)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _statusPill(),
                    const SizedBox(width: 20),
                    _helpLink(),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 32, offset: Offset(0, 12))],
                      border: Border.all(color: _LoginColors.slate200),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: LayoutBuilder(builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 820;
                      final left = _desktopLeftPanel();
                      final right = _desktopRightPanel();
                      if (stacked) {
                        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [left, right]);
                      }
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 5, child: left),
                            Expanded(flex: 7, child: right),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopLeftPanel() {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_LoginColors.heroFrom, _LoginColors.heroVia, _LoginColors.heroTo],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _logoBadge(height: 30),
          const SizedBox(height: 28),
          Text('Advance Your Career in\nAI & Enterprise Systems', style: _text(size: 28, weight: FontWeight.w800, color: Colors.white, height: 1.2)),
          const SizedBox(height: 14),
          Text(
            'Unified access portal for corporate learners, faculty researchers, and academic administrators.',
            style: _text(size: 14, color: const Color(0xFFCBD5E1), height: 1.5),
          ),
          const SizedBox(height: 32),
          for (var i = 0; i < _kRoles.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _desktopRoleHighlight(_kRoles[i]),
          ],
          const SizedBox(height: 32),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Text('Academic Term: Fall 2025', style: _text(size: 11, color: const Color(0xFF94A3B8)), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _desktopRoleHighlight(_RoleOption role) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: role.accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Icon(role.icon, size: 16, color: role.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role.portalTitle, style: _text(size: 12, weight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 2),
                Text(role.portalDescription, style: _text(size: 11, color: const Color(0xFFCBD5E1), height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopRightPanel() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sign in to your account', style: _text(size: 24, weight: FontWeight.w800, color: _LoginColors.slate900)),
            const SizedBox(height: 4),
            Text('Select your portal role to access your personalized workspace.', style: _text(size: 13, color: _LoginColors.slate500)),
            const SizedBox(height: 22),
            Text('SELECT PORTAL ROLE', style: _text(size: 11, weight: FontWeight.w700, color: _LoginColors.slate500, letterSpacing: 0.6)),
            const SizedBox(height: 8),
            _roleTabs(compact: false),
            const SizedBox(height: 22),
            Text('Work Email / Institutional ID', style: _text(size: 12, weight: FontWeight.w700, color: _LoginColors.slate700)),
            const SizedBox(height: 6),
            _emailField(),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Password', style: _text(size: 12, weight: FontWeight.w700, color: _LoginColors.slate700)),
                Text('Forgot password?', style: _text(size: 12, weight: FontWeight.w600, color: _LoginColors.brandBlue)),
              ],
            ),
            const SizedBox(height: 6),
            _passwordField(),
            const SizedBox(height: 14),
            _rememberMeRow(),
            const SizedBox(height: 18),
            _signInButton(),
            const SizedBox(height: 24),
            Container(height: 1, color: _LoginColors.slate200),
            const SizedBox(height: 18),
            _demoQuickAccess(),
          ],
        ),
      ),
    );
  }

  Widget _demoQuickAccess() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _LoginColors.slate50, borderRadius: BorderRadius.circular(14), border: Border.all(color: _LoginColors.slate200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: _LoginColors.brandBlue, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(
                child: Text('DEMO PROTOTYPE DIRECT ACCESS', style: _text(size: 10.5, weight: FontWeight.w800, color: _LoginColors.slate700, letterSpacing: 0.5), overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: _LoginColors.slate200)),
                child: Text('Instant Bypass', style: _text(size: 9, weight: FontWeight.w600, color: _LoginColors.slate400)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(_kRoles.length, (i) {
              final role = _kRoles[i];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                  child: GestureDetector(
                    onTap: () => _openPortal(i),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: _LoginColors.slate200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(color: role.accentBg, borderRadius: BorderRadius.circular(6)),
                                alignment: Alignment.center,
                                child: Icon(role.icon, size: 13, color: role.accent),
                              ),
                              Icon(Icons.arrow_forward, size: 12, color: role.accent),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(role.label == 'Faculty' ? 'Lecturer Portal' : (role.label == 'Admin' ? 'Admin Portal' : 'Student Portal'),
                              style: _text(size: 11.5, weight: FontWeight.w700, color: _LoginColors.slate900), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
