import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/follow_repository.dart';

/// แสดงจำนวนผู้ติดตาม / กำลังติดตาม
/// ถ้าต้องการให้ตัวเลขโหลดใหม่ ให้ใส่ key ที่เปลี่ยนค่า เช่น ValueKey(status)
class FollowStats extends StatefulWidget {
  const FollowStats({super.key, required this.uid});

  final String uid;

  @override
  State<FollowStats> createState() => _FollowStatsState();
}

class _FollowStatsState extends State<FollowStats> {
  late final Future<List<int>> _future;

  @override
  void initState() {
    super.initState();
    final repo = context.read<FollowRepository>();
    _future = Future.wait([
      repo.countFollowers(widget.uid),
      repo.countFollowing(widget.uid),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: _future,
      builder: (context, snap) {
        final followers = snap.hasData ? '${snap.data![0]}' : '-';
        final following = snap.hasData ? '${snap.data![1]}' : '-';
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Stat(label: 'ผู้ติดตาม', value: followers),
            const SizedBox(width: 32),
            _Stat(label: 'กำลังติดตาม', value: following),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
