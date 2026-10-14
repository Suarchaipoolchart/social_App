import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PostVideo extends StatefulWidget {
  const PostVideo({super.key, required this.url});

  final String url;

  @override
  State<PostVideo> createState() => _PostVideoState();
}

class _PostVideoState extends State<PostVideo> {
  VideoPlayerController? _controller;
  bool _loading = false;
  bool _failed = false;

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await c.initialize();
      c.addListener(() {
        if (mounted) setState(() {});
      });
      await c.play();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _loading = false;
      });
    } catch (_) {
      await c.dispose();
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;

    if (c == null) {
      return GestureDetector(
        onTap: _loading ? null : _start,
        child: Container(
          height: 220,
          width: double.infinity,
          color: Colors.black87,
          alignment: Alignment.center,
          child: _loading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_circle_fill,
                      size: 64,
                      color: Colors.white,
                    ),
                    if (_failed)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'เล่นวิดีโอไม่ได้ แตะเพื่อลองใหม่',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                  ],
                ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => c.value.isPlaying ? c.pause() : c.play(),
      child: AspectRatio(
        aspectRatio: c.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(c),
            if (!c.value.isPlaying)
              const Icon(
                Icons.play_circle_fill,
                size: 64,
                color: Colors.white70,
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(c, allowScrubbing: true),
            ),
          ],
        ),
      ),
    );
  }
}
