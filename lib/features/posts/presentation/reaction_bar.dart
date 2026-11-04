import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../data/post_model.dart';
import '../data/post_repository.dart';
import 'comments_page.dart';
import 'share_post_dialog.dart';

const kReactionEmoji = <String, String>{
  'like': '👍',
  'love': '❤️',
  'haha': '😆',
  'wow': '😮',
  'sad': '😢',
  'angry': '😡',
  'dislike': '👎',
};

const _extraTypes = ['love', 'haha', 'wow', 'sad', 'angry'];

class ReactionBar extends StatefulWidget {
  const ReactionBar({super.key, required this.post, required this.viewer});

  final Post post;
  final AppUser viewer;

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar> {
  late final Map<String, int> _counts;
  late int _commentCount;
  late int _shareCount;

  String? _mine;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _counts = Map.of(widget.post.reactionCounts);
    _commentCount = widget.post.commentCount;
    _shareCount = widget.post.shareCount;
    _loadMine();
  }

  @override
  void didUpdateWidget(covariant ReactionBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.post, widget.post) && !_busy) {
      _counts
        ..clear()
        ..addAll(widget.post.reactionCounts);

      _commentCount = widget.post.commentCount;
      _shareCount = widget.post.shareCount;
      _loadMine();
    }
  }

  int _n(String type) => math.max(0, _counts[type] ?? 0);

  void _apply(String? from, String? to) {
    if (from != null) _counts[from] = _n(from) - 1;
    if (to != null) _counts[to] = _n(to) + 1;
  }

  Future<void> _loadMine() async {
    final repo = context.read<PostRepository>();

    try {
      final type = await repo.getMyReaction(
        widget.post.id,
        widget.viewer.uid,
        groupId: widget.post.groupId,
      );

      if (!mounted) return;
      setState(() => _mine = type);
    } on PostException {
      // โหลดรีแอคชันของเราไม่ได้ ปล่อยเป็นว่างไว้
    }
  }

  Future<void> _react(String type) async {
    if (_busy) return;

    final repo = context.read<PostRepository>();
    final messenger = ScaffoldMessenger.of(context);

    final old = _mine;
    final next = old == type ? null : type;

    setState(() {
      _busy = true;
      _apply(old, next);
      _mine = next;
    });

    try {
      await repo.setReaction(
        widget.post.id,
        widget.viewer.uid,
        next,
        groupId: widget.post.groupId,
        actor: widget.viewer,
        postAuthorId: widget.post.authorId,
        postText: widget.post.text,
      );
    } on PostException catch (e) {
      if (!mounted) return;

      setState(() {
        _apply(next, old);
        _mine = old;
      });

      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _openComments() async {
    final repo = context.read<PostRepository>();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommentsPage(post: widget.post, viewer: widget.viewer),
      ),
    );

    if (!mounted) return;

    try {
      final count = await repo.getCommentCount(
        widget.post.id,
        groupId: widget.post.groupId,
      );

      if (!mounted) return;
      setState(() => _commentCount = count);
    } on PostException {
      // อัปเดตจำนวนคอมเมนต์ไม่ได้ คงตัวเลขเดิมไว้
    }
  }

  Future<void> _share() async {
    final ok = await showSharePostDialog(
      context,
      post: widget.post,
      sharer: widget.viewer,
    );

    if (!mounted) return;

    if (ok) {
      setState(() => _shareCount += 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extras = _extraTypes.where((t) => _n(t) > 0).toList();
    final mineExtra = _extraTypes.contains(_mine) ? _mine : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (extras.isNotEmpty || _shareCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                for (final type in extras)
                  Text(
                    '${kReactionEmoji[type]} ${_n(type)}',
                    style: theme.textTheme.bodySmall,
                  ),
                if (_shareCount > 0)
                  Text(
                    'แชร์ $_shareCount ครั้ง',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),

        const SizedBox(height: 4),

        // ใช้ Wrap แทน Row เพื่อไม่ให้ปุ่มล้นจอบนมือถือ
        Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 2,
          runSpacing: 2,
          children: [
            _ReactButton(
              label: 'ถูกใจ',
              emoji: kReactionEmoji['like']!,
              count: _n('like'),
              selected: _mine == 'like',
              onTap: () => _react('like'),
            ),
            _ReactButton(
              label: 'ไม่ถูกใจ',
              emoji: kReactionEmoji['dislike']!,
              count: _n('dislike'),
              selected: _mine == 'dislike',
              onTap: () => _react('dislike'),
            ),
            PopupMenuButton<String>(
              tooltip: 'รีแอคชันอื่นๆ',
              onSelected: _react,
              itemBuilder: (_) => [
                for (final type in _extraTypes)
                  PopupMenuItem(
                    value: type,
                    child: Text(
                      kReactionEmoji[type]!,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Text(
                  mineExtra != null ? kReactionEmoji[mineExtra]! : '😊',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            IconButton(
              tooltip: 'แชร์โพสต์',
              icon: const Icon(Icons.share_outlined, size: 20),
              onPressed: _busy ? null : _share,
              visualDensity: VisualDensity.compact,
            ),
            TextButton.icon(
              icon: const Icon(Icons.mode_comment_outlined, size: 20),
              label: Text('$_commentCount'),
              onPressed: _openComments,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReactButton extends StatelessWidget {
  const _ReactButton({
    required this.emoji,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label $count',
      excludeSemantics: true,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: selected ? scheme.primary : scheme.onSurfaceVariant,
          backgroundColor: selected
              ? scheme.primary.withValues(alpha: 0.12)
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        child: Text('$emoji $count', style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
