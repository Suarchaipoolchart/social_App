import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// เปิดเต็มจอด้วยตัวเล่นใหม่ที่เริ่มจากตำแหน่งเดิม (หลีกเลี่ยงการใช้ตัวเล่นเดียว
  /// วาดสองที่พร้อมกัน ซึ่งทำให้ภาพขาวบนเว็บ) แล้วซิงก์ตำแหน่งกลับมาตอนปิด
  Future<void> _openFullscreen() async {
    final c = _controller;
    if (c == null) return;
    final wasPlaying = c.value.isPlaying;
    final start = c.value.position;
    await c.pause();
    if (!mounted) return;
    final result = await Navigator.of(context).push<_FullscreenResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullscreenVideoPage(
          url: widget.url,
          start: start,
          autoPlay: wasPlaying,
        ),
      ),
    );
    if (!mounted) return;
    if (result != null) {
      await c.seekTo(result.position);
      if (result.playing) await c.play();
    } else if (wasPlaying) {
      await c.play();
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
            Positioned(
              right: 4,
              bottom: 8,
              child: IconButton(
                tooltip: 'เต็มจอ',
                color: Colors.white,
                icon: const Icon(Icons.fullscreen),
                onPressed: _openFullscreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullscreenResult {
  const _FullscreenResult(this.position, this.playing);

  final Duration position;
  final bool playing;
}

/// เล่นวิดีโอเต็มจอด้วย controller ของตัวเอง (dispose เมื่อปิดหน้า)
class _FullscreenVideoPage extends StatefulWidget {
  const _FullscreenVideoPage({
    required this.url,
    required this.start,
    required this.autoPlay,
  });

  final String url;
  final Duration start;
  final bool autoPlay;

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  late final VideoPlayerController _c;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _init();
  }

  Future<void> _init() async {
    try {
      await _c.initialize();
      await _c.seekTo(widget.start);
      if (widget.autoPlay) await _c.play();
      // วิดีโอแนวนอนให้หมุนจอเป็นแนวนอน (เว็บ/เดสก์ท็อปจะไม่มีผล)
      if (_c.value.aspectRatio > 1) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _close() {
    Navigator.of(context).pop(
      _ready ? _FullscreenResult(_c.value.position, _c.value.isPlaying) : null,
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: _failed
                  ? const Text(
                      'เล่นวิดีโอไม่ได้',
                      style: TextStyle(color: Colors.white70),
                    )
                  : !_ready
                  ? const CircularProgressIndicator()
                  : GestureDetector(
                      onTap: () => _c.value.isPlaying ? _c.pause() : _c.play(),
                      child: AspectRatio(
                        aspectRatio: _c.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(_c),
                            ValueListenableBuilder<VideoPlayerValue>(
                              valueListenable: _c,
                              builder: (context, v, _) => v.isPlaying
                                  ? const SizedBox.shrink()
                                  : const Icon(
                                      Icons.play_circle_fill,
                                      size: 72,
                                      color: Colors.white70,
                                    ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: VideoProgressIndicator(
                                _c,
                                allowScrubbing: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  tooltip: 'ออกจากเต็มจอ',
                  color: Colors.white,
                  icon: const Icon(Icons.fullscreen_exit),
                  onPressed: _close,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
