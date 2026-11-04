import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/services/cloudinary_service.dart';
import '../../auth/data/app_user.dart';
import '../data/group_models.dart';
import '../data/group_repository.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key, required this.me, this.editing});

  final AppUser me;
  final Group? editing; // ถ้ามีค่า = โหมดแก้ไข

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late String _type;
  bool _saving = false;
  final _picker = ImagePicker();
  XFile? _photo;
  Uint8List? _photoBytes;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.editing?.name ?? '');
    _desc = TextEditingController(text: widget.editing?.description ?? '');
    _type = widget.editing?.type ?? 'group';
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _photo = file;
      _photoBytes = bytes;
    });
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ตั้งชื่อก่อนบันทึก')));
      return;
    }
    final repo = context.read<GroupRepository>();
    final cloud = context.read<CloudinaryService>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _saving = true);
    try {
      String? photoUrl;
      if (_photo != null) {
        photoUrl = await cloud.upload(_photo!, isVideo: false);
      }
      if (_isEdit) {
        await repo.updateGroup(
          widget.editing!.id,
          name: name,
          description: _desc.text.trim(),
          photoUrl: photoUrl,
        );
      } else {
        await repo.createGroup(
          widget.me,
          name: name,
          description: _desc.text.trim(),
          type: _type,
          photoUrl: photoUrl,
        );
      }
      navigator.pop();
    } on GroupException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on UploadException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _type == 'page' ? 'เพจ' : 'กลุ่ม';
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'แก้ไข$label' : 'สร้างกลุ่มหรือเพจ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: _photoBytes != null
                        ? MemoryImage(_photoBytes!)
                        : (widget.editing?.photoUrl != null
                              ? NetworkImage(widget.editing!.photoUrl!)
                                    as ImageProvider
                              : null),
                    child:
                        (_photoBytes == null &&
                            widget.editing?.photoUrl == null)
                        ? Icon(
                            _type == 'page' ? Icons.flag : Icons.groups,
                            size: 40,
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 16,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        tooltip: 'เลือกรูปโปรไฟล์',
                        icon: const Icon(Icons.camera_alt),
                        onPressed: _saving ? null : _pickPhoto,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'group',
                  icon: Icon(Icons.groups),
                  label: Text('กลุ่ม'),
                ),
                ButtonSegment(
                  value: 'page',
                  icon: Icon(Icons.flag),
                  label: Text('เพจ'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: _isEdit
                  ? null // เปลี่ยนชนิดตอนแก้ไขไม่ได้
                  : (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              maxLength: 60,
              decoration: InputDecoration(labelText: 'ชื่อ$label'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _desc,
              maxLength: 500,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'คำอธิบาย'),
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
                  : Text(_isEdit ? 'บันทึก' : 'สร้าง$label'),
            ),
          ],
        ),
      ),
    );
  }
}
