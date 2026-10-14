import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../data/chat_models.dart';
import '../data/chat_repository.dart';
import 'chat_page.dart';
import 'new_chat_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key, required this.me});

  final AppUser me;

  String _time(DateTime? t) {
    if (t == null) return '';
    final now = DateTime.now();
    if (t.year == now.year && t.month == now.month && t.day == now.day) {
      return '${t.hour.toString().padLeft(2, '0')}:'
          '${t.minute.toString().padLeft(2, '0')}';
    }
    return '${t.day}/${t.month}';
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ChatRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('แชต')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.chat),
        label: const Text('แชตใหม่'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NewChatPage(me: me)),
        ),
      ),
      body: StreamBuilder<List<ChatSummary>>(
        stream: repo.watchChats(me.uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text(
                'โหลดแชตไม่สำเร็จ\n${snap.error}',
                textAlign: TextAlign.center,
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snap.data!;
          if (chats.isEmpty) {
            return const Center(
              child: Text('ยังไม่มีแชต กด "แชตใหม่" เพื่อเริ่ม'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: chats.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = chats[i];
              final mineLast = c.lastSenderId == me.uid;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: c.peer.photoUrl != null
                      ? NetworkImage(c.peer.photoUrl!)
                      : null,
                  child: c.peer.photoUrl == null
                      ? Text(
                          c.peer.name.isNotEmpty
                              ? c.peer.name[0].toUpperCase()
                              : '?',
                        )
                      : null,
                ),
                title: Text(c.peer.name),
                subtitle: Text(
                  '${mineLast ? 'คุณ: ' : ''}${c.lastMessage}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(_time(c.lastMessageAt)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(me: me, peer: c.peer),
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
