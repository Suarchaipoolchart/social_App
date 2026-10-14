import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../data/chat_models.dart';
import '../data/chat_repository.dart';
import 'chat_page.dart';

class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key, required this.me});

  final AppUser me;

  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  late Future<List<ChatPeer>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ChatRepository>().fetchUsers(widget.me.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เริ่มแชตใหม่')),
      body: FutureBuilder<List<ChatPeer>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('โหลดรายชื่อไม่สำเร็จ\n${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snap.data!;
          if (users.isEmpty) {
            return const Center(child: Text('ยังไม่มีผู้ใช้อื่นในระบบ'));
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, i) {
              final u = users[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: u.photoUrl != null
                      ? NetworkImage(u.photoUrl!)
                      : null,
                  child: u.photoUrl == null
                      ? Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?')
                      : null,
                ),
                title: Text(u.name),
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(me: widget.me, peer: u),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
