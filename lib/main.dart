import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/posts/data/post_repository.dart';
import 'firebase_options.dart';
import 'core/services/cloudinary_service.dart';
import 'features/chat/data/chat_repository.dart';
import 'features/groups/data/group_repository.dart';
import 'features/follow/data/follow_repository.dart';
import 'features/profile/data/user_repository.dart';
import 'features/follow/data/feed_visibility.dart';
import 'features/reports/data/report_repository.dart';
import 'features/notifications/data/notification_repository.dart';
import 'core/theme/theme_controller.dart';
import 'features/stories/data/story_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final repo = AuthRepository();
  final themeCtrl = ThemeController();
  await themeCtrl.load(); // อ่านโหมดสว่าง/มืดที่เคยเลือกไว้ก่อนวาดหน้าแรก
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>.value(value: themeCtrl),
        Provider<AuthRepository>.value(value: repo),
        Provider<PostRepository>(create: (_) => PostRepository()),
        ChangeNotifierProvider(create: (_) => AuthController(repo)),
        Provider<CloudinaryService>(create: (_) => CloudinaryService()),
        Provider<ChatRepository>(create: (_) => ChatRepository()),
        Provider<GroupRepository>(create: (_) => GroupRepository()),
        Provider<FollowRepository>(create: (_) => FollowRepository()),
        Provider<UserRepository>(create: (_) => UserRepository()),
        Provider<FeedVisibility>(create: (_) => FeedVisibility()),
        Provider<ReportRepository>(create: (_) => ReportRepository()),
        Provider<StoryRepository>(create: (_) => StoryRepository()),
        Provider<NotificationRepository>(
          create: (_) => NotificationRepository(),
        ),
      ],
      child: const App(),
    ),
  );
}
