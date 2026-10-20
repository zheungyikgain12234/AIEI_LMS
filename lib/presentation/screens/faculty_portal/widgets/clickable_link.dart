import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Renders a link as tappable, underlined text (its hyperlink text, not the raw URL) that opens in a new browser
/// tab/external app, instead of inert plain text.
class ClickableLink extends StatelessWidget {
  final String url;
  final TextStyle? style;
  final int? maxLines;

  /// What to show instead of the raw URL (the hyperlink text). When empty, the
  /// site's host name is shown, never the full URL.
  final String? text;

  const ClickableLink({super.key, required this.url, this.text, this.style, this.maxLines});

  String get _label {
    final t = text?.trim();
    if (t != null && t.isNotEmpty) return t;
    final host = Uri.tryParse(url)?.host ?? '';
    return host.isEmpty ? 'Link' : host;
  }

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _open,
        child: Text(
          _label,
          style: (style ?? const TextStyle()).copyWith(decoration: TextDecoration.underline),
          maxLines: maxLines,
          overflow: maxLines != null ? TextOverflow.ellipsis : null,
        ),
      ),
    );
  }
}
