import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../../auth/data/auth_repository.dart';
import '../../feed/presentation/feed_page.dart';
import '../../follow/data/follow_repository.dart';
import '../../groups/presentation/groups_page.dart';
import '../../notifications/presentation/badge_icon.dart';
import '../../profile/presentation/profile_page.dart';
import '../../profile/presentation/user_search_page.dart';

/// หน้าหลักที่มีแถบเมนูล่าง: หน้าหลัก / ค้นหา / กลุ่ม / โปรไฟล์
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _visited = <int>{0}; // สร้างหน้าก็ต่อเมื่อเปิดแท็บนั้นครั้งแรก

  Widget _page(int i, AppUser me) {
    switch (i) {
      case 0:
        return const FeedPage();
      case 1:
        return UserSearchPage(me: me);
      case 2:
        return GroupsPage(me: me);
      default:
        return const ProfilePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthRepository>();
    final uid = auth.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<AppUser?>(
      stream: auth.watchUser(uid),
      builder: (context, snap) {
        final me = snap.data;
        if (me == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: IndexedStack(
            index: _index,
            children: [
              for (var i = 0; i < 4; i++)
                _visited.contains(i) ? _page(i, me) : const SizedBox.shrink(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() {
              _index = i;
              _visited.add(i);
            }),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'หน้าหลัก',
              ),
              const NavigationDestination(
                icon: Icon(Icons.search),
                label: 'ค้นหา',
              ),
              const NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups),
                label: 'กลุ่ม',
              ),
              NavigationDestination(
                icon: StreamBadgeIcon(
                  stream: context
                      .read<FollowRepository>()
                      .watchRequests(me.uid)
                      .map((l) => l.length),
                  icon: const Icon(Icons.person_outline),
                ),
                selectedIcon: const Icon(Icons.person),
                label: 'โปรไฟล์',
              ),
            ],
          ),
        );
      },
    );
  }
}
