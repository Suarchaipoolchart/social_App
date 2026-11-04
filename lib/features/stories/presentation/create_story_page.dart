import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/services/cloudinary_service.dart';
import '../../auth/data/app_user.dart';
import '../data/story_repository.dart';

class CreateStoryPage extends StatefulWidget {
  const CreateStoryPage({super.key, required this.me});

  final AppUser me;

  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends State<CreateStoryPage> {
  static const _maxImageBytes = 10 * 1024 * 1024;
  static const _maxVideoBytes = 50 * 1024 * 1024;

  final _picker = ImagePicker();
  final _caption = TextEditingController();

  XFile? _media;
  Uint8List? _imageBytes;
  bool _isVideo = false;
  bool _posting = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pick({
    required bool video,
    ImageSource source = ImageSource.gallery,
  }) async {
    final file = video
        ? await _picker.pickVideo(
            source: source,
            maxDuration: const Duration(seconds: 30),
          )
        : await _picker.pickImage(
            source: source,
            imageQuality: 85,
            maxWidth: 1600,
          );

    if (file == null || !mounted) return;

    final size = await file.length();
    if (!mounted) return;

    final limit = video ? _maxVideoBytes : _maxImageBytes;

    if (size > limit) {
      _snack('ไฟล์ใหญ่เกินไป (สูงสุด ${limit ~/ (1024 * 1024)} MB)');
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

  Future<void> _post() async {
    final file = _media;

    if (file == null) {
      _snack('เลือกรูปหรือวิดีโอก่อนโพสต์สตอรี่');
      return;
    }

    final cloud = context.read<CloudinaryService>();
    final repo = context.read<StoryRepository>();
    final navigator = Navigator.of(context);

    setState(() => _posting = true);

    try {
      final url = await cloud.upload(file, isVideo: _isVideo);

      if (!mounted) return;

      await repo.createStory(
        widget.me,
        mediaUrl: url,
        mediaType: _isVideo ? 'video' : 'image',
        caption: _caption.text.trim(),
      );

      if (!mounted) return;
      navigator.pop(true);
    } on UploadException catch (e) {
      _snack(e.message);
    } on StoryException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) {
        setState(() => _posting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('สร้างสตอรี่')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 9 / 14,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: _media == null
                  ? const Text(
                      'เลือกรูปหรือวิดีโอ (สูงสุด 30 วินาที)',
                      style: TextStyle(color: Colors.white70),
                    )
                  : _isVideo
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam, color: Colors.white, size: 56),
                        SizedBox(height: 8),
                        Text(
                          'เลือกวิดีโอแล้ว',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    )
                  : Image.memory(
                      _imageBytes!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                  OutlinedButton.icon(
                    onPressed: _posting ? null : () => _pick(video: false),
                    icon: const Icon(Icons.photo_outlined),
                    label: const Text('รูปภาพ'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _posting ? null : () => _pick(video: true),
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('วิดีโอ'),
                  ),
                  if (!kIsWeb)
                    OutlinedButton.icon(
                      onPressed: _posting
                          ? null
                          : () =>
                                _pick(video: false, source: ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('ถ่ายรูป'),
                    ),
                ].map((button) {
                  return SizedBox(height: 44, child: button);
                }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _caption,
            maxLength: 120,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'ข้อความบนสตอรี่ (ไม่บังคับ)',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _posting ? null : _post,
            child: _posting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('แชร์สตอรี่'),
          ),
          const SizedBox(height: 8),
          Text(
            'สตอรี่จะหายไปเองใน 24 ชั่วโมง',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
