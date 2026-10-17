import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/services/cloudinary_service.dart';
import '../../auth/data/app_user.dart';
import '../data/post_model.dart';
import '../data/post_repository.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({
    super.key,
    required this.user,
    this.editing,
    this.groupId,
  });

  final AppUser user;
  final Post? editing; // ถ้ามีค่า = โหมดแก้ไข
  final String? groupId; // ถ้ามีค่า = โพสต์ในกลุ่ม/เพจ

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  static const _maxImageBytes = 10 * 1024 * 1024;
  static const _maxVideoBytes = 50 * 1024 * 1024;

  late final TextEditingController _text;
  final _picker = ImagePicker();

  XFile? _media;
  Uint8List? _imageBytes; // ใช้พรีวิวรูป
  bool _isVideo = false;
  bool _saving = false;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.editing?.text ?? '');
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickMedia({required bool video}) async {
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

    final bytes = video ? null : await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _media = file;
      _isVideo = video;
      _imageBytes = bytes;
    });
  }

  void _clearMedia() {
    setState(() {
      _media = null;
      _imageBytes = null;
      _isVideo = false;
    });
  }

  Future<void> _submit() async {
    final text = _text.text.trim();
    if (text.isEmpty && _media == null) {
      _snack('พิมพ์ข้อความหรือแนบรูป/วิดีโอก่อนโพสต์');
      return;
    }

    final repo = context.read<PostRepository>();
    final cloud = context.read<CloudinaryService>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final groupId = widget.editing?.groupId ?? widget.groupId;

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await repo.updatePost(widget.editing!.id, text, groupId: groupId);
      } else {
        String? url;
        String? type;
        if (_media != null) {
          url = await cloud.upload(_media!, isVideo: _isVideo);
          type = _isVideo ? 'video' : 'image';
        }
        await repo.createPost(
          widget.user,
          text,
          mediaUrl: url,
          mediaType: type,
          groupId: groupId,
        );
      }
      navigator.pop();
    } on UploadException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on PostException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _preview() {
    if (_media == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _isVideo
                ? Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.black87,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.videocam, color: Colors.white),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _media!.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: Image.memory(
                      _imageBytes!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton.filled(
              icon: const Icon(Icons.close),
              onPressed: _saving ? null : _clearMedia,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'แก้ไขโพสต์' : 'สร้างโพสต์')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _text,
              minLines: 4,
              maxLines: 10,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText: 'คุณกำลังคิดอะไรอยู่?',
              ),
            ),
            const SizedBox(height: 8),
            _preview(),
            if (!_isEdit)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('รูปภาพ'),
                      onPressed: _saving
                          ? null
                          : () => _pickMedia(video: false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.videocam),
                      label: const Text('วิดีโอสั้น'),
                      onPressed: _saving ? null : () => _pickMedia(video: true),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEdit ? 'บันทึก' : 'โพสต์'),
            ),
          ],
        ),
      ),
    );
  }
}
