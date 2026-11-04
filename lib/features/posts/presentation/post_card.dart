import 'package:flutter/material.dart';

import '../../auth/data/app_user.dart';
import '../../reports/presentation/report_dialog.dart';
import '../data/post_model.dart';
import 'hashtag_text.dart';
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
    this.onTagTap,
  });

  final Post post;
  final bool isOwner;
  final AppUser? viewer;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAuthorTap;
  final void Function(String tag)? onTagTap;

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'เมื่อสักครู่';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชม.ที่แล้ว';
    if (diff.inDays < 7) return '${diff.inDays} วันที่แล้ว';
    return '${t.day}/${t.month}/${t.year}';
  }

  Widget _mediaOf(String url, String? type) {
    if (type == 'video') return PostVideo(url: url);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: Image.network(
        url,
        semanticLabel: 'รูปภาพในโพสต์',
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

  // กรอบสำเนาโพสต์ต้นฉบับที่ถูกแชร์
  Widget _sharedBlock(ThemeData theme) {
    final s = post.shared!;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundImage: s.authorPhotoUrl != null
                    ? NetworkImage(s.authorPhotoUrl!)
                    : null,
                child: s.authorPhotoUrl == null
                    ? Text(
                        s.authorName.isNotEmpty
                            ? s.authorName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 12),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.authorName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (s.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            HashtagText(
              text: s.text,
              style: theme.textTheme.bodyMedium,
              onTagTap: onTagTap,
            ),
          ],
          if (s.mediaUrl != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _mediaOf(s.mediaUrl!, s.mediaType),
            ),
          ],
        ],
      ),
    );
  }

  Widget _authorInfo(ThemeData theme, String subtitle, {bool compact = false}) {
    final avatar = CircleAvatar(
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
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          post.authorName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          post.shared != null ? '$subtitle · แชร์โพสต์' : subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onAuthorTap,
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [avatar, const SizedBox(height: 6), details],
            )
          : Row(
              children: [
                avatar,
                const SizedBox(width: 12),
                Expanded(child: details),
              ],
            ),
    );
  }

  Widget _postMenu(BuildContext context) {
    if (isOwner) {
      return PopupMenuButton<String>(
        tooltip: 'ตัวเลือกโพสต์',
        onSelected: (value) {
          if (value == 'edit') onEdit?.call();
          if (value == 'delete') onDelete?.call();
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
          PopupMenuItem(value: 'delete', child: Text('ลบ')),
        ],
      );
    }

    if (viewer != null) {
      return PopupMenuButton<String>(
        tooltip: 'ตัวเลือก',
        onSelected: (value) {
          if (value == 'report') {
            showReportDialog(context, post: post, reporter: viewer!);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'report', child: Text('รายงานโพสต์')),
        ],
      );
    }

    return const SizedBox.shrink();
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
            // ใช้ LayoutBuilder เพื่อจัดหัวโพสต์ใหม่เมื่อพื้นที่หน้าจอแคบ
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 260;
                final author = _authorInfo(theme, subtitle, compact: compact);
                final menu = _postMenu(context);

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      author,
                      Align(alignment: Alignment.centerRight, child: menu),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: author),
                    menu,
                  ],
                );
              },
            ),
            if (post.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              HashtagText(
                text: post.text,
                style: theme.textTheme.bodyLarge,
                onTagTap: onTagTap,
              ),
            ],
            if (post.shared != null) _sharedBlock(theme),
            if (post.mediaUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _mediaOf(post.mediaUrl!, post.mediaType),
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
