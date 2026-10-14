import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ตั้งชื่อก่อนบันทึก')));
      return;
    }
    final repo = context.read<GroupRepository>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await repo.updateGroup(
          widget.editing!.id,
          name: name,
          description: _desc.text.trim(),
        );
      } else {
        await repo.createGroup(
          widget.me,
          name: name,
          description: _desc.text.trim(),
          type: _type,
        );
      }
      navigator.pop();
    } on GroupException catch (e) {
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
