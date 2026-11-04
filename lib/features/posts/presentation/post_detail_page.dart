import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../../profile/presentation/user_profile_page.dart';
import '../data/post_model.dart';
import '../data/post_repository.dart';
import 'post_card.dart';
import 'tag_posts_page.dart';

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({
    super.key,
    required this.postId,
    required this.me,
    this.groupId,
  });

  final String postId;
  final String? groupId;
  final AppUser me;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late final Future<Post?> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<PostRepository>().fetchOne(
      widget.postId,
      groupId: widget.groupId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('โพสต์')),
      body: FutureBuilder<Post?>(
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
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final post = snap.data;
          if (post == null) {
            return const Center(child: Text('ไม่พบโพสต์นี้ (อาจถูกลบไปแล้ว)'));
          }
          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            children: [
              PostCard(
                viewer: widget.me,
                post: post,
                isOwner: false,
                onAuthorTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        UserProfilePage(uid: post.authorId, me: widget.me),
                  ),
                ),
                onTagTap: (tag) => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TagPostsPage(tag: tag, me: widget.me),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
