import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:video_player/video_player.dart';

import '../../auth/data/app_user.dart';

import '../data/story_models.dart';

import '../data/story_repository.dart';

const _reactionChoices = ['❤️', '😂', '😮', '😢', '👍', '🔥'];

String _timeAgo(DateTime? t) {
  if (t == null) return '';

  final diff = DateTime.now().difference(t);

  if (diff.inSeconds < 60) return 'เมื่อสักครู่';

  if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';

  if (diff.inHours < 24) return '${diff.inHours} ชม.ที่แล้ว';

  return '${diff.inDays} วันที่แล้ว';
}

/// ดูสตอรี่เต็มจอ: แตะขวา/ซ้ายเพื่อข้าม กดค้างเพื่อหยุด

/// คนอื่น -> กดอิโมจิได้ / เจ้าของ -> เห็นยอดคนดูและรายชื่อ (ไม่มีปุ่มอิโมจิ)

class StoryViewerPage extends StatefulWidget {
  const StoryViewerPage({
    super.key,

    required this.groups,

    required this.initialGroup,

    required this.me,
  });

  final List<UserStories> groups;

  final int initialGroup;

  final AppUser me;

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;

  late final StoryRepository _repo;

  late int _g;

  int _s = 0;

  VideoPlayerController? _video;

  Stream<List<StoryViewer>>? _viewers;

  bool _loading = true;

  bool _failed = false;

  bool _paused = false;

  String? _myReaction;

  int _token = 0; // กันผลของการโหลดเก่ามาทับเมื่อข้ามสตอรี่เร็วๆ

  Story get _story => widget.groups[_g].stories[_s];

  bool get _mine => _story.authorId == widget.me.uid;

