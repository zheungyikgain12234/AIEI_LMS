import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';

/// How many class syllabi are waiting for admin approval (status "submitted").
/// Drives the red dot on the "Manage Syllabi" menu item.
final ValueNotifier<int> pendingSyllabusCount = ValueNotifier<int>(0);

/// Re-reads [pendingSyllabusCount] from the database. Call it whenever the
/// sidebar appears and after a syllabus is approved / its status changes.
Future<void> refreshPendingSyllabusCount() async {
  try {
    final rows = await Supabase.instance.client.from('course_sections').select('id').eq('syllabus_status', 'submitted');
    pendingSyllabusCount.value = (rows as List).length;
  } catch (_) {
    // The dot is a convenience — never let a failed count break navigation.
  }
}

/// Small red dot, shown only while [pendingSyllabusCount] > 0.
class PendingSyllabusDot extends StatelessWidget {
  const PendingSyllabusDot({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: pendingSyllabusCount,
      builder: (_, count, _) => count > 0
          ? Tooltip(
              message: '$count syllabus${count == 1 ? '' : 'es'} awaiting approval',
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(color: AdminColors.error, shape: BoxShape.circle),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

/// Refreshes [pendingSyllabusCount] once when it first appears (i.e. each time
/// a screen with the sidebar opens), then just shows [child].
class PendingSyllabusRefresher extends StatefulWidget {
  final Widget child;

  const PendingSyllabusRefresher({super.key, required this.child});

  @override
  State<PendingSyllabusRefresher> createState() => _PendingSyllabusRefresherState();
}

class _PendingSyllabusRefresherState extends State<PendingSyllabusRefresher> {
  @override
  void initState() {
    super.initState();
    refreshPendingSyllabusCount();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
