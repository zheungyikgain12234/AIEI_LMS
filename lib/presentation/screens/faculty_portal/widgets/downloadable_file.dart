import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';

/// A file attachment row that downloads/opens the file in a new tab on tap,
/// instead of just showing its name as inert text.
class DownloadableFile extends StatelessWidget {
  final String url;
  final String label;
  final TextStyle? style;

  const DownloadableFile({super.key, required this.url, required this.label, this.style});

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.download_outlined, size: 14, color: FacultyColors.primary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: (style ?? const TextStyle()).copyWith(decoration: TextDecoration.underline, color: FacultyColors.primary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
