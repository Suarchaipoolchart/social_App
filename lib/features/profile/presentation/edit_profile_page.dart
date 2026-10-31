import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/services/cloudinary_service.dart';
import '../../auth/data/app_user.dart';
import '../../auth/presentation/auth_controller.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.user});

  final AppUser user;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late bool _isPrivate;
  final _picker = ImagePicker();
  XFile? _newPhoto;
  Uint8List? _newPhotoBytes;
  XFile? _newCover;
  Uint8List? _newCoverBytes;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.displayName);
    _bio = TextEditingController(text: widget.user.bio);
    _isPrivate = widget.user.isPrivate;
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
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
      _newPhoto = file;
      _newPhotoBytes = bytes;
    });
  }

  Future<void> _pickCover() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _newCover = file;
      _newCoverBytes = bytes;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ctrl = context.read<AuthController>();
    final cloud = context.read<CloudinaryService>();

    String? photoUrl;
    String? coverUrl;
    if (_newPhoto != null || _newCover != null) {
      setState(() => _uploading = true);
      try {
        if (_newPhoto != null) {
          photoUrl = await cloud.upload(_newPhoto!, isVideo: false);
        }
        if (_newCover != null) {
          coverUrl = await cloud.upload(_newCover!, isVideo: false);
        }
      } on UploadException catch (e) {
        if (mounted) {
          setState(() => _uploading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.message)));
        }
        return;
      }
      if (!mounted) return;
      setState(() => _uploading = false);
    }

    final ok = await ctrl.updateProfile(
      widget.user.uid,
      displayName: _name.text.trim(),
      bio: _bio.text.trim(),
      isPrivate: _isPrivate,
      photoUrl: photoUrl,
      coverUrl: coverUrl,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ctrl.error ?? 'บันทึกไม่สำเร็จ')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthController>().loading;
    return Scaffold(
      appBar: AppBar(title: const Text('แก้ไขโปรไฟล์')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // รูปปก
              GestureDetector(
                onTap: _uploading ? null : _pickCover,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    image: _newCoverBytes != null
                        ? DecorationImage(
                            image: MemoryImage(_newCoverBytes!),
                            fit: BoxFit.cover,
                          )
                        : (widget.user.coverUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(widget.user.coverUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null),
                  ),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: IconButton.filled(
                        tooltip: 'เปลี่ยนรูปปก',
                        icon: const Icon(Icons.photo_camera),
                        onPressed: _uploading ? null : _pickCover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundImage: _newPhotoBytes != null
                          ? MemoryImage(_newPhotoBytes!)
                          : (widget.user.photoUrl != null
                                ? NetworkImage(widget.user.photoUrl!)
                                      as ImageProvider
                                : null),
                      child:
                          (_newPhotoBytes == null &&
                              widget.user.photoUrl == null)
                          ? Text(
                              widget.user.displayName.isNotEmpty
                                  ? widget.user.displayName[0].toUpperCase()
                                  : '?',
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: IconButton.filled(
                        tooltip: 'เปลี่ยนรูปโปรไฟล์',
                        icon: const Icon(Icons.photo_camera),
                        onPressed: _uploading ? null : _pickPhoto,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'ชื่อที่แสดง'),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'ชื่ออย่างน้อย 2 ตัวอักษร'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bio,
                maxLines: 3,
                maxLength: 150,
                decoration: const InputDecoration(labelText: 'แนะนำตัว'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('โปรไฟล์ส่วนตัว'),
                subtitle: const Text(
                  'เฉพาะผู้ติดตามที่อนุมัติเท่านั้นที่เห็นโพสต์',
                ),
                value: _isPrivate,
                onChanged: (v) => setState(() => _isPrivate = v),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: (loading || _uploading) ? null : _save,
                child: (loading || _uploading)
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('บันทึก'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
