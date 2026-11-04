import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../../auth/data/auth_repository.dart';
import '../../chat/presentation/chat_list_page.dart';
import '../../follow/data/feed_visibility.dart';
import '../../posts/data/post_model.dart';
import '../../posts/data/post_repository.dart';
import '../../posts/presentation/create_post_page.dart';
import '../../posts/presentation/post_card.dart';
import '../../posts/presentation/tag_posts_page.dart';
import '../../profile/presentation/user_profile_page.dart';
import '../../reports/presentation/reports_page.dart';
import '../../chat/data/chat_repository.dart';
import '../../notifications/presentation/badge_icon.dart';
import '../../notifications/presentation/notification_bell.dart';
import '../../stories/presentation/stories_bar.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  static const _pageSize = 10;

  final _scroll = ScrollController();
  final List<Post> _posts = [];

  DocumentSnapshot<Map<String, dynamic>>? _last;

  bool _loading = false;
  bool _hasMore = true;
  bool _loadedOnce = false;

  String? _error;

  @override
  void initState() {
    super.initState();
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

  Future<PostPage> _fetchVisible(
    DocumentSnapshot<Map<String, dynamic>>? after,
  ) async {
    final repo = context.read<PostRepository>();
    final visibility = context.read<FeedVisibility>();
    final uid = context.read<AuthRepository>().currentUser?.uid ?? '';

    final collected = <Post>[];
    var cursor = after;
    var more = true;
    for (var i = 0; i < 5 && collected.length < _pageSize && more; i++) {
      final page = await repo.fetchPage(after: cursor, limit: _pageSize);
      collected.addAll(await visibility.filter(page.posts, uid));
      cursor = page.last;
      more = page.hasMore;
    }
    return PostPage(posts: collected, last: cursor, hasMore: more);
  }

  Future<void> _loadFirst() async {
    if (_loading) return;

    context.read<FeedVisibility>().refresh();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final page = await _fetchVisible(null);

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
      if (mounted) {
        setState(() => _error = e.message);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore || _last == null) return;

    final messenger = ScaffoldMessenger.of(context);

    setState(() => _loading = true);

    try {
      final page = await _fetchVisible(_last);

      if (!mounted) return;

      setState(() {
        _posts.addAll(page.posts);
        _last = page.last;
        _hasMore = page.hasMore;
      });
    } on PostException catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openEditor(AppUser user, {Post? editing, String? pick}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CreatePostPage(user: user, editing: editing, initialPick: pick),
      ),
    );

    if (!mounted) return;

    await _loadFirst();

    if (_scroll.hasClients) {
      _scroll.jumpTo(0);
    }
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

    if (!mounted || ok != true) return;

    try {
      await repo.deletePost(post.id);

      if (!mounted) return;
      setState(() {
        _posts.removeWhere((p) => p.id == post.id);
      });
    } on PostException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Widget _composerAction(
    IconData icon,
    String label,
    String pick,
    Color foreground,
    AppUser user,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _openEditor(user, pick: pick),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: foreground, size: 21),
                const SizedBox(height: 3),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(color: foreground, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _composer(AppUser user) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : '?',
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => _openEditor(user),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: 0.35,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        'คุณกำลังคิดอะไรอยู่?',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _composerAction(
                  Icons.photo_camera_outlined,
                  'กล้อง',
                  'camera',
                  scheme.onSurfaceVariant,
                  user,
                ),
                _composerAction(
                  Icons.image_outlined,
                  'รูปภาพ',
                  'image',
                  scheme.onSurfaceVariant,
                  user,
                ),
                _composerAction(
                  Icons.videocam_outlined,
                  'วิดีโอ',
                  'video',
                  scheme.onSurfaceVariant,
                  user,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(String uid, AppUser? user) {
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

    return Column(
      children: [
        if (user != null) _composer(user),

        if (user != null) StoriesBar(me: user),

        Expanded(child: _list(uid, user)),
      ],
    );
  }

  Widget _list(String uid, AppUser? user) {
    return RefreshIndicator(
      onRefresh: _loadFirst,
      child: _posts.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 160),
                Center(child: Text('ยังไม่มีโพสต์ มาเป็นคนแรกเลย')),
              ],
            )
          : ListView.builder(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 16),
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
                  viewer: user,
                  post: post,
                  isOwner: post.authorId == uid,
                  onEdit: user == null
                      ? null
                      : () => _openEditor(user, editing: post),
                  onDelete: () => _confirmDelete(post),
                  onAuthorTap: user == null
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                UserProfilePage(uid: post.authorId, me: user),
                          ),
                        ),
                  onTagTap: user == null
                      ? null
                      : (tag) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TagPostsPage(tag: tag, me: user),
                          ),
                        ),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthRepository>();
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<AppUser?>(
      stream: auth.watchUser(uid),
      builder: (context, userSnap) {
        final user = userSnap.data;

        return Scaffold(
          appBar: AppBar(
            centerTitle: false,
            title: const Text(
              'Oxny',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                tooltip: 'แชต',
                icon: user == null
                    ? const Icon(Icons.chat_bubble_outline)
                    : StreamBadgeIcon(
                        stream: context.read<ChatRepository>().watchUnreadCount(
                          user.uid,
                        ),
                        icon: const Icon(Icons.chat_bubble_outline),
                      ),
                onPressed: user == null
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatListPage(me: user),
                        ),
                      ),
              ),
              if (user != null) NotificationBell(me: user),
              if (user != null && user.isAdmin)
                IconButton(
                  tooltip: 'รายงานที่รอตรวจ',
                  icon: const Icon(Icons.flag_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ReportsPage(me: user)),
                  ),
                ),
            ],
          ),
          body: _body(uid, user),
        );
      },
    );
  }
}
