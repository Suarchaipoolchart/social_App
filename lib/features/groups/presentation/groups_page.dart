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

class _GroupList extends StatelessWidget {
  const _GroupList({
    required this.stream,
    required this.me,
    required this.emptyText,
  });

  final Stream<List<Group>> stream;
  final AppUser me;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Group>>(
      stream: stream,
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
        final list = snap.data!;
        if (list.isEmpty) {
          return Center(child: Text(emptyText, textAlign: TextAlign.center));
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: list.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final g = list[i];
            final isOwner = g.isOwner(me.uid);
            final isMember = g.isMember(me.uid);
            return ListTile(
              leading: CircleAvatar(
                child: Icon(g.isPage ? Icons.flag : Icons.groups),
              ),
              title: Text(g.name),
              subtitle: Text(
                '${g.typeLabel} · ${g.memberCount} ${g.memberLabel}',
              ),
              trailing: isOwner
                  ? const Chip(label: Text('ผู้ดูแล'))
                  : isMember
                  ? const Icon(Icons.check_circle_outline)
                  : null,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupDetailPage(groupId: g.id, me: me),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
