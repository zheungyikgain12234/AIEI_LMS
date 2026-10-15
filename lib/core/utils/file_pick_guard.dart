import 'dart:async';

import 'package:flutter/foundation.dart';

/// Marks the moments a native file-picker dialog is open. Opening one makes
/// the browser drop out of fullscreen and blur the page, which the exam
/// lockdown would otherwise treat as cheating and auto-submit. The lockdown
/// checks [active] and ignores those events while a pick is in progress (and
/// for a short grace period afterwards, since the browser can report them late).
///
/// The guard is also a loophole (a student could use the open dialog's time to
/// look elsewhere), so during an exam it is rationed: [startExam] limits how
/// many times the picker may be opened and how long it may stay open. Staying
/// open past the limit calls the exam's overrun callback, which submits it.
class FilePickGuard {
  FilePickGuard._();

  static const _grace = Duration(milliseconds: 1000);

  static int _open = 0;
  static DateTime _graceUntil = DateTime.fromMillisecondsSinceEpoch(0);

  // Exam rationing; null limits mean "unlimited" (outside an exam).
  static int? _maxPicks;
  static Duration? _maxOpen;
  static VoidCallback? _onOverrun;
  static int _picksUsed = 0;
  static Timer? _overrunTimer;

  /// Bumped every time a pick finishes (whether or not a file was chosen).
  static final ValueNotifier<int> finished = ValueNotifier(0);

  /// True while a picker is open, or just closed.
  static bool get active => _open > 0 || DateTime.now().isBefore(_graceUntil);

  /// How long after a pick ends that [active] stays true.
  static Duration get grace => _grace;

  /// Whether the picker may be opened right now.
  static bool get canOpen => _maxPicks == null || _picksUsed < _maxPicks!;

  static int? get maxPicks => _maxPicks;
  static Duration? get maxOpen => _maxOpen;

  /// Rations the picker for an exam: at most [maxPicks] opens, each of which
  /// may stay open at most [maxOpen] before [onOverrun] fires.
  static void startExam({required int maxPicks, required Duration maxOpen, required VoidCallback onOverrun}) {
    _maxPicks = maxPicks;
    _maxOpen = maxOpen;
    _onOverrun = onOverrun;
    _picksUsed = 0;
  }

  static void endExam() {
    _overrunTimer?.cancel();
    _overrunTimer = null;
    _maxPicks = null;
    _maxOpen = null;
    _onOverrun = null;
    _picksUsed = 0;
  }

  /// Runs [pick] (the code that opens the file dialog) under the guard.
  static Future<T> run<T>(Future<T> Function() pick) async {
    _open++;
    _picksUsed++;
    if (_maxOpen != null) {
      _overrunTimer?.cancel();
      _overrunTimer = Timer(_maxOpen!, () {
        if (_open > 0) _onOverrun?.call();
      });
    }
    try {
      return await pick();
    } finally {
      _open--;
      _overrunTimer?.cancel();
      _overrunTimer = null;
      _graceUntil = DateTime.now().add(_grace);
      finished.value++;
    }
  }
}
