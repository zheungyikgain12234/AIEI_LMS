import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// Read-only rendering of a text [ContentBlock]'s rich-text body. Falls back
/// to a plain [Text] when the block predates rich text and only has a plain
/// string body (no Delta ops).
class RichTextViewer extends StatelessWidget {
  final List<dynamic>? delta;
  final String plainText;
  final TextStyle? plainStyle;
  final int? maxLines;

  const RichTextViewer({super.key, required this.delta, required this.plainText, this.plainStyle, this.maxLines});

  @override
  Widget build(BuildContext context) {
    final ops = delta;
    if (ops == null || ops.isEmpty) {
      return Text(plainText, style: plainStyle, maxLines: maxLines, overflow: maxLines != null ? TextOverflow.ellipsis : null);
    }
    final controller = quill.QuillController(
      document: quill.Document.fromJson(ops),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
    return IgnorePointer(
      child: quill.QuillEditor.basic(
        controller: controller,
        config: const quill.QuillEditorConfig(scrollable: false, expands: false, padding: EdgeInsets.zero, showCursor: false),
      ),
    );
  }
}
