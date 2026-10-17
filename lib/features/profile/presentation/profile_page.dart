import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import 'edit_profile_page.dart';
import '../../follow/presentation/follow_requests_page.dart';
import '../../follow/presentation/follow_stats.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
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
                      const SizedBox(height: 16),
                      Text(
                        user.displayName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(user.email),
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
                      if (user.bio.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(user.bio, textAlign: TextAlign.center),
                      ],
                      const SizedBox(height: 16),
                      FollowStats(uid: user.uid),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.person_add_alt),
                        label: const Text('คำขอติดตาม'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FollowRequestsPage(me: user),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('แก้ไขโปรไฟล์'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfilePage(user: user),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
