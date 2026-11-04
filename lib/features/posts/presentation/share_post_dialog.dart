import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../data/post_model.dart';
import '../data/post_repository.dart';

/// เปิดกล่องแชร์โพสต์ไปยังฟีดของตัวเอง คืนค่า true ถ้าแชร์สำเร็จ
Future<bool> showSharePostDialog(
  BuildContext context, {
  required Post post,
  required AppUser sharer,
}) async {
  final repo = context.read<PostRepository>();
  final messenger = ScaffoldMessenger.of(context);

  final caption = await showDialog<String>(
    context: context,
    builder: (_) => _ShareDialog(post: post),
  );
  if (caption == null) return false;

  try {
    await repo.sharePost(sharer, post, caption);
    messenger.showSnackBar(
      const SnackBar(content: Text('แชร์โพสต์ไปยังฟีดของคุณแล้ว')),
    );
    return true;
  } on PostException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
    return false;
  }
}

class _ShareDialog extends StatefulWidget {
  const _ShareDialog({required this.post});

  final Post post;

  @override
  State<_ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<_ShareDialog> {
  final _caption = TextEditingController();

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final source = widget.post.shared;
    final authorName = source?.authorName ?? widget.post.authorName;
    final text = source?.text ?? widget.post.text;

    return AlertDialog(
      title: const Text('แชร์โพสต์'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _caption,
              maxLength: 300,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'เขียนอะไรบางอย่าง (ไม่บังคับ)',
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.35,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authorName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _caption.text.trim()),
          child: const Text('แชร์'),
        ),
      ],
    );
  }
}
