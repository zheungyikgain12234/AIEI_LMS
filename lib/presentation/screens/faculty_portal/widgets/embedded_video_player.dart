import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';

/// Embeds a video directly in the syllabus (no link-out).
///
/// Both the YouTube iframe and the native file player render as real
/// browser/OS platform views rather than ordinary Flutter-painted widgets,
/// so they ignore Flutter's dialog/overlay stacking and can visually sit on
/// top of — and intercept taps meant for — a dialog opened above them (e.g.
/// the rich-text editor dialog, while a video block renders behind it in the
/// content list). To avoid that, this only shows a plain (non-platform-view)
/// thumbnail with a play button until the lecturer explicitly taps it; the
/// real player is mounted only then, once nothing else needs the tap.
///
/// YouTube URLs use the YouTube iframe player once started, which is
/// skippable by design (YouTube's own player can't be locked down further).
/// Any other URL is treated as a direct video file and played with
/// [_UnskippableVideoPlayer], which has no seek bar and ignores taps/drags on
/// the playback position.
class EmbeddedVideoPlayer extends StatefulWidget {
  final String url;
  final String? thumbnailUrl;

  const EmbeddedVideoPlayer({super.key, required this.url, this.thumbnailUrl});

  @override
  State<EmbeddedVideoPlayer> createState() => _EmbeddedVideoPlayerState();
}

class _EmbeddedVideoPlayerState extends State<EmbeddedVideoPlayer> {
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    final videoId = YoutubePlayerController.convertUrlToId(widget.url);
    if (!_started) {
      return _VideoThumbnail(
        youtubeVideoId: videoId,
        thumbnailUrl: widget.thumbnailUrl,
        onTap: () => setState(() => _started = true),
      );
    }
    if (videoId != null) {
      return _WithFullscreenButton(
        onFullscreen: () => _openFullscreen(context, videoId: videoId),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: YoutubePlayer(controller: YoutubePlayerController.fromVideoId(videoId: videoId, autoPlay: true)),
          ),
        ),
      );
    }
    return _WithFullscreenButton(
      onFullscreen: () => _openFullscreen(context, fileUrl: widget.url),
      child: _UnskippableVideoPlayer(url: widget.url),
    );
  }

  void _openFullscreen(BuildContext context, {String? videoId, String? fileUrl}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullscreenVideoPage(videoId: videoId, fileUrl: fileUrl),
      ),
    );
  }
}

/// Overlays a small "fullscreen" icon button on the top-right corner of a
/// playing video, so it can be opened larger without leaving the page.
class _WithFullscreenButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onFullscreen;

  const _WithFullscreenButton({required this.child, required this.onFullscreen});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: IconButton(
              onPressed: onFullscreen,
              icon: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
              tooltip: 'Fullscreen',
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-screen page opened by the fullscreen button — plays the same
/// YouTube video or file URL larger, with a close button to return.
class _FullscreenVideoPage extends StatelessWidget {
  final String? videoId;
  final String? fileUrl;

  const _FullscreenVideoPage({this.videoId, this.fileUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: videoId != null
                    ? YoutubePlayer(controller: YoutubePlayerController.fromVideoId(videoId: videoId!, autoPlay: true))
                    : _UnskippableVideoPlayer(url: fileUrl!),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Close',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoThumbnail extends StatelessWidget {
  final String? youtubeVideoId;
  final String? thumbnailUrl;
  final VoidCallback onTap;

  const _VideoThumbnail({required this.youtubeVideoId, required this.thumbnailUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final videoId = youtubeVideoId;
    final customThumbnail = thumbnailUrl;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Material(
          color: FacultyColors.surfaceContainerLow,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              alignment: Alignment.center,
              fit: StackFit.expand,
              children: [
                if (videoId != null)
                  Image.network(
                    'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  )
                else if (customThumbnail != null && customThumbnail.isNotEmpty)
                  Image.network(
                    customThumbnail,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                Container(color: Colors.black26),
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow, size: 32, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnskippableVideoPlayer extends StatefulWidget {
  final String url;

  const _UnskippableVideoPlayer({required this.url});

  @override
  State<_UnskippableVideoPlayer> createState() => _UnskippableVideoPlayerState();
}

class _UnskippableVideoPlayerState extends State<_UnskippableVideoPlayer> {
  late final VideoPlayerController _controller;
  late final Future<void> _initialize;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _initialize = _controller.initialize().then((_) {
      if (mounted) setState(() {});
      _controller.play();
    });
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialize,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || !_controller.value.isInitialized) {
          return AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(color: FacultyColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: snapshot.hasError
                  ? Text('Could not load video', style: TextStyle(color: FacultyColors.error))
                  : const CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final position = _controller.value.position;
        final duration = _controller.value.duration;
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_controller),
                // No GestureDetector for scrubbing here, and no seek bar below
                // — tapping only toggles play/pause, so position can't be skipped.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _togglePlay,
                  child: AnimatedOpacity(
                    opacity: _controller.value.isPlaying ? 0 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      color: Colors.black26,
                      alignment: Alignment.center,
                      child: const Icon(Icons.play_arrow, size: 56, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 6,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _togglePlay,
                        icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 20),
                        visualDensity: VisualDensity.compact,
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: duration.inMilliseconds == 0 ? 0 : position.inMilliseconds / duration.inMilliseconds,
                            minHeight: 4,
                            backgroundColor: Colors.white30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
