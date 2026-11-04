import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../data/notification_repository.dart';
import 'notifications_page.dart';

/// ไอคอนกระดิ่งพร้อมเลขแจ้งเตือนที่ยังไม่ได้อ่าน
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key, required this.me});

  final AppUser me;

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  late final Stream<int> _unread;

  @override
  void initState() {
    super.initState();
    _unread = context.read<NotificationRepository>().watchUnreadCount(
      widget.me.uid,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _unread,
      builder: (context, snap) {
        final n = snap.data ?? 0;
        return IconButton(
          tooltip: 'การแจ้งเตือน',
          icon: Badge(
            isLabelVisible: n > 0,
            label: Text(n >= 99 ? '99+' : '$n'),
            child: const Icon(Icons.notifications_outlined),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NotificationsPage(me: widget.me)),
          ),
        );
      },
    );
  }
}
