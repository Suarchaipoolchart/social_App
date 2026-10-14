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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final repo = AuthRepository();
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: repo),
        Provider<PostRepository>(create: (_) => PostRepository()),
        ChangeNotifierProvider(create: (_) => AuthController(repo)),
        Provider<CloudinaryService>(create: (_) => CloudinaryService()),
        Provider<ChatRepository>(create: (_) => ChatRepository()),
        Provider<GroupRepository>(create: (_) => GroupRepository()),
      ],
      child: const App(),
    ),
  );
}
