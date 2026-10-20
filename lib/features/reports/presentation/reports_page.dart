import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../../posts/data/post_repository.dart';
import '../data/report_models.dart';
import '../data/report_repository.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key, required this.me});

  final AppUser me;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late final Stream<List<Report>> _stream;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _stream = context.read<ReportRepository>().watchOpen();
  }

  Future<void> _dismiss(Report r) async {
    if (_busy) return;
    final repo = context.read<ReportRepository>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await repo.resolve([r.id], widget.me.uid, 'dismissed');
    } on ReportException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deletePost(Report r, List<Report> all) async {
    if (_busy) return;
    final posts = context.read<PostRepository>();
    final reports = context.read<ReportRepository>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบโพสต์ที่ถูกรายงาน?'),
        content: Text('โพสต์ของ ${r.postAuthorName} จะถูกลบถาวร'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบโพสต์'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await posts.deletePost(r.postId, groupId: r.groupId);
      // ปิดรายงานทุกใบของโพสต์เดียวกัน
      final sameIds = all
          .where((x) => x.postId == r.postId && x.groupId == r.groupId)
          .map((x) => x.id)
          .toList();
      await reports.resolve(sameIds, widget.me.uid, 'post_deleted');
    } on PostException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on ReportException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('รายงานที่รอตรวจ')),
      body: StreamBuilder<List<Report>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'โหลดไม่สำเร็จ (ต้องเป็นผู้ดูแลระบบ)\n${snap.error}',
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
            return const Center(child: Text('ไม่มีรายงานที่รอตรวจ'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final r = list[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Chip(label: Text(r.reasonLabel)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              r.groupId == null ? 'ฟีดหลัก' : 'ในกลุ่ม/เพจ',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ผู้เขียนโพสต์: ${r.postAuthorName}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.postText.isEmpty ? '(โพสต์ไม่มีข้อความ)' : r.postText,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'รายงานโดย ${r.reporterName}'
                        '${r.detail.isEmpty ? '' : ': ${r.detail}'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _busy ? null : () => _dismiss(r),
                            child: const Text('ปิดรายงาน'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              backgroundColor: theme.colorScheme.error,
                            ),
                            onPressed: _busy
                                ? null
                                : () => _deletePost(r, list),
                            child: const Text('ลบโพสต์'),
                          ),
                        ],
                      ),
                    ],
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
