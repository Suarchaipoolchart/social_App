import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../../follow/presentation/follow_requests_page.dart';
import '../../posts/presentation/post_detail_page.dart';
import '../../posts/presentation/reaction_bar.dart';
import '../../profile/presentation/user_profile_page.dart';
import '../data/notification_models.dart';
import '../data/notification_repository.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.me});

  final AppUser me;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final Stream<List<AppNotification>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = context.read<NotificationRepository>().watchMine(widget.me.uid);
  }

  String _message(AppNotification n) {
    switch (n.type) {
      case 'follow':
        return '${n.actorName} เริ่มติดตามคุณ';
      case 'follow_request':
        return '${n.actorName} ขอติดตามคุณ';
      case 'follow_accepted':
        return '${n.actorName} อนุมัติคำขอติดตามของคุณ';
      case 'reaction':
        return '${n.actorName} แสดงความรู้สึก ${kReactionEmoji[n.extra] ?? ''} '
            'ต่อโพสต์ของคุณ';
      case 'comment':
        return '${n.actorName} แสดงความคิดเห็นในโพสต์ของคุณ';
      case 'share':
        return '${n.actorName} แชร์โพสต์ของคุณ';
      case 'post':
        return '${n.actorName} โพสต์ใหม่';
      case 'group_post':
        return '${n.actorName} โพสต์ใน ${n.groupName ?? 'กลุ่ม'}';
      default:
        return '${n.actorName} มีกิจกรรมใหม่';
    }
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'เมื่อสักครู่';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชม.ที่แล้ว';
    if (diff.inDays < 7) return '${diff.inDays} วันที่แล้ว';
    return '${t.day}/${t.month}/${t.year}';
  }

  Future<void> _open(AppNotification n) async {
    final repo = context.read<NotificationRepository>();
    if (!n.read) {
      repo.markRead(widget.me.uid, n.id);
    }

    Widget? page;
    if (n.type == 'follow_request') {
      page = FollowRequestsPage(me: widget.me);
    } else if (n.type.startsWith('follow')) {
      page = UserProfilePage(uid: n.actorId, me: widget.me);
    } else if (n.postId != null) {
      page = PostDetailPage(
        postId: n.postId!,
        groupId: n.groupId,
        me: widget.me,
      );
    }

    final target = page;
    if (target != null && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => target));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.read<NotificationRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('การแจ้งเตือน'),
        actions: [
          IconButton(
            tooltip: 'อ่านทั้งหมด',
            icon: const Icon(Icons.done_all),
            onPressed: () => repo.markAllRead(widget.me.uid),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'โหลดไม่สำเร็จ\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!;
          if (list.isEmpty) {
            return const Center(child: Text('ยังไม่มีการแจ้งเตือน'));
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final n = list[i];
              return ListTile(
                tileColor: n.read
                    ? null
                    : theme.colorScheme.primary.withValues(alpha: 0.08),
                leading: CircleAvatar(
                  backgroundImage: n.actorPhotoUrl != null
                      ? NetworkImage(n.actorPhotoUrl!)
                      : null,
                  child: n.actorPhotoUrl == null
                      ? Text(
                          n.actorName.isNotEmpty
                              ? n.actorName[0].toUpperCase()
                              : '?',
                        )
                      : null,
                ),
                title: Text(
                  _message(n),
                  style: TextStyle(
                    fontWeight: n.read ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  n.snippet.isEmpty
                      ? _timeAgo(n.createdAt)
                      : '${n.snippet}\n${_timeAgo(n.createdAt)}',
                ),
                isThreeLine: n.snippet.isNotEmpty,
                trailing: n.read
                    ? null
                    : Icon(
                        Icons.circle,
                        size: 10,
                        color: theme.colorScheme.primary,
                      ),
                onTap: () => _open(n),
              );
            },
          );
        },
      ),
    );
  }
}
