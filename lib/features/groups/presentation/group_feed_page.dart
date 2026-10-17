import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../../posts/data/post_model.dart';
import '../../posts/data/post_repository.dart';
import '../../posts/presentation/create_post_page.dart';
import '../../posts/presentation/post_card.dart';
import '../data/group_models.dart';
import '../data/group_repository.dart';
import '../../profile/presentation/user_profile_page.dart';

class GroupFeedPage extends StatefulWidget {
  const GroupFeedPage({super.key, required this.groupId, required this.me});

  final String groupId;
  final AppUser me;

  @override
  State<GroupFeedPage> createState() => _GroupFeedPageState();
}

class _GroupFeedPageState extends State<GroupFeedPage> {
  static const _pageSize = 10;

  final _scroll = ScrollController();
  final List<Post> _posts = [];
  late final Stream<Group?> _group;

  DocumentSnapshot<Map<String, dynamic>>? _last;
  bool _loading = false;
  bool _hasMore = true;
  bool _loadedOnce = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _group = context.read<GroupRepository>().watchGroup(widget.groupId);
    _scroll.addListener(_onScroll);
    _loadFirst();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadFirst() async {
    if (_loading) return;
    final repo = context.read<PostRepository>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await repo.fetchPage(
        limit: _pageSize,
        groupId: widget.groupId,
      );
      if (!mounted) return;
      setState(() {
        _posts
          ..clear()
          ..addAll(page.posts);
        _last = page.last;
        _hasMore = page.hasMore;
        _loadedOnce = true;
      });
    } on PostException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore || _last == null) return;
    final repo = context.read<PostRepository>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      final page = await repo.fetchPage(
        after: _last,
        limit: _pageSize,
        groupId: widget.groupId,
      );
      if (!mounted) return;
      setState(() {
        _posts.addAll(page.posts);
        _last = page.last;
        _hasMore = page.hasMore;
      });
    } on PostException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor({Post? editing}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostPage(
          user: widget.me,
          editing: editing,
          groupId: widget.groupId,
        ),
      ),
    );
    if (!mounted) return;
    await _loadFirst();
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _confirmDelete(Post post) async {
    final repo = context.read<PostRepository>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบโพสต์?'),
        content: const Text('ลบแล้วกู้คืนไม่ได้'),
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
    if (ok != true) return;

    try {
      await repo.deletePost(post.id, groupId: widget.groupId);
      if (mounted) setState(() => _posts.removeWhere((p) => p.id == post.id));
    } on PostException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Widget _list() {
    if (!_loadedOnce && _loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadFirst,
                child: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFirst,
      child: _posts.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: Text('ยังไม่มีโพสต์ในที่นี้')),
              ],
            )
          : ListView.builder(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 88),
              itemCount: _posts.length + 1,
              itemBuilder: (context, i) {
                if (i == _posts.length) {
                  if (_hasMore) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('ดูครบทุกโพสต์แล้ว')),
                  );
                }
                final post = _posts[i];
                return PostCard(
                  key: ValueKey(post.id),
                  viewer: widget.me,
                  post: post,
                  isOwner: post.authorId == widget.me.uid,
                  onEdit: () => _openEditor(editing: post),
                  onDelete: () => _confirmDelete(post),

                  onAuthorTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          UserProfilePage(uid: post.authorId, me: widget.me),
                    ),
                  ),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Group?>(
      stream: _group,
      builder: (context, snap) {
        final g = snap.data;
        if (snap.connectionState != ConnectionState.waiting && g == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('ไม่พบกลุ่มนี้ (อาจถูกลบไปแล้ว)')),
          );
        }

        // กลุ่ม: สมาชิกโพสต์ได้ / เพจ: เฉพาะผู้ดูแล
        final canPost =
            g != null &&
            (g.isPage ? g.isOwner(widget.me.uid) : g.isMember(widget.me.uid));

        String? hint;
        if (g != null && !canPost) {
          hint = g.isPage
              ? 'เฉพาะผู้ดูแลเพจที่โพสต์ได้'
              : 'เข้าร่วมกลุ่มเพื่อโพสต์';
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(g?.name ?? 'ฟีด', overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: 'รีเฟรช',
                icon: const Icon(Icons.refresh),
                onPressed: _loading ? null : _loadFirst,
              ),
            ],
          ),
          floatingActionButton: canPost
              ? FloatingActionButton.extended(
                  icon: const Icon(Icons.edit),
                  label: const Text('โพสต์'),
                  onPressed: () => _openEditor(),
                )
              : null,
          body: Column(
            children: [
              if (hint != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.10),
                  child: Text(hint, textAlign: TextAlign.center),
                ),
              Expanded(child: _list()),
            ],
          ),
        );
      },
    );
  }
}
