import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ctrl = context.read<AuthController>();
    final ok = await ctrl.updateProfile(
      widget.user.uid,
      displayName: _name.text.trim(),
      bio: _bio.text.trim(),
      isPrivate: _isPrivate,
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
                onPressed: loading ? null : _save,
                child: const Text('บันทึก'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
