import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Renders a URL as tappable, underlined text that opens in a new browser
/// tab/external app, instead of inert plain text.
class ClickableLink extends StatelessWidget {
  final String url;
  final TextStyle? style;
  final int? maxLines;

  const ClickableLink({super.key, required this.url, this.style, this.maxLines});

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
          url,
          style: (style ?? const TextStyle()).copyWith(decoration: TextDecoration.underline),
          maxLines: maxLines,
          overflow: maxLines != null ? TextOverflow.ellipsis : null,
        ),
      ),
    );
  }
}