  @override
  void initState() {
    super.initState();

    _repo = context.read<StoryRepository>();

    _g = widget.initialGroup;

    _progress =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) _next();
          });

    _load();
  }

  @override
  void dispose() {
    _progress.dispose();

    _video?.dispose();

    super.dispose();
  }

  Future<void> _load() async {
    final token = ++_token;

    final story = _story;

    _progress.stop();

    _progress.value = 0;

    final old = _video;

    setState(() {
      _video = null;

      _loading = true;

      _failed = false;

      _myReaction = null;

      _viewers = _mine ? _repo.watchViewers(story.id) : null;
    });

    await old?.dispose();

    if (!mounted || token != _token) {
      return;
    }

    _repo.markViewed(story, widget.me);

    if (!_mine) {
      _repo.getMyReaction(story.id, widget.me.uid).then((r) {
        if (mounted && token == _token) setState(() => _myReaction = r);
      });
    }

    if (story.isVideo) {
      final c = VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl));

      try {
        await c.initialize();
      } catch (_) {
        await c.dispose();

        if (!mounted || token != _token) return;

        setState(() {
          _loading = false;

          _failed = true;
        });

        _progress.duration = const Duration(seconds: 3);

        if (!_paused) _progress.forward();

        return;
      }

      if (!mounted || token != _token) {
        await c.dispose();

        return;
      }

      final d = c.value.duration;

      _progress.duration = d > const Duration(seconds: 30)
          ? const Duration(seconds: 30)
          : (d < const Duration(seconds: 1) ? const Duration(seconds: 1) : d);

      setState(() {
        _video = c;

        _loading = false;
      });

      if (!_paused) {
        await c.play();

        _progress.forward();
      }
    } else {
      try {
        await precacheImage(NetworkImage(story.mediaUrl), context);
      } catch (_) {
        if (mounted && token == _token) setState(() => _failed = true);
      }

      if (!mounted || token != _token) return;

      _progress.duration = const Duration(seconds: 5);

      setState(() => _loading = false);

      if (!_paused) _progress.forward();
    }
  }

  void _next() {
    if (_s < widget.groups[_g].stories.length - 1) {
      _s++;

      _load();
    } else if (_g < widget.groups.length - 1) {
      _g++;

      _s = 0;

      _load();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _prev() {
    if (_s > 0) {
      _s--;
    } else if (_g > 0) {
      _g--;

      _s = widget.groups[_g].stories.length - 1;
    }

    _load();
  }

  void _pause() {
    _paused = true;

    _progress.stop();

    _video?.pause();
  }

  void _resume() {
    _paused = false;

    if (!_loading) {
      _progress.forward();

      _video?.play();
    }
  }

  Future<void> _react(String emoji) async {
    final story = _story;

    final next = _myReaction == emoji ? null : emoji;

    setState(() => _myReaction = next);

    try {
      await _repo.setReaction(story, widget.me, next);
    } on StoryException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete() async {
    _pause();

    final ok = await showDialog<bool>(
      context: context,

      builder: (ctx) => AlertDialog(
        title: const Text('ลบสตอรี่นี้?'),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),

            child: const Text('ยกเลิก'),
          ),

          TextButton(
            onPressed: () => Navigator.pop(ctx, true),

            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    // ตรวจสอบหลัง await ก่อนกลับไปใช้ context
    if (!mounted) return;

    if (ok != true) {
      if (mounted) _resume();

      return;
    }

    final navigator = Navigator.of(context);

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _repo.deleteStory(_story.id);

      if (!mounted) return;

      navigator.pop();
    } on StoryException catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(SnackBar(content: Text(e.message)));

      _resume();
    }
  }

  Future<void> _showViewers(List<StoryViewer> viewers) async {
    _pause();

    await showModalBottomSheet<void>(
      context: context,

      showDragHandle: true,

      builder: (ctx) => SafeArea(
        child: viewers.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(32),

                child: Center(child: Text('ยังไม่มีใครดู')),
              )
            : ListView(
                shrinkWrap: true,

                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),

                    child: Text(
                      'ผู้ชม ${viewers.length} คน',

                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  for (final v in viewers)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: v.photoUrl != null
                            ? NetworkImage(v.photoUrl!)
                            : null,

                        child: v.photoUrl == null
                            ? Text(
                                v.displayName.isNotEmpty
                                    ? v.displayName[0].toUpperCase()
                                    : '?',
                              )
                            : null,
                      ),

                      title: Text(v.displayName),

                      subtitle: Text(_timeAgo(v.viewedAt)),

                      trailing: v.reaction != null
                          ? Text(
                              v.reaction!,

                              style: const TextStyle(fontSize: 24),
                            )
                          : null,
                    ),
                ],
              ),
      ),
    );

    if (mounted) _resume();
  }

  Widget _media() {
    if (_loading) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    if (_failed) {
      return const Text(
        'โหลดสตอรี่ไม่ได้',

        style: TextStyle(color: Colors.white70),
      );
    }

    final c = _video;

    if (c != null) {
      return AspectRatio(
        aspectRatio: c.value.aspectRatio,

        child: VideoPlayer(c),
      );
    }

    return Image.network(
      _story.mediaUrl,

      fit: BoxFit.contain,

      width: double.infinity,

      height: double.infinity,
    );
  }

  Widget _progressBars() {
    final count = widget.groups[_g].stories.length;

    return Row(
      children: [
        for (var i = 0; i < count; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),

              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),

                child: i == _s
                    ? AnimatedBuilder(
                        animation: _progress,

                        builder: (context, _) => LinearProgressIndicator(
                          value: _progress.value,

                          minHeight: 3,

                          backgroundColor: Colors.white24,

                          color: Colors.white,
                        ),
                      )
                    : LinearProgressIndicator(
                        value: i < _s ? 1 : 0,

                        minHeight: 3,

                        backgroundColor: Colors.white24,

                        color: Colors.white,
                      ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _bottom() {
    final story = _story;

    return Column(
      mainAxisSize: MainAxisSize.min,

      children: [
        if (story.caption.isNotEmpty)
          Container(
            width: double.infinity,

            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),

            padding: const EdgeInsets.all(10),

            decoration: BoxDecoration(
              color: Colors.black54,

              borderRadius: BorderRadius.circular(12),
            ),

            child: Text(
              story.caption,

              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),

        if (_mine)
          StreamBuilder<List<StoryViewer>>(
            stream: _viewers,

            builder: (context, snap) {
              final viewers = snap.data ?? const <StoryViewer>[];

              final reacted = viewers.where((v) => v.reaction != null).length;

              return InkWell(
                onTap: () => _showViewers(viewers),

                child: Container(
                  width: double.infinity,

                  padding: const EdgeInsets.symmetric(vertical: 14),

                  color: Colors.black54,

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      const Icon(Icons.visibility, color: Colors.white),

                      const SizedBox(width: 8),

                      Text(
                        'ผู้ชม ${viewers.length} คน'
                        '${reacted > 0 ? '  ·  แสดงอารมณ์ $reacted' : ''}',

                        style: const TextStyle(color: Colors.white),
                      ),

                      const SizedBox(width: 4),

                      const Icon(
                        Icons.keyboard_arrow_up,

                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        else
          Container(
            width: double.infinity,

            padding: const EdgeInsets.symmetric(vertical: 10),

            color: Colors.black54,

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,

              children: [
                for (final e in _reactionChoices)
                  GestureDetector(
                    onTap: () => _react(e),

                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),

                      padding: const EdgeInsets.all(6),

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        color: _myReaction == e
                            ? Colors.white24
                            : Colors.transparent,
                      ),

                      child: AnimatedScale(
                        scale: _myReaction == e ? 1.3 : 1,

                        duration: const Duration(milliseconds: 150),

                        child: Text(e, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.groups[_g];

    final story = _story;

    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, box) => GestureDetector(
                behavior: HitTestBehavior.opaque,

                onTapUp: (d) =>
                    d.localPosition.dx < box.maxWidth / 3 ? _prev() : _next(),

                onLongPressStart: (_) => _pause(),

                onLongPressEnd: (_) => _resume(),

                child: Center(child: _media()),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),

                  child: _progressBars(),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),

                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,

                        backgroundImage: group.authorPhotoUrl != null
                            ? NetworkImage(group.authorPhotoUrl!)
                            : null,

                        child: group.authorPhotoUrl == null
                            ? Text(
                                group.authorName.isNotEmpty
                                    ? group.authorName[0].toUpperCase()
                                    : '?',
                              )
                            : null,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              group.authorName,

                              maxLines: 1,

                              overflow: TextOverflow.ellipsis,

                              style: const TextStyle(
                                color: Colors.white,

                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Text(
                              _timeAgo(story.createdAt),

                              style: const TextStyle(
                                color: Colors.white70,

                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_mine)
                        IconButton(
                          tooltip: 'ลบสตอรี่',

                          color: Colors.white,

                          icon: const Icon(Icons.delete_outline),

                          onPressed: _delete,
                        ),

                      IconButton(
                        tooltip: 'ปิด',

                        color: Colors.white,

                        icon: const Icon(Icons.close),

                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                _bottom(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
