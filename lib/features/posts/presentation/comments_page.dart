import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../data/comment_model.dart';
import '../data/post_model.dart';
import '../data/post_repository.dart';

class CommentsPage extends StatefulWidget {
  const CommentsPage({super.key, required this.post, required this.viewer});

  final Post post;
  final AppUser viewer;

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final _text = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;
    final repo = context.read<PostRepository>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _sending = true);
    try {
      await repo.addComment(
        widget.post.id,
        widget.viewer,
        text,
        groupId: widget.post.groupId,
      );
      _text.clear();
    } on PostException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(Comment c) async {
    final repo = context.read<PostRepository>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repo.deleteComment(
        widget.post.id,
        c.id,
        groupId: widget.post.groupId,
      );
    } on PostException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<PostRepository>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('ความคิดเห็น')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: repo.watchComments(
                widget.post.id,
                groupId: widget.post.groupId,
              ),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text('โหลดคอมเมนต์ไม่สำเร็จ\n${snap.error}'),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data!;
                if (list.isEmpty) {
                  return const Center(child: Text('ยังไม่มีความคิดเห็น'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final c = list[i];
                    final mine = c.authorId == widget.viewer.uid;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: c.authorPhotoUrl != null
                                ? NetworkImage(c.authorPhotoUrl!)
                                : null,
                            child: c.authorPhotoUrl == null
                                ? Text(
                                    c.authorName.isNotEmpty
                                        ? c.authorName[0].toUpperCase()
                                        : '?',
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.authorName,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(c.text),
                                ],
                              ),
                            ),
                          ),
                          if (mine)
                            IconButton(
                              tooltip: 'ลบความคิดเห็น',
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => _delete(c),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      maxLength: 500,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'เขียนความคิดเห็น...',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'ส่ง',
                    icon: const Icon(Icons.send),
                    onPressed: _sending ? null : _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
