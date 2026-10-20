import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../../posts/presentation/tag_posts_page.dart';
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

  /// แท็กที่พิมพ์ (ตัวพิมพ์เล็ก ไม่มี #) หรือ null ถ้าไม่ได้พิมพ์ #
  String? get _tagQuery {
    final raw = _controller.text.trim();
    if (!raw.startsWith('#') || raw.length < 2) return null;
    return raw.substring(1).toLowerCase();
  }

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
    setState(() {}); // อัปเดตทางลัดแท็กทันที
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(text));
  }

  Future<void> _search(String text) async {
    if (text.trim().startsWith('#')) {
      if (mounted) {
        setState(() => _error = null);
      }
      return; // โหมดแท็ก ไม่ต้องค้นหาผู้ใช้
    }
    final repo = context.read<UserRepository>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await repo.searchUsers(text);
      // ผลเก่าที่ถูกแทนที่แล้ว ไม่ต้องแสดง
      if (!mounted || text != _controller.text) {
        return;
      }
      setState(
        () => _results = list.where((u) => u.uid != widget.me.uid).toList(),
      );
    } on UserException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _body() {
    final tag = _tagQuery;
    if (tag != null) {
      return ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.tag)),
            title: Text('ดูโพสต์ในแท็ก #$tag'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TagPostsPage(tag: tag, me: widget.me),
              ),
            ),
          ),
        ],
      );
    }

    if (_error != null) return Center(child: Text(_error!));
    if (_results.isEmpty && !_loading) {
      return const Center(child: Text('ไม่พบผู้ใช้'));
    }

    return ListView.builder(
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
          subtitle: u.isPrivate ? const Text('โปรไฟล์ส่วนตัว') : null,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserProfilePage(uid: u.uid, me: widget.me),
            ),
          ),
        );
      },
    );
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
            hintText: 'ค้นหาชื่อผู้ใช้ หรือพิมพ์ #แท็ก',
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
          Expanded(child: _body()),
        ],
      ),
    );
  }
}
