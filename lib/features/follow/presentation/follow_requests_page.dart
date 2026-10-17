import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../data/follow_models.dart';
import '../data/follow_repository.dart';

class FollowRequestsPage extends StatefulWidget {
  const FollowRequestsPage({super.key, required this.me});

  final AppUser me;

  @override
  State<FollowRequestsPage> createState() => _FollowRequestsPageState();
}

class _FollowRequestsPageState extends State<FollowRequestsPage> {
  late final Stream<List<FollowRequest>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = context.read<FollowRepository>().watchRequests(widget.me.uid);
  }

  Future<void> _act(Future<void> Function(FollowRepository repo) action) async {
    final repo = context.read<FollowRepository>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action(repo);
    } on FollowException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('คำขอติดตาม')),
      body: StreamBuilder<List<FollowRequest>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('โหลดไม่สำเร็จ\n${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!;
          if (list.isEmpty) {
            return const Center(child: Text('ไม่มีคำขอติดตามที่รออยู่'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final r = list[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: r.followerPhotoUrl != null
                      ? NetworkImage(r.followerPhotoUrl!)
                      : null,
                  child: r.followerPhotoUrl == null
                      ? Text(
                          r.followerName.isNotEmpty
                              ? r.followerName[0].toUpperCase()
                              : '?',
                        )
                      : null,
                ),
                title: Text(r.followerName),
                subtitle: const Text('ขอติดตามคุณ'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'อนุมัติ',
                      icon: const Icon(Icons.check_circle_outline),
                      onPressed: () => _act(
                        (repo) => repo.approve(r.followerId, widget.me.uid),
                      ),
                    ),
                    IconButton(
                      tooltip: 'ปฏิเสธ',
                      icon: const Icon(Icons.cancel_outlined),
                      onPressed: () => _act(
                        (repo) => repo.reject(r.followerId, widget.me.uid),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
