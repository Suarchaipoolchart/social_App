import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../data/story_models.dart';
import '../data/story_repository.dart';
import 'create_story_page.dart';
import 'story_viewer_page.dart';

class StoriesBar extends StatelessWidget {
  const StoriesBar({super.key, required this.me});

  final AppUser me;

  Future<void> _create(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateStoryPage(me: me)),
    );
  }

  void _view(BuildContext context, List<UserStories> groups, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StoryViewerPage(groups: groups, initialGroup: index, me: me),
      ),
    );
  }

  Widget _addStory(BuildContext context) {
    return SizedBox(
      width: 78,
      child: GestureDetector(
        onTap: () => _create(context),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CircleAvatar(
                      backgroundImage: me.photoUrl != null
                          ? NetworkImage(me.photoUrl!)
                          : null,
                      child: me.photoUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                  ),
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.add, color: Colors.white, size: 19),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'เพิ่มสตอรี่',
              style: TextStyle(fontSize: 12),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _storyItem(
    BuildContext context,
    UserStories group,
    int index,
    List<UserStories> groups,
  ) {
    return SizedBox(
      width: 78,
      child: GestureDetector(
        onTap: () => _view(context, groups, index),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF3985FF),
                    Color(0xFF8B5CF6),
                    Color(0xFFFFB347),
                  ],
                ),
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                backgroundImage: group.authorPhotoUrl != null
                    ? NetworkImage(group.authorPhotoUrl!)
                    : null,
                child: group.authorPhotoUrl == null
                    ? const Icon(Icons.person)
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              group.authorId == me.uid ? 'สตอรี่ของฉัน' : group.authorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<StoryRepository>();

    return StreamBuilder<List<Story>>(
      stream: repo.watchActive(),
      builder: (context, snapshot) {
        final stories = snapshot.data ?? [];

        final groups = StoryRepository.group(stories, me.uid);

        return Container(
          height: 112,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              _addStory(context),
              for (int i = 0; i < groups.length; i++)
                if (groups[i].authorId != me.uid)
                  _storyItem(context, groups[i], i, groups),
              if (groups.any((g) => g.authorId == me.uid))
                _storyItem(
                  context,
                  groups.firstWhere((g) => g.authorId == me.uid),
                  groups.indexWhere((g) => g.authorId == me.uid),
                  groups,
                ),
            ],
          ),
        );
      },
    );
  }
}
