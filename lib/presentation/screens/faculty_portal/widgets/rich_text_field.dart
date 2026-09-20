import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';

/// Builds the [quill.QuillController] backing a [RichTextField] — split out
/// so the caller (e.g. a dialog) can own the controller's lifecycle and read
/// its content (via [deltaJsonOf]/[plainTextOf]) without a GlobalKey.
quill.QuillController createRichTextController({List<dynamic>? initialDelta, String? initialPlainText}) {
  quill.Document document;
  if (initialDelta != null && initialDelta.isNotEmpty) {
    document = quill.Document.fromJson(initialDelta);
  } else if (initialPlainText != null && initialPlainText.isNotEmpty) {
    document = quill.Document()..insert(0, initialPlainText);
  } else {
    document = quill.Document();
  }
  return quill.QuillController(document: document, selection: const TextSelection.collapsed(offset: 0));
}

bool isRichTextEmpty(quill.QuillController controller) => controller.document.toPlainText().trim().isEmpty;

List<Map<String, dynamic>> deltaJsonOf(quill.QuillController controller) =>
    controller.document.toDelta().toJson().cast<Map<String, dynamic>>();

String plainTextOf(quill.QuillController controller) => controller.document.toPlainText().trim();

/// A formatting toolbar + editor for authoring the rich-text `body` of a
/// text [ContentBlock]. The caller supplies and disposes the [controller].
///
/// Owns a stable [FocusNode]/[ScrollController] itself (created once, in
/// [State], rather than via [quill.QuillEditor.basic] — that factory builds a
/// *new* default FocusNode/ScrollController on every call it's given none,
/// so if this were a [StatelessWidget], every parent rebuild while typing
/// (the caller listens to the controller to refresh its Save button) would
/// hand the editor a fresh, unfocused FocusNode and immediately kick the
/// cursor out — making it look like the field can't be typed into at all.
class RichTextField extends StatefulWidget {
  final quill.QuillController controller;

  const RichTextField({super.key, required this.controller});

  @override
  State<RichTextField> createState() => _RichTextFieldState();
}

class _RichTextFieldState extends State<RichTextField> {
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: FacultyColors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          quill.QuillSimpleToolbar(
            controller: widget.controller,
            config: const quill.QuillSimpleToolbarConfig(
              showFontFamily: false,
              showFontSize: false,
              showSubscript: false,
              showSuperscript: false,
              showSmallButton: false,
              showInlineCode: false,
              showCodeBlock: false,
              showSearchButton: false,
              showClearFormat: false,
              multiRowsDisplay: false,
            ),
          ),
          const Divider(height: 1, color: FacultyColors.outlineVariant),
          Container(
            constraints: const BoxConstraints(minHeight: 140, maxHeight: 260),
            padding: const EdgeInsets.all(10),
            child: quill.QuillEditor(
              controller: widget.controller,
              focusNode: _focusNode,
              scrollController: _scrollController,
              config: const quill.QuillEditorConfig(placeholder: 'Write session content…', padding: EdgeInsets.zero),
            ),
          ),
        ],
      ),
    );
  }
}
