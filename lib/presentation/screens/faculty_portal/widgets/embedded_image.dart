import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';

/// Directly embeds an image (resized to fit) rather than showing its raw
/// URL. Handles both raster images (png/jpg/webp/gif — via [Image.network])
/// and `.svg` vector images (via [SvgPicture.network], since [Image.network]
/// can't decode SVG at all and would otherwise always fail for it). Shows a
/// spinner while loading and a clear "couldn't load" state instead of
/// silently falling back to plain link text.
///
/// Tapping the thumbnail opens it full-size in a dismissible popup (unless
/// [enableTapToExpand] is false, e.g. for the live preview inside the "Add
/// Content" form, where a popup on top of the dialog would be confusing).
class EmbeddedImage extends StatelessWidget {
  final String url;
  final double height;
  final double? width;
  final bool enableTapToExpand;

  const EmbeddedImage({super.key, required this.url, required this.height, this.width, this.enableTapToExpand = true});

  bool get _isSvg => Uri.tryParse(url)?.path.toLowerCase().endsWith('.svg') ?? false;

  @override
  Widget build(BuildContext context) {
    final thumbnail = ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: _isSvg
          ? SvgPicture.network(
              url,
              height: height,
              width: width,
              fit: BoxFit.contain,
              placeholderBuilder: (context) => _loading(),
              errorBuilder: (context, error, stackTrace) => _error(),
            )
          : Image.network(
              url,
              height: height,
              width: width,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) => progress == null ? child : _loading(),
              errorBuilder: (context, error, stackTrace) => _error(),
            ),
    );
    if (!enableTapToExpand) return thumbnail;
    return GestureDetector(
      onTap: () => _showFullScreen(context),
      child: MouseRegion(cursor: SystemMouseCursors.click, child: thumbnail),
    );
  }

  void _showFullScreen(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: _isSvg
                    ? SvgPicture.network(url, fit: BoxFit.contain)
                    : Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => _error(),
                      ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(ctx).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
              tooltip: 'Close',
            ),
          ],
        ),
      ),
    );
  }

  Widget _loading() => SizedBox(
        height: height,
        width: width,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );

  Widget _error() => Container(
        height: height,
        width: width,
        color: FacultyColors.surfaceContainerLow,
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image_outlined, size: 20, color: FacultyColors.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(
              'Image failed to load — if this is a link to another site, try uploading the file instead',
              style: TextStyle(fontSize: 11, color: FacultyColors.onSurfaceVariant),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
}
