import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../routes/app_routes.dart';
import '../../auth/data/app_user.dart';
import '../../auth/data/auth_repository.dart';
import '../../chat/presentation/chat_list_page.dart';
import '../../groups/presentation/groups_page.dart';
import '../../posts/data/post_model.dart';
import '../../posts/data/post_repository.dart';
import '../../posts/presentation/create_post_page.dart';
import '../../posts/presentation/post_card.dart';

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

  Future<void> _loadFirst() async {
    if (_loading) return;

    final repo = context.read<PostRepository>();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final page = await repo.fetchPage(limit: _pageSize);

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

    final repo = context.read<PostRepository>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _loading = true);

    try {
      final page = await repo.fetchPage(after: _last, limit: _pageSize);

      if (!mounted) return;

      setState(() {
        _posts.addAll(page.posts);
        _last = page.last;
        _hasMore = page.hasMore;
      });
    } on PostException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openEditor(AppUser user, {Post? editing}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostPage(user: user, editing: editing),
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

    if (ok != true) return;

    try {
      await repo.deletePost(post.id);

      if (mounted) {
        setState(() {
          _posts.removeWhere((p) => p.id == post.id);
        });
      }
    } on PostException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
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
                  viewer: user,
                  post: post,
                  isOwner: post.authorId == uid,
                  onEdit: user == null
                      ? null
                      : () => _openEditor(user, editing: post),
                  onDelete: () => _confirmDelete(post),
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
            title: const Text('ฟีด'),
            actions: [
              // ปุ่มรีเฟรช
              IconButton(
                tooltip: 'รีเฟรช',
                icon: const Icon(Icons.refresh),
                onPressed: _loading ? null : _loadFirst,
              ),

              // ปุ่มกลุ่มและเพจ
              IconButton(
                tooltip: 'กลุ่มและเพจ',
                icon: const Icon(Icons.groups_outlined),
                onPressed: user == null
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => GroupsPage(me: user)),
                      ),
              ),

              // ปุ่มแชต
              IconButton(
                tooltip: 'แชต',
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: user == null
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatListPage(me: user),
                        ),
                      ),
              ),

              // ปุ่มโปรไฟล์
              IconButton(
                tooltip: 'โปรไฟล์',
                icon: const Icon(Icons.person),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.profile);
                },
              ),
            ],
          ),
          floatingActionButton: user == null
              ? null
              : FloatingActionButton.extended(
                  icon: const Icon(Icons.edit),
                  label: const Text('โพสต์'),
                  onPressed: () => _openEditor(user),
                ),
          body: _body(uid, user),
        );
      },
    );
  }
}
