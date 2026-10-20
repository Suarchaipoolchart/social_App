import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../../follow/data/feed_visibility.dart';
import '../../profile/presentation/user_profile_page.dart';
import '../data/post_model.dart';
import '../data/post_repository.dart';
import 'post_card.dart';

class TagPostsPage extends StatefulWidget {
  const TagPostsPage({super.key, required this.tag, required this.me});

  final String tag; // ตัวพิมพ์เล็ก ไม่มี #
  final AppUser me;

  @override
  State<TagPostsPage> createState() => _TagPostsPageState();
}

class _TagPostsPageState extends State<TagPostsPage> {
  late final Future<List<Post>> _future;

  @override
  void initState() {
    super.initState();
    final repo = context.read<PostRepository>();
    final visibility = context.read<FeedVisibility>();
    _future = _load(repo, visibility);
  }

  Future<List<Post>> _load(PostRepository repo, FeedVisibility vis) async {
    final posts = await repo.fetchByTag(widget.tag);
    return vis.filter(posts, widget.me.uid);
  }

  void _openTag(String tag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TagPostsPage(tag: tag, me: widget.me),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('#${widget.tag}')),
      body: FutureBuilder<List<Post>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'โหลดไม่สำเร็จ\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snap.data!;
          if (posts.isEmpty) {
            return Center(
              child: Text('ยังไม่มีโพสต์ที่ติดแท็ก #${widget.tag}'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: posts.length,
            itemBuilder: (context, i) {
              final p = posts[i];
              return PostCard(
                key: ValueKey(p.id),
                viewer: widget.me,
                post: p,
                isOwner: false,
                onAuthorTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        UserProfilePage(uid: p.authorId, me: widget.me),
                  ),
                ),
                onTagTap: _openTag,
              );
            },
          );
        },
      ),
    );
  }
}
