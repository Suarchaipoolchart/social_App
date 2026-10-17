import 'package:flutter/material.dart';

import '../../auth/data/app_user.dart';
import '../data/post_model.dart';
import 'post_video.dart';
import 'reaction_bar.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.isOwner,
    this.viewer,
    this.onEdit,
    this.onDelete,
    this.onAuthorTap,
  });

  final Post post;
  final bool isOwner;
  final AppUser? viewer;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAuthorTap; // แตะรูป/ชื่อผู้เขียนเพื่อเปิดโปรไฟล์

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'เมื่อสักครู่';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชม.ที่แล้ว';
    if (diff.inDays < 7) return '${diff.inDays} วันที่แล้ว';
    return '${t.day}/${t.month}/${t.year}';
  }

  Widget _media() {
    final url = post.mediaUrl!;
    if (post.mediaType == 'video') return PostVideo(url: url);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: Image.network(
        url,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
        errorBuilder: (context, error, stack) => const SizedBox(
          height: 120,
          child: Center(child: Icon(Icons.broken_image)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle =
        '${_timeAgo(post.createdAt)}${post.edited ? ' · แก้ไขแล้ว' : ''}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onAuthorTap,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: post.authorPhotoUrl != null
                              ? NetworkImage(post.authorPhotoUrl!)
                              : null,
                          child: post.authorPhotoUrl == null
                              ? Text(
                                  post.authorName.isNotEmpty
                                      ? post.authorName[0].toUpperCase()
                                      : '?',
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.authorName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                subtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isOwner)
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') onEdit?.call();
                      if (v == 'delete') onDelete?.call();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
                      PopupMenuItem(value: 'delete', child: Text('ลบ')),
                    ],
                  ),
              ],
            ),
            if (post.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(post.text, style: theme.textTheme.bodyLarge),
            ],
            if (post.mediaUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _media(),
              ),
            ],
            if (viewer != null) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              ReactionBar(post: post, viewer: viewer!),
            ],
          ],
        ),
      ),
    );
  }
}
