import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../follow/data/follow_repository.dart';
import '../../follow/presentation/follow_requests_page.dart';
import '../../notifications/presentation/badge_icon.dart';
import '../../posts/data/post_repository.dart';
import '../../../core/theme/theme_controller.dart';
import 'edit_profile_page.dart';
import 'user_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _tab = 0; // 0 = โพสต์, 1 = รูปภาพ, 2 = วิดีโอ

  static const _tabs = ['โพสต์', 'รูปภาพ', 'วิดีโอ'];

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AuthRepository>();
    final uid = repo.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<AppUser?>(
      stream: repo.watchUser(uid),
      builder: (context, snap) {
        final user = snap.data;
        return Scaffold(
          appBar: AppBar(
            title: const Text('โปรไฟล์'),
            actions: [
              // ถาดสี: กดแล้วมีเมนูเลือกโหมดสว่าง/มืด/ตามระบบเด้งลงมา
              PopupMenuButton<ThemeMode>(
                tooltip: 'ธีมและการแสดงผล',
                icon: const Icon(Icons.palette_outlined),
                onSelected: context.read<ThemeController>().setMode,
                itemBuilder: (_) {
                  final current = context.read<ThemeController>().mode;
                  return [
                    CheckedPopupMenuItem(
                      value: ThemeMode.system,
                      checked: current == ThemeMode.system,
                      child: const Text('ตามระบบ'),
                    ),
                    CheckedPopupMenuItem(
                      value: ThemeMode.light,
                      checked: current == ThemeMode.light,
                      child: const Text('สว่าง'),
                    ),
                    CheckedPopupMenuItem(
                      value: ThemeMode.dark,
                      checked: current == ThemeMode.dark,
                      child: const Text('มืด'),
                    ),
                  ];
                },
              ),
              IconButton(
                tooltip: 'ออกจากระบบ',
                icon: const Icon(Icons.logout),
                onPressed: () {
                  final ctrl = context.read<AuthController>();
                  Navigator.of(context).popUntil((r) => r.isFirst);
                  ctrl.logout();
                },
              ),
            ],
          ),
          body: user == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _header(context, user),
                      const SizedBox(height: 12),
                      Text(
                        user.displayName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (user.bio.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(user.bio, textAlign: TextAlign.center),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Chip(
                        avatar: Icon(
                          user.isPrivate ? Icons.lock : Icons.public,
                          size: 16,
                        ),
                        label: Text(
                          user.isPrivate ? 'โปรไฟล์ส่วนตัว' : 'โปรไฟล์สาธารณะ',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ProfileStats(uid: user.uid),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditProfilePage(user: user),
                                  ),
                                ),
                                child: const Text('แก้ไขโปรไฟล์'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: StreamBadgeIcon(
                                  stream: context
                                      .read<FollowRepository>()
                                      .watchRequests(user.uid)
                                      .map((l) => l.length),
                                  icon: const Icon(Icons.person_add_alt),
                                ),
                                label: const Text('คำขอติดตาม'),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        FollowRequestsPage(me: user),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _tabBar(context),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: AuthorPosts(
                          key: ValueKey('${user.uid}-$_tab'),
                          uid: user.uid,
                          me: user,
                          mediaFilter: _tab == 1
                              ? 'image'
                              : _tab == 2
                              ? 'video'
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  /// แบนเนอร์ด้านบน + รูปโปรไฟล์ที่ซ้อนทับขอบล่างของแบนเนอร์
  Widget _header(BuildContext context, AppUser user) {
    final scheme = Theme.of(context).colorScheme;
    final bannerH = (MediaQuery.of(context).size.width * 0.5).clamp(
      160.0,
      260.0,
    );
    return SizedBox(
      height: bannerH + 52,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: bannerH,
            child: Container(
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.18),
                image: user.coverUrl != null
                    ? DecorationImage(
                        image: NetworkImage(user.coverUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
          ),
          Positioned(
            top: bannerH - 52,
            left: 0,
            right: 0,
            child: Center(
              child: CircleAvatar(
                radius: 52,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 32),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < _tabs.length; i++)
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _tab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _tab == i
                          ? scheme.primary
                          : scheme.onSurfaceVariant.withValues(alpha: 0.25),
                      width: _tab == i ? 2.5 : 1,
                    ),
                  ),
                ),
                child: Text(
                  _tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: _tab == i ? FontWeight.bold : FontWeight.normal,
                    color: _tab == i ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// สถิติ 3 ช่อง: โพสต์ / ผู้ติดตาม / กำลังติดตาม
class _ProfileStats extends StatefulWidget {
  const _ProfileStats({required this.uid});

  final String uid;

  @override
  State<_ProfileStats> createState() => _ProfileStatsState();
}

class _ProfileStatsState extends State<_ProfileStats> {
  late final Future<List<int>> _future;

  @override
  void initState() {
    super.initState();
    final follow = context.read<FollowRepository>();
    final posts = context.read<PostRepository>();
    _future = Future.wait([
      posts.countByAuthor(widget.uid),
      follow.countFollowers(widget.uid),
      follow.countFollowing(widget.uid),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: _future,
      builder: (context, snap) {
        String v(int i) => snap.hasData ? '${snap.data![i]}' : '-';
        return Row(
          children: [
            _cell(context, v(0), 'โพสต์'),
            _divider(context),
            _cell(context, v(1), 'ผู้ติดตาม'),
            _divider(context),
            _cell(context, v(2), 'กำลังติดตาม'),
          ],
        );
      },
    );
  }

  Widget _cell(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
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
      ),
    );
  }

  Widget _divider(BuildContext context) => Container(
    width: 1,
    height: 32,
    color: Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
  );
}
