import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/services/cloudinary_service.dart';
import '../../auth/data/app_user.dart';
import '../../posts/presentation/post_video.dart';
import '../data/chat_models.dart';
import '../data/chat_repository.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.me, required this.peer});

  final AppUser me;
  final ChatPeer peer;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  static const _maxImageBytes = 10 * 1024 * 1024;
  static const _maxVideoBytes = 50 * 1024 * 1024;

  final _text = TextEditingController();
  final _picker = ImagePicker();
  bool _sending = false;

  late final String _chatId = ChatRepository.chatIdFor(
    widget.me.uid,
    widget.peer.uid,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _sendText() async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;
    final repo = context.read<ChatRepository>();

    setState(() => _sending = true);
    try {
      await repo.sendMessage(me: widget.me, peer: widget.peer, text: text);
      _text.clear();
    } on ChatException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendMedia({required bool video}) async {
    if (_sending) return;
    final repo = context.read<ChatRepository>();
    final cloud = context.read<CloudinaryService>();

    final file = video
        ? await _picker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(seconds: 60),
          )
        : await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
            maxWidth: 1600,
          );
    if (file == null) return;

    final size = await file.length();
    final limit = video ? _maxVideoBytes : _maxImageBytes;
    if (size > limit) {
      if (mounted) {
        _snack('ไฟล์ใหญ่เกินไป (สูงสุด ${limit ~/ (1024 * 1024)} MB)');
      }
      return;
    }

    setState(() => _sending = true);
    try {
      final url = await cloud.upload(file, isVideo: video);
      await repo.sendMessage(
        me: widget.me,
        peer: widget.peer,
        mediaUrl: url,
        mediaType: video ? 'video' : 'image',
      );
    } on UploadException catch (e) {
      if (mounted) _snack(e.message);
    } on ChatException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ChatRepository>();
    final peer = widget.peer;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: peer.photoUrl != null
                  ? NetworkImage(peer.photoUrl!)
                  : null,
              child: peer.photoUrl == null
                  ? Text(
                      peer.name.isNotEmpty ? peer.name[0].toUpperCase() : '?',
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Flexible(child: Text(peer.name, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: repo.watchMessages(_chatId),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'โหลดข้อความไม่สำเร็จ\n${snap.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data!;
                if (list.isEmpty) {
                  return const Center(
                    child: Text('ยังไม่มีข้อความ ทักทายกันเลย'),
                  );
                }
                return ListView.builder(
                  reverse: true, // ข้อความใหม่สุดอยู่ล่าง
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, i) => _Bubble(
                    message: list[i],
                    mine: list[i].senderId == widget.me.uid,
                  ),
                );
              },
            ),
          ),
          if (_sending) const LinearProgressIndicator(minHeight: 2),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'ส่งรูปภาพ',
                    icon: const Icon(Icons.image),
                    onPressed: _sending ? null : () => _sendMedia(video: false),
                  ),
                  IconButton(
                    tooltip: 'ส่งวิดีโอ',
                    icon: const Icon(Icons.videocam),
                    onPressed: _sending ? null : () => _sendMedia(video: true),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      maxLength: 2000,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendText(),
                      decoration: const InputDecoration(
                        hintText: 'พิมพ์ข้อความ...',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    tooltip: 'ส่ง',
                    icon: const Icon(Icons.send),
                    onPressed: _sending ? null : _sendText,
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final Message message;
  final bool mine;

  String _time(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = mine ? scheme.primary : scheme.surface;
    final fg = mine ? scheme.onPrimary : scheme.onSurface;

    final media = message.mediaUrl;
    Widget? mediaWidget;
    if (media != null) {
      mediaWidget = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: message.mediaType == 'video'
            ? PostVideo(url: media)
            : ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: Image.network(
                  media,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : const SizedBox(
                          height: 120,
                          width: 160,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                  errorBuilder: (context, error, stack) => const SizedBox(
                    height: 80,
                    width: 120,
                    child: Center(child: Icon(Icons.broken_image)),
                  ),
                ),
              ),
      );
    }

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            ?mediaWidget,
            if (message.text.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: mediaWidget != null ? 8 : 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(message.text, style: TextStyle(color: fg)),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              _time(message.createdAt),
              style: TextStyle(color: fg.withValues(alpha: 0.7), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
