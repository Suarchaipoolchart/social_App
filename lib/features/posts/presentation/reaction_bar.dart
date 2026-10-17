import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../data/post_model.dart';
import '../data/post_repository.dart';
import 'comments_page.dart';

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
  String? _mine;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _counts = Map.of(widget.post.reactionCounts);
    _commentCount = widget.post.commentCount;
    _loadMine();
  }

  int _n(String type) => math.max(0, _counts[type] ?? 0);

  void _apply(String? from, String? to) {
    if (from != null) _counts[from] = _n(from) - 1;
    if (to != null) _counts[to] = _n(to) + 1;
  }

  Future<void> _loadMine() async {
    final repo = context.read<PostRepository>();
    try {
      final t = await repo.getMyReaction(
        widget.post.id,
        widget.viewer.uid,
        groupId: widget.post.groupId,
      );
      if (mounted) setState(() => _mine = t);
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
      );
    } on PostException catch (e) {
      if (mounted) {
        setState(() {
          _apply(next, old);
          _mine = old;
        });
      }
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
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
    try {
      final n = await repo.getCommentCount(
        widget.post.id,
        groupId: widget.post.groupId,
      );
      if (mounted) setState(() => _commentCount = n);
    } on PostException {
      // อัปเดตจำนวนคอมเมนต์ไม่ได้ คงตัวเลขเดิมไว้
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
        if (extras.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 12,
              children: [
                for (final t in extras)
                  Text(
                    '${kReactionEmoji[t]} ${_n(t)}',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        Row(
          children: [
            _ReactButton(
              emoji: kReactionEmoji['like']!,
              count: _n('like'),
              selected: _mine == 'like',
              onTap: () => _react('like'),
            ),
            _ReactButton(
              emoji: kReactionEmoji['dislike']!,
              count: _n('dislike'),
              selected: _mine == 'dislike',
              onTap: () => _react('dislike'),
            ),
            PopupMenuButton<String>(
              tooltip: 'รีแอคชันอื่นๆ',
              onSelected: _react,
              itemBuilder: (_) => [
                for (final t in _extraTypes)
                  PopupMenuItem(
                    value: t,
                    child: Text(
                      kReactionEmoji[t]!,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  mineExtra != null ? kReactionEmoji[mineExtra]! : '😊',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.mode_comment_outlined, size: 20),
              label: Text('$_commentCount'),
              onPressed: _openComments,
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
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: selected ? scheme.primary : scheme.onSurfaceVariant,
        backgroundColor: selected
            ? scheme.primary.withValues(alpha: 0.12)
            : null,
      ),
      child: Text('$emoji $count', style: const TextStyle(fontSize: 16)),
    );
  }
}
