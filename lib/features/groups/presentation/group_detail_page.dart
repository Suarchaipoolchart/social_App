import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../data/group_models.dart';
import '../data/group_repository.dart';
import 'create_group_page.dart';
import 'group_feed_page.dart';

class GroupDetailPage extends StatefulWidget {
  const GroupDetailPage({super.key, required this.groupId, required this.me});

  final String groupId;
  final AppUser me;

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  late final Stream<Group?> _group;
  late final Stream<List<GroupMember>> _members;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final repo = context.read<GroupRepository>();
    _group = repo.watchGroup(widget.groupId);
    _members = repo.watchMembers(widget.groupId);
  }

  Future<void> _run(Future<void> Function(GroupRepository repo) action) async {
    if (_busy) return;
    final repo = context.read<GroupRepository>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action(repo);
    } on GroupException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String body, String okLabel) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(okLabel),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _delete(Group g) async {
    final navigator = Navigator.of(context);
    final ok = await _confirm(
      'ลบ${g.typeLabel}นี้?',
      'ลบแล้วกู้คืนไม่ได้ และ${g.memberLabel}ทั้งหมดจะถูกนำออก',
      'ลบ',
    );
    if (!ok) return;
    await _run((repo) async {
      await repo.deleteGroup(g.id);
      navigator.pop();
    });
  }

  Future<void> _leave(Group g) async {
    final ok = await _confirm(
      g.leaveLabel,
      'ต้องการ${g.leaveLabel}จาก "${g.name}" ใช่ไหม',
      g.leaveLabel,
    );
    if (!ok) return;
    await _run((repo) => repo.leave(g.id, widget.me.uid));
  }

  Widget _actions(Group g) {
    final uid = widget.me.uid;

    if (g.isOwner(uid)) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('แก้ไข'),
              onPressed: _busy
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CreateGroupPage(me: widget.me, editing: g),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: Text('ลบ${g.typeLabel}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: _busy ? null : () => _delete(g),
            ),
          ),
        ],
      );
    }

    if (g.isMember(uid)) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.logout),
        label: Text(g.leaveLabel),
        onPressed: _busy ? null : () => _leave(g),
      );
    }

    return FilledButton.icon(
      icon: const Icon(Icons.add),
      label: Text(g.joinLabel),
      onPressed: _busy
          ? null
          : () => _run((repo) => repo.join(g.id, widget.me)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<Group?>(
      stream: _group,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('โหลดข้อมูลไม่สำเร็จ\n${snap.error}')),
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final g = snap.data;
        if (g == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('ไม่พบกลุ่มนี้ (อาจถูกลบไปแล้ว)')),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(g.name, overflow: TextOverflow.ellipsis)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            child: Icon(g.isPage ? Icons.flag : Icons.groups),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  g.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${g.typeLabel} · ${g.memberCount} ${g.memberLabel}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (g.description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(g.description),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'ผู้ดูแล: ${g.ownerName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _actions(g),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.dynamic_feed),
                  title: Text('ฟีดของ${g.typeLabel}'),
                  subtitle: Text(
                    g.isPage ? 'โพสต์จากผู้ดูแลเพจ' : 'โพสต์จากสมาชิกในกลุ่ม',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          GroupFeedPage(groupId: g.id, me: widget.me),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${g.memberLabel} (${g.memberCount})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              StreamBuilder<List<GroupMember>>(
                stream: _members,
                builder: (context, msnap) {
                  if (msnap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('โหลดรายชื่อไม่สำเร็จ\n${msnap.error}'),
                    );
                  }
                  if (!msnap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return Column(
                    children: [
                      for (final m in msnap.data!)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundImage: m.photoUrl != null
                                ? NetworkImage(m.photoUrl!)
                                : null,
                            child: m.photoUrl == null
                                ? Text(
                                    m.displayName.isNotEmpty
                                        ? m.displayName[0].toUpperCase()
                                        : '?',
                                  )
                                : null,
                          ),
                          title: Text(m.displayName),
                          trailing: m.uid == g.ownerId
                              ? const Chip(label: Text('ผู้ดูแล'))
                              : null,
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
