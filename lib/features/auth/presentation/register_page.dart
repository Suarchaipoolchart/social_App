import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_controller.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ctrl = context.read<AuthController>();
    final ok = await ctrl.register(
      _name.text.trim(),
      _email.text.trim(),
      _password.text,
    );
    if (!mounted) return;
    if (ok) {
      // ปิดหน้าสมัคร กลับไปที่ AuthGate ซึ่งจะแสดงหน้าหลักให้
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ctrl.error ?? 'สมัครไม่สำเร็จ')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthController>().loading;
    return Scaffold(
      appBar: AppBar(title: const Text('สมัครสมาชิก')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'อีเมล'),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'กรอกอีเมลให้ถูกต้อง'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'รหัสผ่าน'),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'อย่างน้อย 6 ตัวอักษร'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'ยืนยันรหัสผ่าน',
                  ),
                  validator: (v) =>
                      v != _password.text ? 'รหัสผ่านไม่ตรงกัน' : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: loading ? null : _submit,
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('สมัครสมาชิก'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
