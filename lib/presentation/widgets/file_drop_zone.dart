import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/ui_contrast.dart';
import 'package:stitch_aiei_lms/core/utils/file_pick_guard.dart';

/// Maximum number of files any attachment area accepts.
const int kMaxAttachments = 10;

/// A file chosen by drag-and-drop or the file browser, already read into memory.
class PickedUpload {
  final String name;
  final Uint8List bytes;

  const PickedUpload(this.name, this.bytes);
}

/// The upload area used everywhere files can be attached: a large dashed box
/// that says plainly to drag files in (or click to browse), how many files are
/// allowed, and how many are already attached. Dropping files, or choosing
/// them in the file browser, hands them to [onFiles]; anything over the limit
/// is skipped with a message.
class FileDropZone extends StatefulWidget {
  /// Most files this area can hold, counting [currentCount].
  final int maxFiles;

  /// Files already attached to this area.
  final int currentCount;
  final bool uploading;
  final FileType fileType;

  /// Replaces the default heading, e.g. "Drag & drop a video here".
  final String? title;
  final Future<void> Function(List<PickedUpload> files) onFiles;

  const FileDropZone({
    super.key,
    required this.onFiles,
    this.maxFiles = kMaxAttachments,
    this.currentCount = 0,
    this.uploading = false,
    this.fileType = FileType.any,
    this.title,
  });

  @override
  State<FileDropZone> createState() => _FileDropZoneState();
}

class _FileDropZoneState extends State<FileDropZone> {
  bool _dragging = false;

  static const _imageExt = {'png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'svg'};
  static const _videoExt = {'mp4', 'webm', 'mov', 'm4v', 'ogg'};

  int get _remaining => (widget.maxFiles - widget.currentCount).clamp(0, widget.maxFiles);
  bool get _full => _remaining == 0;
  bool get _multiple => widget.maxFiles > 1;

  String get _typeNoun => switch (widget.fileType) {
        FileType.image => _multiple ? 'images' : 'an image',
        FileType.video => _multiple ? 'videos' : 'a video',
        _ => _multiple ? 'files' : 'a file',
      };

  bool _allowed(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return switch (widget.fileType) {
      FileType.image => _imageExt.contains(ext),
      FileType.video => _videoExt.contains(ext),
      _ => true,
    };
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Applies the type and count limits, then passes the rest on.
  Future<void> _accept(List<PickedUpload> picked) async {
    if (picked.isEmpty || widget.uploading) return;
    final typeOk = picked.where((f) => _allowed(f.name)).toList();
    final wrongType = picked.length - typeOk.length;
    final room = _remaining;
    final taken = typeOk.take(room).toList();
    final overLimit = typeOk.length - taken.length;
    if (wrongType > 0) _say('$wrongType file${wrongType == 1 ? '' : 's'} skipped — only $_typeNoun can be added here.');
    if (overLimit > 0) _say('Only ${widget.maxFiles} file${widget.maxFiles == 1 ? '' : 's'} allowed — $overLimit skipped.');
    if (taken.isNotEmpty) await widget.onFiles(taken);
  }

  Future<void> _browse() async {
    if (_full || widget.uploading) return;
    if (!FilePickGuard.canOpen) {
      _say('The file browser can only be opened ${FilePickGuard.maxPicks} times during this exam. Drag your files in instead.');
      return;
    }
    // Guarded so the exam lockdown doesn't mistake the dialog for leaving fullscreen.
    final result = await FilePickGuard.run(
      () => FilePicker.platform.pickFiles(type: widget.fileType, allowMultiple: _remaining > 1, withData: true),
    );
    if (result == null) return;
    await _accept([
      for (final f in result.files)
        if (f.bytes != null) PickedUpload(f.name, f.bytes!),
    ]);
  }

  Future<void> _onDrop(DropDoneDetails details) async {
    setState(() => _dragging = false);
    if (_full) {
      _say('Maximum of ${widget.maxFiles} file${widget.maxFiles == 1 ? '' : 's'} reached — remove one to add another.');
      return;
    }
    final picked = <PickedUpload>[];
    for (final item in details.files) {
      try {
        picked.add(PickedUpload(item.name, await item.readAsBytes()));
      } catch (_) {
        // A folder or unreadable item: skip it.
      }
    }
    await _accept(picked);
  }

  @override
  Widget build(BuildContext context) {
    final active = _dragging && !_full;
    final accent = AdminColors.primaryContainer;
    final title = widget.uploading
        ? 'Uploading…'
        : _full
            ? 'Maximum of ${widget.maxFiles} file${widget.maxFiles == 1 ? '' : 's'} reached'
            : active
                ? 'Drop to upload'
                : (widget.title ?? 'Drag & drop ${_multiple ? 'files' : 'a file'} here');
    final subtitle = _full
        ? 'Remove a file to add another.'
        : _multiple
            ? 'or click to browse • up to ${widget.maxFiles} files (${widget.currentCount} of ${widget.maxFiles} added)'
            : 'or click to browse • 1 file only';

    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: _onDrop,
      child: MouseRegion(
        cursor: _full || widget.uploading ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _browse,
          child: CustomPaint(
            painter: _DashedBorderPainter(color: active ? accent : UiContrast.border, strokeWidth: active ? 2.5 : 1.5),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFDBEAFE) : UiContrast.fieldFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.uploading
                      ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3))
                      : Icon(active ? Icons.file_download_outlined : Icons.cloud_upload_outlined, size: 32, color: _full ? UiContrast.placeholder : accent),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _full ? UiContrast.textSecondary : UiContrast.text),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: UiContrast.textSecondary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _DashedBorderPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 7), paint);
        distance += 12;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color || old.strokeWidth != strokeWidth;
}
