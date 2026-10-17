import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../../auth/data/auth_repository.dart';
import '../../chat/data/chat_models.dart';
import '../../chat/presentation/chat_page.dart';
import '../../follow/data/follow_repository.dart';
import '../../follow/presentation/follow_stats.dart';
import '../../posts/data/post_model.dart';
import '../../posts/data/post_repository.dart';
import '../../posts/presentation/post_card.dart';
import 'edit_profile_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key, required this.uid, required this.me});

  final String uid;
  final AppUser me;

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late final Stream<AppUser?> _user;
  late final Stream<String?> _relation;
  bool _busy = false;

  bool get _isSelf => widget.uid == widget.me.uid;

  @override
  void initState() {
    super.initState();
    _user = context.read<AuthRepository>().watchUser(widget.uid);
    _relation = _isSelf
        ? Stream<String?>.value(null)
        : context.read<FollowRepository>().watchRelation(
            widget.me.uid,
            widget.uid,
          );
  }

  Future<void> _run(Future<void> Function(FollowRepository repo) action) async {
    if (_busy) return;
    final repo = context.read<FollowRepository>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action(repo);
    } on FollowException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmUnfollow(AppUser target, String? status) async {
    final pending = status == 'pending';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(pending ? 'ยกเลิกคำขอติดตาม?' : 'เลิกติดตาม?'),
        content: Text(target.displayName),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ไม่'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run((repo) => repo.unfollow(widget.me.uid, target.uid));
  }

  Widget _followButton(AppUser target, String? status) {
    if (status == 'accepted') {
      return OutlinedButton.icon(
        icon: const Icon(Icons.check),
        label: const Text('กำลังติดตาม'),
        onPressed: _busy ? null : () => _confirmUnfollow(target, status),
      );
    }
    if (status == 'pending') {
      return OutlinedButton.icon(
        icon: const Icon(Icons.hourglass_top),
        label: const Text('ส่งคำขอแล้ว (ยกเลิก)'),
        onPressed: _busy ? null : () => _confirmUnfollow(target, status),
      );
    }
    return FilledButton.icon(
      icon: const Icon(Icons.person_add_alt),
      label: Text(target.isPrivate ? 'ขอติดตาม' : 'ติดตาม'),
      onPressed: _busy
          ? null
          : () => _run((repo) => repo.follow(widget.me, target)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<AppUser?>(
      stream: _user,
      builder: (context, userSnap) {
        if (userSnap.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('โหลดไม่สำเร็จ\n${userSnap.error}')),
          );
        }
        if (userSnap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final target = userSnap.data;
        if (target == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('ไม่พบผู้ใช้นี้ (อาจลบบัญชีไปแล้ว)'),
            ),
          );
        }

        return StreamBuilder<String?>(
          stream: _relation,
          builder: (context, relSnap) {
            final status = relSnap.data;
            final canView =
                _isSelf || !target.isPrivate || status == 'accepted';

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  target.displayName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundImage: target.photoUrl != null
                                ? NetworkImage(target.photoUrl!)
                                : null,
                            child: target.photoUrl == null
                                ? Text(
                                    target.displayName.isNotEmpty
                                        ? target.displayName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(fontSize: 32),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            target.displayName,
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 6),
                          Chip(
                            avatar: Icon(
                              target.isPrivate ? Icons.lock : Icons.public,
                              size: 16,
                            ),
                            label: Text(
                              target.isPrivate
                                  ? 'โปรไฟล์ส่วนตัว'
                                  : 'โปรไฟล์สาธารณะ',
                            ),
                          ),
                          if (target.bio.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(target.bio, textAlign: TextAlign.center),
                          ],
                          const SizedBox(height: 16),
                          FollowStats(
                            key: ValueKey('${target.uid}-$status'),
                            uid: target.uid,
                          ),
                          const SizedBox(height: 16),
                          if (_isSelf)
                            OutlinedButton.icon(
                              icon: const Icon(Icons.edit),
                              label: const Text('แก้ไขโปรไฟล์'),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditProfilePage(user: target),
                                ),
                              ),
                            )
                          else
                            Row(
                              children: [
                                Expanded(child: _followButton(target, status)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.chat_bubble_outline),
                                    label: const Text('ส่งข้อความ'),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatPage(
                                          me: widget.me,
                                          peer: ChatPeer(
                                            uid: target.uid,
                                            name: target.displayName,
                                            photoUrl: target.photoUrl,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (canView) ...[
                    Text(
                      'โพสต์',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _AuthorPosts(
                      key: ValueKey(target.uid),
                      uid: target.uid,
                      me: widget.me,
                    ),
                  ] else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(Icons.lock_outline, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              'บัญชีนี้เป็นส่วนตัว\nติดตามและรอการอนุมัติเพื่อดูโพสต์',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AuthorPosts extends StatefulWidget {
  const _AuthorPosts({super.key, required this.uid, required this.me});

  final String uid;
  final AppUser me;

  @override
  State<_AuthorPosts> createState() => _AuthorPostsState();
}

class _AuthorPostsState extends State<_AuthorPosts> {
  late final Future<List<Post>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<PostRepository>().fetchByAuthor(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Post>>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('โหลดโพสต์ไม่สำเร็จ\n${snap.error}'),
          );
        }
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final posts = snap.data!;
        if (posts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('ยังไม่มีโพสต์')),
          );
        }
        return Column(
          children: [
            for (final p in posts)
              PostCard(
                key: ValueKey(p.id),
                viewer: widget.me,
                post: p,
                isOwner: false, // แก้ไข/ลบจัดการที่ฟีดหลัก
              ),
          ],
        );
      },
    );
  }
}
