import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../data/group_models.dart';
import '../data/group_repository.dart';
import 'create_group_page.dart';
import 'group_detail_page.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key, required this.me});

  final AppUser me;

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  late final Stream<List<Group>> _mine;
  late final Stream<List<Group>> _all;

  @override
  void initState() {
    super.initState();
    final repo = context.read<GroupRepository>();
    _mine = repo.watchMyGroups(widget.me.uid);
    _all = repo.watchDiscover();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('กลุ่มและเพจ'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'ของฉัน'),
              Tab(text: 'สำรวจ'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text('สร้าง'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateGroupPage(me: widget.me)),
          ),
        ),
        body: TabBarView(
          children: [
            _GroupList(
              stream: _mine,
              me: widget.me,
              emptyText:
                  'ยังไม่ได้เข้าร่วมกลุ่มหรือเพจใด\nไปที่แท็บ "สำรวจ" หรือกด "สร้าง"',
            ),
            _GroupList(
              stream: _all,
              me: widget.me,
              emptyText: 'ยังไม่มีกลุ่มหรือเพจ มาสร้างเป็นคนแรกเลย',
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupList extends StatefulWidget {
  const _GroupList({
    required this.stream,
    required this.me,
    required this.emptyText,
  });

  final Stream<List<Group>> stream;
  final AppUser me;
  final String emptyText;

  @override
  State<_GroupList> createState() => _GroupListState();
}

class _GroupListState extends State<_GroupList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<Group>>(
      stream: widget.stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text(
              'โหลดไม่สำเร็จ\n${snap.error}',
              textAlign: TextAlign.center,
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snap.data!;
        if (all.isEmpty) {
          return Center(
            child: Text(widget.emptyText, textAlign: TextAlign.center),
          );
        }
        final q = _query.trim().toLowerCase();
        final list = q.isEmpty
            ? all
            : all
                  .where(
                    (g) =>
                        g.name.toLowerCase().contains(q) ||
                        g.description.toLowerCase().contains(q),
                  )
                  .toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'ค้นหากลุ่มหรือเพจ',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('ไม่พบผลการค้นหา'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      itemCount: list.length,
                      itemBuilder: (context, i) =>
                          _buildCard(context, theme, list[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, ThemeData theme, Group g) {
    final isOwner = g.isOwner(widget.me.uid);
    final isMember = g.isMember(widget.me.uid);
    final scheme = theme.colorScheme;

    Widget? badge;
    if (isOwner) {
      badge = _Badge(text: 'ผู้ดูแล', color: scheme.primary);
    } else if (isMember) {
      badge = _Badge(
        text: g.isPage ? 'กำลังติดตาม' : 'เป็นสมาชิก',
        color: scheme.tertiary,
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupDetailPage(groupId: g.id, me: widget.me),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                backgroundImage: g.photoUrl != null
                    ? NetworkImage(g.photoUrl!)
                    : null,
                child: g.photoUrl == null
                    ? Icon(g.isPage ? Icons.flag : Icons.groups)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${g.typeLabel} · ${g.memberCount} ${g.memberLabel}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (g.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        g.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              if (badge != null) ...[const SizedBox(width: 8), badge],
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
