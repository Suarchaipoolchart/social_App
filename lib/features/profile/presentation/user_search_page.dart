import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../data/user_repository.dart';
import 'user_profile_page.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key, required this.me});

  final AppUser me;

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<AppUser> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(text));
  }

  Future<void> _search(String text) async {
    final repo = context.read<UserRepository>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await repo.searchUsers(text);

      if (!mounted || text != _controller.text) {
        return; // ผลเก่าที่ถูกแทนที่แล้ว
      }

      setState(
        () => _results = list.where((u) => u.uid != widget.me.uid).toList(),
      );
    } on UserException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: _search,
          decoration: const InputDecoration(
            hintText: 'ค้นหาผู้ใช้ด้วยชื่อ...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
        ),
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _error != null
                ? Center(child: Text(_error!))
                : _results.isEmpty && !_loading
                ? const Center(child: Text('ไม่พบผู้ใช้'))
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, i) {
                      final u = _results[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: u.photoUrl != null
                              ? NetworkImage(u.photoUrl!)
                              : null,
                          child: u.photoUrl == null
                              ? Text(
                                  u.displayName.isNotEmpty
                                      ? u.displayName[0].toUpperCase()
                                      : '?',
                                )
                              : null,
                        ),
                        title: Text(u.displayName),
                        subtitle: u.isPrivate
                            ? const Text('โปรไฟล์ส่วนตัว')
                            : null,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                UserProfilePage(uid: u.uid, me: widget.me),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
